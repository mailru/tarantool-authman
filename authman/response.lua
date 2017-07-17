local response = {}
local errors = require('authman.error')

----
-- Standart output format
----

function response.error(code)
    local message = {[code] = errors.CODES[code]}
    return false, message
end

function response.ok(data)
    return true, data
end

return response