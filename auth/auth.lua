local auth = {}
local response = require('auth.response')
local error = require('auth.error')
local validator = require('auth.validator')
local db = require('auth.db')


function auth.api(config)
    local api = {}

    if not validator.config(config) then
        return response.error(error.IMPROPERLY_CONFIGURED)
    end

    local user = require('auth.model.user').model(config)
    local password_token = require('auth.model.password_token').model(config)
    local social = require('auth.model.social').model(config)
    db.create_database()

    -----------------
    -- API methods --
    -----------------
    function api.registration(email)
        if not validator.email(email) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_email(email)
        if user_tuple ~= nil then
            if user_tuple[user.IS_ACTIVE] then
                return response.error(error.USER_ALREADY_EXISTS)
            else
                local code = user.generate_activation_code(user_tuple[user.ID])
                return response.ok(code)
            end
        end

        user_tuple = user.create({
            [user.EMAIL] = email,
            [user.IS_ACTIVE] = false
        })

        local code = user.generate_activation_code(user_tuple[user.ID])
        return response.ok(code)
    end

    function api.complete_registration(email, code, password)
        if not (validator.email(email) and validator.not_empty_string(code)) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_email(email)
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

        user_tuple = user.update({
            [user.ID] = user_id,
            [user.IS_ACTIVE] = true,
            [user.PASSWORD] = user.hash_password(password)
        })

        return response.ok(user.serialize(user_tuple))
    end

    function api.set_profile(user_id, first_name, last_name)
        if not (validator.string(first_name) and validator.string(last_name) and
                validator.not_empty_string(user_id)) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_id(user_id)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        user_tuple = user.update({
            [user.ID] = user_id,
            [user.PROFILE] = {
                [user.PROFILE_FIRST_NAME] = first_name,
                [user.PROFILE_LAST_NAME] = last_name,
            },
        })

        return user_tuple
    end

    function api.auth(email, password)
        local user_tuple = user.get_by_email(email)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if user.hash_password(password) ~= user_tuple[user.PASSWORD] then
            return response.error(error.WRONG_PASSWORD)
        end

        local signed_session = user.create_session(user_tuple[user.ID], user.COMMON_SESSION_TYPE)

        return response.ok(user.serialize(user_tuple, signed_session))
    end

    function api.check_auth(signed_session)
        if not validator.not_empty_string(signed_session) then
            return response.error(error.INVALID_PARAMS)
        end

        if not user.session_is_valid(signed_session) then
            return response.error(error.WRONG_SESSION_SIGN)
        end

        local user_tuple, session_data = user.get_session_data(signed_session)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        local new_session

        if session_data.type == user.SOCIAL_SESSION_TYPE then
            local social_tuple = social.get_by_id(user_tuple[user.ID])
            if social_tuple == nil then
                return response.error(error.USER_NOT_FOUND)
            end

            if session_data.exp < os.time() then
                local new_user_tuple = {user_tuple[user.ID]}
                local social_id = social.get_profile_info(
                    social_tuple[social.PROVIDER], social_tuple[social.TOKEN], new_user_tuple
                )

                if social_id == nil then
                    return response.error(error.NOT_AUTHENTICATED)
                end

                user_tuple = user.update(new_user_tuple)
                new_session = user.create_session(user_tuple[user.ID], user.SOCIAL_SESSION_TYPE)

            else
                new_session = signed_session
            end

        else

            if session_data.exp < os.time() then
                return response.error(error.NOT_AUTHENTICATED)
            elseif session_data.exp < (os.time() - config.session_update_timedelta) then
                new_session = user.create_session(session_data.user_id, user.COMMON_SESSION_TYPE)
            else
                new_session = signed_session
            end
        end

        return response.ok(user.serialize(user_tuple, new_session))
    end

    function api.restore_password(email)
        local user_tuple = user.get_by_email(email)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end
        return response.ok(password_token.generate_restore_token(user_tuple[user.ID]))
    end

    function api.complete_restore_password(email, token, password)
        if not validator.not_empty_string(token) then
            return response.error(error.INVALID_PARAMS)
        end

        local user_tuple = user.get_by_email(email)
        if user_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if not user_tuple[user.IS_ACTIVE] then
            return response.error(error.USER_NOT_ACTIVE)
        end

        if password_token.restore_token_is_valid(user_tuple[user.ID], token) then
            user_tuple = user.update({
                [user.ID] = user_tuple[user.ID],
                [user.PASSWORD] = user.hash_password(password),
            })

            return response.ok(user.serialize(user_tuple))
        else
            return response.error(error.WRONG_RESTORE_TOKEN)
        end
    end

    function api.social_auth_url(provider)
        -- TODO validate provider
        return response.ok(social.get_social_auth_url(provider))
    end

    function api.social_auth(provider, code)
        -- TODO validate provider and code
        local token, social_id, social_tuple
        local user_tuple = {}
        token = social.get_token(provider, code, user_tuple)
        if not validator.not_empty_string(token) then
            return response.error(error.WRONG_AUTH_TOKEN)
        end

        social_id = social.get_profile_info(provider, token, user_tuple)

        local email = user_tuple[user.EMAIL]
        local exists_user_tuple = user.get_by_email(email)
        if exists_user_tuple ~= nil then
            user_tuple[user.ID] = exists_user_tuple[user.ID]
        end

        user_tuple[user.IS_ACTIVE] = true
        user_tuple = user.create_or_update(user_tuple)
        social_tuple = social.create_or_update(user_tuple[user.ID], provider, social_id, token)

        local session = user.create_session(user_tuple[user.ID], user.SOCIAL_SESSION_TYPE)

        return response.ok(user.serialize(user_tuple, session))
    end

    return response.ok(api)
end

return auth