local db = require('db')

db.start()
db.create_database()

local TEST_CASES = {
    'test_user_auth'
}

function run()
    for case in TEST_CASES do
        case.before()
            local test_count = tests + #case.tests
            for test in case.tests do
                local errors = errors + test()
            end
        case.after()
    end
end

db.clear_database()