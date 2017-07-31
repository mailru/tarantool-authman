local utils = require('authman.utils.utils')
local fiber = require('fiber')

return function(config)
    local user = require('authman.model.user').model(config)

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

        -- put migrations with box.once here

    end
end