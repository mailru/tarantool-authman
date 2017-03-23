local password = {}

local digest = require('digest')
local uuid = require('uuid')
local validator = require('auth.validator')
local utils = require('auth.utils.utils')


-----
-- password (id, user_id, password)
-----
function password.model(config)
    local model = {}

    model.SPACE_NAME = 'auth_password_credential'

    model.PRIMARY_INDEX = 'primary'
    model.USER_ID_INDEX = 'user'

    model.ID = 1
    model.USER_ID = 2
    model.HASH = 3

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.get_by_id(id)
        return model.get_space():get(id)
    end

    function model.get_by_user_id(user_id)
        if validator.not_empty_string(user_id) then
            -- TODO create index and migrations
            return model.get_space().index[model.USER_ID_INDEX]:select({user_id})[1]
        end
    end

    function model.hash(password, salt)
        return digest.sha256(string.format('%s%s', salt, password))
    end

    function model.is_valid(raw_password, user_id)
        local password_tuple = model.get_by_user_id(user_id)
        if password_tuple == nil then
            return false
        end

        return password_tuple[model.HASH] == model.hash(raw_password, user_id)
    end

    function model.create(password_tuple)
        local id = uuid.str()
        return model.get_space():insert({
            id,
            password_tuple[model.USER_ID],
            password_tuple[model.HASH],
        })
    end

    function model.update(password_tuple)
        local social_id, fields
        social_id = password_tuple[model.ID]
        fields = utils.format_update(password_tuple)
        return model.get_space():update(social_id, fields)
    end

    function model.create_or_update(password_tuple)
        local user_id = password_tuple[model.USER_ID]
        local exists_password_tuple = model.get_by_user_id(user_id)
        if exists_password_tuple == nil then
            return model.create(password_tuple)
        else
            password_tuple[model.ID] = exists_password_tuple[model.ID]
            return model.update(password_tuple)
        end
    end

    return model
end

return password
