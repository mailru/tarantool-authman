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

local test = tap.test('auth_test')

function exports.setup() end

function exports.before() end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end


function test_set_profile_success()
    local user_profile, ok, user, code, expected
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    user_profile = {last_name='test_last', first_name='test_first' }

    ok, user = auth.set_profile(user['id'], user_profile)

    user['id'] = nil
    expected = {email = 'test@test.ru', is_active = true, profile=user_profile}
    test:is(ok, true, 'test_set_profile_success user returned')
    test:is_deeply(user, expected, 'test_set_profile_success profile set')
end

function test_set_profile_invalid_id()
    local got, expected, user_profile
    user_profile = {last_name='test_last', first_name='test_first' }

    got = {auth.set_profile('', user_profile), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_set_profile_invalid_id')
end

function test_set_profile_user_not_found()
    local got, expected, user_profile
    user_profile = {last_name='test_last', first_name='test_first' }

    got = {auth.set_profile('not exists', user_profile), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_set_user_not_found')
end

function test_set_profile_user_not_active()
    local got, expected, user_profile, ok, code, user, id
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    id = user['id']

    user_space:update(id, {{'=', 4, false}})
    user_profile = {last_name='test_last', first_name='test_first' }

    got = {auth.set_profile(id, user_profile), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_set_profile_user_not_active')
end

function test_get_profile_success()
    local user_profile, ok, user, code, expected
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    user_profile = {last_name='test_last', first_name='test_first' }

    ok, user = auth.set_profile(user['id'], user_profile)
    ok, user = auth.get_profile(user['id'])

    user['id'] = nil
    expected = {email = 'test@test.ru', is_active = true, profile=user_profile}
    test:is(ok, true, 'test_get_profile_success user returned')
    test:is_deeply(user, expected, 'test_get_profile_success profile')
end

function test_get_profile_invalid_id()
    local got, expected, user_profile

    got = {auth.get_profile(''), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_set_profile_invalid_id')
end

function test_get_profile_user_not_found()
    local got, expected, user_profile

    got = {auth.get_profile('not exists'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_set_user_not_found')
end

function test_delete_user_success()
    local user_profile, ok, user, code, expected, got, id
    ok, user = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', user.code, v.USER_PASSWORD)
    user_profile = {last_name='test_last', first_name='test_first' }

    ok, user = auth.delete_user(user['id'])
    id = user['id']
    user['id'] = nil
    expected = {email = 'test@test.ru', is_active = true}
    test:is(ok, true, 'test_delete_user_success user deleted')
    test:is_deeply(user, expected, 'test_delete_user_success profile returned')

    got = {auth.get_profile(id), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_delete_user_success user not found')
end

function test_delete_user_invalid_id()
    local got, expected, user_profile

    got = {auth.delete_user(''), }
    expected = {response.error(error.INVALID_PARAMS), }
    test:is_deeply(got, expected, 'test_delete_user_invalid_id')
end

function test_delete_user_user_not_found()
    local got, expected, user_profile

    got = {auth.delete_user('not exists'), }
    expected = {response.error(error.USER_NOT_FOUND), }
    test:is_deeply(got, expected, 'test_delete_user_user_not_found')
end

exports.tests = {
    test_set_profile_success,
    test_get_profile_success,
    test_delete_user_success,

    test_set_profile_invalid_id,
    test_set_profile_user_not_found,
    test_set_profile_user_not_active,
    test_get_profile_invalid_id,
    test_get_profile_user_not_found,
    test_delete_user_invalid_id,
    test_delete_user_user_not_found,
}

return exports
