local app = {}

local uuid = require('uuid')
local validator =  require('authman.validator')
local utils = require('authman.utils.utils')


-----
-- app (uuid, user_uuid, type, is_active, domain, redirect_url, secret)
-----
function app.model(config)

    local oauth_consumer = require('authman.model.oauth.consumer').model(config)
    local oauth_code = require('authman.model.oauth.code').model(config)
    local oauth_token = require('authman.model.oauth.token').model(config)

    local model = {}
    model.SPACE_NAME = config.spaces.oauth_app.name

    model.PRIMARY_INDEX = 'primary'
    model.USER_ID_INDEX = 'user'

    model.ID = 1
    model.USER_ID = 2
    model.NAME = 3
    model.TYPE = 4
    model.IS_ACTIVE = 5
    model.REGISTRATION_TS = 6

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(app_tuple, data)

        local app_data = {
            id = app_tuple[model.ID],
            user_id = app_tuple[model.USER_ID],
            name = app_tuple[model.NAME],
            type = app_tuple[model.TYPE],
            is_active = app_tuple[model.IS_ACTIVE],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                app_data[k] = v
            end
        end

        return app_data
    end


    function model.create(app_tuple)
        app_tuple[model.REGISTRATION_TS] = utils.now()

        local app_id = uuid.str()
        local app_type = validator.oauth_app_type(app_tuple[model.TYPE]) and app_tuple[model.TYPE] or 'browser'

        return model.get_space():insert{
            app_id,
            app_tuple[model.USER_ID],
            app_tuple[model.NAME],
            app_tuple[model.TYPE],
            app_tuple[model.IS_ACTIVE],
            app_tuple[model.REGISTRATION_TS],
        }

    end

    function model.get_by_user_id(user_id)
        if validator.not_empty_string(user_id) then
            return model.get_space().index[model.USER_ID_INDEX]:select({user_id})
        end
    end

    function model.delete_by_user_id(user_id)

        local app_list = model.get_by_user_id(user_id)
        if app_list ~= nil then
            for i, tuple in ipairs(app_list) do
                local consumer = oauth_consumer.delete_by_app_id(tuple[model.ID])

                if consumer ~= nil then
                    oauth_code.delete_by_consumer_key(consumer[oauth_consumer.ID])
                    oauth_token.delete_by_consumer_key(consumer[oauth_consumer.ID])
                end
                model.get_space():delete({tuple[model.ID]})
            end
            return app_list
        end
    end

    function model.get_by_id(id)
        if validator.not_empty_string(id) then
            return model.get_space():get(id)
        end
    end

    function model.delete(id)
        if validator.not_empty_string(id) then
            return model.get_space():delete({id})
        end
    end

    function model.update(app_tuple)
        local id, fields
        id = app_tuple[model.ID]
        fields = utils.format_update(app_tuple)
        return model.get_space():update(id, fields)
    end

    return model
end

return app
