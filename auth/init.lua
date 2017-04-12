local auth = {}
local response = require('auth.response')
local error = require('auth.error')
local validator = require('auth.validator')
local db = require('auth.db')
local utils = require('auth.utils.utils')


function auth.api(config)
    local api = {}

    config = validator.config(config)

    local user = require('auth.model.user').model(config)
    local password = require('auth.model.password').model(config)
    local password_token = require('auth.model.password_token').model(config)
    local social = require('auth.model.social').model(config)
    local session = require('auth.model.session').model(config)

    db.create_database()

    -----------------
    -- API methods --
    -----------------
    function api.registration(email)
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

        user_tuple = user.create({
            [user.EMAIL] = email,
            [user.TYPE] = user.COMMON_TYPE,
            [user.IS_ACTIVE] = false,
        })

        local code = user.generate_activation_code(user_tuple[user.ID])
        return response.ok(user.serialize(user_tuple, {code=code}))
    end

    function api.complete_registration(email, code, raw_password)
        email = utils.lower(email)

        if not (validator.email(email) and validator.not_empty_string(code)) then
            return response.error(error.INVALID_PARAMS)
        end

        if not validator.password(raw_password) then
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

        if not validator.password(raw_password) then
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

        user_tuple[user.EMAIL] = utils.lower(user_tuple[user.EMAIL])
        user_tuple[user.IS_ACTIVE] = true
        user_tuple[user.TYPE] = user.SOCIAL_TYPE

        social_tuple = social.get_by_social_id(social_id, provider)
        if social_tuple == nil then
            user_tuple = user.create(user_tuple)
            social_tuple = social.create({
                [social.USER_ID] = user_tuple[user.ID],
                [social.PROVIDER] = provider,
                [social.SOCIAL_ID] = social_id,
                [social.TOKEN] = token
            })
        else
            user_tuple[user.ID] = social_tuple[social.USER_ID]
            user_tuple = user.create_or_update(user_tuple)
            social_tuple = social.update({
                [social.ID] = social_tuple[social.ID],
                [social.USER_ID] = user_tuple[user.ID],
                [social.TOKEN] = token
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

    return api
end

return auth