local password_token = {}

local digest = require('digest')

-----
-- token (user_uuid, code)
-----
function password_token.model(config)
    local model = {}

    model.SPACE_NAME = 'auth_password_token'

    model.PRIMARY_INDEX = 'primary'

    model.USER_ID = 1
    model.CODE = 2

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(token_tuple)
        return {
            id = token_tuple[model.ID],
            code = token_tuple[model.CODE],
        }
    end

    function model.generate_restore_token(user_id)
        local token = digest.md5_hex(user_id .. os.time() .. config.restore_secret)
        model.get_space():upsert({user_id, token}, {{'=', 2, token}})
        return token
    end

    function model.restore_token_is_valid(user_id, user_token)
        local token_tuple = model.get_space():select{user_id}[1]
        if token_tuple == nil then
            return false
        end
        local token = token_tuple[2]
        if token ~= user_token then
            return false
        else
            model.get_space():delete{user_id}
            return true
        end
    end

    return model
end

return password_token