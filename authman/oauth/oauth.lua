local response = require('authman.response')
local error = require('authman.error')
local validator = require('authman.validator')

return function(config)
    local api = {}

    local user = require('authman.model.user').model(config)
    local oauth_app = require('authman.model.oauth.app').model(config)
    local oauth_consumer = require('authman.model.oauth.consumer').model(config)
    local oauth_code = require('authman.model.oauth.code').model(config)
    local oauth_token = require('authman.model.oauth.token').model(config)

    function api.add_app(user_id, app_name, app_type, redirect_urls)

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if not validator.not_empty_string(app_name)
            or not validator.oauth_app_type(app_type)
            or not validator.not_empty_string(redirect_urls)
        then
            return response.error(error.INVALID_PARAMS)
        end

        local user_apps = oauth_app.get_by_user_id(user_id)
        if user_apps ~= nil and #user_apps ~= 0 then
            if #user_apps >= config.oauth_max_apps then
                return response.error(error.OAUTH_MAX_APPS_REACHED)
            end

            for _, app_tuple in pairs(user_apps) do
                if app_tuple[oauth_app.NAME] == app_name then
                    return response.error(error.OAUTH_APP_ALREADY_EXISTS)
                end
            end
        end

        local app_tuple = {
            [oauth_app.USER_ID] = user_id,
            [oauth_app.NAME] = app_name,
            [oauth_app.TYPE] = app_type,
            [oauth_app.IS_ACTIVE] = true,
        }

        local app = oauth_app.create(app_tuple)
        local consumer_secret = oauth_consumer.generate_consumer_secret()

        local consumer = oauth_consumer.create(
            oauth_consumer.generate_consumer_key(),
            consumer_secret,
            app[oauth_app.ID],
            redirect_urls
        )

        return response.ok(
            oauth_app.serialize( app, {
                consumer_key = consumer[oauth_consumer.ID],
                consumer_secret = consumer_secret,
                redirect_urls = consumer[oauth_consumer.REDIRECT_URLS],
            })
        )
    end

    function api.disable_app(app_id)
        if not validator.not_empty_string(app_id) then
            return response.error(error.INVALID_PARAMS)
        end

        app = oauth_app.update({
            [oauth_app.ID] = app_id,
            [oauth_app.IS_ACTIVE] = false,
        })

        if app == nil then
            return response.error(error.OAUTH_APP_NOT_FOUND)
        end

        return response.ok(oauth_app.serialize(app))
    end

    function api.enable_app(app_id)
        if not validator.not_empty_string(app_id) then
            return response.error(error.INVALID_PARAMS)
        end

        app = oauth_app.update({
            [oauth_app.ID] = app_id,
            [oauth_app.IS_ACTIVE] = true,
        })

        if app == nil then
            return response.error(error.OAUTH_APP_NOT_FOUND)
        end

        return response.ok(oauth_app.serialize(app))
    end

    function api.delete_app(app_id)
        if not validator.not_empty_string(app_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local consumer = oauth_consumer.delete_by_app_id(app_id)

        if consumer ~= nil then
            oauth_code.delete_by_consumer_key(consumer[oauth_consumer.ID])
            oauth_token.delete_by_consumer_key(consumer[oauth_consumer.ID])
        end

        local app = oauth_app.delete(app_id)
        if app == nil then
            return response.error(error.OAUTH_APP_NOT_FOUND)
        end

        return response.ok(oauth_app.serialize(app, oauth_consumer.serialize(consumer)))
    end

    function api.get_app(app_id)
        if not validator.not_empty_string(app_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local app = oauth_app.get_by_id(app_id)
        if app == nil then
            return response.error(error.OAUTH_APP_NOT_FOUND)
        end

        local consumer = oauth_consumer.get_by_app_id(app_id)
        if consumer == nil then
            return response.error(error.OAUTH_CONSUMER_NOT_FOUND)
        end

        return response.ok(oauth_app.serialize(app, oauth_consumer.serialize(consumer)))
    end

    function api.get_user_apps(user_id)
        if not validator.not_empty_string(user_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local result = {}

        local user_apps = oauth_app.get_by_user_id(user_id)
        if user_apps ~= nil and #user_apps ~= 0 then
            for i, app in pairs(user_apps) do
                consumer = oauth_consumer.get_by_app_id(app[oauth_app.ID])
                result[i] = oauth_app.serialize(app, oauth_consumer.serialize(consumer))
            end
        end

        return response.ok(result)
    end

    function api.get_consumer(consumer_key)
        if not validator.not_empty_string(consumer_key) then
            return response.error(error.INVALID_PARAMS)
        end

        local consumer = oauth_consumer.get_by_id(consumer_key)
        if consumer == nil then
            return response.error(error.OAUTH_CONSUMER_NOT_FOUND)
        end

        local app = oauth_app.get_by_id(consumer[oauth_consumer.APP_ID])
        if app == nil then
            return response.error(error.OAUTH_APP_NOT_FOUND)
        end
        return response.ok(oauth_app.serialize(app, oauth_consumer.serialize(consumer)))
    end

    function api.reset_consumer_secret(consumer_key)
        if not validator.not_empty_string(consumer_key) then
            return response.error(error.INVALID_PARAMS)
        end

        local consumer = oauth_consumer.get_by_id(consumer_key)

        if consumer == nil then
            return response.error(error.OAUTH_CONSUMER_NOT_FOUND)
        end

        local consumer_secret = oauth_consumer.generate_consumer_secret()
        local c = oauth_consumer.update_consumer_secret(consumer_key, consumer_secret, consumer[oauth_consumer.APP_ID])

        return response.ok(consumer_secret)
    end

    function api.save_code(code, consumer_key, redirect_url, scope, state, expires_in, created_at, code_challenge, code_challenge_method)

        local code_tuple = {
            [oauth_code.CODE] = code,
            [oauth_code.CONSUMER_KEY] = consumer_key,
            [oauth_code.REDIRECT_URL] = redirect_url,
            [oauth_code.SCOPE] = scope,
            [oauth_code.STATE] = state,
            [oauth_code.EXPIRES_IN] = expires_in,
            [oauth_code.CREATED_AT] = created_at,
            [oauth_code.CODE_CHALLENGE] = code_challenge,
            [oauth_code.CODE_CHALLENGE_METHOD] = code_challenge_method,
        }

        for _, v in pairs({oauth_code.CODE, oauth_code.CONSUMER_KEY, oauth_code.REDIRECT_URL, oauth_code.SCOPE}) do
            if not validator.not_empty_string(code_tuple[v]) then
                return response.error(error.INVALID_PARAMS)
            end
        end

        for _, v in pairs({oauth_code.EXPIRES_IN, oauth_code.CREATED_AT}) do
            if not validator.positive_number(code_tuple[v]) then
                return response.error(error.INVALID_PARAMS)
            end
        end

        return response.ok(oauth_code.serialize(oauth_code.create(code_tuple)))
    end

    function api.delete_code(code)
        if not validator.not_empty_string(code) then
            return response.error(error.INVALID_PARAMS)
        end

        local code_tuple = oauth_code.delete(code)

        if code_tuple == nil then
            return response.error(error.OAUTH_CODE_NOT_FOUND)
        else
            return response.ok(oauth_code.serialize(code_tuple))
        end
    end

    function api.get_code(code)
        if not validator.not_empty_string(code) then
            return response.error(error.INVALID_PARAMS)
        end

        local code_tuple = oauth_code.get_by_code(code)

        if code_tuple == nil then
            return response.error(error.OAUTH_CODE_NOT_FOUND)
        end

        local ok, consumer = api.get_consumer(code_tuple[oauth_code.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_code.serialize(code_tuple, {consumer = consumer}))
    end

    function api.delete_expired_codes(expiration_ts)
        if not validator.positive_number(expiration_ts) then
            return response.error(error.INVALID_PARAMS)
        end
        return response.ok(oauth_code.delete_expired(expiration_ts))
    end

    function api.delete_expired_tokens(expiration_ts)
        if not validator.positive_number(expiration_ts) then
            return response.error(error.INVALID_PARAMS)
        end
        return response.ok(oauth_token.delete_expired(expiration_ts))
    end

    function api.save_access(access_token, consumer_key, refresh_token, redirect_url, scope, expires_in, created_at)

        local token_tuple = {
            [oauth_token.ACCESS_TOKEN] = access_token,
            [oauth_token.CONSUMER_KEY] = consumer_key,
            [oauth_token.REFRESH_TOKEN] = refresh_token,
            [oauth_token.REDIRECT_URL] = redirect_url,
            [oauth_token.SCOPE] = scope,
            [oauth_token.EXPIRES_IN] = expires_in,
            [oauth_token.CREATED_AT] = created_at,
        }

        for _, v in pairs({oauth_token.ACCESS_TOKEN, oauth_token.CONSUMER_KEY,
                            oauth_token.REFRESH_TOKEN, oauth_token.REDIRECT_URL, oauth_token.SCOPE}) do

            if not validator.not_empty_string(token_tuple[v]) then
                return response.error(error.INVALID_PARAMS)
            end
        end

        for _, v in pairs({oauth_token.EXPIRES_IN, oauth_token.CREATED_AT}) do
            if not validator.positive_number(token_tuple[v]) then
                return response.error(error.INVALID_PARAMS)
            end
        end

        return response.ok(oauth_token.serialize(oauth_token.create(token_tuple)))
    end

    function api.delete_access(access_token)
        if not validator.not_empty_string(access_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.delete(access_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        else
            return response.ok(oauth_token.serialize(token_tuple))
        end
    end

    function api.get_access(access_token)

        if not validator.not_empty_string(access_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.get_by_access_token(access_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        end

        local ok, consumer = api.get_consumer(token_tuple[oauth_token.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_token.serialize(token_tuple, {consumer = consumer}))
    end

    function api.get_refresh(refresh_token)

        if not validator.not_empty_string(refresh_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.get_by_refresh_token(refresh_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        end

        local ok, consumer = api.get_consumer(token_tuple[oauth_token.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_token.serialize(token_tuple, {consumer = consumer}))
    end

    function api.delete_refresh(refresh_token)
        if not validator.not_empty_string(refresh_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.delete_by_refresh(refresh_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        else
            return response.ok(oauth_token.serialize(token_tuple))
        end
    end


    return api
end
