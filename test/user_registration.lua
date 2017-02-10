local exports = {}
local tap = require('tap')
local auth = require('auth')

local test = tap.test('user_registration')

function exports.before() print('before') end

function exports.after() print('after') end

function test_registration()
    local ok, message = auth.registration('test@mail.ru')
    test:is(ok, true, 'user created')
    test:isstring(message, 'code returned')
end

function test_user_exists()
    local ok, message = auth.registration('test_exists@mail.ru')
    local ok, message = auth.registration('test_exists@mail.ru')
    test:is(ok, false, 'user not created')
    test:is(message, 'code returned')
end

exports.tests = {
    test_registration,
    test_user_exists
}

return exports