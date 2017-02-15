local user = {}
local digest = require('digest')
local config = require('config')
local json = require('json')
-----
-- user (uuid, email, is_active, password, profile)
-----

user.SPACE_NAME = 'portal_user'

user.PRIMARY_INDEX = 'primary'
user.EMAIL_INDEX = 'email_index'

user.ID = 1
user.EMAIL = 2
user.IS_ACTIVE = 3
user.PASSWORD = 4
user.PROFILE = 5

function user.get_space()
    return box.space[user.SPACE_NAME]
end

user.SOCIAL_SESSION_TYPE = 'social'
user.COMMON_SESSION_TYPE = 'common'

function user.serialize(user_tuple, session)
    local user_data = {
        id = user_tuple[user.ID],
        email = user_tuple[user.EMAIL],
        is_active = user_tuple[user.IS_ACTIVE],
    }
    if session ~= nil then
        user_data['session'] = session
    end
    return user_data
end

function user.get_by_email(email)
    return user.get_space().index[user.EMAIL_INDEX]:select(email)[1]
end

function user.get_id_by_email(email)
    local user_tuple = user.get_space().index[user.EMAIL_INDEX]:select(email)[1]
    if user_tuple ~= nil then
        return user_tuple[user.ID]
    else
        return nil
    end
end

function user.create_or_update(user_id, email, is_active, password)
    local user_tuple
    user_tuple = user.get_space():get(user_id)
    if user_tuple ~= nil then
        user_tuple = user.get_space():update(user_id, {
            {'=', user.EMAIL, email},
            {'=', user.IS_ACTIVE, is_active},
            {'=', user.PASSWORD, password}
        })
    else
        user_tuple = user.get_space():insert({user_id, email, is_active, password})
    end
    return user_tuple
end

function user.generate_activation_code(user_id)
    return digest.md5_hex(string.format('%s%s', config.activation_secret, user_id))
end

function user.hash_password(password, salt)
    -- Need stronger hash?
    return digest.sha256(string.format('%s%s', salt, password))
end

function make_session_sign(encoded_session_data)
    local sign = digest.sha256_hex(string.format('%s%s', encoded_session_data, config.session_secret))
    return digest.base64_encode(sign)
end

function get_expiration_time()
    return os.time() + config.session_lifetime
end

function get_social_expiration_time()
    return os.time() + config.social_check_time
end

function split_session(session)
    return string.match(session, '([^.]+).([^.]+)')
end

function user.create_session(user_id, type)
    local expiration_time
    if type == user.SOCIAL_SESSION_TYPE then
        expiration_time = get_social_expiration_time()
    else
        expiration_time = get_expiration_time()
    end

    local session_data = json.encode({user_id = user_id, exp = expiration_time, type = type})
    local encoded_session_data = digest.base64_encode(session_data)

    local encoded_sign = make_session_sign(encoded_session_data)
    return string.format('%s.%s', encoded_session_data, encoded_sign)
end

function user.session_is_valid(session)
    local encoded_session_data, user_sign = split_session(session)
    local sign = make_session_sign(encoded_session_data)
    return sign == user_sign
end

function user.get_session_data(session)
    local encoded_session_data, sign = split_session(session)
    local session_data_json = digest.base64_decode(encoded_session_data)
    local session_data = json.decode(session_data_json)

    local user_tuple = user.get_space():get(session_data.user_id)
    return user_tuple, session_data
end

return user