---@class UI
---@field render function
---@field viewSize number
---@field formatter string
---@field formatType number
---@field enableReplacer boolean
UI = {
    version = "0.0.8",
    Utils = require('modules/Utils'),
    Recorder = require('modules/ui/Recorder'),
    Teleport = require('modules/ui/Teleport'),
    Offsets = require('modules/ui/Offsets'),

    tppToggle = false,
    formatType = 0,
    formatter = "%.9f",

    viewSize = 0,
    replacerState = 1, -- 1 = on; 0 = off
    enableReplacer = true
}

function UI:render()
    if self.viewSize == 0 then
        self.viewSize = self.Utils:getViewSize()
    end

    local player = Game.GetPlayer()
    local position = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()

    ImGui.SetNextWindowPos(100, 100, ImGuiCond.FirstUseEver) -- set window position x, y
    ImGui.SetNextWindowSize(100, 100, ImGuiCond.FirstUseEver) -- set window size w, h

    if ImGui.Begin("World Position Helper") then
        ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)

        ImGui.PushItemWidth(100 * self.viewSize)
        self.formatType = ImGui.RadioButton("%.9f", self.formatType, 0)
        ImGui.SameLine()
        self.formatType = ImGui.RadioButton("%.2f", self.formatType, 1)
        ImGui.PopItemWidth()

        if self.formatType == 0 then
            self.formatter = "%.9f"
        else
            self.formatter = "%.2f"
        end

        ImGui.PushItemWidth(100 * self.viewSize)
        ImGui.TextWrapped("Enable replacer . for ,")
        self.replacerState = ImGui.RadioButton("On", self.replacerState, 1)
        ImGui.SameLine()
        self.replacerState = ImGui.RadioButton("Off", self.replacerState, 0)

        if self.replacerState == 0 then
            self.enableReplacer = false
        else
            self.enableReplacer = true
        end
        ImGui.PopItemWidth()

        if self.formatType == 0 then
            self.formatter = "%.9f"
        else
            self.formatter = "%.2f"
        end

        ImGui.Separator()

        ImGui.PushItemWidth(100 * self.viewSize)
        self.Utils.drawField("X", position.x, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("Y", position.y, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("Z", position.z, self.formatter, self.enableReplacer)
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(80 * self.viewSize)
        self.Utils.drawField("I", orient.i, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("J", orient.j, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("K", orient.k, self.formatter, self.enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("R", orient.r, self.formatter, self.enableReplacer)
        ImGui.PopItemWidth()

        ImGui.Separator()

        ImGui.PushItemWidth(80 * self.viewSize)
        if ImGui.Button("Toggle TPP") then
            self.tppToggle = not self.tppToggle
            if self.tppToggle then
                player:GetFPPCameraComponent():SetLocalPosition(Vector4.new(-0.5, -2, 0, 1.0))
                player:GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
            else
                player:GetFPPCameraComponent():SetLocalPosition(Vector4.new(0.0, 0, 0, 1.0))
                player:GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
            end
        end

        ImGui.Separator()

        self.Offsets:render(self.formatter, self.enableReplacer)

        self.Recorder:render()

        self.Teleport:render()

    end
    ImGui.End()

end

return UI
