local exports = {}
local tap = require('tap')
local response = require('auth.response')
local error = require('auth.error')
local db = require('auth.db')
local config = require('auth.test.config')

local test = tap.test('auth_test')
local ok, auth = require('auth.auth').api(config)
local user_space = require('auth.model.user').model(config).get_space()

function exports.setup() end

function exports.before() end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end


function test_set_profile_success()
    local user_profile, ok, user, code, expected
    ok, code = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', code, '123')
    user_profile = {last_name='test_last', first_name='test_first' }

    ok, user = auth.set_profile(user['id'], user_profile)

    user['id'] = nil
    expected = {email = 'test@test.ru', is_active = true, profile=user_profile}
    test:is(ok, true, 'test_set_profile_success user returned')
    test:is_deeply(user, expected, 'test_auth_success profile set')
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
    ok, code = auth.registration('test@test.ru')
    ok, user = auth.complete_registration('test@test.ru', code, '123')
    id = user['id']

    user_space:update(id, {{'=', 3, false}})
    user_profile = {last_name='test_last', first_name='test_first' }

    got = {auth.set_profile(id, user_profile), }
    expected = {response.error(error.USER_NOT_ACTIVE), }
    test:is_deeply(got, expected, 'test_set_profile_user_not_active')
end

exports.tests = {
    test_set_profile_success,

    test_set_profile_invalid_id,
    test_set_profile_user_not_found,
    test_set_profile_user_not_active
}

return exports
