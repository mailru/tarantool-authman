local social = {}
local json = require('json')
local utils = require('auth.util.utils')
local validator = require('auth.validator')
local curl = require('curl')

local http = curl.http()

-----
-- social (user_uuid, social_type, social_id, token)
-----
function social.model(config)
    local model = {}
    local user = require('auth.model.user').model(config)

    model.SPACE_NAME = 'portal_social_auth_credentials'

    model.PRIMARY_INDEX = 'primary'
    model.SOCIAL_INDEX = 'social'

    model.USER_ID = 1
    model.PROVIDER = 2
    model.SOCIAL_ID = 3
    model.TOKEN = 4

    model.ALLOWED_PROVIDERS = {'facebook', 'vk', 'google'}

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.serialize(social_tuple)
        return {
            provider = social_tuple[model.PROVIDER],
            social_id = social_tuple[model.SOCIAL_ID],
        }
    end

    function model.get_by_id(user_id)
        return model.get_space():get(user_id)
    end

    function model.create_or_update(social_tuple)
        local exists_social_tuple = model.get_space():get(social_tuple[model.USER_ID])
        if exists_social_tuple ~= nil then
            social_tuple = model.get_space():update(social_tuple[model.USER_ID], {
                {'=', model.PROVIDER, social_tuple[model.PROVIDER]},
                {'=', model.SOCIAL_ID, social_tuple[model.SOCIAL_ID]},
                {'=', model.TOKEN, social_tuple[model.TOKEN]}
            })
            return social_tuple
        end

        exists_social_tuple = model.get_space().index[model.SOCIAL_INDEX]:get({
            social_tuple[model.SOCIAL_ID],
            social_tuple[model.PROVIDER]
        })

        if exists_social_tuple ~= nil then
            social_tuple = model.get_space():update(social_tuple[model.USER_ID], {
                {'=', model.TOKEN, social_tuple[model.TOKEN]}
            })
            return social_tuple
        end

        social_tuple = model.get_space():insert(social_tuple)
        return social_tuple
    end

    function model.get_social_auth_url(provider, state)
        local url, params

        if provider == 'facebook' then
            url = 'https://www.facebook.com/v2.8/dialog/oauth'
            params = '?client_id=${client_id}&redirect_uri=${redirect_uri}&scope=email'
            params = utils.format(params, {
                client_id = config[provider].client_id,
                redirect_uri = config[provider].redirect_uri
            })
        elseif provider == 'vk' then
            url = 'https://oauth.vk.com/authorize'
            params = '?client_id=${client_id}&display=page&redirect_uri=${redirect_uri}&scope=offline,email&response_type=code&v=5.62'
            params = utils.format(params, {
                client_id = config[provider].client_id,
                redirect_uri = config[provider].redirect_uri
            })
        elseif provider == 'google' then
            url = 'https://accounts.google.com/o/oauth2/v2/auth'
            params = '?client_id=${client_id}&redirect_uri=${redirect_uri}&response_type=code&scope=email&access_type=offline&prompt=consent'
            params = utils.format(params, {
                client_id = config[provider].client_id,
                redirect_uri = config[provider].redirect_uri
            })
        end

        if validator.not_empty_string(state) then
            params = params .. '&state=' .. state
        end

        return url .. params
    end

    function model.get_token(provider, code, user_tuple)
        local response, data, token
        if provider == 'facebook' then
            response = utils.request(
                'GET',
                'https://graph.facebook.com/v2.8/oauth/access_token',
                '?client_id=${client_id}&redirect_uri=${redirect_uri}&client_secret=${client_secret}&code=${code}',
                {
                    client_id = config[provider].client_id,
                    redirect_uri = config[provider].redirect_uri,
                    client_secret = config[provider].client_secret,
                    code = code,
                }
            )
            if response == nil or response.code ~= 200 then
                return nil
            else
                data = json.decode(response.body)
                return data.access_token
            end

        elseif provider == 'vk' then
            response = utils.request(
                'GET',
                'https://oauth.vk.com/access_token',
                '?client_id=${client_id}&redirect_uri=${redirect_uri}&client_secret=${client_secret}&code=${code}',
                {
                    client_id = config[provider].client_id,
                    redirect_uri = config[provider].redirect_uri,
                    client_secret = config[provider].client_secret,
                    code = code,
                }
            )
            if response == nil or response.code ~= 200 then
                return nil
            else
                data = json.decode(response.body)
                user_tuple[user.EMAIL] = data.email
                return data.access_token
            end

        elseif provider == 'google' then
            response = utils.request(
                'POST',
                'https://www.googleapis.com/oauth2/v4/token',
                'client_id=${client_id}&redirect_uri=${redirect_uri}&client_secret=${client_secret}&code=${code}&grant_type=authorization_code',
                {
                    client_id = config[provider].client_id,
                    redirect_uri = config[provider].redirect_uri,
                    client_secret = config[provider].client_secret,
                    code = code,
                }
            )

            if response == nil or response.code ~= 200 then
                return nil
            else
                data = json.decode(response.body)
                return data.refresh_token
            end

        end
    end

    function model.get_profile_info(provider, token, user_tuple)
        local url, params, response, data, body, access_token, social_id
        user_tuple[user.PROFILE] = {}

        if provider == 'facebook' then
            response = utils.request(
                'GET',
                'https://graph.facebook.com/me',
                '?access_token=${token}&fields=email,first_name,last_name',
                { token = token }
            )

            if response == nil or response.code ~= 200 then
                return nil
            else
                data = json.decode(response.body)
                user_tuple[user.EMAIL] = data.email
                user_tuple[user.PROFILE][user.PROFILE_FIRST_NAME] = data.first_name
                user_tuple[user.PROFILE][user.PROFILE_LAST_NAME] = data.last_name
                return data.id
            end
        elseif provider == 'vk' then
            response = utils.request(
                'GET',
                'https://api.vk.com/method/users.get',
                '?access_token=${token}&fields=first_name,last_name',
                { token = token }
            )

            if response == nil or response.code ~= 200 then
                return nil
            else
                data = json.decode(response.body)
                data = data.response[1]
                if data == nil then
                    return nil
                end
                if data.uid == nil then
                    return nil
                end
                user_tuple[user.PROFILE][user.PROFILE_FIRST_NAME] = data.first_name
                user_tuple[user.PROFILE][user.PROFILE_LAST_NAME] = data.last_name
                return tostring(data.uid)
            end

        elseif provider == 'google' then
            response = utils.request(
                'POST',
                'https://www.googleapis.com/oauth2/v4/token',
                'client_id=${client_id}&client_secret=${client_secret}&refresh_token=${token}&grant_type=refresh_token',
                {
                    client_id = config[provider].client_id,
                    client_secret = config[provider].client_secret,
                    token = token
                }
            )

            if response == nil or response.code ~= 200 then
                return nil
            end

            data = json.decode(response.body)
            access_token = data.access_token

            response = utils.request(
                'GET',
                'https://www.googleapis.com/oauth2/v2/userinfo',
                '?access_token=${access_token}',
                { access_token = access_token }
            )

            if response == nil or response.code ~= 200 then
                return nil
            end

            data = json.decode(response.body)

            user_tuple[user.EMAIL] = data.email
            user_tuple[user.PROFILE][user.PROFILE_FIRST_NAME] = data.given_name
            user_tuple[user.PROFILE][user.PROFILE_LAST_NAME] = data.family_name
            return data.id
        end
    end

    return model
end

return social