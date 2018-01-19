local token = {}

local validator =  require('authman.validator')


-----
-- oauth access token
-- oauth_token (access_token, consumer_key, refresh_token, redirect_url, scope, expires_in, created_at)
-----
function token.model(config)

    local model = {}
    model.SPACE_NAME = config.spaces.oauth_token.name

    model.PRIMARY_INDEX = 'primary'
    model.REFRESH_INDEX = 'refresh'
    model.CONSUMER_INDEX = 'consumer'

    model.ACCESS_TOKEN = 1
    model.CONSUMER_KEY = 2
    model.REFRESH_TOKEN = 3
    model.REDIRECT_URL = 4
    model.SCOPE = 5
    model.EXPIRES_IN = 6
    model.CREATED_AT = 7

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(token_tuple, data)

        local result = {
            access_token = token_tuple[model.ACCESS_TOKEN],
            consumer_key = token_tuple[model.CONSUMER_KEY],
            refresh_token = token_tuple[model.REFRESH_TOKEN],
            redirect_url = token_tuple[model.REDIRECT_URL],
            scope = token_tuple[model.SCOPE],
            expires_in = token_tuple[model.EXPIRES_IN],
            created_at = token_tuple[model.CREATED_AT],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                result[k] = v
            end
        end

        return result
    end

    function model.create(token_tuple)
        return model.get_space():insert(token_tuple)
    end

    function model.get_by_access_token(access_token)
        if validator.not_empty_string(access_token) then
            return model.get_space():get(access_token)
        end
    end

    function model.get_by_refresh_token(refresh_token)
        if validator.not_empty_string(refresh_token) then
            return model.get_space().index[model.REFRESH_INDEX]:get(refresh_token)
        end
    end

    function model.delete(access_token)
        if validator.not_empty_string(access_token) then
            return model.get_space():delete(access_token)
        end
    end

    function model.delete_expired(expiration_ts)
        local total = 0
        local total_deleted = 0
        for _, t in model.get_space().index[model.PRIMARY_INDEX]:pairs(nil, {iterator = box.index.ALL}) do

            if t[model.CREATED_AT] + t[model.EXPIRES_IN] <= expiration_ts then
                model.get_space():delete({t[model.ACCESS_TOKEN]})
                total_deleted = total_deleted + 1
            end
            total = total + 1
            if math.fmod(total, 500) == 0 then
                fiber.yield()
            end
        end

        return total_deleted
    end

    function model.delete_by_refresh(refresh_token)
        if validator.not_empty_string(refresh_token) then
            return model.get_space().index[model.REFRESH_INDEX]:delete(refresh_token)
        end
    end

    function model.get_by_consumer_key(consumer_key)
        if validator.not_empty_string(consumer_key) then
            return model.get_space().index[model.CONSUMER_INDEX]:select({consumer_key})
        end
    end

    function model.delete_by_consumer_key(consumer_key)
        local token_list = model.get_by_consumer_key(consumer_key)
        if token_list ~= nil then
            for i, tuple in  ipairs(token_list) do
                model.get_space():delete({tuple[model.ACCESS_TOKEN]})
            end
            return token_list
        end
    end

    return model
end

return token
