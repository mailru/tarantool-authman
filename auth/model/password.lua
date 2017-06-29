local password = {}

local digest = require('digest')
local uuid = require('uuid')
local validator = require('auth.validator')
local utils = require('auth.utils.utils')

local CHAR_GROUP_PATTERNS = {
    '[%l]',   -- lower case
    '[%u]',   -- upper case
    '[%d]',   -- didgets
    '[!@#&_=;:,/\\|`~ %?%+%-%.%^%%%$%*]',  -- ! @ # & _ = ; : , / \ | ` ~ ? + - . ^ % $ *
}

-----
-- password (id, user_id, password)
-----
function password.model(config)
    local model = {}

    model.SPACE_NAME = config.spaces.password.name

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

    function model.delete_by_user_id(user_id)
        if validator.not_empty_string(user_id) then
            return model.get_space().index[model.USER_ID_INDEX]:delete({user_id})
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

    function model.strong_enough(password)
        if not validator.not_empty_string(password) then
            return false
        end

        if config.password == nil then
            return true
        end

        local min_length = config.password.min_length
        local min_char_group_count = config.password.min_char_group_count

        if min_length ~= nil and string.len(password) < min_length then
            return false
        end

        if min_char_group_count ~= nil then
            local char_group_count = 0
            for _, pattern in pairs(CHAR_GROUP_PATTERNS) do
                if string.match(password, pattern) then
                    char_group_count = char_group_count + 1
                end
            end

            if char_group_count < min_char_group_count then
                return false
            end
        end

        return true
    end

    return model
end

return password
