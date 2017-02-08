local uuid = require('uuid')
local config = require('config')
local digest = require('digest')
local response = require('response')
local json = require('json')
local session = require('session')

local user_space = box.space.portal_user
-----
-- user (uuid, email, is_active, password, profile)
-----

function generate_activation_code(user_id)
    return digest.md5_hex(string.format('%s%s', config.activation_secret, user_id))
end

function find_user(email)
    return user_space.index.email:select(email)[1]
end

-----
-- API methods
-----
exports = {}

function exports.registration(email)
    local user = find_user(email)
    if user ~= nil then
        local message = string.format('User with email %s already exists', email)
        return response.error(message)
    end
    local user_id = uuid.str()
    local code = generate_activation_code(user_id)
    user_space:insert{user_id, email, false, '', nil}
    return response.ok(code)
end

function exports.complete_registration(email, code, password)
    local user = find_user(email)
    if user == nil then
        local message = string.format('User with email %s does not exist', email)
        return response.error(message)
    end
    local user_id = user[1]
    local correct_code = generate_activation_code(user_id)
    if code ~= correct_code then
        local message = string.format('Wrong activation code', email)
        return response.error(message)
    end
    user_space:update(user_id, {{'=', 3, true}, {'=', 4, session.hash_password(password)}})
    user = user_space:get(user_id)
    return response.ok(user)
end

function exports.auth(email, password)
    local user = find_user(email)
    if user == nil then
        local message = string.format('User not found')
        return response.error(message)
    end

    local user_id = user[1]
    local user_password = user[4]
    if session.hash_password(password) ~= user_password then
        local message = string.format('Wrong password')
        return response.error(message)
    end

    local session = session.create_session(user_id)
    return response.ok(session)
end

function exports.check_auth(session)
    local is_signed = check_session(session)
    if not is_signed then
        local message = string.format('Wrong sign')
        return response.error(message)
    end

    local encoded_session_data, sign = string.match(session, '([^.]+).([^.]+)')
    local session_data_json = digest.base64_decode(encoded_session_data)
    local session_data = json.decode(session_data_json)
    local user = user_space:get{session_data.user_id}
    if user == nil then
        local message = string.format('User not found')
        return response.error(message)
    end

    local new_session

    if session_data.exp < os.time() then
        local message = string.format('User is logged out')
        return response.error(message)
    elseif session_data.exp < (os.time() - config.session_update_timedelta) then
        new_session = session.create_session(session_data.user_id)
    else
        new_session = session
    end

    return response.ok(new_session)
end

function exports.create_social_user()
    local user_id = uuid.str()
    user_space:insert{user_id, '', true, '', nil }
    return response.ok()
end

return exports