local exports = {}
local tap = require('tap')
local response = require('auth.response')
local error = require('auth.error')
local validator = require('auth.validator')
local v = require('test.values')

-- model configuration
local config = validator.config(require('test.config'))
local db = require('auth.db').configurate(config)
local auth = require('auth').api(config)

local test = tap.test('registration_test')

function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_registration_succes()
    local ok, user
    ok, user = auth.registration('test@test.ru')
    test:is(ok, true, 'test_registration_succes user created')
    test:isstring(user.code, 'test_registration_succes code returned')
    test:is(user.email, 'test@test.ru', 'test_registration_succes email returned')
end

function test_registartion_user_not_active_success()
    local ok, user
    ok, user = auth.registration('test_exists@test.ru')
    ok, user = auth.registration('test_exists@test.ru')
    test:is(ok, true, 'test_registartion_user_not_active_success user created')
    test:isstring(user.code, 'test_registartion_user_not_active_success code returned')
    test:is(user.email, 'test_exists@test.ru', 'test_registartion_user_not_active_success email returned')
end

function test_complete_registration_succes()
    local ok, user
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)

    user['id'] = nil -- remove random id
    test:is(ok, true, 'test_complete_registration_succes activated success')
    test:is_deeply(user, {email = 'test@test.ru', is_active = true}, 'test_complete_registration_succes user returned')
end

function test_registration_invalid_email()
    local got, expected
    expected = {response.error(error.INVALID_PARAMS), }
    got = {auth.registration('not_email'), }
    test:is_deeply(got, expected, 'test_registration_invalid_email not email')
    got = {auth.registration(''), }
    test:is_deeply(got, expected, 'test_registration_invalid_email empty email')
end

function test_registration_user_already_active()
    local ok, got, expected, user
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    got = {auth.registration('test@test.ru'), }
    expected = {response.error(error.USER_ALREADY_EXISTS), }
    test:is_deeply(got, expected, 'test_registration_user_already_active')
end

function test_complete_registration_wrong_code()
    local ok, user, got, expected
    ok, user = auth.registration('test@test.ru')
    got = {auth.complete_registration('test@test.ru', 'bad_code', v.USER_PASSWORD), }
    expected = {response.error(error.WRONG_ACTIVATION_CODE), }
    test:is_deeply(got, expected, 'test_complete_registration_wrong_code')
end

function test_complete_registration_weak_password()
    local ok, user, got, expected
    ok, user = auth.registration('test@test.ru')

    got = {auth.complete_registration('test@test.ru', user.code, 'weak'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_registration_weak_password 1')

    got = {auth.complete_registration('test@test.ru', user.code, '123123123'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_registration_weak_password 2')

    got = {auth.complete_registration('test@test.ru', user.code, 'слабый'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_registration_weak_password 3')
end

function test_complete_registration_user_already_active()
    local ok, user, got, expected, user, code
    ok, user = auth.registration('test@test.ru')
    code = user.code
    ok, user = auth.complete_registration('test@test.ru', code, v.USER_PASSWORD)
    got = {auth.complete_registration('test@test.ru', code, v.USER_PASSWORD), }
    expected = {response.error(error.USER_ALREADY_ACTIVE), }
    test:is_deeply(got, expected, 'test_complete_registration_user_already_active')
end

function test_complete_registration_user_not_found()
    local got, expected
    got = {auth.complete_registration('not_found@test.ru', 'some_code_here', v.USER_PASSWORD), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_complete_registration_user_not_found')
end

function test_complete_registration_empty_code()
    local ok, user, got, expected
    ok, user = auth.registration('test@test.ru')
    got = {auth.complete_registration('test@test.ru', '', v.USER_PASSWORD), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_complete_registration_empty_code')
end

exports.tests = {
    test_registration_succes,
    test_registartion_user_not_active_success,
    test_complete_registration_succes,

    test_registration_invalid_email,
    test_registration_user_already_active,
    test_complete_registration_wrong_code,
    test_complete_registration_weak_password,
    test_complete_registration_user_already_active,
    test_complete_registration_user_not_found,
    test_complete_registration_empty_code,
}

return exports