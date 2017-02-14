# tarantool-media-auth

Require tarantool >= 1.7

Run tarantool and create scopes:

```
tarantool> db = require('db')
tarantool> db.start()
tarantool> db.create_database()
```

Use auth api:
```
tarantool> auth = require('auth')
tarantool> ok, activation_code = auth.registration('example@mail.ru')
```

## Api methods

#### auth.registration(email)
```
tarantool> ok, code = auth.registration('aaa@mail.ru')
tarantool> code
- 022c1ff1f0b171e51cb6c6e32aefd6ab
```
Creates user, return code for email confirmation.

#### auth.complete_registration(email, code, password)
```
tarantool> ok, user = auth.complete_registration('aaa@mail.ru', code, '123')
tarantool> user
- is_active: true
  email: aaa@mail.ru
  id: b8c9ee9d-ae15-469d-a16f-415594121ece
```
Set user is_active=true and password, return user table (without session)

#### auth.auth(email, password)
```
tarantool> ok, user = auth.auth('aaa@mail.ru', '123')
tarantool> user
- is_active: true
  email: aaa@mail.ru
  session:'eyJ1c2VyX2lkIjoiYjhjOWVlOWQtYWUxN....'
  id: b8c9ee9d-ae15-469d-a16f-415594121ece

```
Sign in user, return user table (with session)

#### auth.check_auth(session)
```
tarantool> ok, user = auth.check_auth(session)
tarantool> user
- is_active: true
  email: aaa@mail.ru
  session: 'eyJ1c2VyX2lkIjoiYjhjOWVlOWQtYWUxNS00Nj.....'
  id: b8c9ee9d-ae15-469d-a16f-415594121ece
```
Check user is signed in, return user table (with new session)

Session can be renewed, so set it again after each call oh this method


#### auth.restore_password(email)
```
tarantool> ok, token = auth.restore_password('aaa@mail.ru')
tarantool> token
- 8b9c03b7786a465e2175bb1a8bd8a59f
```
Get restore password token

#### auth.complete_restore_password(email, token, password)

```
tarantool> ok, user = auth.complete_restore_password('aaa@mail.ru', code, '234')
tarantool> user
- is_active: true
  email: aaa@mail.ru
  id: b8c9ee9d-ae15-469d-a16f-415594121ece
```
Set new password, return user table (without session)

## Handling errors:

If first parametr (ok - bool) is false then error is occured. Error description will be stored in second param like:
```
error = {code = description}
```
Example:
```
tarantool> ok, user = auth.registration('aaa@mail.ru')
tarantool> ok
- false
tarantool> user
- '2': User already exists
```
Complete list of error codes:
```
error.USER_NOT_FOUND = '1'
error.USER_ALREADY_EXISTS = '2'
error.INVALID_PARAMS = '3'
error.USER_NOT_ACTIVE = '4'
error.WRONG_PASSWORD = '5'
error.WRONG_ACTIVATION_CODE = '6'
error.WRONG_SESSION_SIGN = '7'
error.NOT_AUTHENTICATED = '8'
error.WRONG_RESTORE_TOKEN = '9'
error.USER_ALREADY_ACTIVE = '10'
```

## Run tests:
To perform tests run this in directory with media-auth module:
```
$ tarantool run_tests.lua
```
