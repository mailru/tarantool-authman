local session = {}

local digest = require('digest')
local uuid = require('uuid')
local json = require('json')

-----
-- token (session_id, code)
-----
function session.model(config)
    local model = {}

    model.SPACE_NAME = 'portal_sesssion_code'

    model.PRIMARY_INDEX = 'primary'

    model.ID = 1
    model.CODE = 2

    function model.get_space()
        return box.space[model.SPACE_NAME]
    end

    function model.generate()
        local code = uuid.str()
        local session_id = uuid.str()
        return model.get_space():insert({session_id, code})
    end

    function model.get(session_id)
        return model.get_space():get(session_id)
    end

    function model.decode_session(encoded_session_data)
        local session_data_json, session_data, ok, msg
        ok, msg = pcall(function()
            session_data_json = digest.base64_decode(encoded_session_data)
            session_data = json.decode(session_data_json)
        end)
        return session_data
    end

    return model
end

return session