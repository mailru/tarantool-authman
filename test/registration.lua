local exports = {}
local tap = require('tap')
local response = require('response')
local error = require('error')
local auth = require('auth')
local db = require('db')

local test = tap.test('user_registration')

function exports.before()
    db.truncate_spaces()
end

function exports.after()

end

function test_registration()
    local ok, code = auth.registration('test@mail.ru')
    test:is(ok, true, 'user created')
    test:isstring(code, 'code returned')
end

function test_not_active_user_exists()
    auth.registration('test_exists@mail.ru')
    local ok, message = auth.registration('test_exists@mail.ru')
    test:is(ok, true, 'user created')
    test:isstring(message, 'code returned')
end

function test_invalid_email()
    local got, expected
    expected = {response.error(error.INVALID_PARAMS), }
    got = {auth.registration('not_email'), }
    test:is_deeply(got, expected, 'not email')
    got = {auth.registration(''), }
    test:is_deeply(got, expected, 'empty email')
end

function test_activate_user()
    local ok, code, user
    ok, code = auth.registration('test@mail.ru')
    ok, user = auth.complete_registration('test@mail.ru', code, '123123')

    user['id'] = nil -- remove random id
    test:is(ok, true, 'user activated success')
    test:is_deeply(user, {email = 'test@mail.ru', is_active = true}, 'user activated data returned')
end

function test_activate_user_wrong_code()
    local ok, code, got, expected
    ok, code = auth.registration('test@mail.ru')
    got = {auth.complete_registration('test@mail.ru', 'bad_code', '123123'), }
    expected = {response.error(error.WRONG_ACTIVATION_CODE), }
    test:is_deeply(got, expected, 'wrong activation code')
end

function test_register_already_active()
    local ok, code, got, expected, user
    ok, code = auth.registration('test@mail.ru')
    ok, user = auth.complete_registration('test@mail.ru', code, '123123')
    got = {auth.registration('test@mail.ru'), }
    expected = {response.error(error.USER_ALREADY_EXISTS), }
    test:is_deeply(got, expected, 'active user already exists')
end

function test_activate_already_active()
    local ok, code, got, expected, user
    ok, code = auth.registration('test@mail.ru')
    ok, user = auth.complete_registration('test@mail.ru', code, '123123')
    got = {auth.complete_registration('test@mail.ru', code, '123123'), }
    expected = {response.error(error.USER_ALREADY_ACTIVE), }
    test:is_deeply(got, expected, 'user already activated')
end

function test_activate_not_existing_user()
    local got, expected
    got = {auth.complete_registration('not_exists@mail.ru', 'some_code_here', '123123'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'activate not existing user')
end

exports.tests = {
    test_registration,
    test_not_active_user_exists,
    test_invalid_email,
    test_activate_user,
    test_activate_user_wrong_code,
    test_register_already_active,
    test_activate_already_active,
    test_activate_not_existing_user
}

return exports