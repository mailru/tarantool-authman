local utils = require('authman.utils.utils')
local fiber = require('fiber')

return function(config)
    local user = require('authman.model.user').model(config)
    local oauth_app = require('authman.model.oauth.app').model(config)
    local oauth_consumer = require('authman.model.oauth.consumer').model(config)
    local oauth_code = require('authman.model.oauth.code').model(config)
    local oauth_token = require('authman.model.oauth.token').model(config)

    if box.cfg.read_only == false then

        box.once('20170726_authman_add_registration_and_session_ts', function ()
            local counter = 0
            local now = utils.now()
            for _, tuple in user.get_space():pairs(nil, {iterator=box.index.ALL}) do
                local user_tuple = tuple:totable()
                user_tuple[user.REGISTRATION_TS] = now
                user_tuple[user.SESSION_UPDATE_TS] = now
                user.get_space():replace(user_tuple)

                counter = counter + 1
                if counter % 10000 == 0 then
                    fiber.sleep(0)
                end
            end
        end)

        box.once('20180125_authman_oauth_add_app_is_trusted', function ()
            local counter = 0
            for _, tuple in oauth_app.get_space():pairs(nil, {iterator=box.index.ALL}) do
                local app_tuple = tuple:totable()
                app_tuple[oauth_app.IS_TRUSTED] = false
                oauth_app.get_space():replace(app_tuple)

                counter = counter + 1
                if counter % 10000 == 0 then
                    fiber.sleep(0)
                end
            end
        end)

        box.once('20180125_authman_oauth_add_code_and_token_resource_owner', function ()
            local counter = 0
            for _, tuple in oauth_code.get_space():pairs(nil, {iterator=box.index.ALL}) do
                local code_tuple = tuple:totable()
                local consumer_tuple = oauth_consumer.get_by_id(code_tuple[oauth_code.CONSUMER_KEY])
                if consumer_tuple ~= nil then
                    local app_tuple = oauth_app.get_by_id(consumer_tuple[oauth_consumer.APP_ID])
                    if app_tuple ~= nil then
                        code_tuple[oauth_code.RESOURCE_OWNER] = app_tuple[oauth_app.USER_ID]
                        oauth_code.get_space():replace(code_tuple)
                    end
                end

                counter = counter + 1
                if counter % 10000 == 0 then
                    fiber.sleep(0)
                end
            end
            for _, tuple in oauth_token.get_space():pairs(nil, {iterator=box.index.ALL}) do
                local token_tuple = tuple:totable()
                local consumer_tuple = oauth_consumer.get_by_id(token_tuple[oauth_token.CONSUMER_KEY])
                if consumer_tuple ~= nil then
                    local app_tuple = oauth_app.get_by_id(consumer_tuple[oauth_consumer.APP_ID])
                    if app_tuple ~= nil then
                        token_tuple[oauth_token.RESOURCE_OWNER] = app_tuple[oauth_app.USER_ID]
                        oauth_token.get_space():replace(token_tuple)
                    end
                end

                counter = counter + 1
                if counter % 10000 == 0 then
                    fiber.sleep(0)
                end
            end
        end)

        -- put migrations with box.once here

    end
end
