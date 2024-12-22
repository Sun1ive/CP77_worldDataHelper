worldDataHelper = {
    GameUI = require("modules/GameUI"),
    Utils = require("modules/Utils"),

    tppToggle = false,
    savedPosition = nil,
    positionOffset = nil,
    player = nil,
    cetOpen = false,
    inGame = false,
    inMenu = false,
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
        self.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.cetOpen = false
    end)

    registerForEvent('onDraw', function()
        if self.inGame and not self.inMenu then
            local player = Game.GetPlayer()
            local position = player.GetWorldPosition(player)
            local orient = player.GetWorldOrientation(player)

            local viewSize = ImGui.GetFontSize() / 15

            local function setCursorRelative(x, y)
                local xC, yC = ImGui.GetMousePos()
                ImGui.SetNextWindowPos(xC + x * viewSize, yC + y * viewSize, ImGuiCond.Always)
            end

            local function tooltip(text)
                if ImGui.IsItemHovered() then
                    setCursorRelative(8, 8)

                    ImGui.SetTooltip(text)
                end
            end

            local function drawField(name, prop)
                local formatText = "%.9f"
                local text = string.gsub(string.format(formatText, prop), "%.", ",")
                ImGui.InputTextWithHint("##" .. name, name, text, #text + 1, ImGuiInputTextFlags.ReadOnly)
                tooltip(name)
            end

            ImGui.SetNextWindowPos(100, 100, ImGuiCond.FirstUseEver)  -- set window position x, y
            ImGui.SetNextWindowSize(100, 100, ImGuiCond.FirstUseEver) -- set window size w, h

            if ImGui.Begin("World Position Helper") then
                ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)
                ImGui.PushItemWidth(80 * viewSize)
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
            end
            ImGui.End()
        end
    end)
end

return worldDataHelper:new()
