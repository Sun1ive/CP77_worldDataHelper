---@class Offsets
---@field from Vector4
---@field to Vector4
---@field result Vector4
---@field viewSize number
local Offsets = {
    Utils = require('modules/Utils'),
    from = Vector4.new(0, 0, 0, 1),
    to = Vector4.new(0, 0, 0, 1),
    result = Vector4.new(0, 0, 0, 1),
    viewSize = 0
}

---Render Offsets calculation panel
---@param formatter string
---@param enableReplacer boolean
function Offsets:render(formatter, enableReplacer)
    self.viewSize = self.Utils.getViewSize()

    if ImGui.CollapsingHeader("Offsets Calculator") then
        local player = Game.GetPlayer()
        local playerPos = player and player:GetWorldPosition()

        -- Quick helper buttons
        if playerPos then
            if ImGui.Button("Copy Player -> From") then
                self.from = Vector4.new(playerPos.x, playerPos.y, playerPos.z, 1.0)
            end
            ImGui.SameLine()
            if ImGui.Button("Copy Player -> To") then
                self.to = Vector4.new(playerPos.x, playerPos.y, playerPos.z, 1.0)
            end
            ImGui.SameLine()
            if ImGui.Button("Reset") then
                self.from = Vector4.new(0, 0, 0, 1)
                self.to = Vector4.new(0, 0, 0, 1)
            end
        end

        ImGui.Separator()

        -- From Inputs
        ImGui.Text("From (Base Point):")
        ImGui.PushItemWidth(90 * self.viewSize)
        self.from.x = self.Utils.handleVector4Input("From", "x", self.from)
        ImGui.SameLine()
        self.from.y = self.Utils.handleVector4Input("From", "y", self.from)
        ImGui.SameLine()
        self.from.z = self.Utils.handleVector4Input("From", "z", self.from)
        ImGui.PopItemWidth()

        -- To Inputs
        ImGui.Text("To (Target Point):")
        ImGui.PushItemWidth(90 * self.viewSize)
        self.to.x = self.Utils.handleVector4Input("To", "x", self.to)
        ImGui.SameLine()
        self.to.y = self.Utils.handleVector4Input("To", "y", self.to)
        ImGui.SameLine()
        self.to.z = self.Utils.handleVector4Input("To", "z", self.to)
        ImGui.PopItemWidth()

        -- Calculation Result
        self.result = self.Utils.calculateVector4DifferenceWithQuat(self.from, self.to, Quaternion.new(0, 0, 0, 1))

        ImGui.Text("Result Offset (Delta):")
        ImGui.PushItemWidth(90 * self.viewSize)
        self.Utils.drawField("ResultX", self.result.x, formatter, enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("ResultY", self.result.y, formatter, enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("ResultZ", self.result.z, formatter, enableReplacer)
        ImGui.PopItemWidth()
    end
end

return Offsets
