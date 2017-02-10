local auth = {}
local uuid = require('uuid')
local config = require('config')
local digest = require('digest')
local response = require('response')
local error = require('error')
local json = require('json')
local session = require('session')
local validator = require('validator')

local user = require('model.user')
local password_token = require('model.password_token')

local user_space = user.get_space()
local pwd_token_space = password_token.get_space()


function generate_activation_code(user_id)
    return digest.md5_hex(string.format('%s%s', config.activation_secret, user_id))
end

function generate_restore_token(user_id)
    local token = digest.md5_hex(user_id .. os.time() .. config.restore_secret)
    pwd_token_space:upsert(user_id, {{'=', 2, token}})
    return token
end

function restore_token_is_valid(user_id, user_token)
    local token = pwd_token_space:get{user_id}[2]
    if token ~= user_token then
        return False
    else
        pwd_token_space:delete{user_id}
        return True
    end
end

-----
-- API methods
-----
function auth.registration(email)
    if not validator.email(email) then
        return response.error(error.INVALID_PARAMS)
    end

    local user_tuple = user.get_by_email(email)
    if user_tuple ~= nil then
        return response.error(error.USER_ALREADY_EXISTS)
    end

    local user_id = uuid.str()
    local code = generate_activation_code(user_id)
    user_space:insert{user_id, email, false, '' }
    return response.ok(code)
end

function auth.complete_registration(email, code, password)
    if not validator.email(email) then
        return response.error(error.INVALID_PARAMS)
    end

    local user_tuple = user.get_by_email(email)
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    local user_id = user_tuple[user.ID]
    local correct_code = generate_activation_code(user_id)
    if code ~= correct_code then
        return response.error(error.WRONG_ACTIVATION_CODE)
    end

    user_space:update(user_id, {{'=', 3, true}, {'=', 4, session.hash_password(password)}})
    user_tuple = user_space:get(user_id)
    return response.ok(user.serialize(user_tuple))
end

function auth.auth(email, password)
    local user_tuple = user.get_by_email(email)
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    if not user_tuple[user.IS_ACTIVE] then
        return response.error(error.USER_NOT_ACTIVE)
    end
    if session.hash_password(password) ~= user_tuple[user.PASSWORD] then
        return response.error(error.WRONG_PASSWORD)
    end

    local signed_session = session.create_session(user_tuple[user.ID])
    return response.ok(signed_session)
end

function auth.check_auth(signed_session)
    if not session.sign_is_valid(signed_session) then
        return response.error(error.WRONG_SESSION_SIGN)
    end

    local encoded_session_data, sign = string.match(session, '([^.]+).([^.]+)')
    local session_data_json = digest.base64_decode(encoded_session_data)
    local session_data = json.decode(session_data_json)
    local user_tuple = user_space:get{session_data.user_id}
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    local new_session

    if session_data.exp < os.time() then
        return response.error(error.NOT_AUTHENTICATED)
    elseif session_data.exp < (os.time() - config.session_update_timedelta) then
        new_session = session.create_session(session_data.user_id)
    else
        new_session = signed_session
    end

    return response.ok(new_session)
end

function auth.restore_password(email)
    local user_tuple = user.get_by_email(email)
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    return response.ok(generate_restore_token(user_tuple[user.ID]))
end

function auth.set_new_password(email, token, password)
    local user_tuple = user.get_by_email(email)
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    if restore_token_is_valid(email, token) then
        user_space:update(user_tuple[user.ID], {{'=', user.PASSWORD, session.hash_password(password)}})
        return response.ok(user.serialize(user_tuple))
    else
        return response.error(error.WRONG_RESTORE_TOKEN)
    end
end

--function auth.create_social_user()
--    local user_id = uuid.str()
--    user_space:insert{user_id, '', true, '', nil }
--    return response.ok()
--end

return auth