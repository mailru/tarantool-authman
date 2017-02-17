local db = require('auth.db')

db.start()

-- Need for manual tests
--local auth = require('auth')
--local ok, code
--
--ok, code = auth.registration('lindeni@mail.ru')
--ok, code = auth.complete_registration('lindeni@mail.ru', code, '123')