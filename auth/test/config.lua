return {
    port = 3301,
    test_database_dir = '/tmp/trantool-auth/test/test_db',

    activation_secret = 'ehbgrTUHIJ7689fyvg',
    session_secret = 'aswfWERVefver324efv',
    restore_secret = 'ybhinjTRCFYVGUHB5678jh',
    session_lifetime = 3,
    session_update_timedelta = 2,
    social_check_time = 3,

    facebook = {
        client_id = '1813230128941062',
        client_secret = '3bb5bbe8b72ff05bcf66ce9d5cbff3b3',
        redirect_uri='http://localhost:8000/',
    },
    google = {
        client_id = '495340653331-3gmtvon6tc1o61ajn5piek6jgi0p2o47.apps.googleusercontent.com',
        client_secret = 'aaFDCa0mMK8YqeBWOeAnfGYY',
        redirect_uri='http://localhost:8000/',
    },
    vk = {
        client_id = '5873775',
        client_secret = 'nwUFQsavhwIDR6ToDtX6',
        redirect_uri='http://localhost:8000/',
    },
}