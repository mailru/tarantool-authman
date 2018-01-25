## OAuth2 related API methods

#### auth.oauth.add_app(user_id, app_name, app_type, redirect_urls, is_trusted)
```
tarantool> ok, app = auth.oauth.add_app('268a8464-e39d-4f82-b55f-e68197c6c3f2', 'test app', 'browser', 'https://example.com/1 https://example.com/2', false)
tarantool> app
- is_active: true
  redirect_urls: https://example.com/1 https://example.com/2
  consumer_key: 2f2d9591fae84f4fb388bab878ee4613
  id: bcf5297f-3192-403d-a316-13d31780160a
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  consumer_secret: 41eef0fc10f9a62a1b301a7f1db703e076271b01f148efcdc3dcb3a69a78101c
  name: test app
  type: browser
  is_trusted: false
```
Register new OAuth client. Return OAuth client table. Valid application types are "server", "browser", "mobile", "native".
Optional is_trusted parameter indicates that app is approved to be authorized by all resource owners.

#### auth.oauth.disable_app(app_id)
```
tarantool> ok, app = auth.oauth.disable_app('bcf5297f-3192-403d-a316-13d31780160a')
tarantool> app
---
- is_active: false
  id: bcf5297f-3192-403d-a316-13d31780160a
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  name: test app
  type: browser
```
Disable OAuth client. Return app table.

#### auth.oauth.enable_app(app_id)
```
tarantool> ok, app = auth.oauth.enable_app('bcf5297f-3192-403d-a316-13d31780160a')
tarantool> app
---
- is_active: true
  id: bcf5297f-3192-403d-a316-13d31780160a
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  name: test app
  type: browser
```
Enable OAuth client. Return app table.

#### auth.oauth.delete_app(app_id)
```
tarantool> ok, app = auth.oauth.delete_app('bcf5297f-3192-403d-a316-13d31780160a')
tarantool> app
---
- consumer_key: 2f2d9591fae84f4fb388bab878ee4613
  id: bcf5297f-3192-403d-a316-13d31780160a
  is_active: true
  redirect_urls: https://example.com/1 https://example.com/2
  type: browser
  consumer_secret_hash: !!binary fhHEsS7eXm/oFUN2yV+eK7KVb9ydn1iQi9/PlZZYjRw=
  application_id: bcf5297f-3192-403d-a316-13d31780160a
  name: test app
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
```
Delete OAuth client. Return OAuth client table.

#### auth.oauth.get_app(app_id)
```
tarantool> ok, app = auth.oauth.get_app('1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7')
tarantool> app
---
- consumer_key: 9169b664839bca439ca11fe4274838b2
  id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
  is_active: true
  redirect_urls: https://example.com/1 https://example.com/2
  type: browser
  consumer_secret_hash: !!binary xPVbgBDs53gqmhp7ZBtzKIjU9IjtDlQYfqMAQOfVYLU=
  application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
  name: test app
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
```
Given application id return OAuth client info

#### auth.oauth.get_user_apps(user_id)
```
tarantool> ok, apps = auth.oauth.get_user_apps('268a8464-e39d-4f82-b55f-e68197c6c3f2')
tarantool> apps
- - consumer_key: 9169b664839bca439ca11fe4274838b2
    id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    is_active: true
    redirect_urls: https://example.com/1 https://example.com/2
    type: browser
    consumer_secret_hash: !!binary hYVXta3lfUE/f8VctPZcmN4FE7yeRJvqao6YrviHBzs=
    application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    name: test app
    user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
```
Given user id return list of user's applications

#### auth.oauth.get_consumer(consumer_key)
```
tarantool> ok, consumer = auth.oauth.get_consumer('9169b664839bca439ca11fe4274838b2')
tarantool> consumer
---
- consumer_key: 9169b664839bca439ca11fe4274838b2
  id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
  is_active: true
  redirect_urls: https://example.com/1 https://example.com/2
  type: browser
  consumer_secret_hash: !!binary xPVbgBDs53gqmhp7ZBtzKIjU9IjtDlQYfqMAQOfVYLU=
  application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
  name: test app
  user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
...
```
Given consumer key return OAuth client info.

#### auth.oauth.reset_consumer_secret(consumer_key)
```
tarantool> ok, secret = auth.oauth.reset_consumer_secret('9169b664839bca439ca11fe4274838b2')
tarantool> secret
---
- a6d9ef466f38dec5ea85106da7a419151e83b1df0445a92400845830329e13f9
```
Given consumer key generate and save new consumer secret. Return new consumer secret.

#### auth.oauth.save_code(code, consumer_key, redirect_url, scope, state, expires_in, created_at, code_challenge, code_challenge_method, resource_owner)
```
tarantool> ok, code = auth.oauth.save_code('some code', '9169b664839bca439ca11fe4274838b2', 'https://example.com/1', 'read', 'some state', 600, 1514452159, 'code challenge', 'code challenge method', 'user_id or resource owner')
tarantool> code
---
- expires_in: 600
  code: some code
  redirect_url: https://example.com/1
  created_at: 1514452159
  scope: read
  code_challenge_method: code challenge method
  state: some state
  consumer_key: 9169b664839bca439ca11fe4274838b2
  code_challenge: code challenge
```
Save OAuth authorization code info. Return authorization code table w/o consumer. See rfc7636 for explanation of code_challenge and code_challenge_method params.

#### auth.oauth.get_code(code)
```
tarantool> ok, code = auth.oauth.get_code('some code')
tarantool> code
---
- expires_in: 600
  code: some code
  redirect_url: https://example.com/1
  created_at: 1514452159
  scope: read
  consumer:
    consumer_key: 9169b664839bca439ca11fe4274838b2
    id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    is_active: true
    redirect_urls: https://example.com/1 https://example.com/2
    type: browser
    consumer_secret_hash: !!binary hYVXta3lfUE/f8VctPZcmN4FE7yeRJvqao6YrviHBzs=
    application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    name: test app
    user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  code_challenge_method: code challenge method
  state: some state
  consumer_key: 9169b664839bca439ca11fe4274838b2
  code_challenge: code challenge
```
Return OAuth authorization code info

#### auth.oauth.delete_code(code)
```
tarantool> ok, code = auth.oauth.delete_code('some code')
tarantool> code
- expires_in: 600
  code: some code
  redirect_url: https://example.com/1
  created_at: 1514452159
  scope: read
  code_challenge_method: code challenge method
  state: some state
  consumer_key: 9169b664839bca439ca11fe4274838b2
  code_challenge: code challenge
```
Delete OAuth authorization code. Return authorization code table without consumer.

#### auth.oauth.delete_expired_codes(expiration_ts)
```
tarantool> ok, deleted_cnt = auth.oauth.delete_expired_codes(1514452759)
tarantool> deleted_cnt
---
- 1
```
Given timestamp delete OAuth authorization codes having expiration time lt than this timestamp

#### auth.oauth.save_access(access_token, consumer_key, refresh_token, redirect_url, scope, expires_in, created_at, resource_owner)
```
tarantool> ok, access = auth.oauth.save_access('some token', '9169b664839bca439ca11fe4274838b2', 'some refresh token', 'https://example.com/1', 'read', 3600, 1514452760, 'user_id of resource owner')
tarantool> access
---
- refresh_token: some refresh token
  access_token: some token
  consumer_key: 9169b664839bca439ca11fe4274838b2
  expires_in: 3600
  redirect_url: https://example.com/1
  created_at: 1514452760
  scope: read
```
Save OAuth access token info.

#### auth.oauth.get_access(access_token)
```
tarantool> ok, access = auth.oauth.get_access('some token')
tarantool> access
---
- refresh_token: some refresh token
  access_token: some token
  consumer_key: 9169b664839bca439ca11fe4274838b2
  consumer:
    consumer_key: 9169b664839bca439ca11fe4274838b2
    id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    is_active: true
    redirect_urls: https://example.com/1 https://example.com/2
    type: browser
    consumer_secret_hash: !!binary hYVXta3lfUE/f8VctPZcmN4FE7yeRJvqao6YrviHBzs=
    application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    name: test app
    user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  expires_in: 3600
  redirect_url: https://example.com/1
  created_at: 1514452760
  scope: read
```
Return OAuth access token info

#### auth.oauth.delete_access(access_token)
```
tarantool> ok, access = auth.oauth.delete_access('some token')
tarantool> access
---
- refresh_token: some refresh token
  access_token: some token
  consumer_key: 9169b664839bca439ca11fe4274838b2
  expires_in: 3600
  redirect_url: https://example.com/1
  created_at: 1514452760
  scope: read
```
Delete OAuth access token. Return token table without consumer

#### auth.oauth.delete_expired_token(expiration_ts)
```
tarantool> ok, deleted_cnt = auth.oauth.delete_expired_tokens(1514456869)
tarantool> deleted_cnt
---
- 1
```
Given timestamp delete OAuth access tokens having expiration time lt than this timestamp

#### auth.oauth.get_refresh(refresh_token)
```
tarantool> ok, refresh = auth.oauth.get_refresh('some refresh token')
tarantool> refresh
---
- refresh_token: some refresh token
  access_token: some token
  consumer_key: 9169b664839bca439ca11fe4274838b2
  consumer:
    consumer_key: 9169b664839bca439ca11fe4274838b2
    id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    is_active: true
    redirect_urls: https://example.com/1 https://example.com/2
    type: browser
    consumer_secret_hash: !!binary hYVXta3lfUE/f8VctPZcmN4FE7yeRJvqao6YrviHBzs=
    application_id: 1cd3806a-4221-4ff2-aa7c-e5d076c4c1a7
    name: test app
    user_id: 268a8464-e39d-4f82-b55f-e68197c6c3f2
  expires_in: 3600
  redirect_url: https://example.com/1
  created_at: 1514452760
  scope: read
```
Return OAuth refresh token info.

#### auth.oauth.delete_refresh(access_refresh)
```
tarantool> ok, refresh = auth.oauth.delete_refresh('some refresh token')
tarantool> refresh
---
- refresh_token: some refresh token
  access_token: some token
  consumer_key: 9169b664839bca439ca11fe4274838b2
  expires_in: 3600
  redirect_url: https://example.com/1
  created_at: 1514452760
  scope: read
```
Delete OAuth refresh token. Return token table w/o consumer


