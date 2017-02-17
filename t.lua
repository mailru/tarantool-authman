require('auth.init_db')
local c = require('auth.config')
local auth = require('auth').api(c)
local ok, url= auth.social_auth_url('facebook')
print(url)
return auth