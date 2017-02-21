local utils = {}
local curl = require('curl')

local http = curl.http()

function utils.format(string, tab)
    return (string:gsub('($%b{})', function(word) return tab[word:sub(3, -2)] or word end))
end

function utils.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. utils.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function utils.request(method, url, params, param_values)
    local response, connection_timeot, read_timeout, body, ok, msg
    connection_timeot = 10
    read_timeout = 20

    if method == 'POST' then
        body = utils.format(params, param_values)
        ok, msg = pcall(function()
            response = http:post(url, body, {
                headers = {['Content-Type'] = 'application/x-www-form-urlencoded'},
                connection_timeot = connection_timeot,
                read_timeout = read_timeout
            })
        end)
    else
        params = utils.format(params, param_values)
        url = url .. params
        ok, msg = pcall(function()
            response = http:get(url, {
                connection_timeot = connection_timeot,
                read_timeout = read_timeout
            })
        end)
    end
    return response
end

return utils