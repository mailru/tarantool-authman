local exports = {}
local tap = require('tap')
local response = require('authman.response')
local error = require('authman.error')
local validator = require('authman.validator')
local v = require('test.values')
local uuid = require('uuid')
local utils = require('authman.utils.utils')

-- model configuration
local config = validator.config(require('test.config'))
local db = require('authman.db').configurate(config)
local auth = require('authman').api(config)

local test = tap.test('oauth_app_test')

function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_add_app_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i, app_type in pairs(v.OAUTH_VALID_APP_TYPES) do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)
        local app_is_trusted = i%2 and true or false

        local ok, app = auth.oauth.add_app(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS, app_is_trusted)

        test:is(ok, true, string.format('test_add_app_success; app type: %s', app_type))
        test:isstring(app.consumer_key, 'test_registration_success oauth consumer key returned')
        test:is(app.consumer_key:len(), 32, 'test_registration_success oauth consumer key length')
        test:isstring(app.consumer_secret, 'test_registration_success oauth consumer secret returned')
        test:is(app.consumer_secret:len(), 64, 'test_registration_success oauth consumer secret length')
        test:is(app.redirect_urls, v.OAUTH_CONSUMER_REDIRECT_URLS, 'test_registration_success oauth consumer redirect urls returned')
        test:is(app.name, app_name, 'test_registration_success app name returned')
        test:is(app.type, app_type, 'test_registration_success app type returned')
        test:is(app.user_id, user.id, 'test_registration_success consumer app user_id returned')
        test:is(app.is_active, true, 'test_registration_success consumer app is_active returned')
        test:is(app.is_trusted, app_is_trusted, 'test_registration_success consumer app is_trusted returned')

        local got = {auth.oauth.get_app(app.id)}
        test:is(got[2].consumer_secret_hash, utils.salted_hash(app.consumer_secret, app.id), 'test_registration_success consumer secret hash returned')

    end
end

function test_add_app_max_apps_reached()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i = 1, config.oauth_max_apps do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)

        local ok, app = auth.oauth.add_app(user.id, app_name, v.OAUTH_VALID_APP_TYPES[i % 4 + 1], v.OAUTH_CONSUMER_REDIRECT_URLS)

        test:is(ok, true, string.format('test_add_app_max_apps_reached; added %d application', i))
    end

    local got = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.OAUTH_MAX_APPS_REACHED)}

    test:is_deeply(got, expected, 'test_add_app_max_apps_reached')

end


function test_add_app_user_is_not_active()

    local _, user = auth.registration(v.USER_EMAIL)

    local got = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.USER_NOT_ACTIVE)}

    test:is_deeply(got, expected, 'test_add_app_user_is_not_activated')
end

function test_add_app_invalid_app_type()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'invalid_app_type', v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_app_invalid_app_type')
end

function test_add_app_already_exists()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    local got = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.OAUTH_APP_ALREADY_EXISTS)}
    test:is_deeply(got, expected, 'test_add_app_already_exists')
end

function test_add_app_unknown_user()

    local got = {auth.oauth.add_app(uuid.str(), v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.USER_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_add_app_unknown_user')
end

function test_add_app_empty_app_name()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.oauth.add_app(user.id, '', v.OAUTH_VALID_APP_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_app_empty_app_name')
end

function test_add_app_empty_redirect_urls()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[2], '')}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_app_empty_redirect_urls')
end

function test_get_app_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local got = {auth.oauth.get_app(expected[2].id)}

    expected[2].consumer_secret = nil

    test:isstring(got[2].consumer_secret_hash, 'test_get_app_success; consumer_secret_hash returned')
    got[2].consumer_secret_hash = nil

    test:is(got[2].app_id, expected[2].id, 'test_get_app_success; app_id returned')
    got[2].app_id = nil

    test:is_deeply(got, expected, 'test_get_app_success')
end

function test_get_app_unknown_app()

    local got = {auth.oauth.get_app(uuid.str())}
    local expected = {response.error(error.OAUTH_APP_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_app_unknown_app')
end

function test_get_app_empty_app_id()

    local got = {auth.oauth.get_app()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_app_empty_app_id')
end

function test_get_consumer_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local got = {auth.oauth.get_consumer(expected[2].consumer_key)}

    expected[2].consumer_secret = nil

    test:isstring(got[2].consumer_secret_hash, 'test_get_consumer_success; consumer_secret_hash returned')
    got[2].consumer_secret_hash = nil

    test:is(got[2].app_id, expected[2].id, 'test_get_consumer_success; app_id returned')
    got[2].app_id = nil

    test:is_deeply(got, expected, 'test_get_consumer_success')
end

function test_get_consumer_unknown_consumer()

    local got = {auth.oauth.get_consumer(string.hex(uuid.bin()))}
    local expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_consumer_unknown_consumer')
end

function test_get_consumer_empty_consumer_key()

    local got = {auth.oauth.get_consumer()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_consumer_empty_consumer_key')
end

function test_get_user_apps_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {}
    for i, app_type in pairs(v.OAUTH_VALID_APP_TYPES) do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)

        local ok, app = auth.oauth.add_app(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS)
        app.consumer_secret = nil
        expected[i] = app
    end

    local got = {auth.oauth.get_user_apps(user.id)}

    test:is(got[1], true, 'test_get_user_apps_success; success response')

    for i, app in pairs(got[2]) do

        test:isstring(app.consumer_secret_hash, string.format('test_get_user_apps_success; app %d; consumer_secret_hash returned', i))
        app.consumer_secret_hash = nil

        test:is(app.app_id, expected[i].id, string.format('test_get_user_apps_success; app %d; app_id returned', i))
        app.app_id = nil

    end

    test:is_deeply(got[2], expected, 'test_get_user_apps_success')
end

function test_get_user_apps_empty_user_id()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i, app_type in pairs(v.OAUTH_VALID_APP_TYPES) do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)

        local ok, app = auth.oauth.add_app(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS)
    end

    local got = {auth.oauth.get_user_apps()}

    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_user_apps_empty_user_id')
end

function test_delete_app_success()

    local expected, got

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    expected = {auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}

    local app_id = expected[2].id
    local consumer_key = expected[2].consumer_key

    got = {auth.oauth.delete_app(app_id)}

    expected[2].consumer_secret = nil
    got[2].consumer_secret_hash = nil
    got[2].app_id = nil

    test:is_deeply(got, expected, 'test_delete_app_success; deleted')

    expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}
    got = {auth.oauth.get_consumer(consumer_key)}
    test:is_deeply(got, expected, 'test_delete_app_success; consumer not found')

    expected = {response.error(error.OAUTH_APP_NOT_FOUND)}
    got = {auth.oauth.get_app(app_id)}
    test:is_deeply(got, expected, 'test_delete_app_success; application not found')
end

function test_delete_app_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.oauth.delete_app("")}
    test:is_deeply(got, expected, 'test_delete_app_invalid_params')
end

function test_delete_app_not_found()
    local expected = {response.error(error.OAUTH_APP_NOT_FOUND)}
    local got = {auth.oauth.delete_app("not exists")}
    test:is_deeply(got, expected, 'test_delete_app_not_found')
end

function test_toggle_app_success()

    local got

    local _, user = auth.registration(v.USER_EMAIL)
    _, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local _, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    got = {auth.oauth.disable_app(app.id)}
    test:is(got[2].is_active, false, 'test_toggle_app_success; disabled')

    got = {auth.oauth.enable_app(app.id)}
    test:is(got[2].is_active, true, 'test_toggle_app_success; enabled')
end

function test_disable_app_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.oauth.disable_app("")}
    test:is_deeply(got, expected, 'test_disable_app_invalid_params')
end

function test_disable_app_not_found()
    local expected = {response.error(error.OAUTH_APP_NOT_FOUND)}
    local got = {auth.oauth.disable_app("not exists")}
    test:is_deeply(got, expected, 'test_disable_app_not_found')
end

function test_enable_app_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.oauth.enable_app("")}
    test:is_deeply(got, expected, 'test_enable_app_invalid_params')
end

function test_enable_app_not_found()
    local expected = {response.error(error.OAUTH_APP_NOT_FOUND)}
    local got = {auth.oauth.enable_app("not exists")}
    test:is_deeply(got, expected, 'test_enable_app_not_found')
end

function test_delete_user()

    local expected, got

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local _, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    auth.delete_user(user.id)

    expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}
    got = {auth.oauth.get_consumer(app.consumer_key)}
    test:is_deeply(got, expected, 'test_delete_user; consumer not found')

    expected = {response.error(error.OAUTH_APP_NOT_FOUND)}
    got = {auth.oauth.get_app(app.id)}
    test:is_deeply(got, expected, 'test_delete_user; application not found')
end

function test_reset_consumer_secret()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected, got

    local _, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, v.OAUTH_VALID_APP_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)
    local old_secret = app.consumer_secret

    local got
    got = {auth.oauth.reset_consumer_secret(app.consumer_key)}
    test:is(got[1], true, 'test_reset_consumer_secret; ok')

    local new_secret = got[2]
    test:isstring(new_secret, 'test_reset_consumer_secret; consumer secret is string')
    test:is(new_secret:len(), 64, 'test_reset_consumer_secret; consumer secret length')
    test:is(old_secret ~= new_secret, true, 'test_reset_consumer_secret; consumer secret was changed')

    got = {auth.oauth.get_app(app.id)}
    test:is(got[2].consumer_secret_hash, utils.salted_hash(new_secret, app.id), 'test_reset_consumer_secret; consumer secret hash')
end

function test_list_apps()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local added_apps = {}
    local i = 1
    while i <= 10 do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)
        local ok, app = auth.oauth.add_app(user.id, app_name, 'browser', v.OAUTH_CONSUMER_REDIRECT_URLS)
        app.consumer_secret = nil
        added_apps[app.id] = app
        i = i + 1
    end

    local tt = {
        {offset = 0, limit = 1},
        {offset = 1, limit = 2},
        {offset = 3, limit = 5},
        {offset = 9, limit = 1},
    }

    for _, tc in ipairs(tt) do
        local got = {auth.oauth.list_apps(tc.offset, tc.limit)}
        test:is_deeply(got[1], true, string.format("offset %d; limit %d; result is true", tc.offset, tc.limit))

        for i, app in ipairs(got[2].data) do
            app.app_id = nil
            app.consumer_secret_hash = nil
            test:is_deeply(added_apps[app.id], app, string.format("offset %d; limit %d; %d app is ok", tc.offset, tc.limit, i))
            added_apps[app.id] = nil
        end
        test:is_deeply(got[2].pager, {offset = tc.offset, limit =  tc.limit, total = 10}, string.format("offset %d, limit %d; pager is ok", tc.offset, tc.limit))
    end
end

function test_list_apps_invalid_offset_and_limit()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local added_apps = {}
    local i = 1
    while i <= 10 do

        local app_name = string.format("%s %d", v.OAUTH_APP_NAME, i)
        local ok, app = auth.oauth.add_app(user.id, app_name, 'browser', v.OAUTH_CONSUMER_REDIRECT_URLS)
        app.consumer_secret = nil
        added_apps[app.id] = app
        i = i + 1
    end

    local offset, limit = -1, -2

    local got = {auth.oauth.list_apps(offset, limit)}
    for i, app in ipairs(got[2].data) do
        app.app_id = nil
        app.consumer_secret_hash = nil
        test:is_deeply(added_apps[app.id], app, string.format("%d app returned", i))
        added_apps[app.id] = nil
    end
    test:is_deeply(got[2].pager, {offset = 0, limit =  10, total = 10}, string.format("offset %d, limit %d; pager is ok", offset, limit))
end



exports.tests = {
    test_add_app_success,
    test_add_app_max_apps_reached,
    test_add_app_user_is_not_active,
    test_add_app_invalid_app_type,
    test_add_app_already_exists,
    test_add_app_unknown_user,
    test_add_app_empty_app_name,
    test_add_app_empty_redirect_urls,
    test_get_app_success,
    test_get_app_unknown_app,
    test_get_app_empty_app_id,
    test_get_consumer_success,
    test_get_consumer_unknown_consumer,
    test_get_consumer_empty_consumer_key,
    test_get_user_apps_success,
    test_get_user_apps_empty_user_id,
    test_delete_app_success,
    test_delete_app_invalid_params,
    test_delete_app_not_found,
    test_toggle_app_success,
    test_disable_app_invalid_params,
    test_disable_app_not_found,
    test_enable_app_invalid_params,
    test_enable_app_not_found,
    test_delete_user,
    test_reset_consumer_secret,
    test_list_apps,
    test_list_apps_invalid_offset_and_limit
}


return exports
