local password_token = {}

-----
-- token (user_uuid, code)
-----

password_token.SPACE_NAME = 'portal_reset_pwd_token'

password_token.PRIMARY_INDEX = 'primary'

password_token.USER_ID = 1
password_token.CODE = 2

function password_token.get_space()
    return box.space[password_token.SPACE_NAME]
end

function password_token.serialize(token_tuple)
    return {
        id = token_tuple[password_token.ID],
        code = token_tuple[password_token.CODE],
    }
end

return password_token
