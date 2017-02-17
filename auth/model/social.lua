local social = {}
local curl = require('curl')
local json = require('json')
local utils = require('auth.util.utils')

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
            id = social_tuple[social_tuple.ID],
            social_type = social_tuple[social_tuple.SOCIAL_TYPE],
            social_id = social_tuple[social_tuple.SOCIAL_ID],
        }
    end

    function model.create_or_update(user_id, provider, social_id, token)
        local social_tuple
        social_tuple = model.get_space():get(user_id)
        if social_tuple ~= nil then
            model.get_space():update(user_id, {
                {'=', model.PROVIDER, provider},
                {'=', model.SOCIAL_ID, social_id},
                {'=', model.TOKEN, token}
            })
            return user_id
        end

        social_tuple = model.get_space().index[model.SOCIAL_INDEX]:get({social_id, provider})

        if social_tuple ~= nil then
            model.get_space():update(social_tuple[model.USER_ID], {
                {'=', model.TOKEN, token}
            })
            return user_id
        end

        model.get_space():insert({user_id, provider, social_id, token})
        return user_id
    end

    function model.get_social_auth_url(provider)
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

    function model.get_token(provider, code, user_tuple)
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

    function model.get_profile_info(provider, token, user_tuple)
        local url, params, response, data
        user_tuple[user.PROFILE] = {}

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
                user_tuple[user.PROFILE][user.PROFILE_FIRST_NAME] = data.first_name
                user_tuple[user.PROFILE][user.PROFILE_LAST_NAME] = data.last_name
                return data.id
            end
        end
    end

    return model
end

return social