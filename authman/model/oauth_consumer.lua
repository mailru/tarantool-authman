local consumer = {}

local validator =  require('authman.validator')
local utils = require('authman.utils.utils')
local uuid = require('uuid')


-----
-- oauth_consumer (id, secret, application_id, redirect_urls)
-----
function consumer.model(config)

    local model = {}
    model.SPACE_NAME = config.spaces.oauth_consumer.name

    model.PRIMARY_INDEX = 'primary'
    model.APPLICATION_ID_INDEX = 'application'

    model.ID = 1
    model.SECRET_HASH = 2
    model.APPLICATION_ID = 3
    model.REDIRECT_URLS = 4 -- blank space separated list

    model.CONSUMER_SECRET_LEN = 32

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(consumer_tuple, data)
        if consumer_tuple == nil then
            return {}
        end

        local result = {
            consumer_key = consumer_tuple[model.ID],
            consumer_secret_hash = consumer_tuple[model.SECRET_HASH],
            application_id = consumer_tuple[model.APPLICATION_ID],
            redirect_urls = consumer_tuple[model.REDIRECT_URLS],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                result[k] = v
            end
        end

        return result
    end


    function model.create(id, secret, app_id, redirect_urls)

        return model.get_space():insert{
            id,
            utils.salted_hash(secret, app_id),
            app_id,
            redirect_urls,
        }
    end

    function model.get_by_id(id)
        if validator.not_empty_string(id) then
            return model.get_space():get(id)
        end
    end

    function model.get_by_application_id(app_id)
        if validator.not_empty_string(app_id) then
            return model.get_space().index[model.APPLICATION_ID_INDEX]:get(app_id)
        end
    end

    function model.generate_consumer_key()
        return string.hex(uuid.bin())
    end

    function model.generate_consumer_secret()
        return utils.gen_random_key(model.CONSUMER_SECRET_LEN) 
    end

    function model.update_consumer_secret(consumer_key, consumer_secret, app_id)
        local consumer_secret_hash = utils.salted_hash(consumer_secret, app_id)
        return model.get_space():update(consumer_key, {{'=', model.SECRET_HASH, consumer_secret_hash}})
    end

    function model.delete_by_application_id(app_id)
        if validator.not_empty_string(app_id) then
            return model.get_space().index[model.APPLICATION_ID_INDEX]:delete(app_id)
        end
    end

    return model
end

return consumer
