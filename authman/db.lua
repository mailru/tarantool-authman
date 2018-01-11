local db = {}


function db.configurate(config)
    local api = {}

    local user = require('authman.model.user').model(config)
    local password = require('authman.model.password').model(config)
    local password_token = require('authman.model.password_token').model(config)
    local social = require('authman.model.social').model(config)
    local session = require('authman.model.session').model(config)
    local application = require('authman.model.application').model(config)
    local oauth_consumer = require('authman.model.oauth_consumer').model(config)
    local oauth_code = require('authman.model.oauth_code').model(config)
    local oauth_token = require('authman.model.oauth_token').model(config)

    function api.create_database()
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
            parts = {user.EMAIL, 'string', user.TYPE, 'unsigned'},
            if_not_exists = true
        })

        local password_space = box.schema.space.create(password.SPACE_NAME, {
            if_not_exists = true
        })
        password_space:create_index(password.PRIMARY_INDEX, {
            type = 'hash',
            parts = {password.ID, 'string'},
            if_not_exists = true
        })
        password_space:create_index(password.USER_ID_INDEX, {
            type = 'tree',
            unique = true,
            parts = {password.USER_ID, 'string'},
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

        local social_space = box.schema.space.create(social.SPACE_NAME, {
            if_not_exists = true
        })
        social_space:create_index(social.PRIMARY_INDEX, {
            type = 'hash',
            parts = {social.ID, 'string'},
            if_not_exists = true
        })
        social_space:create_index(social.USER_ID_INDEX, {
            type = 'tree',
            unique = true,
            parts = {social.USER_ID, 'string', social.PROVIDER, 'string'},
            if_not_exists = true
        })
        social_space:create_index(social.SOCIAL_INDEX, {
            type = 'hash',
            unique = true,
            parts = {social.SOCIAL_ID, 'string', social.PROVIDER, 'string'},
            if_not_exists = true
        })

        local session_space = box.schema.space.create(session.SPACE_NAME, {
            if_not_exists = true
        })
        session_space:create_index(session.PRIMARY_INDEX, {
            type = 'hash',
            parts = {session.ID, 'string'},
            if_not_exists = true
        })

        local app_space = box.schema.space.create(application.SPACE_NAME, {
            if_not_exists = true
        })
        app_space:create_index(application.PRIMARY_INDEX, {
            type = 'hash',
            parts = {application.ID, 'string'},
            if_not_exists = true
        })
        app_space:create_index(application.USER_ID_INDEX, {
            type = 'tree',
            unique = true,
            parts = {application.USER_ID, 'string', application.NAME, 'string'},
            if_not_exists = true
        })

        local oauth_consumer_space = box.schema.space.create(oauth_consumer.SPACE_NAME, {
            if_not_exists = true
        })

        oauth_consumer_space:create_index(oauth_consumer.PRIMARY_INDEX, {
            type = 'hash',
            parts = {oauth_consumer.ID, 'string'},
            if_not_exists = true
        })
        oauth_consumer_space:create_index(oauth_consumer.APPLICATION_ID_INDEX, {
            type = 'tree',
            unique = true,
            parts = {oauth_consumer.APPLICATION_ID, 'string'},
            if_not_exists = true
        })

        local oauth_code_space = box.schema.space.create(oauth_code.SPACE_NAME, {
            if_not_exists = true
        })

        oauth_code_space:create_index(oauth_code.PRIMARY_INDEX, {
            type = 'hash',
            parts = {oauth_code.CODE, 'string'},
            if_not_exists = true
        })
        oauth_code_space:create_index(oauth_code.CONSUMER_INDEX, {
            type = 'tree',
            unique = false,
            parts = {oauth_code.CONSUMER_KEY, 'string'},
            if_not_exists = true
        })

        local oauth_token_space = box.schema.space.create(oauth_token.SPACE_NAME, {
            if_not_exists = true
        })

        oauth_token_space:create_index(oauth_token.PRIMARY_INDEX, {
            type = 'hash',
            parts = {oauth_token.ACCESS_TOKEN, 'string'},
            if_not_exists = true
        })
        oauth_token_space:create_index(oauth_token.CONSUMER_INDEX, {
            type = 'tree',
            unique = false,
            parts = {oauth_token.CONSUMER_KEY, 'string'},
            if_not_exists = true
        })
        oauth_token_space:create_index(oauth_token.REFRESH_INDEX, {
            type = 'tree',
            unique = true,
            parts = {oauth_token.REFRESH_TOKEN, 'string'},
            if_not_exists = true
        })
    end

    function api.truncate_spaces()
        user.get_space():truncate()
        password_token.get_space():truncate()
        password.get_space():truncate()
        social.get_space():truncate()
        session.get_space():truncate()
        application.get_space():truncate()
        oauth_consumer.get_space():truncate()
        oauth_code.get_space():truncate()
        oauth_token.get_space():truncate()
    end

    return api
end

return db
