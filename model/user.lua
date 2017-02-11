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

function user.serialize(user_tuple, session)
    local user_data = {
        id = user_tuple[user.ID],
        email = user_tuple[user.EMAIL],
        is_active = user_tuple[user.IS_ACTIVE],
    }
    if session ~= nil then
        user_data['session'] = session
    end
    return user_data
end

function user.get_by_email(email)
    return user.get_space().index[user.EMAIL_INDEX]:select(email)[1]
end

function user.get_id_by_email(email)
    local user_tuple = user.get_space().index[user.EMAIL_INDEX]:select(email)[1]
    if user_tuple ~= nil then
        return user_tuple[user.ID]
    else
        return nil
    end
end

return user