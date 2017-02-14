local validator = {}

function validator.string(str)
    return type(str) == 'string'
end

function validator.not_empty_string(str)
    return validator.string(str) and str ~= ''
end

function validator.email(email_string)
    return validator.not_empty_string(email_string) and email_string:match('([^@]+@[^@]+)') == email_string
end

return validator



