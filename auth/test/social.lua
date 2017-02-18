local exports = {}
local tap = require('tap')
local response = require('auth.response')
local error = require('auth.error')
local db = require('auth.db')
local config = require('auth.test.config')

local test = tap.test('auth_test')
local ok, auth = require('auth.auth').api(config)

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

    got = {auth.social_auth('facebook', 'invalid code'), }
    expected = {response.error(error.WRONG_AUTH_CODE) }
    test:is_deeply(got, expected, 'test_social_auth_invalid_code')
end


exports.tests = {
    test_social_auth_url_success,

    test_social_auth_url_invalid_provider,
    test_social_auth_invalid_provider,
    test_social_auth_invalid_code,
}

return exports