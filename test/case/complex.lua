local exports = {}
local tap = require('tap')
local db = require('auth.db')
local config = require('test.config')
local v = require('test.values')

local test = tap.test('auth_test')
local auth = require('auth').api(config)

function exports.setup() end

function exports.before() end

function exports.after()
    db.truncate_spaces()
end

function exports.teardown() end

function test_register_social_and_common()
    local ok, code, common_user, common_session, social_user, social_session, expected

    local profile = {
        first_name = v.USER_FIRST_NAME,
        last_name = v.USER_LAST_NAME
    }

    ok, common_user = auth.registration(v.USER_EMAIL)
    ok, common_user = auth.complete_registration(v.USER_EMAIL, common_user.code, '123123')
    ok, common_user = auth.set_profile(common_user['id'], profile)

    ok, social_user = auth.social_auth('vk', v.VALID_CODE)

    test:isnt(social_user['id'], common_user['id'], 'test_register_social_and_common users created')
    common_user['id'] = nil
    social_user['id'] = nil


    expected = {
        provider = 'vk',
        social_id = v.SOCIAL_ID
    }
    test:is_deeply(social_user['social'], expected, 'test_register_social_and_common social data')
    social_user['social'] = nil
    social_user['session'] = nil
    test:is_deeply(common_user, social_user, 'test_register_social_and_common profile equal')
end


function test_auth_social_and_common()
    local ok, code, common_user, common_session, social_user, social_session, expected

    ok, common_user = auth.registration(v.USER_EMAIL)
    ok, common_user = auth.complete_registration(v.USER_EMAIL, common_user.code, '123123')
    ok, common_user = auth.auth(v.USER_EMAIL, '123123')
    common_session = common_user['session']

    ok, social_user = auth.social_auth('vk', v.VALID_CODE)
    social_session = social_user['session']

    test:isnt(social_user['id'], common_user['id'], 'test_auth_social_and_common users created')
    test:isnt(social_session, common_session, 'test_auth_social_and_common different sessions')

    ok, common_user = auth.check_auth(common_session)
    test:is(ok, true, 'test_auth_social_and_common common auth')
    ok, social_user = auth.check_auth(social_session)
    test:is(ok, true, 'test_auth_social_and_common social auth')
end



exports.tests = {
    test_register_social_and_common,
    test_auth_social_and_common,
}

return exports