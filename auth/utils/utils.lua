local utils = {}
local digest = require('digest')
local validator = require('auth.validator')

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

function utils.base64_encode(string)
    return string.gsub(
        digest.base64_encode(string), '\n', ''
    )
end

function utils.lower(string)
    if validator.string(string) then
        return string:lower()
    end
end

return utils