local scope = {}

local validator =  require('authman.validator')


-----
-- oauth consumer authorization scope
-- oauth_scope (user_id, consumer_key, scope)
-----
function scope.model(config)
    local model = {}
    model.SPACE_NAME = config.spaces.oauth_scope.name

    model.PRIMARY_INDEX = 'primary'
    model.USER_ID_INDEX = 'user_id'

    model.CONSUMER_KEY = 1
    model.USER_ID = 2
    model.NAME = 3

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(scope_tuples, data)

        local res = {}

        if scope_tuples ~= nil then
            for i, t in ipairs(scope_tuples) do
                res[i] = {
                    user_id = t[model.USER_ID],
                    consumer_key = t[model.CONSUMER_KEY],
                    name = t[model.NAME],
                }

                if data and data[i] then
                    for k,v in pairs(data[i]) do
                        res[i][k] = v
                    end
                end
            end
        end

        return res
    end

    function model.add_consumer_scopes(consumer_key, user_id, scopes)

        local cur_scopes = model.get_by_consumer_key(consumer_key, user_id)
        for _, scope_name in ipairs(scopes) do

            if validator.not_empty_string(scope_name) then
                for _, e in ipairs(cur_scopes) do
                    if e[model.NAME] == scope_name then
                        goto continue
                    end
                end

                local scope_tuple = {
                    [model.CONSUMER_KEY] = consumer_key,
                    [model.USER_ID] = user_id,
                    [model.NAME] = scope_name,
                }

                table.insert(cur_scopes, model.get_space():replace(scope_tuple))
            end

            ::continue::
        end

        return cur_scopes
    end

    function model.get_by_user_id(user_id)
        return model.get_space().index[model.USER_ID_INDEX]:select({user_id})
    end

    function model.delete_by_user_id(user_id)
        local scope_list = {}
        local tuples = model.get_by_user_id(user_id)
        for i, t in ipairs(tuples) do
            scope_list[i] = model.get_space():delete({t[model.CONSUMER_KEY], t[model.USER_ID], t[model.NAME]})
        end
        return scope_list
    end

    function model.get_by_consumer_key(consumer_key, user_id)
        local query = {[model.CONSUMER_KEY] = consumer_key}
        if validator.not_empty_string(user_id) then
            query[model.USER_ID] = user_id
        end
        return model.get_space().index[model.PRIMARY_INDEX]:select(query)
    end

    function model.delete_by_consumer_key(consumer_key, user_id)
        local scope_list = {}
        local tuples = model.get_by_consumer_key(consumer_key, user_id)
        for i, t in ipairs(tuples) do
            scope_list[i] = model.get_space():delete({t[model.CONSUMER_KEY], t[model.USER_ID], t[model.NAME]})
        end
        return scope_list
    end

    return model
end

return scope
