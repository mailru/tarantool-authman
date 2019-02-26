local exports = {}
local tap = require('tap')
local response = require('authman.response')
local error = require('authman.error')
local validator = require('authman.validator')
local v = require('test.values')

-- model configuration
local config = validator.config(require('test.config'))
local db = require('authman.db').configurate(config)
local auth = require('authman').api(config)
local user_space = require('authman.model.user').model(config).get_space()
local get_id_by_email = require('authman.model.user').model(config).get_id_by_email

local test = tap.test('restore_pwd_test')

function exports.setup() end

function exports.before()
    local ok, user
    ok, user = auth.registration('test@test.ru')
    auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    ok, user = auth.registration('not_active@test.ru')
end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end

function test_restore_password_success()
    local ok, token
    ok, token = auth.restore_password('test@test.ru')
    test:is(ok, true, 'test_restore_password_success password restored')
    test:isstring(token, 'test_restore_password_success token returned')
end

function test_complete_restore_password_success()
    local ok, token, user, expected, session, nok
    ok, user = auth.auth('test@test.ru', v.USER_PASSWORD)
    session = user['session']
    ok, token = auth.restore_password('test@test.ru')
    ok, user = auth.complete_restore_password('test@test.ru', token, 'new_pwd')
    nok, _ = auth.check_auth(session)
    user['id'] = nil
    expected = {email = 'test@test.ru', is_active = true}
    test:is(ok, true, 'test_complete_restore_password_success password changed')
    test:is(nok, false, 'test_complete_restore_password_success session dropped')
    test:is_deeply(user, expected, 'test_complete_restore_password_success user returned')
end

function test_complete_restore_password_and_auth_success()
    local ok, token, user, expected, session
    ok, token = auth.restore_password('test@test.ru')
    ok, user = auth.complete_restore_password('test@test.ru', token, 'new_pwd')
    ok, user = auth.auth('test@test.ru', 'new_pwd')
    session = user['session']
    user['id'] = nil
    user['session'] = nil
    expected = {email = 'test@test.ru', is_active = true}
    test:is(ok, true, 'test_complete_restore_password_and_auth_success user logged in')
    test:isstring(session, 'test_complete_restore_password_and_auth_success session returned')
    test:is_deeply(user, expected, 'test_complete_restore_password_and_auth_success user returned')
end

function test_restore_password_user_not_found()
    local got, expected
    got = {auth.restore_password('not_found@test.ru'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_restore_password_user_not_found')
end

function test_restore_password_user_not_active()
    local got, expected
    got = {auth.restore_password('not_active@test.ru'), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_restore_password_user_not_active')
end

function test_complete_restore_password_user_not_found()
    local ok, token, id, session, got, expected
    ok, token = auth.restore_password('test@test.ru')

    -- TODO API METHOD FOR DELETING USER BY EMAIL ?
    id = get_id_by_email('test@test.ru')
    user_space:delete(id)

    got = {auth.complete_restore_password('test@test.ru', token, 'new_pwd'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_complete_restore_password_user_not_found')
end

function test_complete_restore_passsword_weak()
    local ok, token, id, session, got, expected
    ok, token = auth.restore_password('test@test.ru')

    got = {auth.complete_restore_password('test@test.ru', token, 'weak'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_restore_passsword_weak 1')

    got = {auth.complete_restore_password('test@test.ru', token, '123123123'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_restore_passsword_weak 2')

    got = {auth.complete_restore_password('test@test.ru', token, 'слабый'), }
    expected = {response.error(error.WEAK_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_restore_passsword_weak 3')
end

function test_complete_restore_password_user_not_active()
    local ok, token, id, session, got, expected
    ok, token = auth.restore_password('test@test.ru')

    -- TODO API METHOD FOR BAN USER BY EMAIL ?
    id = get_id_by_email('test@test.ru')
    user_space:update(id, {{'=', 4, false}})

    got = {auth.complete_restore_password('test@test.ru', token, 'new_pwd'), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_complete_restore_password_user_not_active')
end

function test_complete_restore_password_wrong_token()
    local ok, token, id, session, got, expected
    ok, token = auth.restore_password('test@test.ru')

    got = {auth.complete_restore_password('test@test.ru', 'wrong_password_token', 'new_pwd'), }
    expected = {response.error(error.WRONG_RESTORE_TOKEN), }
    test:is_deeply(got, expected, 'test_complete_restore_password_wrong_token')
end

function test_complete_restore_password_auth_with_old_password()
    local ok, token, user, got, expected
    ok, token = auth.restore_password('test@test.ru')
    ok, user = auth.complete_restore_password('test@test.ru', token, 'new_pwd')
    got = {auth.auth('test@test.ru', v.USER_PASSWORD), }
    expected = {response.error(error.WRONG_PASSWORD), }
    test:is_deeply(got, expected, 'test_complete_restore_password_auth_with_old_password')
end

function test_complete_restore_password_empty_token()
    local ok, token, got, expected
    ok, token = auth.restore_password('test@test.ru')
    got = {auth.complete_restore_password('test@test.ru', '', 'new_pwd'), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_complete_restore_password_empty_token')
end

exports.tests = {
    test_restore_password_success,
    test_complete_restore_password_success,
    test_complete_restore_password_and_auth_success,

    test_restore_password_user_not_found,
    test_restore_password_user_not_active,
    test_complete_restore_password_user_not_found,
    test_complete_restore_passsword_weak,
    test_complete_restore_password_user_not_active,
    test_complete_restore_password_wrong_token,
    test_complete_restore_password_auth_with_old_password,
    test_complete_restore_password_empty_token,
}

return exports
