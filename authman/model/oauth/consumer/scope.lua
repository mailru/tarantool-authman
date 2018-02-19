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
            for i, scope_tuple in ipairs(scope_tuples) do
                res[i] = {
                    user_id = scope_tuple[model.USER_ID],
                    consumer_key = scope_tuple[model.CONSUMER_KEY],
                    name = scope_tuple[model.NAME],
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

            if validator.not_empty_string(scope_name)
                and not model.scope_exists(scope_name, cur_scopes) then

                local scope_tuple = {
                    [model.CONSUMER_KEY] = consumer_key,
                    [model.USER_ID] = user_id,
                    [model.NAME] = scope_name,
                }

                table.insert(cur_scopes, model.get_space():replace(scope_tuple))
            end
        end

        return cur_scopes
    end

    function model.scope_exists(scope_name, scopes)
        for _, scope in ipairs(scopes) do
            if scope[model.NAME] == scope_name then
                return true
            end
        end

        return false
    end

    function model.get_by_user_id(user_id)
        return model.get_space().index[model.USER_ID_INDEX]:select({user_id})
    end

    function model.delete_by_user_id(user_id)
        local scope_list = {}
        local tuples = model.get_by_user_id(user_id)
        for i, tuple in ipairs(tuples) do
            scope_list[i] = model.get_space():delete({tuple[model.CONSUMER_KEY], tuple[model.USER_ID], tuple[model.NAME]})
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
        for i, tuple in ipairs(tuples) do
            scope_list[i] = model.get_space():delete({tuple[model.CONSUMER_KEY], tuple[model.USER_ID], tuple[model.NAME]})
        end
        return scope_list
    end

    return model
end

return scope
