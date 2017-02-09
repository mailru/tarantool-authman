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

    local reset_pwd_token_space = box.schema.space.create('portal_reset_pwd_token')
    reset_pwd_token_space:create_index('primary', {
        type = 'hash',
        parts = {1, 'string'}
    })
    reset_pwd_token_space:create_index('primary', {
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

function exports.drop_database()
    box.schema.portal_user:drop()
    box.schema.portal_reset_pwd_token:drop()
    box.schema.portal_social:drop()
end

return exports