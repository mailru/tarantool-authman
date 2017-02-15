local auth = {}
local uuid = require('uuid')
local config = require('auth.config')
local response = require('auth.response')
local error = require('auth.error')
local validator = require('auth.validator')

local user = require('auth.model.user')
local password_token = require('auth.model.password_token')
local social = require('auth.model.social')

local user_space = user.get_space()

-----
-- API methods
-----
function auth.registration(email)
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

    local user_id = uuid.str()
    local code = user.generate_activation_code(user_id)
    user_space:insert{user_id, email, false, '' }
    return response.ok(code)
end

function auth.complete_registration(email, code, password)
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

    user_space:update(user_id, {{'=', 3, true}, {'=', 4, user.hash_password(password)}})
    user_tuple = user_space:get(user_id)
    return response.ok(user.serialize(user_tuple))
end

function auth.auth(email, password)
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

function auth.check_auth(signed_session)
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
        local social_tuple = social.get_space():get(user_tuple[user.ID])
        if social_tuple == nil then
            return response.error(error.USER_NOT_FOUND)
        end

        if session_data.exp < os.time() then
            -- TODO try to update profile
            local new_user_tuple = {}
            local social_id = social.get_profile_info(
                social_tuple[social.PROVIDER], social_tuple[social.TOKEN], new_user_tuple
            )

            if social_id == nil then
                return response.error(error.NOT_AUTHENTICATED)
            end

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

function auth.restore_password(email)
    local user_tuple = user.get_by_email(email)
    if user_tuple == nil then
        return response.error(error.USER_NOT_FOUND)
    end

    if not user_tuple[user.IS_ACTIVE] then
        return response.error(error.USER_NOT_ACTIVE)
    end
    return response.ok(password_token.generate_restore_token(user_tuple[user.ID]))
end

function auth.complete_restore_password(email, token, password)
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
        user_space:update(user_tuple[user.ID], {{'=', user.PASSWORD, user.hash_password(password)}})
        return response.ok(user.serialize(user_tuple))
    else
        return response.error(error.WRONG_RESTORE_TOKEN)
    end
end

function auth.social_auth_url(provider)
    return response.ok(social.get_social_auth_url(provider))
end

function auth.social_auth(provider, code)
    -- TODO validate provider and code
    local user_tuple = {}
    local token = social.get_token(provider, code, user_tuple)

    if not validator.not_empty_string(token) then
        return response.error(error.WRONG_AUTH_TOKEN)
    end
    local social_id = social.get_profile_info(provider, token, user_tuple)

    local email = user_tuple[user.EMAIL]
    local exists_user_tuple = user.get_by_email(email)
    local user_id = exists_user_tuple ~= nil and exists_user_tuple[user.ID] or uuid.str();
    local user_id = social.create_or_update(user_id, provider, social_id, token)
    -- TODO refactor for create_or_update
    local user_tuple = user.create_or_update(user_id, email, true, '')
    -- TODO update profile with user_tuple
    local session = user.create_session(user_tuple[user.ID], user.SOCIAL_SESSION_TYPE)

    return response.ok(session)
end

return auth