# tarantool-auth

Require tarantool >= 1.7

## Quickstart
Run tarantool if not running yet:
```
tarantool> db = require('auth.db')
tarantool> db.start()
```

Use auth api:
```
tarantool> config = require('my_config')
tarantool> auth = require('auth').api(config) -- creates scopes
tarantool> ok, activation_code = auth.registration('example@mail.ru')
tarantool> ok, user = auth.registration('example@mail.ru', activation_code, 'Pa$$wOrD')
tarantool> ok, user = auth.set_profile(user['id'], {first_name='name', laste_name='surname'})
tarantool> ok, user = auth.auth('example@mail.ru', 'Pa$$wOrD')
tarantool> session =  user['session']
tarantool> ok, user = auth.check_auth(session) -- user can get new session
```

## Configuration
Exaple of my_config.lua module, fill empty strings with your values:
```
return {
    activation_secret = '',
    session_secret = '',
    restore_secret = '',
    session_lifetime = 7 * 24 * 60 * 60,
    session_update_timedelta = 2 * 24 * 60* 60,
    social_check_time = 60 * 60* 24,

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

#### auth.set_profile(user_id, profile_table)
```
tarantool> ok, user = auth.set_profile(id, {first_name='name', laste_name='surname'})
tarantool> user
- is_active: true
  email: aaa@mail.ru
  profile: {'first_name': 'name'}
  id: bcb6e00a-1148-4b7d-9ab1-9a9a3b21ce2a

```
Set user profile first_name and last_name

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

#### auth.social_auth_url(provider, state)

```
tarantool> ok, url = auth.social_auth_url('facebook', 'some-state-string')
tarantool> url
- https://www.facebook.com/v2.8/dialog/oauth?client_id=1813230128941062&redirect_uri={redirect}&scope=email&state=some-state-string
```
Return url for social auth. State is optional but recommended for csrf protection.

#### auth.social_auth(provider, code)

```
tarantool> ok, user = auth.social_auth('facebook', code)
tarantool> user
- is_active: true
  profile: {'first_name': 'a', 'last_name': 'aa'}
  id: e954033b-3a61-4e49-9e8c-640e01bf8d66
  email: aaa@mail.ru
  session: 'eyJ1c2VyX2lkIj.....'
```
Sign in user, return user table (with session)

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
error.WRONG_AUTH_CODE = '11'
error.IMPROPERLY_CONFIGURED = '12'
error.WRONG_PROVIDER = '13'
error.WEAK_PASSWORD = '14'
error.SOCIAL_AUTH_ERROR = '15'

```

## Run tests:
To perform tests run this in directory with media-auth module:
```
$ tarantool auth/run_tests.lua
```
