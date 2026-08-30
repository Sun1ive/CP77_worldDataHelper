---@class UI
---@field version string
---@field formatter string
---@field formatType number
---@field enableReplacer boolean
---@field viewSize number
local UI = {
    version = "0.0.9",
    Utils = require('modules/Utils'),
    Teleport = require('modules/ui/Teleport'),
    Offsets = require('modules/ui/Offsets'),
    Recorder = require('modules/ui/Recorder'),

    tppToggle = false,
    formatType = 0,
    formatter = "%.9f",
    replacerState = 1,
    enableReplacer = true,
    viewSize = 0
}

---Main UI render loop called from CET onDraw
function UI:render()
    self.viewSize = self.Utils.getViewSize()

    local player = Game.GetPlayer()
    if not player then
        return
    end

    local position = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()

    ImGui.SetNextWindowPos(120, 120, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(380 * self.viewSize, 520 * self.viewSize, ImGuiCond.FirstUseEver)

    if ImGui.Begin("World Position Helper v" .. self.version) then
        ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)

        -- Precision Selector
        ImGui.Text("Precision:")
        ImGui.SameLine()
        ImGui.PushItemWidth(90 * self.viewSize)
        self.formatType = ImGui.RadioButton("%.9f", self.formatType, 0)
        ImGui.SameLine()
        self.formatType = ImGui.RadioButton("%.4f", self.formatType, 1)
        ImGui.SameLine()
        self.formatType = ImGui.RadioButton("%.2f", self.formatType, 2)
        ImGui.PopItemWidth()

        if self.formatType == 0 then
            self.formatter = "%.9f"
        elseif self.formatType == 1 then
            self.formatter = "%.4f"
        else
            self.formatter = "%.2f"
        end

        -- Decimal Separator Replacer
        ImGui.Text("Decimal separator (, for .):")
        ImGui.SameLine()
        ImGui.PushItemWidth(70 * self.viewSize)
        self.replacerState = ImGui.RadioButton("On", self.replacerState, 1)
        ImGui.SameLine()
        self.replacerState = ImGui.RadioButton("Off", self.replacerState, 0)
        ImGui.PopItemWidth()
        self.enableReplacer = (self.replacerState == 1)

        ImGui.Separator()

        -- Current Player Position
        ImGui.Text("Player World Position:")
        ImGui.PushItemWidth(95 * self.viewSize)
        self.Utils.drawField("X", position.x, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("Y", position.y, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("Z", position.z, self.formatter, self.enableReplacer)
        ImGui.PopItemWidth()

        -- Current Player Orientation
        ImGui.Text("Player World Orientation (Quaternion):")
        ImGui.PushItemWidth(70 * self.viewSize)
        self.Utils.drawField("I", orient.i, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("J", orient.j, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("K", orient.k, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("R", orient.r, self.formatter, self.enableReplacer)
        ImGui.PopItemWidth()

        ImGui.Separator()

        -- Camera View Toggle
        if ImGui.Button("Toggle TPP Camera") then
            self.tppToggle = not self.tppToggle
            pcall(function()
                local camera = player:GetFPPCameraComponent()
                if camera then
                    if self.tppToggle then
                        camera:SetLocalPosition(Vector4.new(-0.5, -2.0, 0.0, 1.0))
                        camera:SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
                    else
                        camera:SetLocalPosition(Vector4.new(0.0, 0.0, 0.0, 1.0))
                        camera:SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
                    end
                end
            end)
        end

        ImGui.Separator()

        -- Subpanels
        self.Offsets:render(self.formatter, self.enableReplacer)
        self.Teleport:render()
        self.Recorder:render()

        ImGui.PopStyleColor()
    end
    ImGui.End()
end

return UI
