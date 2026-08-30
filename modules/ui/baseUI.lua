--- Base class for UI elements
--- @class baseUI
--- @field player PlayerPuppet?
--- @field Utils Utils
--- @field viewSize number
local baseUI = {}
baseUI.__index = baseUI

---Create a new UI component instance
---@return baseUI
function baseUI:new()
    local instance = setmetatable({}, self)
    instance.player = nil
    instance.viewSize = 0
    instance.Utils = require('modules/Utils')
    return instance
end

---Initialize or refresh frame-specific references
function baseUI:init()
    if not self.player or not IsDefined(self.player) then
        self.player = Game.GetPlayer()
    end
    self.viewSize = self.Utils.getViewSize()
end

---Get current view size scalar
---@return number
function baseUI:getViewSize()
    if not self.viewSize or self.viewSize <= 0 then
        self.viewSize = self.Utils.getViewSize()
    end
    return self.viewSize
end

return baseUI
