local user = {}

local digest = require('digest')
local uuid = require('uuid')
local validator =  require('authman.validator')
local utils = require('authman.utils.utils')

-----
-- user (uuid, email, type, is_active, profile)
-----
function user.model(config)
    local model = {}
    model.SPACE_NAME = config.spaces.user.name

    model.PRIMARY_INDEX = 'primary'
    model.EMAIL_INDEX = 'email_index'

    model.ID = 1
    model.EMAIL = 2
    model.TYPE = 3
    model.IS_ACTIVE = 4
    model.PROFILE = 5

    model.PROFILE_FIRST_NAME = 'first_name'
    model.PROFILE_LAST_NAME = 'last_name'

    model.COMMON_TYPE = 1
    model.SOCIAL_TYPE = 2

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(user_tuple, data)

        local user_data = {
            id = user_tuple[model.ID],
            email = user_tuple[model.EMAIL],
            is_active = user_tuple[model.IS_ACTIVE],
            profile = user_tuple[model.PROFILE],
        }
        if data ~= nil then
            for k,v in pairs(data) do
                user_data[k] = v
            end
        end

        return user_data
    end

    function model.get_by_id(user_id)
        return model.get_space():get(user_id)
    end

    function model.get_by_email(email, type)
        if validator.not_empty_string(email) then
            return model.get_space().index[model.EMAIL_INDEX]:select({email, type})[1]
        end
    end

    function model.get_id_by_email(email, type)
        local user_tuple = model.get_by_email(email, type)
        if user_tuple ~= nil then
            return user_tuple[model.ID]
        end
    end

    function model.delete(user_id)
        if validator.not_empty_string(user_id) then
            return model.get_space():delete({user_id})
        end
    end

    function model.create(user_tuple)
        local user_id
        if user_tuple[model.ID] then
            user_id = user_tuple[model.ID]
        else
            user_id = uuid.str()
        end
        local email = validator.string(user_tuple[model.EMAIL]) and user_tuple[model.EMAIL] or ''
        return model.get_space():insert{
            user_id,
            email,
            user_tuple[model.TYPE],
            user_tuple[model.IS_ACTIVE],
            user_tuple[model.PROFILE]
        }
    end

    function model.update(user_tuple)
        local user_id, fields
        user_id = user_tuple[model.ID]
        fields = utils.format_update(user_tuple)
        return model.get_space():update(user_id, fields)
    end

    function model.create_or_update(user_tuple)
        local user_id = user_tuple[model.ID]

        if user_id and model.get_by_id(user_id) then
            user_tuple = model.update(user_tuple)
        else
            user_tuple = model.create(user_tuple)
        end
        return user_tuple
    end

    function model.set_new_id(user_id, new_user_id)
        local user_tuple = model.get_by_id(user_id)
        model.delete(user_id)

        model.create_or_update()
        return model.get_space():update(user_id, {{'=', model.ID, new_user_id}})
    end

    function model.generate_activation_code(user_id)
        return digest.md5_hex(string.format('%s%s', config.activation_secret, user_id))
    end

    return model
end

return user