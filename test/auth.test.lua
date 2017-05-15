local config = require('test.config')

local test_db_path = config.test_database_dir

-- mock
package.path = "./test/mock/?.lua;" .. package.path
os.execute('mkdir -p ' .. test_db_path)

box.cfg {
    listen = config.port,
    wal_dir = test_db_path,
    snap_dir = test_db_path,
    vinyl_dir = test_db_path,
    memtx_dir = test_db_path,
}

local TEST_CASES = {
    'test.case.registration',
    'test.case.auth',
    'test.case.restore_password',
    'test.case.profile',
    'test.case.social',
    'test.case.complex'
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