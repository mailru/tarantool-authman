local response = {}
local errors = require('error')

----
-- Standart output format
----

function response.error(code)
    local message = errors.CODES[code]
    error(message)
    return false, {[code] = message}
end

function response.ok(data)
    return true, data
end

return response