local validator = {}

local enabled_providers = {
    facebook = true,
    google = true,
    vk = true
}

local config_required = {
    'activation_secret', 'session_secret', 'restore_secret'
}

local social_required = {
    'client_id', 'client_secret', 'redirect_uri',
}

local config_default = {
    session_lifetime = 7 * 24 * 60 * 60,
    session_update_timedelta = 2 * 24 * 60 * 60,
    social_check_time = 60 * 60 * 24,
}

function validator.string(str)
    return type(str) == 'string'
end

function validator.not_empty_string(str)
    return validator.string(str) and str ~= ''
end

function validator.email(email_string)
    return validator.not_empty_string(email_string) and email_string:match('([^@]+@[^@]+)') == email_string
end

function validator.provider(provider)
    return enabled_providers[provider]
end

function validator.positive_integer(integer)
    return type(integer) == 'number' and integer >= 0
end

function validator.table(tbl)
    return type(tbl) == 'table'
end

function validator.password(pwd)
    return validator.not_empty_string(pwd)
end

function validator.config(config)
    if not validator.table(config) then
        return false
    end

    local param_name, param_value, is_valid
    for param_index = 1, #config_required do
        param_name = config_required[param_index]
        is_valid = validator.not_empty_string(config[param_name])
        if not is_valid then
            return false
        end
    end

    for param_name, value in pairs(config_default) do
        param_value = config[param_name]
        if param_value == nil then
            config[param_name] = value
        elseif not validator.positive_integer(param_value) then
            return false
        end
    end

    for provider, enabled in pairs(enabled_providers) do
        param_value = config[provider]
        if enabled and param_value ~= nil then
            if not validator.table(param_value) then
                return false
            end

            for field_num = 1, #social_required do
                if not validator.not_empty_string(param_value[social_required[field_num]]) then
                    return false
                end
            end
        end
    end
    return true
end

return validator



