local social = {}

local config = require('config')
-----
-- token (user_uuid, social_type, social_id)
-----

social.SPACE_NAME = 'portal_social_auth_credentials'

social.PRIMARY_INDEX = 'primary'
social.SOCIAL_INDEX = 'social'

social.USER_ID = 1
social.SOCIAL_TYPE = 2
social.SOCIAL_ID = 3

function social.get_space()
    return box.space[social.SPACE_NAME]
end

function social.serialize(social_tuple)
    return {
        id = social_tuple[social_tuple.ID],
        social_type = social_tuple[social_tuple.SOCIAL_TYPE],
        social_id = social_tuple[social_tuple.SOCIAL_ID],
    }
end

return social