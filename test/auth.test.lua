print(package.path)

package.path = "./test/mock/?.lua;" .. package.path
print(package.path)
local utils = require('auth.utils.utils')
local m = require('auth.model.session').model()
--local utils2 = require('test.mock.auth.utils.utils')
print(utils.format)
print(m)