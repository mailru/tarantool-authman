local utils = {}
local digest = require('digest')
local fiber = require('fiber')
local math = require('math')
local validator = require('authman.validator')

function utils.now()
    return math.floor(fiber.time())
end

function utils.format(string, tab)
    return (string:gsub('($%b{})', function(word) return tab[word:sub(3, -2)] or word end))
end

function utils.format_update(tuple)
    local fields = {}
    for number, value in pairs(tuple) do
        table.insert(fields, {'=', number, value})
    end
    return fields
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

function utils.gen_random_key(key_len)
    return string.hex(digest.urandom(key_len or 10))
end

function utils.salted_hash(str, salt)
    return digest.sha256(string.format('%s%s', salt, str))
end

return utils
