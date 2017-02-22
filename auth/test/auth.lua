local exports = {}
local tap = require('tap')
local fiber = require('fiber')
local response = require('auth.response')
local error = require('auth.error')
local db = require('auth.db')
local config = require('auth.test.config')

local test = tap.test('auth_test')
local auth = require('auth').api(config)
local user_space = require('auth.model.user').model(config).get_space()

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
    expected = {email = 'test@test.ru', is_active = true }
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

function test_check_auth_update_session_success()
    local ok, user, got, expected, first_session, second_session
    ok, user = auth.auth('test@test.ru', '123')
    first_session = user['session']

    fiber.sleep(config.session_lifetime - config.session_update_timedelta)

    ok, user = auth.check_auth(first_session)
    test:is(ok, true, 'test_check_auth_update_session_success session updated')

    second_session = user['session']
    test:isstring(second_session, 'test_check_auth_update_session_success session returned')
    test:isnt(first_session, second_session, 'test_check_auth_update_session_success new session')
end

function test_check_auth_expired_session()
    local ok, user, got, expected, session
    ok, user = auth.auth('test@test.ru', '123')
    session = user['session']

    fiber.sleep(config.session_lifetime)

    got = {auth.check_auth(session), }
    expected = {response.error(error.NOT_AUTHENTICATED), }
    test:is_deeply(got, expected, 'test_check_auth_expired_session')
end

exports.tests = {
    test_auth_success,
    test_check_auth_success,
    test_check_auth_update_session_success,

    test_auth_wrong_password,
    test_auth_user_not_found,
    test_auth_user_not_active,
    test_check_auth_wrong_sign,
    test_check_auth_user_not_found,
    test_check_auth_user_not_active,
    test_check_auth_empty_session,
    test_check_auth_expired_session,

}

return exports