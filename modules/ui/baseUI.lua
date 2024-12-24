--- Base class for ui elements that needed data
--- @class baseUI
--- @field player PlayerPuppet?
--- @field Utils Utils
baseUI = {}

function baseUI:new()
    local instance = {}
    instance.player = nil
    instance.Utils = require('modules/Utils')

    instance.class = {"baseUI"}
    self.__index = self
    return setmetatable(instance, self)
end

return baseUI
