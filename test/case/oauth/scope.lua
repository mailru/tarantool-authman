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
local utils = require('authman.utils.utils')

local test = tap.test('oauth_scope_test')


function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_add_consumer_scopes_success()

    local user_id = "user_id"
    local scopes, got, expected

    scopes = {"scope1", "scope2", "scope3"}

    got = {auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, user_id, scopes)}
    expected = {true, {
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
    }}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_success; added 3 scopes')

    scopes = {"scope3", "scope4", "scope5"}

    got = {auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, user_id, scopes)}
    expected = {true, {
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope4"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope5"},
    }}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_success; added 2 of 3 scopes')

    scopes = {"scope3", "scope4"}

    got = {auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, user_id, scopes)}
    expected = {true, {
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope4"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope5"},
    }}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_success; added 0 scopes')

    got = {auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, user_id, {})}
    expected = {true, {
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope4"},
        {user_id = user_id, consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope5"},
    }}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_success; added 0 scopes')
end

function test_add_consumer_scopes_invalid_params()

    local user_id = "user_id"
    local got, expected

    local scopes = {"scope1", "scope2", "scope3"}

    got = {auth.oauth.add_consumer_scopes(nil, user_id, scopes)}
    expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_invalid_params; nil consumer key')

    got = {auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, nil, scopes)}
    expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_add_consumer_scopes_invalid_params; nil user_id')
end

function test_get_user_authorizations_success()

    local scopes, got, expected

    scopes = {"scope1", "scope2", "scope3"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id1", scopes)

    scopes = {"scope4", "scope5", "scope6"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id2", scopes)

    got = {auth.oauth.get_user_authorizations("user_id1")}
    expected = {true, {
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
    }}
    test:is_deeply(got, expected, 'test_get_user_authorizations_success; user_id1')

    got = {auth.oauth.get_user_authorizations("user_id2")}
    expected = {true, {
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope4"},
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope5"},
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope6"},
    }}
    test:is_deeply(got, expected, 'test_get_user_authorizations_success; user_id2')
end


function test_get_user_authorizations_invalid_params()

    local scopes = {"scope1", "scope2", "scope3"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id1", scopes)

    local got = {auth.oauth.get_user_authorizations()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_user_authorizations_invalid_params')
end

function test_delete_user_authorizations_success()

    local scopes, got, expected

    scopes = {"scope1", "scope2", "scope3"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id1", scopes)

    scopes = {"scope4", "scope5", "scope6"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id2", scopes)

    got = {auth.oauth.delete_user_authorizations("user_id1", v.OAUTH_CONSUMER_KEY)}
    expected = {true, {
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope1"},
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope2"},
        {user_id = "user_id1", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope3"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_authorizations_success; user_id1')

    got = {auth.oauth.delete_user_authorizations("user_id2", v.OAUTH_CONSUMER_KEY)}
    expected = {true, {
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope4"},
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope5"},
        {user_id = "user_id2", consumer_key = v.OAUTH_CONSUMER_KEY, name = "scope6"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_authorizations_success; user_id2')
end

function test_delete_app()

    local ok, got, expected

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app1 = auth.oauth.add_app(user.id, "Test app 1", 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    auth.oauth.add_consumer_scopes(app1.consumer_key, v.OAUTH_RESOURCE_OWNER, {v.OAUTH_SCOPE})

    local ok, app2 = auth.oauth.add_app(user.id, "Test app 2", 'browser', v.OAUTH_CONSUMER_REDIRECT_URLS)
    auth.oauth.add_consumer_scopes(app2.consumer_key, v.OAUTH_RESOURCE_OWNER, {v.OAUTH_SCOPE})

    auth.oauth.delete_app(app1.id)

    got = {auth.oauth.get_user_authorizations(v.OAUTH_RESOURCE_OWNER, app1.consumer_key)}
    expected = {ok, {}}
    test:is_deeply(got, expected, 'test_delete_app; app1 authorization is deleted')

    got = {auth.oauth.get_user_authorizations(v.OAUTH_RESOURCE_OWNER, app2.consumer_key)}
    expected = {ok, {
        {user_id = v.OAUTH_RESOURCE_OWNER, consumer_key = app2.consumer_key, name = v.OAUTH_SCOPE},
    }}
    test:is_deeply(got, expected, 'test_delete_app; app2 authorization is not deleted')
end

function test_get_consumer_authorizations_success()

    local scopes, got, expected

    scopes = {"scope1", "scope2", "scope3"}

    auth.oauth.add_consumer_scopes("consumer_key1", "user_id", scopes)

    scopes = {"scope4", "scope5", "scope6"}

    auth.oauth.add_consumer_scopes("consumer_key2", "user_id", scopes)

    got = {auth.oauth.get_consumer_authorizations("consumer_key1")}
    expected = {true, {
        {user_id = "user_id", consumer_key = "consumer_key1", name = "scope1"},
        {user_id = "user_id", consumer_key = "consumer_key1", name = "scope2"},
        {user_id = "user_id", consumer_key = "consumer_key1", name = "scope3"},
    }}
    test:is_deeply(got, expected, 'test_get_consumer_authorizations_success; consumer_key1')

    got = {auth.oauth.get_consumer_authorizations("consumer_key2")}
    expected = {true, {
        {user_id = "user_id", consumer_key = "consumer_key2", name = "scope4"},
        {user_id = "user_id", consumer_key = "consumer_key2", name = "scope5"},
        {user_id = "user_id", consumer_key = "consumer_key2", name = "scope6"},
    }}
    test:is_deeply(got, expected, 'test_get_consumer_authorizations_success; consumer_key2')
end

function test_get_consumer_authorizations_invalid_params()

    local scopes = {"scope1", "scope2", "scope3"}

    auth.oauth.add_consumer_scopes(v.OAUTH_CONSUMER_KEY, "user_id1", scopes)

    local got = {auth.oauth.get_consumer_authorizations()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_consumer_authorizations_invalid_params')
end



exports.tests = {
    test_add_consumer_scopes_success,
    test_add_consumer_scopes_invalid_params,
    test_get_user_authorizations_success,
    test_get_user_authorizations_invalid_params,
    test_delete_user_authorizations_success,
    test_delete_app,
    test_get_consumer_authorizations_success,
    test_get_consumer_authorizations_invalid_params,
}


return exports
