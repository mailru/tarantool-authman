local redirect = {}

local validator =  require('authman.validator')


-----
-- oauth consumer redirect url
-- oauth_redirect (consumer_key, user_id, url)
-----
function redirect.model(config)
    local model = {}
    model.SPACE_NAME = config.spaces.oauth_redirect.name

    model.PRIMARY_INDEX = 'primary'
    model.USER_ID_INDEX = 'user_id'

    model.CONSUMER_KEY = 1
    model.USER_ID = 2
    model.URL = 3

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(redirect_tuple)

        local data = {
            consumer_key = redirect_tuple[model.CONSUMER_KEY],
            user_id = redirect_tuple[model.USER_ID],
            url = redirect_tuple[model.URL],
        }

        return data
    end

    function model.upsert_redirect(redirect_tuple)
        model.get_space():upsert(redirect_tuple, {{'=', model.URL, redirect_tuple[model.URL]}})
        return redirect_tuple
    end

    function model.get_by_user_id(user_id)
        return model.get_space().index[model.USER_ID_INDEX]:select({user_id})
    end

    function model.delete_by_user_id(user_id)
        local redirect_list = {}
        local tuples = model.get_by_user_id(user_id)
        for i, t in ipairs(tuples) do
            redirect_list[i] = model.get_space():delete({[model.CONSUMER_KEY] = t[model.CONSUMER_KEY], [model.USER_ID] = t[model.USER_ID]})
        end
        return redirect_list
    end

    function model.get_by_consumer_key(consumer_key, user_id)
        local query = {[model.CONSUMER_KEY] = consumer_key}
        if validator.not_empty_string(user_id) then
            query[model.USER_ID] = user_id
        end
        return model.get_space().index[model.PRIMARY_INDEX]:select(query)
    end

    function model.delete_by_consumer_key(consumer_key, user_id)
        local redirect_list = {}
        local tuples = model.get_by_consumer_key(consumer_key, user_id)
        for i, t in ipairs(tuples) do
            redirect_list[i] = model.get_space():delete({[model.CONSUMER_KEY] = t[model.CONSUMER_KEY], [model.USER_ID] = t[model.USER_ID]})
        end
        return redirect_list
    end

    return model
end

return redirect
