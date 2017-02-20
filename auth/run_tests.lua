local config = require('auth.test.config')

local test_db_path = config.test_database_dir

os.execute('mkdir -p ' .. test_db_path)

box.cfg {
    listen = config.port,
    wal_dir = test_db_path,
    snap_dir = test_db_path,
    vinyl_dir = test_db_path,
}

local TEST_CASES = {
    'auth.test.registration',
    'auth.test.auth',
    'auth.test.restore_password',
    'auth.test.profile',
    'auth.test.social'
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
os.execute('rm -rf '.. test_db_path)