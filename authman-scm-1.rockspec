package = 'authman'
version = 'scm-1'
source  = {
    url    = 'git://github.com/mailru/tarantool-authman.git',
    branch = 'master',
}
description = {
    summary  = 'Auth module for Tarantool',
    homepage = 'https://github.com/mailru/tarantool-authman.git',
    license  = 'MIT',
}
dependencies = {
    'lua >= 5.1',
}
build = {
    type = 'builtin',

    modules = {
        ['authman.migrations.migrations'] = 'authman/migrations/migrations.lua',
        ['authman.model.password']        = 'authman/model/password.lua',
        ['authman.model.password_token']  = 'authman/model/password_token.lua',
        ['authman.model.session']         = 'authman/model/session.lua',
        ['authman.model.social']          = 'authman/model/social.lua',
        ['authman.model.user']            = 'authman/model/user.lua',
        ['authman.utils.http']            = 'authman/utils/http.lua',
        ['authman.utils.utils']           = 'authman/utils/utils.lua',
        ['authman.validator']             = 'authman/validator.lua',
        ['authman.response']              = 'authman/response.lua',
        ['authman.error']                 = 'authman/error.lua',
        ['authman.db']                    = 'authman/db.lua',
        ['authman']                       = 'authman/init.lua'
    }
}

-- vim: syntax=lua