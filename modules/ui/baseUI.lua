--- Base class for ui elements that needed data
--- @class baseUI
--- @field player PlayerPuppet?
--- @field Utils Utils
--- @field viewSize number
local baseUI = {}
baseUI.__index = baseUI -- This ensures inheritance works properly

function baseUI:new()
    local instance = setmetatable({}, self) -- Set baseUI as the metatable for the instance
    instance.player = nil
    instance.viewSize = 0
    instance.Utils = require('modules/Utils')

    assert(instance.Utils, "Utils module could not be loaded") -- Ensure Utils is loaded
    assert(instance.Utils.getViewSize, "Utils.getViewSize is nil") -- Ensure getViewSize exists

    return instance
end

function baseUI:init()
    if not self.player then
        self.player = Game.GetPlayer()
    end
    if self.viewSize == 0 or self.viewSize == nil then
        self.viewSize = Utils.getViewSize()
    end
end

return baseUI
