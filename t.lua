require('auth.init_db')
local c = require('auth.config')
local ok, auth = require('auth').api(c)
print(ok,auth)
local ok, url= auth.social_auth_url('google')
print(url)
return auth