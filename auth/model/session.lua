local session = {}

local utils = require('auth.utils.utils')
local digest = require('digest')
local uuid = require('uuid')
local json = require('json')

-----
-- token (id, code, user_id, credential_id(optional))
-----
function session.model(config)
    local model = {}

    model.SPACE_NAME = 'auth_sesssion'

    model.PRIMARY_INDEX = 'primary'

    model.ID = 1
    model.CODE = 2
    model.USER_ID = 3
    model.CREDENTIAL_ID = 4

    model.SOCIAL_SESSION_TYPE = 'social'
    model.COMMON_SESSION_TYPE = 'common'

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.generate(user_id, credential_id)
        local code = uuid.str()
        local session_id = uuid.str()
        return model.get_space():insert({session_id, code, user_id, credential_id})
    end

    function model.get_by_id(session_id)
        return model.get_space():get(session_id)
    end

    function model.delete(encoded_session_data)
        local session_tuple = model.get_by_session(encoded_session_data)
        if session_tuple == nil then
            return false
        end

        session_tuple = model.get_space():delete(session_tuple[model.ID])
        return session_tuple ~= nil
    end

    function model.decode(encoded_session_data)
        local session_data_json, session_data, ok, msg
        ok, msg = pcall(function()
            session_data_json = digest.base64_decode(encoded_session_data)
            session_data = json.decode(session_data_json)
        end)
        return session_data
    end

    function model.get_by_session(encoded_session_data)
        local session_data = model.decode(encoded_session_data)
        if session_data == nil then
            return nil
        end

        local session_tuple = model.get_by_id(session_data.sid)
        return session_tuple
    end

    local function make_session_sign(encoded_session_data, session_code)
        local sign = digest.sha256_hex(string.format('%s%s%s',
            session_code,
            encoded_session_data,
            config.session_secret
        ))
        return utils.base64_encode(sign)
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

    function model.create(user_id, type, credential_id)
        local expiration_time, update_time, session_data, session_tuple
        update_time = get_social_update_time()
        expiration_time = get_expiration_time()
        session_tuple = model.generate(user_id, credential_id)
        session_data = {
                sid = session_tuple[model.ID],
                exp = expiration_time,
                type = type,
        }

        if type == model.SOCIAL_SESSION_TYPE then
            session_data['update'] = update_time
        end

        session_data = json.encode(session_data)
        local encoded_session_data = utils.base64_encode(session_data)
        local encoded_sign = make_session_sign(encoded_session_data, session_tuple[model.CODE])
        return string.format('%s.%s', encoded_session_data, encoded_sign)
    end

    function model.validate_session(encoded_session)
        local encoded_session_data, session_sign = split_session(encoded_session)
        local session_tuple = model.get_by_session(encoded_session_data)

        if session_tuple == nil then
            return nil
        end

        local sign = make_session_sign(encoded_session_data, session_tuple[model.CODE])

        if sign ~= session_sign then
            return nil
        end

        return encoded_session_data
    end

    return model
end

return session