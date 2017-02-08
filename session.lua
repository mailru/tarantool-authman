local digest = require('digest')
local config = require('config')
local json = require('json')

function make_session_sign(encoded_session_data)
    local sign = digest.sha256_hex(string.format('%s%s', encoded_session_data, config.session_secret))
    return digest.base64_encode(sign)
end

function get_expiration_time()
    return os.time() + config.session_lifetime
end

exports = {}

function exports.hash_password(password, salt)
    -- Need stronger hash?
    return digest.sha256(string.format('%s%s', salt, password))
end

function exports.create_session(user_id)
    local expiration_time = get_expiration_time()
    local session_data = json.encode({user_id = user_id, exp = expiration_time})
    local encoded_session_data = digest.base64_encode(session_data)

    local encoded_sign = make_session_sign(encoded_session_data)
    return string.format('%s.%s', encoded_session_data, encoded_sign)
end

function exports.check_session(session)
    local encoded_session_data, user_sign = string.match(session, '([^.]+).([^.]+)')
    local sign = make_session_sign(encoded_session_data)
    return sign == user_sign
end

return exports