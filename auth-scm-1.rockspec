package = 'auth'
version = 'scm-1'
source  = {
    url    = 'git://github.com/mailru/tarantool-auth.git',
    branch = 'master',
}
description = {
    summary  = 'Auth module for Tarantool',
    homepage = 'https://github.com/mailru/tarantool-auth.git',
    license  = 'MIT',
}
dependencies = {
    'lua >= 5.1',
}
build = {
    type = 'builtin',

    modules = {
        ['auth.model.password']       = 'auth/model/password.lua',
        ['auth.model.password_token'] = 'auth/model/password_token.lua',
        ['auth.model.session']        = 'auth/model/session.lua',
        ['auth.model.social']         = 'auth/model/social.lua',
        ['auth.model.user']           = 'auth/model/user.lua',
        ['auth.utils.http']           = 'auth/utils/http.lua',
        ['auth.utils.utils']          = 'auth/utils/utils.lua',
        ['auth.validator']            = 'auth/validator.lua',
        ['auth.response']             = 'auth/response.lua',
        ['auth.error']                = 'auth/error.lua',
        ['auth.db']                   = 'auth/db.lua',
        ['auth']                      = 'auth/init.lua'
    }
}

-- vim: syntax=lua