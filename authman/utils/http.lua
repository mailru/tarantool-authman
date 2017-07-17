local http = {}
local utils = require('authman.utils.utils')
local curl_http = require('http.client')

function http.api(config)
    local api = {}

    local timeout = config.request_timeout

    function api.request(method, url, params, param_values)
        local response, connection_timeot, read_timeout, body, ok, msg

        if method == 'POST' then
            body = utils.format(params, param_values)
            ok, msg = pcall(function()
                response = curl_http.post(url, body, {
                    headers = {['Content-Type'] = 'application/x-www-form-urlencoded'},
                    timeout = timeout
                })
            end)
        else
            params = utils.format(params, param_values)
            url = url .. params
            ok, msg = pcall(function()
                response = curl_http.get(url, {
                    timeout = timeout
                })
            end)
        end
        return response
    end

    return api
end

return http