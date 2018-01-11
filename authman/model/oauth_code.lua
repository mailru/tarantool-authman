local code = {}

local validator =  require('authman.validator')


-----
-- oauth authorization code
-- oauth_code (code, consumer_key, redirect_url, scope, state, expires_in, created_at, code_challenge, code_challenge_method)
-----
function code.model(config)

    local model = {}
    model.SPACE_NAME = config.spaces.oauth_code.name

    model.PRIMARY_INDEX = 'primary'
    model.CONSUMER_INDEX = 'consumer'

    model.CODE = 1
    model.CONSUMER_KEY = 2
    model.REDIRECT_URL = 3
    model.SCOPE = 4
    model.STATE = 5
    model.EXPIRES_IN = 6
    model.CREATED_AT = 7
    model.CODE_CHALLENGE = 8
    model.CODE_CHALLENGE_METHOD = 9 

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(code_tuple, data)

        local result = {
            code = code_tuple[model.CODE],
            consumer_key = code_tuple[model.CONSUMER_KEY],
            redirect_url = code_tuple[model.REDIRECT_URL],
            scope = code_tuple[model.SCOPE],
            state = code_tuple[model.STATE],
            expires_in = code_tuple[model.EXPIRES_IN],
            created_at = code_tuple[model.CREATED_AT],
            code_challenge = code_tuple[model.CODE_CHALLENGE],
            code_challenge_method = code_tuple[model.CODE_CHALLENGE_METHOD],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                result[k] = v
            end
        end

        return result
    end

    function model.create(code_tuple)
        return model.get_space():insert(code_tuple)
    end

    function model.get_by_code(code)
        if validator.not_empty_string(code) then
            return model.get_space():get(code)
        end
    end

    function model.delete(code)
        if validator.not_empty_string(code) then
            return model.get_space():delete({code})
        end
    end

    return model
end

return code
