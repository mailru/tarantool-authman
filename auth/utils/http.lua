local http = {}
local curl = require('curl')
local utils = require('auth.utils.utils')
local curl_http = curl.http()

function http.request(method, url, params, param_values)
    local response, connection_timeot, read_timeout, body, ok, msg
    connection_timeot = 10
    read_timeout = 20

    if method == 'POST' then
        body = utils.format(params, param_values)
        ok, msg = pcall(function()
            response = curl_http:post(url, body, {
                headers = {['Content-Type'] = 'application/x-www-form-urlencoded'},
                connection_timeot = connection_timeot,
                read_timeout = read_timeout
            })
        end)
    else
        params = utils.format(params, param_values)
        url = url .. params
        ok, msg = pcall(function()
            response = curl_http:get(url, {
                connection_timeot = connection_timeot,
                read_timeout = read_timeout
            })
        end)
    end
    return response
end

return http