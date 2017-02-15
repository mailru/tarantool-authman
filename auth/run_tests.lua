local db = require('auth.db')
local config = require('auth.config')

box.cfg {
    listen = config.port,
    wal_dir = config.test_database_dir,
    snap_dir = config.test_database_dir,
    vinyl_dir = config.test_database_dir,
}

db.create_database()

local TEST_CASES = {
    'auth.test.registration',
    'auth.test.auth',
    'auth.test.restore_password'
}

function run()
    for case_index = 1, #TEST_CASES do
        local case = require(TEST_CASES[case_index])
        case.setup()
            for test_index = 1, #case.tests do
                case.before()
                case.tests[test_index]()
                case.after()
            end
        case.teardown()
    end
end

run()

db.drop_database()