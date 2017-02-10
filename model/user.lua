local user = {}
-----
-- user (uuid, email, is_active, password, profile)
-----

user.SPACE_NAME = 'portal_user'

user.PRIMARY_INDEX = 'primary'
user.EMAIL_INDEX = 'email_index'

user.ID = 1
user.EMAIL = 2
user.IS_ACTIVE = 3
user.PASSWORD = 4
user.PROFILE = 5

function user.get_space()
    return box.space[user.SPACE_NAME]
end

function user.serialize(user_tuple)
    return {
        id = user_tuple[user.ID],
        email = user_tuple[user.EMAIL],
        is_active = user_tuple[user.IS_ACTIVE],
    }
end

function user.get_by_email(email)
    -- first user with email
    return user.get_space().index[user.EMAIL_INDEX]:select(email)[1]
end

return user