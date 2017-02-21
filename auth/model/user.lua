local user = {}

local digest = require('digest')
local json = require('json')
local uuid = require('uuid')
local validator =  require('auth.validator')

-----
-- user (uuid, email, is_active, password, profile)
-----
function user.model(config)
    local model = {}
    local session = require('auth.model.session').model(config)

    model.SPACE_NAME = 'portal_user'

    model.PRIMARY_INDEX = 'primary'
    model.EMAIL_INDEX = 'email_index'

    model.ID = 1
    model.EMAIL = 2
    model.IS_ACTIVE = 3
    model.PASSWORD = 4
    model.PROFILE = 5

    model.PROFILE_FIRST_NAME = 'first_name'
    model.PROFILE_LAST_NAME = 'last_name'



    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    model.SOCIAL_SESSION_TYPE = 'social'
    model.COMMON_SESSION_TYPE = 'common'

    function model.serialize(user_tuple, session)
        local user_data = {
            id = user_tuple[model.ID],
            email = user_tuple[model.EMAIL],
            is_active = user_tuple[model.IS_ACTIVE],
            profile = user_tuple[model.PROFILE],
        }
        if session ~= nil then
            user_data['session'] = session
        end
        return user_data
    end

    function model.get_by_id(user_id)
        return model.get_space():get(user_id)
    end

    function model.get_by_email(email)
        return model.get_space().index[model.EMAIL_INDEX]:select(email)[1]
    end

    function model.get_id_by_email(email)
        if not validator.not_empty_string(email) then
            return nil
        end
        local user_tuple = model.get_space().index[model.EMAIL_INDEX]:select(email)[1]
        if user_tuple ~= nil then
            return user_tuple[model.ID]
        else
            return nil
        end
    end

    function model.create(user_tuple)
        local user_id = uuid.str()
        local email = validator.string(user_tuple[model.EMAIL]) and user_tuple[model.EMAIL] or ''
        return model.get_space():insert{
            user_id,
            email,
            user_tuple[model.IS_ACTIVE],
            user_tuple[model.PASSWORD],
            user_tuple[model.PROFILE]
        }
    end

    function model.update(user_tuple)
        local user_id, fields
        user_id = user_tuple[model.ID]
        fields = {}
        for number, value in pairs(user_tuple) do
            table.insert(fields, {'=', number, value})
        end
        return model.get_space():update(user_id, fields)
    end

    function model.create_or_update(user_tuple)
        local user_id = user_tuple[model.ID]
        if user_id and model.get_space():get(user_id) then
            user_tuple = model.update(user_tuple)
        else
            user_tuple = model.create(user_tuple)
        end
        return user_tuple
    end

    function model.generate_activation_code(user_id)
        return digest.md5_hex(string.format('%s%s', config.activation_secret, user_id))
    end

    function model.hash_password(password, salt)
        -- Need stronger hash?
        return digest.sha256(string.format('%s%s', salt, password))
    end

    local function make_session_sign(encoded_session_data, user_secret)
        local sign = digest.sha256_hex(string.format('%s%s%s',
            user_secret,
            encoded_session_data,
            config.session_secret
        ))
        return digest.base64_encode(sign)
    end

    local function get_expiration_time()
        return os.time() + config.session_lifetime
    end

    local function get_social_update_time()
        return os.time() + config.social_check_time
    end

    local function split_session(session)
        return string.match(session, '([^.]+).([^.]+)')
    end

    function model.create_session(user_id, type)
        local expiration_time, update_time, session_data, session_tuple
        update_time = get_social_update_time()
        expiration_time = get_expiration_time()
        session_tuple = session.generate()
        session_data = {
                user_id = user_id,
                session_id = session_tuple[session.ID],
                exp = expiration_time,
                type = type,
        }

        if type == model.SOCIAL_SESSION_TYPE then
            session_data['update'] = update_time
        end

        session_data = json.encode(session_data)
        local encoded_session_data = digest.base64_encode(session_data)
        local encoded_sign = make_session_sign(encoded_session_data, session_tuple[session.CODE])
        return string.format('%s.%s', encoded_session_data, encoded_sign)
    end

    function model.session_is_valid(encoded_session)
        local encoded_session_data, user_sign = split_session(encoded_session)
        local session_tuple = model.get_session_tuple(encoded_session_data)
        if session_tuple == nil then
            return false
        end
        local sign = make_session_sign(encoded_session_data, session_tuple[session.CODE])
        return sign == user_sign
    end

    function model.get_session_data(encoded_sesssion)
        local encoded_session_data, sign = split_session(encoded_sesssion)
        local session_data = session.decode_session(encoded_session_data)
        if session_data == nil then
            return nil
        end

        local user_tuple = model.get_space():get(session_data.user_id)
        return user_tuple, session_data
    end

    function model.get_session_tuple(encoded_session_data)
        local session_data = session.decode_session(encoded_session_data)
        if session_data == nil then
            return nil
        end

        local session_tuple = session.get(session_data.session_id)
        return session_tuple
    end

    return model
end

return user