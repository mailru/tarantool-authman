local social = {}

local curl = require('curl')
local json = require('json')
local config = require('auth.config')
local utils = require('auth.util.utils')
local user = require('auth.model.user')

local http = curl.http()

-----
-- token (user_uuid, social_type, social_id, token)
-----

social.SPACE_NAME = 'portal_social_auth_credentials'

social.PRIMARY_INDEX = 'primary'
social.SOCIAL_INDEX = 'social'

social.USER_ID = 1
social.PROVIDER = 2
social.SOCIAL_ID = 3
social.TOKEN = 4

social.ALLOWED_PROVIDERS = {'facebook', 'vk', 'google'}

function social.get_space()
    return box.space[social.SPACE_NAME]
end

function social.serialize(social_tuple)
    return {
        id = social_tuple[social_tuple.ID],
        social_type = social_tuple[social_tuple.SOCIAL_TYPE],
        social_id = social_tuple[social_tuple.SOCIAL_ID],
    }
end

function social.create_or_update(user_id, provider, social_id, token)
    local social_tuple
    social_tuple = social.get_space():get(user_id)
    if social_tuple ~= nil then
        -- TODO remove provider-social_id pair?
        social.get_space():update(user_id, {
            {'=', social.PROVIDER, provider},
            {'=',social.SOCIAL_ID, social_id},
            {'=', social.TOKEN, token}
        })
        return user_id
    end

    social_tuple = social.get_space().index[social.SOCIAL_INDEX]:get({provider, social_id})
    if social_tuple ~= nil then
        social.get_space():update(social_tuple[social.USER_ID], {
            {'=', social.TOKEN, token}
        })
        return user_id
    end

    social.get_space():insert({user_id, provider, social_id, token})
    return user_id
end

function social.get_social_auth_url(provider)
    local url, params
    if provider == 'facebook' then
        url = 'https://www.facebook.com/v2.8/dialog/oauth'
        params = '?client_id=${client_id}&redirect_uri=${redirect_uri}&scope=email'
        params = utils.format(params, {
            client_id = config[provider].client_id,
            redirect_uri = config[provider].redirect_uri
        })
        return url .. params
    end
end

function social.get_token(provider, code, user_tuple)
    local url, params, response, data, token
    if provider == 'facebook' then
        url = 'https://graph.facebook.com/v2.8/oauth/access_token'
        params = '?client_id=${client_id}&redirect_uri=${redirect_uri}&client_secret=${client_secret}&code=${code}'
        params = utils.format(params, {
            client_id = config[provider].client_id,
            redirect_uri = config[provider].redirect_uri,
            client_secret = config[provider].client_secret,
            code = code,
        })
        url = url .. params
        response = http:request('GET', url, '')
        if response.code ~= 200 then
            return nil
        else
            data = json.decode(response.body)
            return data.access_token
        end
    end
end

function social.get_profile_info(provider, token, user_tuple)
    local url, params, response, data
    if provider == 'facebook' then
        url = 'https://graph.facebook.com/me'
        params = '?access_token=${token}&fields=email,first_name,last_name'
        params = utils.format(params, {token = token})

        url = url .. params
        response = http:request('GET', url, '')
        if response.code ~= 200 then
            return nil
        else
            data = json.decode(response.body)
            user_tuple[user.EMAIL] = data.email
            -- TODO set profile
            return data.id
        end
    end

end

return social