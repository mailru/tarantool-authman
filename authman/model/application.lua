local application = {}

local uuid = require('uuid')
local validator =  require('authman.validator')
local utils = require('authman.utils.utils')


-----
-- application (uuid, user_uuid, type, is_active, domain, redirect_url, secret)
-----
function application.model(config)

    local model = {}
    model.SPACE_NAME = config.spaces.application.name

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
        local app_type = validator.application_type(app_tuple[model.TYPE]) and app_tuple[model.TYPE] or 'browser'

        return model.get_space():insert{
            app_id,
            app_tuple[model.USER_ID],
            app_tuple[model.NAME],
            app_tuple[model.TYPE],
            app_tuple[model.IS_ACTIVE],
            app_tuple[model.REGISTRATION_TS],
        }

    end

    function model.get_user_apps(user_id)
        if validator.not_empty_string(user_id) then
            return model.get_space().index[model.USER_ID_INDEX]:select({user_id})
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

    return model
end

return application
