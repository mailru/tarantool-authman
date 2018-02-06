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

local test = tap.test('oauth_redirect_test')


function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_save_redirect_success()

    local user_id = "user_id"
    local redirect_url = "http://test.ru/test1"
    local got, expected


    got = {auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, user_id, redirect_url)}
    expected = {true, {
        consumer_key = v.OAUTH_CONSUMER_KEY,
        user_id = user_id,
        url = redirect_url
    }}

    test:is_deeply(got, expected, 'test_save_redirect_success; url1')

    redirect_url = "http://test.ru/test2"

    got = {auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, user_id, redirect_url)}
    expected = {true, {
        consumer_key = v.OAUTH_CONSUMER_KEY,
        user_id = user_id,
        url = redirect_url
    }}

    test:is_deeply(got, expected, 'test_save_redirect_success; url2')
end

function test_save_redirect_invalid_params()

    local user_id = "user_id"
    local got, expected
    local redirect_url = "http://test.ru/test1"

    got = {auth.oauth.save_redirect(nil, user_id, redirect_url)}
    expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_save_redirect_invalid_params; nil consumer key')

    got = {auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, nil, redirect_url)}
    expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_save_redirect_invalid_params; nil user_id')

    got = {auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, user_id, nil)}
    expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_save_redirect_invalid_params; nil redirect url')
end

function test_get_user_redirects_success()

    local got, expected

    auth.oauth.save_redirect("consumer_key1", "user_id1", "http://test.ru/1")
    auth.oauth.save_redirect("consumer_key1", "user_id2", "http://test.ru/2")
    auth.oauth.save_redirect("consumer_key2", "user_id1", "http://test.ru/3")
    auth.oauth.save_redirect("consumer_key2", "user_id2", "http://test.ru/4")

    got = {auth.oauth.get_user_redirects("user_id1")}

    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id1", url = "http://test.ru/1"},
        {consumer_key = "consumer_key2", user_id = "user_id1", url = "http://test.ru/3"},
    }}

    test:is_deeply(got, expected, 'test_get_user_redirects_success; user_id1')

    got = {auth.oauth.get_user_redirects("user_id2")}
    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id2", url = "http://test.ru/2"},
        {consumer_key = "consumer_key2", user_id = "user_id2", url = "http://test.ru/4"},
    }}
    test:is_deeply(got, expected, 'test_get_user_redirects_success; user_id2')
end


function test_get_user_redirects_invalid_params()

    local redirect_url = "http://test.ru/test1"
    auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, "user_id1", redirect_url)

    local got = {auth.oauth.get_user_redirects()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_user_redirects_invalid_params')
end

function test_delete_user_redirects_success()
    local got, expected

    auth.oauth.save_redirect("consumer_key1", "user_id1", "http://test.ru/1")
    auth.oauth.save_redirect("consumer_key1", "user_id2", "http://test.ru/2")
    auth.oauth.save_redirect("consumer_key2", "user_id1", "http://test.ru/3")
    auth.oauth.save_redirect("consumer_key2", "user_id2", "http://test.ru/4")

    got = {auth.oauth.delete_user_redirects("user_id1", "consumer_key1")}
    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id1", url = "http://test.ru/1"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id1')

    got = {auth.oauth.delete_user_redirects("user_id1", "consumer_key2")}
    expected = {true, {
        {consumer_key = "consumer_key2", user_id = "user_id1", url = "http://test.ru/3"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id1')

    got = {auth.oauth.delete_user_redirects("user_id2", "consumer_key1")}
    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id2", url = "http://test.ru/2"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id2')

    got = {auth.oauth.delete_user_redirects("user_id2", "consumer_key2")}
    expected = {true, {
        {consumer_key = "consumer_key2", user_id = "user_id2", url = "http://test.ru/4"},
    }}
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id2')

    got = {auth.oauth.get_user_redirects("user_id1")}
    expected = {true, {}} 
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id1; deleted')

    got = {auth.oauth.get_user_redirects("user_id2")}
    expected = {true, {}}
    test:is_deeply(got, expected, 'test_delete_user_redirects_success; user_id2; deleted')

end

function test_delete_user_redirects_invalid_params()
    local got, expected

    auth.oauth.save_redirect("consumer_key1", "user_id1", "http://test.ru/1")

    got = {auth.oauth.delete_user_redirects()}
    local expected = {response.error(error.INVALID_PARAMS)}
end

function test_delete_app()

    local ok, got, expected

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app1 = auth.oauth.add_app(user.id, "Test app 1", 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    auth.oauth.save_redirect(app1.consumer_key, 'user_id2', v.OAUTH_CONSUMER_REDIRECT_URLS)

    local ok, app2 = auth.oauth.add_app(user.id, "Test app 2", 'browser', v.OAUTH_CONSUMER_REDIRECT_URLS)
    auth.oauth.save_redirect(app2.consumer_key, 'user_id2', v.OAUTH_CONSUMER_REDIRECT_URLS)

    auth.oauth.delete_app(app1.id)

    got = {auth.oauth.get_user_redirects("user_id2", app1.consumer_key)}
    expected = {ok, {
        {consumer_key = app2.consumer_key, user_id = "user_id2", url = v.OAUTH_CONSUMER_REDIRECT_URLS},
    }}
    test:is_deeply(got, expected, 'test_delete_app; app1 redirect urls deleted')
end

function test_get_consumer_redirects_success()

    local got, expected

    auth.oauth.save_redirect("consumer_key1", "user_id1", "http://test.ru/1")
    auth.oauth.save_redirect("consumer_key1", "user_id2", "http://test.ru/2")
    auth.oauth.save_redirect("consumer_key2", "user_id1", "http://test.ru/3")
    auth.oauth.save_redirect("consumer_key2", "user_id2", "http://test.ru/4")

    got = {auth.oauth.get_consumer_redirects("consumer_key1", "user_id1")}
    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id1", url = "http://test.ru/1"},
    }}

    test:is_deeply(got, expected, 'test_get_consumer_redirects_success; consumer_key1; user_id1')

    got = {auth.oauth.get_consumer_redirects("consumer_key1", "user_id2")}
    expected = {true, {
        {consumer_key = "consumer_key1", user_id = "user_id2", url = "http://test.ru/2"},
    }}

    test:is_deeply(got, expected, 'test_get_consumer_redirects_success; consumer_key1; user_id2')

    got = {auth.oauth.get_consumer_redirects("consumer_key2")}
    expected = {true, {
        {consumer_key = "consumer_key2", user_id = "user_id1", url = "http://test.ru/3"},
        {consumer_key = "consumer_key2", user_id = "user_id2", url = "http://test.ru/4"},
    }}
    test:is_deeply(got, expected, 'test_get_consumer_redirects_success; consumer_key2')
end

function test_get_consumer_redirects_invalid_params()

    auth.oauth.save_redirect(v.OAUTH_CONSUMER_KEY, "user_id1", v.OAUTH_CONSUMER_REDIRECT_URL)

    local got = {auth.oauth.get_consumer_redirects()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_consumer_redirects_invalid_params')
end



exports.tests = {
    test_save_redirect_success,
    test_save_redirect_invalid_params,
    test_get_user_redirects_success,
    test_get_user_redirects_invalid_params,
    test_delete_user_redirects_success,
    test_delete_user_redirects_invalid_params,
    test_delete_app,
    test_get_consumer_redirects_success,
    test_get_consumer_redirects_invalid_params,
}


return exports
