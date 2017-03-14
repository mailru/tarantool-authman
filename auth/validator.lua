local validator = {}

local uuid = require('uuid')
local log = require('log')

local enabled_providers = {
    facebook = true,
    google = true,
    vk = true
}

local social_required = {
    'client_id', 'client_secret', 'redirect_uri',
}

local config_default_values = {
    session_lifetime = 7 * 24 * 60 * 60,
    session_update_timedelta = 2 * 24 * 60 * 60,
    social_check_time = 60 * 60 * 24,
}
local config_default_secrets = {
    activation_secret = uuid.str(),
    session_secret = uuid.str(),
    restore_secret = uuid.str(),
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
        config = {}
        log.warn('Config is not a table. Use default instead.')
    end

    local param_name, param_value, is_valid

    for param_name, value in pairs(config_default_values) do
        param_value = config[param_name]
        if param_value == nil or not validator.positive_integer(param_value) then
            config[param_name] = value
            log.warn(string.format('Use %s for %s', value, param_name))
        end
    end

    for param_name, value in pairs(config_default_secrets) do
        param_value = config[param_name]
        if param_value == nil or not validator.not_empty_string(param_value) then
            config[param_name] = value
            log.warn(string.format('Use %s for %s', value, param_name))
        end
    end

    for provider, enabled in pairs(enabled_providers) do
        param_value = config[provider]
        if enabled then
            if not validator.table(param_value) then
                param_value = {}
                log.warn(string.format('Use empty for %s', provider))
            end

            for field_num = 1, #social_required do
                if not validator.not_empty_string(param_value[social_required[field_num]]) then
                    param_value[social_required[field_num]] = ''
                    log.warn(string.format(
                        'Use empty for %s in %s', social_required[field_num], provider
                    ))
                end
            end
        end
    end
    return config
end

return validator



