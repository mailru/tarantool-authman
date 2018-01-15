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

local test = tap.test('application_test')

function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_add_application_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i, app_type in pairs(v.VALID_APPLICATION_TYPES) do
        
        local app_name = string.format("%s %d", v.APPLICATION_NAME, i)

        local ok, app = auth.add_application(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS)

        test:is(ok, true, string.format('test_add_application_success; application type: %s', app_type))
        test:isstring(app.consumer_key, 'test_registration_success oauth consumer key returned')
        test:is(app.consumer_key:len(), 32, 'test_registration_success oauth consumer key length')
        test:isstring(app.consumer_secret, 'test_registration_success oauth consumer secret returned')
        test:is(app.consumer_secret:len(), 64, 'test_registration_success oauth consumer secret length')
        test:is(app.redirect_urls, v.OAUTH_CONSUMER_REDIRECT_URLS, 'test_registration_success oauth consumer redirect urls returned')
        test:is(app.name, app_name, 'test_registration_success app name returned')
        test:is(app.type, app_type, 'test_registration_success app type returned')
        test:is(app.user_id, user.id, 'test_registration_success consumer app user_id returned')
        test:is(app.is_active, true, 'test_registration_success consumer app is_active returned')

        local got = {auth.get_application(app.id)}
        test:is(got[2].consumer_secret_hash, utils.salted_hash(app.consumer_secret, app.id), 'test_registration_success consumer secret hash returned')
        
    end 
end

function test_add_application_max_applications_reached()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i = 1, config.max_applications do
        
        local app_name = string.format("%s %d", v.APPLICATION_NAME, i)

        local ok, app = auth.add_application(user.id, app_name, v.VALID_APPLICATION_TYPES[i % 4 + 1], v.OAUTH_CONSUMER_REDIRECT_URLS)

        test:is(ok, true, string.format('test_add_application_max_applications_reached; added %d application', i))
    end 
        
    local got = {auth.add_application(user.id, v.APPLICATION_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.MAX_APPLICATIONS_REACHED)}

    test:is_deeply(got, expected, 'test_add_application_max_applications_reached')

end


function test_add_application_user_is_not_active()

    local _, user = auth.registration(v.USER_EMAIL)

    local got = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.USER_NOT_ACTIVE)}

    test:is_deeply(got, expected, 'test_add_application_user_is_not_activated')
end

function test_add_application_invalid_app_type()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.add_application(user.id, v.APPLICATION_NAME, 'invalid_app_type', v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_application_invalid_app_type')
end

function test_add_application_already_exists()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    local got = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.APPLICATION_ALREADY_EXISTS)}
    test:is_deeply(got, expected, 'test_add_application_already_exists')
end

function test_add_application_unknown_user()

    local got = {auth.add_application(uuid.str(), v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.USER_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_add_application_unknown_user')
end

function test_add_application_empty_app_name()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.add_application(user.id, '', v.VALID_APPLICATION_TYPES[2], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_application_empty_app_name')
end

function test_add_application_empty_redirect_urls()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local got = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[2], '')}
    local expected = {response.error(error.INVALID_PARAMS)}
    test:is_deeply(got, expected, 'test_add_application_empty_redirect_urls')
end

function test_get_application_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local got = {auth.get_application(expected[2].id)}

    expected[2].consumer_secret = nil

    test:isstring(got[2].consumer_secret_hash, 'test_get_application_success; consumer_secret_hash returned')
    got[2].consumer_secret_hash = nil

    test:is(got[2].application_id, expected[2].id, 'test_get_application_success; application_id returned')
    got[2].application_id = nil

    test:is_deeply(got, expected, 'test_get_application_success')
end

function test_get_application_unknown_application()

    local got = {auth.get_application(uuid.str())}
    local expected = {response.error(error.APPLICATION_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_application_unknown_application')
end

function test_get_application_empty_application_id()

    local got = {auth.get_application()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_application_empty_application_id')
end

function test_get_oauth_consumer_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}
    local got = {auth.get_oauth_consumer(expected[2].consumer_key)}

    expected[2].consumer_secret = nil

    test:isstring(got[2].consumer_secret_hash, 'test_get_oauth_consumer_success; consumer_secret_hash returned')
    got[2].consumer_secret_hash = nil

    test:is(got[2].application_id, expected[2].id, 'test_get_oauth_consumer_success; application_id returned')
    got[2].application_id = nil

    test:is_deeply(got, expected, 'test_get_oauth_consumer_success')
end

function test_get_oauth_consumer_unknown_oauth_consumer()

    local got = {auth.get_oauth_consumer(string.hex(uuid.bin()))}
    local expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_oauth_consumer_unknown_oauth_consumer')
end

function test_get_oauth_consumer_empty_consumer_key()

    local got = {auth.get_oauth_consumer()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_oauth_consumer_empty_consumer_key')
end

function test_get_user_applications_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected = {}
    for i, app_type in pairs(v.VALID_APPLICATION_TYPES) do
        
        local app_name = string.format("%s %d", v.APPLICATION_NAME, i)

        local ok, app = auth.add_application(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS)
        app.consumer_secret = nil
        expected[i] = app
    end 

    local got = {auth.get_user_applications(user.id)}

    test:is(got[1], true, 'test_get_user_applications_success; success response')

    for i, app in pairs(got[2]) do

        test:isstring(app.consumer_secret_hash, string.format('test_get_user_applications_success; app %d; consumer_secret_hash returned', i))
        app.consumer_secret_hash = nil

        test:is(app.application_id, expected[i].id, string.format('test_get_user_applications_success; app %d; application_id returned', i))
        app.application_id = nil

    end

    test:is_deeply(got[2], expected, 'test_get_user_applications_success')
end

function test_get_user_applications_empty_user_id()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    for i, app_type in pairs(v.VALID_APPLICATION_TYPES) do
        
        local app_name = string.format("%s %d", v.APPLICATION_NAME, i)

        local ok, app = auth.add_application(user.id, app_name, app_type, v.OAUTH_CONSUMER_REDIRECT_URLS)
    end 

    local got = {auth.get_user_applications()}

    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_user_applications_empty_user_id')
end

function test_delete_application_success()

    local expected, got

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    expected = {auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)}

    local app_id = expected[2].id
    local consumer_key = expected[2].consumer_key

    got = {auth.delete_application(app_id)}

    expected[2].consumer_secret = nil
    got[2].consumer_secret_hash = nil
    got[2].application_id = nil

    test:is_deeply(got, expected, 'test_delete_application_success; deleted')

    expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}
    got = {auth.get_oauth_consumer(consumer_key)}
    test:is_deeply(got, expected, 'test_delete_application_success; consumer not found')

    expected = {response.error(error.APPLICATION_NOT_FOUND)}
    got = {auth.get_application(app_id)}
    test:is_deeply(got, expected, 'test_delete_application_success; application not found')
end

function test_delete_application_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.delete_application("")}
    test:is_deeply(got, expected, 'test_delete_application_invalid_params')
end

function test_delete_application_not_found()
    local expected = {response.error(error.APPLICATION_NOT_FOUND)}
    local got = {auth.delete_application("not exists")}
    test:is_deeply(got, expected, 'test_delete_application_not_found')
end

function test_toggle_application_success()

    local got

    local _, user = auth.registration(v.USER_EMAIL)
    _, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local _, app = auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    got = {auth.disable_application(app.id)}
    test:is(got[2].is_active, false, 'test_toggle_application_success; disabled')

    got = {auth.enable_application(app.id)}
    test:is(got[2].is_active, true, 'test_toggle_application_success; enabled')
end

function test_disable_application_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.disable_application("")}
    test:is_deeply(got, expected, 'test_disable_application_invalid_params')
end

function test_disable_application_not_found()
    local expected = {response.error(error.APPLICATION_NOT_FOUND)}
    local got = {auth.disable_application("not exists")}
    test:is_deeply(got, expected, 'test_disable_application_not_found')
end

function test_enable_application_invalid_params()
    local expected = {response.error(error.INVALID_PARAMS)}
    local got = {auth.enable_application("")}
    test:is_deeply(got, expected, 'test_enable_application_invalid_params')
end

function test_enable_application_not_found()
    local expected = {response.error(error.APPLICATION_NOT_FOUND)}
    local got = {auth.enable_application("not exists")}
    test:is_deeply(got, expected, 'test_enable_application_not_found')
end

function test_delete_user()

    local expected, got

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local _, app = auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    auth.delete_user(user.id)

    expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}
    got = {auth.get_oauth_consumer(app.consumer_key)}
    test:is_deeply(got, expected, 'test_delete_user; consumer not found')

    expected = {response.error(error.APPLICATION_NOT_FOUND)}
    got = {auth.get_application(app.id)}
    test:is_deeply(got, expected, 'test_delete_user; application not found')
end

function test_reset_oauth_consumer_secret()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local expected, got

    local _, app = auth.add_application(user.id, v.APPLICATION_NAME, v.VALID_APPLICATION_TYPES[1], v.OAUTH_CONSUMER_REDIRECT_URLS)

    local got
    got = {auth.reset_oauth_consumer_secret(app.consumer_key)}
    test:is(got[1], true, 'test_reset_oauth_consumer_secret; ok')

    local new_secret = got[2]
    test:isstring(new_secret, 'test_reset_oauth_consumer_secret; consumer secret is string')
    test:is(new_secret:len(), 64, 'test_reset_oauth_consumer_secret; consumer secret length')

    got = {auth.get_application(app.id)}
    test:is(got[2].consumer_secret_hash, utils.salted_hash(new_secret, app.id), 'test_reset_oauth_consumer_secret; consumer secret hash')
end




exports.tests = {
    test_add_application_success,
    test_add_application_max_applications_reached,
    test_add_application_user_is_not_active,
    test_add_application_invalid_app_type,
    test_add_application_already_exists,
    test_add_application_unknown_user,
    test_add_application_empty_app_name,
    test_add_application_empty_redirect_urls,
    test_get_application_success,
    test_get_application_unknown_application,
    test_get_application_empty_application_id,
    test_get_oauth_consumer_success,
    test_get_oauth_consumer_unknown_oauth_consumer,
    test_get_oauth_consumer_empty_consumer_key,
    test_get_user_applications_success,
    test_get_user_applications_empty_user_id,
    test_delete_application_success,
    test_delete_application_invalid_params,
    test_delete_application_not_found,
    test_toggle_application_success,
    test_disable_application_invalid_params,
    test_disable_application_not_found,
    test_enable_application_invalid_params,
    test_enable_application_not_found,
    test_delete_user,
    test_reset_oauth_consumer_secret,
}


return exports
