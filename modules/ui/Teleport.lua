local baseUI = require('modules/ui/baseUI')

---@class Teleport : baseUI
---@field destination Vector4?
local Teleport = setmetatable({}, baseUI)
Teleport.__index = Teleport

-- Constructor
function Teleport:new()
    self.destination = nil
    local obj = baseUI.new(self) -- Call BaseUI constructor
    return obj
end

function Teleport:teleportPlayer()
    print('teleport' .. self.destination.x, self.destination.y, self.destination.z)
    Game.GetTeleportationFacility():Teleport(self.player, self.destination, EulerAngles.new(0, 0, 45))
end

function Teleport:render()
    baseUI:init()

    if ImGui.CollapsingHeader("Teleport Player") then
        if self.destination == nil then
            self.destination = Vector4.new(0, 0, 0, 1)
        end

        ImGui.PushItemWidth(100 * self.viewSize)
        self.destination.x = Utils.handleVector4Input("TPDest", "x", self.destination)
        ImGui.SameLine()
        self.destination.y = Utils.handleVector4Input("TPDest", "y", self.destination)
        ImGui.SameLine()
        self.destination.z = Utils.handleVector4Input("TPDest", "z", self.destination)
        ImGui.PopItemWidth()

        if ImGui.Button("tp to point") then
            self:teleportPlayer()
        end
    end
end

return Teleport
