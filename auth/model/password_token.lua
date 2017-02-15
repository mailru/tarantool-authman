local password_token = {}

local digest = require('digest')
local config = require('auth.config')
-----
-- token (user_uuid, code)
-----

password_token.SPACE_NAME = 'portal_reset_pwd_token'

password_token.PRIMARY_INDEX = 'primary'

password_token.USER_ID = 1
password_token.CODE = 2

function password_token.get_space()
    return box.space[password_token.SPACE_NAME]
end

function password_token.serialize(token_tuple)
    return {
        id = token_tuple[password_token.ID],
        code = token_tuple[password_token.CODE],
    }
end

function password_token.generate_restore_token(user_id)
    local token = digest.md5_hex(user_id .. os.time() .. config.restore_secret)
    password_token.get_space():upsert({user_id, token}, {{'=', 2, token}})
    return token
end

function password_token.restore_token_is_valid(user_id, user_token)
    local token_tuple = password_token.get_space():select{user_id}[1]
    if token_tuple == nil then
        return false
    end
    local token = token_tuple[2]
    if token ~= user_token then
        return false
    else
        password_token.get_space():delete{user_id}
        return true
    end
end

return password_token
