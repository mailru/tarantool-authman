local exports = {}
local tap = require('tap')
local fiber = require('fiber')
local response = require('auth.response')
local error = require('auth.error')
local validator = require('auth.validator')
local v = require('test.values')

-- model configuration
local config = validator.config(require('test.config'))
local db = require('auth.db').configurate(config)
local auth = require('auth').api(config)

local test = tap.test('auth_test')

function exports.setup() end

function exports.before() end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end


function test_social_auth_url_success()
    local ok, state, url

    state = 'somestate'
    ok, url = auth.social_auth_url('facebook', state)
    test:is(ok, true, 'test_social_auth_url_success fb ok')
    test:isstring(url, 'test_social_auth_url_success fb url')

    ok, url = auth.social_auth_url('vk')
    test:is(ok, true, 'test_social_auth_url_success vk ok')
    test:isstring(url, 'test_social_auth_url_success vk url')

    ok, url = auth.social_auth_url('google', state)
    test:is(ok, true, 'test_social_auth_url_success google ok')
    test:isstring(url, 'test_social_auth_url_success google url')
end

function test_social_auth_success()
    local ok, user,session, expected
    ok, user = auth.social_auth('vk', v.VALID_CODE)
    session = user['session']
    user['id'] = nil
    user['session'] = nil

    expected = {
        email = v.USER_EMAIL,
        is_active = true,
        social = {
            provider = 'vk',
            social_id = v.SOCIAL_ID
        },
        profile = {
            first_name = v.USER_FIRST_NAME,
            last_name = v.USER_LAST_NAME
        }
    }

    test:is(ok, true, 'test_social_auth_success user logged in')
    test:isstring(session, 'test_social_auth_success session returned')
    test:is_deeply(user, expected, 'test_social_auth_success user returned')
end

function test_social_auth_no_email_success()
    local ok, user,session, expected
    ok, user = auth.social_auth('vk', v.VALID_CODE_NO_EMAIL)
    session = user['session']
    user['id'] = nil
    user['session'] = nil

    expected = {
        email = '',
        is_active = true,
        social = {
            provider = 'vk',
            social_id = v.SOCIAL_ID
        },
        profile = {
            first_name = v.USER_FIRST_NAME,
            last_name = v.USER_LAST_NAME
        }
    }

    test:is(ok, true, 'test_social_auth_no_email_success user logged in')
    test:isstring(session, 'test_social_auth_no_email_success session returned')
    test:is_deeply(user, expected, 'test_social_auth_no_email_success user returned')
end

function test_social_auth_no_profile_success()
    local ok, user,session, expected
    ok, user = auth.social_auth('vk', v.VALID_CODE_NO_PROFILE)
    session = user['session']
    user['id'] = nil
    user['session'] = nil

    expected = {
        email = v.USER_EMAIL,
        is_active = true,
        social = {
            provider = 'vk',
            social_id = v.SOCIAL_ID
        },
        profile = {}
    }

    test:is(ok, true, 'test_social_auth_no_profile_success user logged in')
    test:isstring(session, 'test_social_auth_no_profile_success session returned')
    test:is_deeply(user, expected, 'test_social_auth_no_profile_success user returned')
end

function test_check_auth_social_success()
    local ok, user,session, expected
    ok, user = auth.social_auth('vk', v.VALID_CODE)
    session = user['session']

    ok, user = auth.check_auth(session)
    session = user['session']
    user['id'] = nil
    user['session'] = nil

    expected = {
        email = v.USER_EMAIL,
        is_active = true,
        social = {
            provider = 'vk',
            social_id = v.SOCIAL_ID
        },
        profile = {
            first_name = v.USER_FIRST_NAME,
            last_name = v.USER_LAST_NAME
        }
    }

    test:is(ok, true, 'test_check_auth_social_success user logged in')
    test:isstring(session, 'test_check_auth_social_success session returned')
    test:is_deeply(user, expected, 'test_check_auth_social_success user returned')
end

function test_drop_social_session_success()
    local ok, user,session, expected, deleted, got
    ok, user = auth.social_auth('vk', v.VALID_CODE)
    session = user['session']
    ok, deleted = auth.drop_session(session)
    test:is(ok, true, 'test_drop_session_success session droped')

    got = {auth.check_auth(session), }
    expected = {response.error(error.WRONG_SESSION_SIGN), }
    test:is_deeply(got, expected, 'test_drop_social_session_success wrong sign')
end

function test_check_auth_update_social_session_success()
    local ok, user, got, expected, first_session, second_session
    ok, user = auth.social_auth('vk', v.VALID_CODE)
    first_session = user['session']

    fiber.sleep(config.social_check_time)

    ok, user = auth.check_auth(first_session)
    test:is(ok, true, 'test_check_auth_update_social_session_success session updated')

    second_session = user['session']
    test:isstring(second_session, 'test_check_auth_update_social_session_success session returned')
    test:isnt(first_session, second_session, 'test_check_auth_update_social_session_success new session')
end

function test_check_auth_expired_social_session()
    local ok, user, got, expected, session
    ok, user = auth.social_auth('vk', v.VALID_CODE)
    session = user['session']

    fiber.sleep(config.session_lifetime)

    got = {auth.check_auth(session), }
    expected = {response.error(error.NOT_AUTHENTICATED), }
    test:is_deeply(got, expected, 'test_check_auth_expired_social_session')
end


function test_social_auth_url_invalid_provider()
    local got, expected

    got = {auth.social_auth_url('invalid'), }
    expected = {response.error(error.WRONG_PROVIDER) }
    test:is_deeply(got, expected, 'test_social_auth_url_invalid_provider')
end

function test_social_auth_invalid_provider()
    local got, expected

    got = {auth.social_auth('invalid', 'some code'), }
    expected = {response.error(error.WRONG_PROVIDER) }
    test:is_deeply(got, expected, 'test_social_auth_url_invalid_provider')
end

function test_social_auth_invalid_code()
    local got, expected

    got = {auth.social_auth('vk', 'invalid code'), }
    expected = {response.error(error.WRONG_AUTH_CODE) }
    test:is_deeply(got, expected, 'test_social_auth_invalid_code')
end

function test_social_auth_invalid_auth()
    local got, expected

    got = {auth.social_auth('vk', v.INVALID_CODE_TOKEN), }
    expected = {response.error(error.SOCIAL_AUTH_ERROR) }
    test:is_deeply(got, expected, 'test_social_auth_invalid_auth')
end


exports.tests = {
    test_social_auth_url_success,
    test_social_auth_success,
    test_social_auth_no_email_success,
    test_social_auth_no_profile_success,
    test_drop_social_session_success,
    test_check_auth_social_success,
    test_check_auth_update_social_session_success,

    test_check_auth_expired_social_session,
    test_social_auth_url_invalid_provider,
    test_social_auth_invalid_provider,
    test_social_auth_invalid_code,
    test_social_auth_invalid_auth,
}

return exports