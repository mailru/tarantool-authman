box.cfg {
    listen = 3302,
}


local config = {
    activation_secret = '123456',
    session_secret = '123456',
    restore_secret = '123456',
    session_lifetime = 7 * 24 * 60 * 60,
    session_update_timedelta = 2 * 24 * 60* 60,
    social_check_time = 60 * 60* 24,

    -- password_strength can be: 
    -- none, whocares, easy, common, moderate, violence, nightmare,
    password_strength = 'common', -- default value

    facebook = {
        client_id = '',
        client_secret = '',
        redirect_uri='',
    },
    google = {
        client_id = '',
        client_secret = '',
        redirect_uri=''
    },
    vk = {
        client_id = '',
        client_secret = '',
        redirect_uri='',
    },
}

auth = require('authman').api(config)
