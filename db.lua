local db = {}
local config = require('config')

local user = require('model.user')
local password_token = require('model.password_token')

function db.create_database()

    local user_space = box.schema.space.create(user.SPACE_NAME, {
        if_not_exists = true
    })
    user_space:create_index(user.PRIMARY_INDEX, {
        type = 'hash',
        parts = {user.ID, 'string'},
        if_not_exists = true
    })
    user_space:create_index(user.EMAIL_INDEX, {
        type = 'tree',
        unique = false,
        parts = {user.EMAIL, 'string'},
        if_not_exists = true
    })

    local reset_pwd_token_space = box.schema.space.create(password_token.SPACE_NAME, {
        if_not_exists = true
    })
    reset_pwd_token_space:create_index(password_token.PRIMARY_INDEX, {
        type = 'hash',
        parts = {password_token.USER_ID, 'string'},
        if_not_exists = true
    })

--    local social_space = box.schema.space.create('portal_social')
end

function db.start()
    print('start database now!')
    box.cfg {
        listen = config.port,
    }
end

function db.drop_database()
    box.schema.portal_user:drop()
    box.schema.portal_reset_pwd_token:drop()
    box.schema.portal_social:drop()
end

return db