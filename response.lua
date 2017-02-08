exports = {}

----
-- Standart output format
----
function exports.error(message)
    error(message)
    return false, message
end

function exports.ok(data)
    return true, data
end

return exports