return {
    port = 3301,
    test_database_dir = '/tmp/tarantool-auth/test/test_db',

    activation_secret = 'ehbgrTUHIJ7689fyvg',
    session_secret = 'aswfWERVefver324efv',
    restore_secret = 'ybhinjTRCFYVGUHB5678jh',
    session_lifetime = 3,
    session_update_timedelta = 2,
    social_check_time = 2,

    password = {
        min_length = 6,
        min_char_group_count = 2,
    },

    facebook = {
        client_id = '1813230128941062',
        client_secret = 'some secret here',
        redirect_uri='http://localhost:8000/',
    },
    google = {
        client_id = '495340653331-3gmtvon6tc1o61ajn5piek6jgi0p2o47.apps.googleusercontent.com',
        client_secret = 'some secret here',
        redirect_uri='http://localhost:8000/',
    },
    vk = {
        client_id = '5873775',
        client_secret = 'some secret here',
        redirect_uri='http://localhost:8000/',
    },
}