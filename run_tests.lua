local db = require('db')
local config = require('config')

print('start test database now!')
box.cfg {
    listen = config.port,
    wal_dir = config.test_database_dir,
    snap_dir = config.test_database_dir,
    vinyl_dir = config.test_database_dir,
}

db.create_database()

local TEST_CASES = {
    'test.user_auth',
    'test.user_registration'
}

function run()
    for case_index = 1, #TEST_CASES do
        local case = require(TEST_CASES[case_index])
        case.before()
            for test_index = 1, #case.tests do
                case.tests[test_index]()
            end
        case.after()
    end
end

run()