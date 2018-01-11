local auth = {}
local response = require('authman.response')
local error = require('authman.error')
local validator = require('authman.validator')
local db = require('authman.db')
local utils = require('authman.utils.utils')


function auth.api(config)
    local api = {}

    config = validator.config(config)
    local user = require('authman.model.user').model(config)
    local password = require('authman.model.password').model(config)
    local password_token = require('authman.model.password_token').model(config)
    local social = require('authman.model.social').model(config)
    local session = require('authman.model.session').model(config)
    local application = require('authman.model.application').model(config)
    local oauth_consumer = require('authman.model.oauth_consumer').model(config)
    local oauth_code = require('authman.model.oauth_code').model(config)
    local oauth_token = require('authman.model.oauth_token').model(config)

    db.configurate(config).create_database()
    require('authman.migrations.migrations')(config)

    -----------------
    -- API methods --
    -----------------
    function api.registration(email, user_id)
        email = utils.lower(email)

        if not validator.email(email) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_email(email, user.COMMON_TYPE)
        if user_tuple ~= nil then
            if user_tuple[user.IS_ACTIVE] and user_tuple[user.TYPE] == user.COMMON_TYPE then
                return response.error(error.USER_ALREADY_EXISTS)
            else
                local code = user.generate_activation_code(user_tuple[user.ID])
                return response.ok(user.serialize(user_tuple, {code=code}))
            end
        end

        user_tuple = {
            [user.EMAIL] = email,
            [user.TYPE] = user.COMMON_TYPE,
            [user.IS_ACTIVE] = false,
        }
        if validator.not_empty_string(user_id) then
            user_tuple[user.ID] = user_id
        end

        user_tuple = user.create(user_tuple)

        local code = user.generate_activation_code(user_tuple[user.ID])
        return response.ok(user.serialize(user_tuple, {code=code}))
    end

    function api.complete_registration(email, code, raw_password)
        email = utils.lower(email)

        if not (validator.email(email) and validator.not_empty_string(code)) then
            return response.error(error.INVALID_PARAMS)
        end

        if not password.strong_enough(raw_password) then
            return response.error(error.WEAK_PASSWORD)
        end

        local user_tuple = user.get_by_email(email, user.COMMON_TYPE)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_ALREADY_ACTIVE)
        end

        local user_id = user_tuple[user.ID]
        local correct_code = user.generate_activation_code(user_id)
        if code ~= correct_code then
            return response.error(error.WRONG_ACTIVATION_CODE)
        end

        password.create_or_update({
            [password.USER_ID] = user_id,
            [password.HASH] = password.hash(raw_password, user_id)
        })

        user_tuple = user.update({
            [user.ID] = user_id,
            [user.IS_ACTIVE] = true,
            [user.REGISTRATION_TS] = utils.now(),
        })

        return response.ok(user.serialize(user_tuple))
    end

    function api.set_profile(user_id, user_profile)
        if not validator.not_empty_string(user_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        user_tuple = user.update({
            [user.ID] = user_id,
            [user.PROFILE] = {
                [user.PROFILE_FIRST_NAME] = user_profile['first_name'],
                [user.PROFILE_LAST_NAME] = user_profile['last_name'],
            },
        })

        return response.ok(user.serialize(user_tuple))
    end

    function api.get_profile(user_id)
        if not validator.not_empty_string(user_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        return response.ok(user.serialize(user_tuple))
    end

    function api.delete_user(user_id)
        if not validator.not_empty_string(user_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        user.delete(user_id)
        password.delete_by_user_id(user_id)
        social.delete_by_user_id(user_id)
        password_token.delete(user_id)

        return response.ok(user.serialize(user_tuple))
    end

    function api.auth(email, raw_password)
        email = utils.lower(email)

        local user_tuple = user.get_by_email(email, user.COMMON_TYPE)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if not password.is_valid(raw_password, user_tuple[user.ID]) then
            return response.error(error.WRONG_PASSWORD)
        end

        local signed_session = session.create(user_tuple[user.ID], session.COMMON_SESSION_TYPE)
        user.update_session_ts(user_tuple)

        return response.ok(user.serialize(user_tuple, {session = signed_session}))
    end

    function api.check_auth(signed_session)
        if not validator.not_empty_string(signed_session) then
            return response.error(error.INVALID_PARAMS)
        end

        local encoded_session_data = session.validate_session(signed_session)

        if encoded_session_data == nil then
            return response.error(error.WRONG_SESSION_SIGN)
        end

        local session_tuple = session.get_by_session(encoded_session_data)
        if session_tuple == nil then
            return response.error(error.NOT_AUTHENTICATED)
        end

        local user_tuple = user.get_by_id(session_tuple[session.USER_ID])
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end


        local session_data = session.decode(encoded_session_data)
        local new_session
        if session_data.type == session.SOCIAL_SESSION_TYPE then

            local social_tuple = social.get_by_id(session_tuple[session.CREDENTIAL_ID])
            if social_tuple == nil then
                return response.error(error.USER_NOT_FOUND)
            end

            if session.is_expired(session_data) then
                return response.error(error.NOT_AUTHENTICATED)

            elseif session.need_social_update(session_data) then

                local updated_user_tuple = {user_tuple[user.ID]}
                local social_id = social.get_profile_info(
                    social_tuple[social.PROVIDER], social_tuple[social.TOKEN], updated_user_tuple
                )

                if social_id == nil then
                    return response.error(error.NOT_AUTHENTICATED)
                end

                user_tuple = user.update(updated_user_tuple)
                new_session = session.create(
                    user_tuple[user.ID], session.SOCIAL_SESSION_TYPE, social_tuple[social.ID]
                )

                user.update_session_ts(user_tuple)

            else
                new_session = signed_session
            end

            social_tuple = social.get_by_user_id(user_tuple[user.ID])

            return response.ok(
                user.serialize(user_tuple, {
                    session = new_session,
                    social = social.serialize(social_tuple),
                })
            )

        else

            if session.is_expired(session_data) then
                return response.error(error.NOT_AUTHENTICATED)

            elseif session.need_common_update(session_data) then
                new_session = session.create(session_data.user_id, session.COMMON_SESSION_TYPE)
                user.update_session_ts(user_tuple)
            else
                new_session = signed_session
            end

            return response.ok(user.serialize(user_tuple, {session = new_session}))

        end
    end

    function api.drop_session(signed_session)
        if not validator.not_empty_string(signed_session) then
            return response.error(error.INVALID_PARAMS)
        end

        local encoded_session_data = session.validate_session(signed_session)

        if encoded_session_data == nil then
            return response.error(error.WRONG_SESSION_SIGN)
        end

        local deleted = session.delete(encoded_session_data)
        return response.ok(deleted)
    end

    function api.restore_password(email)
        email = utils.lower(email)

        local user_tuple = user.get_by_email(email, user.COMMON_TYPE)

        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end
        return response.ok(password_token.generate(user_tuple[user.ID]))
    end

    function api.complete_restore_password(email, token, raw_password)
        email = utils.lower(email)

        if not validator.not_empty_string(token) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_email(email, user.COMMON_TYPE)

        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if not password.strong_enough(raw_password) then
            return response.error(error.WEAK_PASSWORD)
        end

        local user_id = user_tuple[user.ID]
        if password_token.is_valid(token, user_id) then

            password.create_or_update({
                [password.USER_ID] = user_id,
                [password.HASH] = password.hash(raw_password, user_id)
            })


            user_tuple = user.update({
                [user.ID] = user_id,
                [user.TYPE] = user.COMMON_TYPE,
            })

            password_token.delete(user_id)

            return response.ok(user.serialize(user_tuple))
        else
            return response.error(error.WRONG_RESTORE_TOKEN)
        end
    end

    function api.social_auth_url(provider, state)
        if not validator.provider(provider) then
            return response.error(error.WRONG_PROVIDER)
        end

        return response.ok(social.get_social_auth_url(provider, state))
    end

    function api.social_auth(provider, code)
        local token, social_id, social_tuple
        local user_tuple = {}

        if not (validator.provider(provider) and validator.not_empty_string(code)) then
            return response.error(error.WRONG_PROVIDER)
        end

        token = social.get_token(provider, code, user_tuple)
        if not validator.not_empty_string(token) then
            return response.error(error.WRONG_AUTH_CODE)
        end

        social_id = social.get_profile_info(provider, token, user_tuple)
        if not validator.not_empty_string(social_id) then
            return response.error(error.SOCIAL_AUTH_ERROR)
        end

        local now = utils.now()
        user_tuple[user.EMAIL] = utils.lower(user_tuple[user.EMAIL])
        user_tuple[user.IS_ACTIVE] = true
        user_tuple[user.TYPE] = user.SOCIAL_TYPE
        user_tuple[user.SESSION_UPDATE_TS] = now

        social_tuple = social.get_by_social_id(social_id, provider)
        if social_tuple == nil then
            user_tuple = user.create(user_tuple)
            social_tuple = social.create({
                [social.USER_ID] = user_tuple[user.ID],
                [social.PROVIDER] = provider,
                [social.SOCIAL_ID] = social_id,
                [social.TOKEN] = token,
            })
        else
            user_tuple[user.ID] = social_tuple[social.USER_ID]
            user_tuple = user.create_or_update(user_tuple)
            social_tuple = social.update({
                [social.ID] = social_tuple[social.ID],
                [social.USER_ID] = user_tuple[user.ID],
                [social.TOKEN] = token,
            })
        end

        local new_session = session.create(
            user_tuple[user.ID], session.SOCIAL_SESSION_TYPE, social_tuple[social.ID]
        )

        return response.ok(user.serialize(user_tuple, {
            session = new_session,
            social = social.serialize(social_tuple),
        }))
    end

    function api.add_application(user_id, app_name, app_type, redirect_urls)

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if not validator.not_empty_string(app_name)
            or not validator.application_type(app_type)
            or not validator.not_empty_string(redirect_urls)
        then
            return response.error(error.INVALID_PARAMS)
        end

        local user_apps = application.get_user_apps(user_id)

        if #user_apps >= config.max_applications then
            return response.error(error.MAX_APPLICATIONS_REACHED)
        end

        if user_apps ~= nil and #user_apps ~= 0 then
            for _, app_tuple in pairs(user_apps) do
                if app_tuple[application.NAME] == app_name then
                    return response.error(error.APPLICATION_ALREADY_EXISTS)
                end
            end
        end

        local app_tuple = {
            [application.USER_ID] = user_id,
            [application.NAME] = app_name,
            [application.TYPE] = app_type,
            [application.IS_ACTIVE] = true,
        }

        local app = application.create(app_tuple)
        local consumer_secret = oauth_consumer.generate_consumer_secret()

        local consumer = oauth_consumer.create(
            oauth_consumer.generate_consumer_key(),
            consumer_secret,
            app[application.ID],
            redirect_urls
        )

        return response.ok(
            application.serialize( app, {
                consumer_key = consumer[oauth_consumer.ID],
                consumer_secret = consumer_secret,
                redirect_urls = consumer[oauth_consumer.REDIRECT_URLS],
            })
        )
    end

    function api.get_oauth_consumer(consumer_key)
        if not validator.not_empty_string(consumer_key) then
            return response.error(error.INVALID_PARAMS)
        end

        local consumer = oauth_consumer.get_by_id(consumer_key)
        if consumer == nil then
            return response.error(error.OAUTH_CONSUMER_NOT_FOUND)
        end

        local app = application.get_by_id(consumer[oauth_consumer.APPLICATION_ID])
        if app == nil then
            return response.error(error.APPLICATION_NOT_FOUND)
        end
        return response.ok(application.serialize(app, oauth_consumer.serialize(consumer)))
    end

    function api.get_application(app_id)
        if not validator.not_empty_string(app_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local app = application.get_by_id(app_id)
        if app == nil then
            return response.error(error.APPLICATION_NOT_FOUND)
        end

        local consumer = oauth_consumer.get_by_application_id(app_id)
        if consumer == nil then
            return response.error(error.OAUTH_CONSUMER_NOT_FOUND)
        end

        return response.ok(application.serialize(app, oauth_consumer.serialize(consumer)))
    end

    function api.get_user_applications(user_id)
        if not validator.not_empty_string(user_id) then
            return response.error(error.INVALID_PARAMS)
        end

        local result = {}

        local user_apps = application.get_user_apps(user_id)
        if user_apps ~= nil and #user_apps ~= 0 then
            for i, app in pairs(user_apps) do
                consumer = oauth_consumer.get_by_application_id(app[application.ID])
                result[i] = application.serialize(app, oauth_consumer.serialize(consumer))
            end
        end

        return response.ok(result)
    end

    function api.save_oauth_code(code, consumer_key, redirect_url, scope, state, expires_in, created_at, code_challenge, code_challenge_method)

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

    function api.delete_oauth_code(code)
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

    function api.get_oauth_code(code)
        if not validator.not_empty_string(code) then
            return response.error(error.INVALID_PARAMS)
        end

        local code_tuple = oauth_code.get_by_code(code)

        if code_tuple == nil then
            return response.error(error.OAUTH_CODE_NOT_FOUND)
        end

        local ok, consumer = api.get_oauth_consumer(code_tuple[oauth_code.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_code.serialize(code_tuple, {consumer = consumer}))
    end

    function api.save_oauth_access(access_token, consumer_key, refresh_token, redirect_url, scope, expires_in, created_at)

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

    function api.delete_oauth_access(access_token)
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

    function api.get_oauth_access(access_token)

        if not validator.not_empty_string(access_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.get_by_access_token(access_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        end

        local ok, consumer = api.get_oauth_consumer(token_tuple[oauth_token.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_token.serialize(token_tuple, {consumer = consumer}))
    end

    function api.get_oauth_refresh(refresh_token)

        if not validator.not_empty_string(refresh_token) then
            return response.error(error.INVALID_PARAMS)
        end

        local token_tuple = oauth_token.get_by_refresh_token(refresh_token)

        if token_tuple == nil then
            return response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)
        end

        local ok, consumer = api.get_oauth_consumer(token_tuple[oauth_token.CONSUMER_KEY])

        -- could not get oauth consumer
        -- return error
        if not ok then
            return ok, consumer
        end

        return response.ok(oauth_token.serialize(token_tuple, {consumer = consumer}))
    end

    function api.delete_oauth_refresh(refresh_token)
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

return auth
