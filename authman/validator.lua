local validator = {}

local uuid = require('uuid')
local log = require('log')

local enabled_providers = {
    facebook = true,
    google = true,
    vk = true
}

local oauth_app_types = {
    server = true,
    browser = true,
    mobile = true,
    native = true,
}

local social_required = {
    'client_id', 'client_secret', 'redirect_uri',
}

local password_strength = {
    none = true,
    whocares = true,
    easy = true,
    common = true,
    moderate = true,
    violence = true,
    nightmare = true,
}

local config_default_values = {
    session_lifetime = 7 * 24 * 60 * 60,
    session_update_timedelta = 2 * 24 * 60 * 60,
    social_check_time = 60 * 60 * 24,
    request_timeout = 3,
    oauth_max_apps = 10,
}

local config_default_secrets = {
    activation_secret = uuid.str(),
    session_secret = uuid.str(),
    restore_secret = uuid.str(),
}

local config_default_space_names = {
    password = 'auth_password_credential',
    password_token = 'auth_password_token',
    session = 'auth_sesssion',
    social = 'auth_social_credential',
    user = 'auth_user',
    oauth_app = 'auth_oauth_app',
    oauth_consumer = 'auth_oauth_consumer',
    oauth_code = 'auth_oauth_code',
    oauth_token = 'auth_oauth_token',
    oauth_scope = 'auth_oauth_scope',
    oauth_redirect = 'auth_oauth_redirect',
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

function validator.positive_number(number)
    return type(number) == 'number' and number >= 0
end

function validator.table(tbl)
    return type(tbl) == 'table'
end

function validator.password(pwd)
    return validator.not_empty_string(pwd)
end

function validator.oauth_app_type(app_type)
    return oauth_app_types[app_type]
end

function validator.config(config)
    if not validator.table(config) then
        config = {}
        log.warn('Config is not a table. Use default instead.')
    end

    if not (validator.not_empty_string(config.password_strength)
            or password_strength[config.password_strength]) then

        config.password_strength = 'common'
        log.warn('Use common for password_strength')
    end

    local param_name, param_value, is_valid

    for param_name, value in pairs(config_default_values) do
        param_value = config[param_name]
        if param_value == nil or not validator.positive_number(param_value) then
            config[param_name] = value
            log.warn('Use %s for %s', value, param_name)
        end
    end

    for param_name, value in pairs(config_default_secrets) do
        param_value = config[param_name]
        if param_value == nil or not validator.not_empty_string(param_value) then
            config[param_name] = value
            log.warn('Use %s for %s', value, param_name)
        end
    end

    if not validator.table(config.spaces) then
        config.spaces = {}
    end

    for param_name, value in pairs(config_default_space_names) do
        if not (validator.table(config.spaces[param_name]) and
            validator.not_empty_string(config.spaces[param_name].name)) then

            config.spaces[param_name] = {}
            config.spaces[param_name].name = value
        end
    end

    for provider, enabled in pairs(enabled_providers) do
        param_value = config[provider]
        if enabled then
            if not validator.table(param_value) then
                param_value = {}
                log.warn('Use empty for %s', provider)
            end

            for field_num = 1, #social_required do
                if not validator.not_empty_string(param_value[social_required[field_num]]) then
                    param_value[social_required[field_num]] = ''
                    log.warn('Use empty for %s in %s', social_required[field_num], provider)
                end
            end
        end
    end
    return config
end

return validator



