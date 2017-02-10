local exports = {}
local tap = require('tap')
local auth = require('auth')
local test = tap.test('fake_test')

function exports.before() print('before') end

function exports.after() print('after') end

function fake_test()
    test:ok(2 * 2 == 4, '2 * 2 is 4')
end

exports.tests = {
    fake_test
}

return exports