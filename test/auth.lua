local exports = {}
local tap = require('tap')
local response = require('response')
local error = require('error')
local auth = require('auth')
local db = require('db')

local test = tap.test('fake_test')
local user_space = require('model.user').get_space()

function exports.setup() end

function exports.before()
    local ok, code
    ok, code = auth.registration('test@test.ru')
    auth.complete_registration('test@test.ru', code, '123')
    ok, code = auth.registration('not_active@test.ru')
end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end

function test_auth_success()
    local ok, user,session, expected
    ok, user = auth.auth('test@test.ru', '123')
    session = user['session']
    user['id'] = nil
    user['session'] = nil
    expected = {email = 'test@test.ru', is_active = true}
    test:is(ok, true, 'test_auth_success user logged in')
    test:isstring(session, 'test_auth_success session returned')
    test:is_deeply(user, expected, 'test_auth_success user returned')
end

function test_check_auth_success()
    local ok, user,session, expected
    ok, user = auth.auth('test@test.ru', '123')
    session = user['session']
    ok, user = auth.check_auth(session)
    session = user['session']
    user['id'] = nil
    user['session'] = nil
    expected = {email = 'test@test.ru', is_active = true}
    test:is(ok, true, 'test_check_auth_success user logged in')
    test:isstring(session, 'test_check_auth_success session returned')
    test:is_deeply(user, expected, 'test_check_auth_success user returned')
end

function test_auth_wrong_password()
    local got, expected
    got = {auth.auth('test@test.ru', 'wrong_password'), }
    expected = {response.error(error.WRONG_PASSWORD), }
    test:is_deeply(got, expected, 'test_auth_wrong_password')
end

function test_auth_user_not_found()
    local got, expected
    got = {auth.auth('not_found@test.ru', '123'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_auth_user_not_found')
end

function test_auth_user_not_active()
    local got, expected
    got = {auth.auth('not_active@test.ru', '123'), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_auth_user_not_active')
end

function test_check_auth_wrong_sign()
    local ok, user, got, expected
    ok, user = auth.auth('test@test.ru', '123')
    got = {auth.check_auth('thissession.iswrongsigned'), }
    expected = {response.error(error.WRONG_SESSION_SIGN), }
    test:is_deeply(got, expected, 'test_check_auth_wrong_sign')
end

function test_check_auth_user_not_found()
    local ok, user, id, session, got, expected
    ok, user = auth.auth('test@test.ru', '123')
    id = user['id']
    session = user['session']
    -- TODO API METHOD FOR DELETING USER ?
    user_space:delete(id)

    got = {auth.check_auth(session), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_check_auth_user_not_found')
end

function test_check_auth_user_not_active()
    local ok, user, id, session, got, expected
    ok, user = auth.auth('test@test.ru', '123')
    id = user['id']
    session = user['session']
    -- TODO API METHOD FOR BAN USER ?
    user_space:update(id, {{'=', 3, false}})

    got = {auth.check_auth(session), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_check_auth_user_not_active')
end

function test_check_auth_empty_session()
    local ok, user, got, expected
    ok, user = auth.auth('test@test.ru', '123')

    got = {auth.check_auth(''), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_check_auth_empty_session')
end

-- TODO NEED TO TEST CHECK_AUTH EXPIRATION DATE FUNCTIONALITY

exports.tests = {
    test_auth_success,
    test_check_auth_success,

    test_auth_wrong_password,
    test_auth_user_not_found,
    test_auth_user_not_active,
    test_check_auth_wrong_sign,
    test_check_auth_user_not_found,
    test_check_auth_user_not_active,
    test_check_auth_empty_session,

}

return exports