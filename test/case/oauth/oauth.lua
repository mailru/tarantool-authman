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
local oauth_code = require('authman.model.oauth.code').model(config)
local oauth_token = require('authman.model.oauth.token').model(config)
local utils = require('authman.utils.utils')

local test = tap.test('oauth_test')

local oauth_code_tuple = {
    v.OAUTH_CODE,
    v.OAUTH_CONSUMER_KEY,
    v.OAUTH_CONSUMER_REDIRECT_URL,
    v.OAUTH_SCOPE,
    v.OAUTH_STATE,
    v.OAUTH_EXPIRES_IN,
    v.OAUTH_CREATED_AT,
    v.OAUTH_CODE_CHALLENGE,
    v.OAUTH_CODE_CHALLENGE_METHOD,
    v.OAUTH_RESOURCE_OWNER,
}

local oauth_token_tuple = {
    v.OAUTH_ACCESS_TOKEN,
    v.OAUTH_CONSUMER_KEY,
    v.OAUTH_REFRESH_TOKEN,
    v.OAUTH_CONSUMER_REDIRECT_URL,
    v.OAUTH_SCOPE,
    v.OAUTH_EXPIRES_IN,
    v.OAUTH_CREATED_AT,
    v.OAUTH_RESOURCE_OWNER,
}


function exports.setup() end

function exports.before()
    db.truncate_spaces()
end

function exports.after() end

function exports.teardown() end

function test_save_code_success()

    local got = {auth.oauth.save_code(unpack(oauth_code_tuple))}

    local expected = {true, {
        code = v.OAUTH_CODE,
        consumer_key = v.OAUTH_CONSUMER_KEY,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        state = v.OAUTH_STATE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        code_challenge = v.OAUTH_CODE_CHALLENGE,
        code_challenge_method = v.OAUTH_CODE_CHALLENGE_METHOD,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_save_code_success')
end

function test_save_code_invalid_params()

    for _, f in pairs({oauth_code.CODE, oauth_code.CONSUMER_KEY, oauth_code.REDIRECT_URL, 
                            oauth_code.SCOPE, oauth_code.EXPIRES_IN, oauth_code.CREATED_AT}) do

        local t = { unpack(oauth_code_tuple) }
    
        t[f] = nil
    
        local got = {auth.oauth.save_code(unpack(t))}
        local expected = {response.error(error.INVALID_PARAMS)}
        test:is_deeply(got, expected, string.format('test_save_code_invalid_params; field %d', f))
    end
end

function test_get_code_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    local ok, consumer = auth.oauth.get_consumer(app.consumer_key)

    local t = { unpack(oauth_code_tuple) }
    t[oauth_code.CONSUMER_KEY] = app.consumer_key

    local ok, code = auth.oauth.save_code(unpack(t))

    local got = {auth.oauth.get_code(oauth_code_tuple[oauth_code.CODE])}

    local expected = {true, {
        code = v.OAUTH_CODE,
        consumer_key = app.consumer_key, 
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        state = v.OAUTH_STATE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        code_challenge = v.OAUTH_CODE_CHALLENGE,
        code_challenge_method = v.OAUTH_CODE_CHALLENGE_METHOD,
        consumer = consumer,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_get_code_success')
end

function test_get_code_x_consumer_not_found()

    local ok, code = auth.oauth.save_code(unpack(oauth_code_tuple))

    local got = {auth.oauth.get_code(oauth_code_tuple[oauth_code.CODE])}
    local expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_code_x_consumer_not_found')
end


function test_get_code_invalid_params()

    local ok, code = auth.oauth.save_code(unpack(oauth_code_tuple))

    local got = {auth.oauth.get_code()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_code_invalid_params')
end

function test_get_code_not_found()

    local got = {auth.oauth.get_code(v.OAUTH_CODE)}
    local expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_code_not_found')
end

function test_delete_code_success()

    local ok, code = auth.oauth.save_code(unpack(oauth_code_tuple))

    local got = {auth.oauth.delete_code(oauth_code_tuple[oauth_code.CODE])}

    local expected = {true, {
        code = v.OAUTH_CODE,
        consumer_key = v.OAUTH_CONSUMER_KEY,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        state = v.OAUTH_STATE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        code_challenge = v.OAUTH_CODE_CHALLENGE,
        code_challenge_method = v.OAUTH_CODE_CHALLENGE_METHOD,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_delete_code_success; deleted')

    got = {auth.oauth.get_code(oauth_code_tuple[oauth_code.CODE])}
    expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_code_success; not found')
end

function test_delete_code_invalid_params()

    local ok, code = auth.oauth.save_code(unpack(oauth_code_tuple))

    local got = {auth.oauth.delete_code()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_delete_code_invalid_params')
end

function test_delete_code_not_found()

    local got = {auth.oauth.delete_code(v.OAUTH_CODE)}
    local expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_code_not_found')
end

function test_save_access_success()

    local got = {auth.oauth.save_access(unpack(oauth_token_tuple))}

    local expected = {true, {
        access_token = v.OAUTH_ACCESS_TOKEN,
        consumer_key = v.OAUTH_CONSUMER_KEY,
        refresh_token = v.OAUTH_REFRESH_TOKEN,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_save_token_success')
end

function test_save_access_invalid_params()

    for _, f in pairs({oauth_token.ACCESS_TOKEN, oauth_token.CONSUMER_KEY,
                        oauth_token.REFRESH_TOKEN, oauth_token.REDIRECT_URL, oauth_token.SCOPE}) do

        local t = { unpack(oauth_token_tuple) }
    
        t[f] = nil
    
        local got = {auth.oauth.save_access(unpack(t))}
        local expected = {response.error(error.INVALID_PARAMS)}
        test:is_deeply(got, expected, string.format('test_save_access_invalid_params; field %d', f))
    end
end

function test_get_access_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    local ok, consumer = auth.oauth.get_consumer(app.consumer_key)

    local t = { unpack(oauth_token_tuple) }
    t[oauth_token.CONSUMER_KEY] = app.consumer_key

    local ok, token = auth.oauth.save_access(unpack(t))

    local got = {auth.oauth.get_access(oauth_token_tuple[oauth_token.ACCESS_TOKEN])}
    local expected = {true, {
        access_token = v.OAUTH_ACCESS_TOKEN,
        consumer_key = app.consumer_key, 
        refresh_token = v.OAUTH_REFRESH_TOKEN,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        consumer = consumer,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_get_access_success')
end

function test_get_access_x_consumer_not_found()

    local ok, code = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.get_access(oauth_token_tuple[oauth_token.ACCESS_TOKEN])}
    local expected = {response.error(error.OAUTH_CONSUMER_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_access_x_consumer_not_found')
end

function test_get_access_not_found()

    local got = {auth.oauth.get_access(v.OAUTH_ACCESS_TOKEN)}
    local expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_get_access_not_found')
end

function test_get_access_invalid_params()

    local ok, code = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.get_access()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_get_access_invalid_params')
end

function test_delete_access_success()

    local ok, access = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.delete_access(oauth_token_tuple[oauth_token.ACCESS_TOKEN])}

    local expected = {true, {
        access_token = v.OAUTH_ACCESS_TOKEN,
        consumer_key = v.OAUTH_CONSUMER_KEY,
        refresh_token = v.OAUTH_REFRESH_TOKEN,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_delete_access_success; deleted')

    got = {auth.oauth.get_access(oauth_token_tuple[oauth_token.ACCESS_TOKEN])}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_access_success; not found')
end

function test_delete_access_not_found()

    local got = {auth.oauth.delete_access(v.OAUTH_ACCESS_TOKEN)}
    local expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_access_not_found')
end

function test_delete_access_invalid_params()

    local ok, code = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.delete_access()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_delete_access_invalid_params')
end


function test_get_refresh_success()

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    local ok, consumer = auth.oauth.get_consumer(app.consumer_key)

    local t = { unpack(oauth_token_tuple) }
    t[oauth_token.CONSUMER_KEY] = app.consumer_key

    local ok, token = auth.oauth.save_access(unpack(t))

    local got = {auth.oauth.get_refresh(oauth_token_tuple[oauth_token.REFRESH_TOKEN])}
    local expected = {true, {
        access_token = v.OAUTH_ACCESS_TOKEN,
        consumer_key = app.consumer_key, 
        refresh_token = v.OAUTH_REFRESH_TOKEN,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        consumer = consumer,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_get_refresh_success')
end

function test_delete_refresh_success()

    local ok, access = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.delete_refresh(oauth_token_tuple[oauth_token.REFRESH_TOKEN])}

    local expected = {true, {
        access_token = v.OAUTH_ACCESS_TOKEN,
        consumer_key = v.OAUTH_CONSUMER_KEY,
        refresh_token = v.OAUTH_REFRESH_TOKEN,
        redirect_url = v.OAUTH_CONSUMER_REDIRECT_URL,
        scope = v.OAUTH_SCOPE,
        expires_in = v.OAUTH_EXPIRES_IN,
        created_at = v.OAUTH_CREATED_AT,
        resource_owner = v.OAUTH_RESOURCE_OWNER,
    }}

    test:is_deeply(got, expected, 'test_delete_refresh_success; deleted')

    got = {auth.oauth.get_refresh(oauth_token_tuple[oauth_token.REFRESH_TOKEN])}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_refresh_success; not found')
end

function test_delete_refresh_not_found()

    local got = {auth.oauth.delete_refresh(v.OAUTH_REFRESH_TOKEN)}
    local expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}

    test:is_deeply(got, expected, 'test_delete_refresh_not_found')
end

function test_delete_refresh_invalid_params()

    local ok, code = auth.oauth.save_access(unpack(oauth_token_tuple))

    local got = {auth.oauth.delete_refresh()}
    local expected = {response.error(error.INVALID_PARAMS)}

    test:is_deeply(got, expected, 'test_delete_refresh_invalid_params')
end

function test_delete_user()

    local got, expected

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    local ok, consumer = auth.oauth.get_consumer(app.consumer_key)

    local c = { unpack(oauth_code_tuple) }
    c[oauth_code.CONSUMER_KEY] = app.consumer_key
    auth.oauth.save_code(unpack(c))

    local t = { unpack(oauth_token_tuple) }
    t[oauth_token.CONSUMER_KEY] = app.consumer_key
    auth.oauth.save_access(unpack(t))

    auth.delete_user(user.id)

    got = {auth.oauth.get_code(c[oauth_code.CODE])}
    expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_user; oauth code deleted')

    got = {auth.oauth.get_access(t[oauth_token.ACCESS_TOKEN])}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_user; oauth token deleted')
end


function test_delete_app()

    local got, expected

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)
    local ok, consumer = auth.oauth.get_consumer(app.consumer_key)

    local c = { unpack(oauth_code_tuple) }
    c[oauth_code.CONSUMER_KEY] = app.consumer_key
    auth.oauth.save_code(unpack(c))

    local t = { unpack(oauth_token_tuple) }
    t[oauth_token.CONSUMER_KEY] = app.consumer_key
    auth.oauth.save_access(unpack(t))

    auth.oauth.delete_app(app.id)

    got = {auth.oauth.get_code(c[oauth_code.CODE])}
    expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_app; oauth code deleted')

    got = {auth.oauth.get_access(t[oauth_token.ACCESS_TOKEN])}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_app; oauth token deleted')
end

function test_delete_expired_codes()

    local current_ts = utils.now()
    local expires_in = 10
    local codes = {}

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)

    for i, created_at in ipairs{ current_ts - 11, current_ts - 10, current_ts - 9} do

        local t = { unpack(oauth_code_tuple) }
        t[oauth_code.CODE] = string.format("%s%d", t[oauth_code.CODE], i)
        t[oauth_code.CONSUMER_KEY] = app.consumer_key
        t[oauth_code.CREATED_AT] = created_at
        t[oauth_code.EXPIRES_IN] = expires_in

        local ok, code = auth.oauth.save_code(unpack(t))
        table.insert(codes, code)
    end

    local got, expected
    got = {auth.oauth.delete_expired_codes(current_ts)}
    expected = {true, 2}

    test:is_deeply(got, expected, 'test_delete_expired_codes; deleted')

    got = {auth.oauth.get_code(codes[1].code)}
    expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_expired_codes; code 1 not found')

    got = {auth.oauth.get_code(codes[2].code)}
    expected = {response.error(error.OAUTH_CODE_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_expired_codes; code 2 not found')

    got = {auth.oauth.get_code(codes[3].code)}
    expected = {true, codes[3]}
    got[2].consumer = nil
    test:is_deeply(got, expected, 'test_delete_expired_codes; code 3 found')
end

function test_delete_expired_tokens()

    local current_ts = utils.now()
    local expires_in = 10
    local tokens = {}

    local ok, user = auth.registration(v.USER_EMAIL)
    ok, user = auth.complete_registration(v.USER_EMAIL, user.code, v.USER_PASSWORD)

    local ok, app = auth.oauth.add_app(user.id, v.OAUTH_APP_NAME, 'server', v.OAUTH_CONSUMER_REDIRECT_URLS)

    for i, created_at in ipairs{ current_ts - 11, current_ts - 10, current_ts - 9} do

        local t = { unpack(oauth_token_tuple) }
        t[oauth_token.ACCESS_TOKEN] = string.format("%s%d", t[oauth_token.ACCESS_TOKEN], i)
        t[oauth_token.REFRESH_TOKEN] = string.format("%s%d", t[oauth_token.REFRESH_TOKEN], i)
        t[oauth_token.CONSUMER_KEY] = app.consumer_key
        t[oauth_token.CREATED_AT] = created_at
        t[oauth_token.EXPIRES_IN] = expires_in

        local ok, token = auth.oauth.save_access(unpack(t))
        table.insert(tokens, token)
    end

    local got, expected
    got = {auth.oauth.delete_expired_tokens(current_ts)}
    expected = {true, 2}

    test:is_deeply(got, expected, 'test_delete_expired_tokens; deleted')

    got = {auth.oauth.get_access(tokens[1].access_token)}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_expired_tokens; token 1 not found')

    got = {auth.oauth.get_access(tokens[2].access_token)}
    expected = {response.error(error.OAUTH_ACCESS_TOKEN_NOT_FOUND)}
    test:is_deeply(got, expected, 'test_delete_expired_tokens; token 2 not found')

    got = {auth.oauth.get_access(tokens[3].access_token)}
    expected = {true, tokens[3]}
    got[2].consumer = nil
    test:is_deeply(got, expected, 'test_delete_expired_tokens; token 3 found')
end





exports.tests = {
    test_save_code_success,
    test_save_code_invalid_params,
    test_get_code_success,
    test_get_code_x_consumer_not_found,
    test_get_code_invalid_params,
    test_get_code_not_found,
    test_delete_code_success,
    test_delete_code_invalid_params,
    test_delete_code_not_found,
    test_save_access_success,
    test_save_access_invalid_params,
    test_get_access_success,
    test_get_access_x_consumer_not_found,
    test_get_access_not_found,
    test_get_access_invalid_params,
    test_delete_access_success,
    test_delete_access_not_found,
    test_delete_access_invalid_params,
    test_get_refresh_success,
    test_delete_refresh_success,
    test_delete_refresh_not_found,
    test_delete_refresh_invalid_params,
    test_delete_user,
    test_delete_app,
    test_delete_expired_codes,
    test_delete_expired_tokens,
}


return exports
