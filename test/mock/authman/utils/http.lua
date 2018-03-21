local http = {}

local json = require('json')
local v = require('test.values')

local function response(code, body)
    return {
        status = code,
        body = json.encode(body)
    }
end

function http.api(config)

    local api = {}

    function api.request(method, url, params, param_values)

        if string.match(url, 'vk.com') ~= nil then
            if string.match(params, 'code=') then
                if param_values['code'] == v.VALID_CODE then
                    return response(v.HTTP_OK, {
                        email = v.USER_EMAIL,
                        access_token = v.VALID_TOKEN
                    })
                elseif param_values['code'] == v.VALID_CODE_NO_EMAIL then
                    return response(v.HTTP_OK, {
                        access_token = v.VALID_TOKEN
                    })
                elseif param_values['code'] == v.VALID_CODE_NO_PROFILE then
                    return response(v.HTTP_OK, {
                        email = v.USER_EMAIL,
                        access_token = v.VALID_TOKEN_NO_PROFILE
                    })
                elseif param_values['code'] == v.INVALID_CODE_TOKEN then
                    return response(v.HTTP_OK, {
                        email = v.USER_EMAIL,
                        access_token = v.INVALID_TOKEN
                    })
                elseif param_values['code'] == v.INVALID_CODE then
                    return response(v.HTTP_401, {})
                end

            elseif string.match(params, 'token=') then
                if param_values['token'] == v.VALID_TOKEN then
                    return response(v.HTTP_OK, {
                        response = {
                            {id=v.SOCIAL_ID, first_name=v.USER_FIRST_NAME, last_name=v.USER_LAST_NAME},
                        }
                    })
                elseif param_values['token'] == v.VALID_TOKEN_NO_PROFILE then
                    return response(v.HTTP_OK, {
                        response = {
                            {id=v.SOCIAL_ID},
                        }
                    })
                elseif param_values['token'] == v.INVALID_TOKEN then
                    return response(v.HTTP_401, {})
                end
            end

        end
    end

    return api
end


return http