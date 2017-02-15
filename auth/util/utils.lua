local utils = {}

function utils.format(string, tab)
  return (string:gsub('($%b{})', function(word) return tab[word:sub(3, -2)] or word end))
end

return utils