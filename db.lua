local exports = {}
local config = require('config')

function exports.create_database()
    local user_space = box.schema.space.create('portal_user')
    user_space:create_index('primary', {
        type = 'hash',
        parts = {1, 'string'}
    })
    user_space:create_index('email', {
        type = 'tree',
        unique = false,
        parts = {2, 'string'}
    })

    local social_space = box.schema.space.create('portal_social')
end

function exports.start()
    print('start database now!')
    box.cfg {
        listen = config.port,
    }
end

return exports