---@class worldDataHelper
---@field player any
---@field formatter string
---@field savedPosition Vector4?
---@field positionOffset Vector4?
---@field channel integer
worldDataHelper = {
    GameUI = require("modules/GameUI"),
    Utils = require("modules/Utils"),

    renderUi = true,
    tppToggle = false,
    savedPosition = nil,
    positionOffset = nil,
    player = nil,
    isOverlay = false,
    inGame = false,
    inMenu = false,

    radioChannel = 0,
    formatter = "%.9f",

    calculator = {
        from = Vector4.new(0, 0, 0, 1),
        to = Vector4.new(0, 0, 0, 1),
        result = Vector4.new(0, 0, 0, 1)
    }
}

function worldDataHelper:new()
    registerForEvent("onInit", function()
        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu)
            self.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.inGame = true
        end)

        self.GameUI.OnSessionEnd(function()
            self.inGame = false
        end)

        self.inGame = not self.GameUI.IsDetached()
    end)

    registerForEvent("onOverlayOpen", function()
        self.isOverlay = true
    end)

    registerForEvent("onOverlayClose", function()
        self.isOverlay = false
    end)

    registerHotkey('renderUi', 'Render UI Key', function()
        self.renderUi = not self.renderUi
    end)

    registerForEvent('onDraw', function()
        if self.inGame and not self.inMenu and self.renderUi then
            local player = Game.GetPlayer()
            local position = player.GetWorldPosition(player)
            local orient = player.GetWorldOrientation(player)
            local viewSize = self.Utils:getViewSize()

            local function drawField(name, prop)
                local text = string.gsub(string.format(self.formatter, prop), "%.", ",")
                ImGui.InputTextWithHint("##" .. name, name, text, #text + 1, ImGuiInputTextFlags.ReadOnly)
                self.Utils:tooltip(name)
            end

            ImGui.SetNextWindowPos(100, 100, ImGuiCond.FirstUseEver)  -- set window position x, y
            ImGui.SetNextWindowSize(100, 100, ImGuiCond.FirstUseEver) -- set window size w, h

            if ImGui.Begin("World Position Helper") then
                ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)

                ImGui.PushItemWidth(100 * viewSize)
                self.radioChannel = ImGui.RadioButton("%.9f", self.radioChannel, 0)
                ImGui.SameLine()
                self.radioChannel = ImGui.RadioButton("%.2f", self.radioChannel, 1)
                ImGui.PopItemWidth()

                if self.radioChannel == 0 then
                    self.formatter = "%.9f"
                else
                    self.formatter = "%.2f"
                end

                ImGui.Separator()

                ImGui.PushItemWidth(100 * viewSize)
                drawField("X", position.x)
                ImGui.SameLine()
                drawField("Y", position.y)
                ImGui.SameLine()
                drawField("Z", position.z)
                ImGui.PopItemWidth()

                ImGui.PushItemWidth(80 * viewSize)
                drawField("I", orient.i)
                ImGui.SameLine()
                drawField("J", orient.j)
                ImGui.SameLine()
                drawField("K", orient.k)
                ImGui.SameLine()
                drawField("R", orient.r)
                ImGui.PopItemWidth()

                ImGui.Separator()

                ImGui.PushItemWidth(80 * viewSize)
                if ImGui.Button("Toggle TPP") then
                    self.tppToggle = not self.tppToggle
                    if self.tppToggle then
                        Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(-0.5, -2, 0, 1.0))
                        Game.GetPlayer():GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
                    else
                        Game.GetPlayer():GetFPPCameraComponent():SetLocalPosition(Vector4.new(0.0, 0, 0, 1.0))
                        Game.GetPlayer():GetFPPCameraComponent():SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
                    end
                end
                ImGui.SameLine()
                if ImGui.Button("Save Position") then
                    if player then
                        self.savedPosition = player.GetWorldPosition(player)
                        print(self.savedPosition.x .. "\n" .. self.savedPosition.y .. "\n" .. self.savedPosition.z)
                    end
                end
                ImGui.SameLine()
                if self.savedPosition then
                    if ImGui.Button("Calc offset") then
                        self.positionOffset = self.Utils:calculateVectorDifference(position, self.savedPosition)
                    end
                end
                ImGui.PopItemWidth()

                ImGui.Separator()

                if self.positionOffset then
                    ImGui.PushItemWidth(100 * viewSize)
                    drawField("X-offset", self.positionOffset.x)
                    ImGui.SameLine()
                    drawField("Y-offset", self.positionOffset.y)
                    ImGui.SameLine()
                    drawField("Z-offset", self.positionOffset.z)
                    ImGui.PopItemWidth()
                end

                ImGui.Separator()

                if ImGui.CollapsingHeader("offsets") then
                    ImGui.PushItemWidth(300 * viewSize)
                    ImGui.Text("From X")
                    ImGui.SameLine()
                    ImGui.Text("From Y")
                    ImGui.SameLine()
                    ImGui.Text("From Z")
                    ImGui.PopItemWidth()

                    ImGui.PushItemWidth(100 * viewSize)
                    self.calculator.from.x = Utils:handleVector4Input("From", "x", self.calculator.from)
                    ImGui.SameLine()
                    self.calculator.from.y = Utils:handleVector4Input("From", "y", self.calculator.from)
                    ImGui.SameLine()
                    self.calculator.from.z = Utils:handleVector4Input("From", "z", self.calculator.from)
                    ImGui.PopItemWidth()

                    ImGui.PushItemWidth(300 * viewSize)
                    ImGui.Text("To X")
                    ImGui.SameLine()
                    ImGui.Text("To Y")
                    ImGui.SameLine()
                    ImGui.Text("To Z")
                    ImGui.PopItemWidth()

                    ImGui.PushItemWidth(100 * viewSize)
                    -- Optionally do the same for `to` Vector4
                    self.calculator.to.x = Utils:handleVector4Input("To", "x", self.calculator.to)
                    ImGui.SameLine()
                    self.calculator.to.y = Utils:handleVector4Input("To", "y", self.calculator.to)
                    ImGui.SameLine()
                    self.calculator.to.z = Utils:handleVector4Input("To", "z", self.calculator.to)
                    ImGui.PopItemWidth()

                    ImGui.PushItemWidth(300 * viewSize)
                    ImGui.Text("Result X")
                    ImGui.SameLine()
                    ImGui.Text("Result Y")
                    ImGui.SameLine()
                    ImGui.Text("Result Z")
                    ImGui.PopItemWidth()

                    ImGui.PushItemWidth(100 * viewSize)
                    local result = Utils:calculateVectorDifference(self.calculator.from, self.calculator.to)
                    drawField("ResultX", result.x)
                    ImGui.SameLine()
                    drawField("ResultY", result.y)
                    ImGui.SameLine()
                    drawField("ResultZ", result.z)
                    ImGui.PopItemWidth()
                end
            end
            ImGui.End()
        end
    end)
end

return worldDataHelper:new()
