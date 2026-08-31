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
    SpeedSections = require('modules/ui/SpeedSections'),
    Widget = require('modules/ui/Widget'),

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

    -- Link recorder to speed sections
    if not self.SpeedSections.Recorder then
        self.SpeedSections:init(self.Recorder)
    end

    local position = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()

    ImGui.SetNextWindowPos(120, 120, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSize(520 * self.viewSize, 580 * self.viewSize, ImGuiCond.FirstUseEver)

    if ImGui.Begin("World Data Helper v" .. self.version) then
        ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)

        if ImGui.BeginTabBar("WorldDataHelperTabs", ImGuiTabBarFlags.None) then
            -- -------------------------------------------------------------
            -- TAB 1: Player & Transform Info
            -- -------------------------------------------------------------
            if ImGui.BeginTabItem("Player Transform") then
                ImGui.Spacing()

                -- Precision Selector
                ImGui.Text("Precision:")
                ImGui.SameLine()
                ImGui.PushItemWidth(90 * self.viewSize)
                self.formatType = ImGui.RadioButton("%.9f", self.formatType, 0)
                ImGui.SameLine()
                self.formatType = ImGui.RadioButton("%.4f", self.formatType, 1)
                ImGui.SameLine()
                self.formatType = ImGui.RadioButton("%.3f", self.formatType, 2)
                ImGui.SameLine()
                self.formatType = ImGui.RadioButton("%.2f", self.formatType, 3)
                ImGui.PopItemWidth()

                if self.formatType == 0 then
                    self.formatter = "%.9f"
                elseif self.formatType == 1 then
                    self.formatter = "%.4f"
                elseif self.formatType == 2 then
                    self.formatter = "%.3f"
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
                ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Player World Position:")
                ImGui.PushItemWidth(100 * self.viewSize)
                self.Utils.drawField("X", position.x, self.formatter, self.enableReplacer)
                ImGui.SameLine()
                self.Utils.drawField("Y", position.y, self.formatter, self.enableReplacer)
                ImGui.SameLine()
                self.Utils.drawField("Z", position.z, self.formatter, self.enableReplacer)
                ImGui.PopItemWidth()

                if ImGui.Button("Copy Position Vector4") then
                    local text = string.format("Vector4.new(%.4f, %.4f, %.4f, 1.0)", position.x, position.y, position.z)
                    ImGui.SetClipboardText(text)
                    self.Utils.UIshowNotificationMsg("Copied Position to Clipboard")
                end

                ImGui.Separator()

                -- Current Player Orientation
                ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Player World Orientation (Quaternion):")
                ImGui.PushItemWidth(75 * self.viewSize)
                self.Utils.drawField("I", orient.i, self.formatter, self.enableReplacer)
                ImGui.SameLine()
                self.Utils.drawField("J", orient.j, self.formatter, self.enableReplacer)
                ImGui.SameLine()
                self.Utils.drawField("K", orient.k, self.formatter, self.enableReplacer)
                ImGui.SameLine()
                self.Utils.drawField("R", orient.r, self.formatter, self.enableReplacer)
                ImGui.PopItemWidth()

                if ImGui.Button("Copy Orientation Quat") then
                    local text = string.format("Quaternion.new(%.4f, %.4f, %.4f, %.4f)", orient.i, orient.j, orient.k, orient.r)
                    ImGui.SetClipboardText(text)
                    self.Utils.UIshowNotificationMsg("Copied Orientation to Clipboard")
                end

                ImGui.Separator()

                -- Camera View Toggle
                ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Camera View:")
                if ImGui.Button(self.tppToggle and "Switch to FPP Camera" or "Switch to TPP Camera") then
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

                -- Coordinates HUD Widget Settings
                ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Coordinates Widget (HUD):")
                self.Widget.visible = ImGui.Checkbox("Show On-Screen Widget", self.Widget.visible)
                ImGui.SameLine()
                self.Widget.compact = ImGui.Checkbox("Compact Mode", self.Widget.compact)
                ImGui.SameLine()
                self.Widget.locked = ImGui.Checkbox("Lock Position", self.Widget.locked)

                if self.Widget.visible then
                    self.Widget.showYaw = ImGui.Checkbox("Show Heading (Yaw)", self.Widget.showYaw)
                    ImGui.SameLine()
                    self.Widget.showOrientation = ImGui.Checkbox("Show Quaternion", self.Widget.showOrientation)
                end

                ImGui.EndTabItem()
            end

            -- -------------------------------------------------------------
            -- TAB 2: Spline Recorder & Test Actor
            -- -------------------------------------------------------------
            if ImGui.BeginTabItem("Spline Recorder") then
                ImGui.Spacing()
                self.Recorder:render()
                ImGui.EndTabItem()
            end

            -- -------------------------------------------------------------
            -- TAB 3: Speed Sections Generator & Editor
            -- -------------------------------------------------------------
            if ImGui.BeginTabItem("Speed Sections") then
                ImGui.Spacing()
                self.SpeedSections:render()
                ImGui.EndTabItem()
            end

            -- -------------------------------------------------------------
            -- TAB 4: Offsets Calculator
            -- -------------------------------------------------------------
            if ImGui.BeginTabItem("Offsets Calculator") then
                ImGui.Spacing()
                self.Offsets:render(self.formatter, self.enableReplacer)
                ImGui.EndTabItem()
            end

            -- -------------------------------------------------------------
            -- TAB 5: Teleport Player
            -- -------------------------------------------------------------
            if ImGui.BeginTabItem("Teleport") then
                ImGui.Spacing()
                self.Teleport:render()
                ImGui.EndTabItem()
            end

            ImGui.EndTabBar()
        end

        ImGui.PopStyleColor()
    end
    ImGui.End()
end

return UI
