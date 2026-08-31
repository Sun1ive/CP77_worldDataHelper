---@class Widget
---@field visible boolean
---@field compact boolean
---@field locked boolean
---@field showYaw boolean
---@field showOrientation boolean
---@field backgroundAlpha number
---@field copyFormat number 0 = Vector4, 1 = Raw x, y, z, 2 = Labelled X, Y, Z
---@field formatter string
---@field enableReplacer boolean
---@field viewSize number
local Widget = {
    Utils = require('modules/Utils'),
    visible = false,
    compact = true,
    locked = false,
    showYaw = false,
    showOrientation = false,
    backgroundAlpha = 0.70,
    copyFormat = 0,
    formatter = "%.3f",
    enableReplacer = false,
    viewSize = 1.0
}

---Format a coordinate number with active formatter and separator replacer
---@param val number
---@param fmt string
---@param replace boolean
---@return string
local function formatCoordinate(val, fmt, replace)
    local text = string.format(fmt, tonumber(val) or 0)
    if replace then
        text = string.gsub(text, "%.", ",")
    end
    return text
end

---Copy position coordinates to clipboard based on configured format
---@param pos Vector4
function Widget:copyCoordinates(pos)
    if not pos then return end
    local text = ""
    if self.copyFormat == 0 then
        text = string.format("Vector4.new(%.3f, %.3f, %.3f, 1.0)", pos.x, pos.y, pos.z)
    elseif self.copyFormat == 1 then
        text = string.format("%.3f, %.3f, %.3f", pos.x, pos.y, pos.z)
    else
        text = string.format("X: %.3f, Y: %.3f, Z: %.3f", pos.x, pos.y, pos.z)
    end

    ImGui.SetClipboardText(text)
    self.Utils.UIshowNotificationMsg("Coordinates copied to clipboard!")
end

---Render the Coordinates HUD Widget
---@param isOverlay boolean True if CET overlay is currently open
---@param parentFormatter string? Formatter inherited from main UI
---@param parentReplacer boolean? Decimal replacer inherited from main UI
function Widget:render(isOverlay, parentFormatter, parentReplacer)
    if not self.visible then
        return
    end

    local player = Game.GetPlayer()
    if not player then
        return
    end

    self.viewSize = self.Utils.getViewSize()
    local position = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()
    if not position then
        return
    end

    local activeFmt = self.formatter or parentFormatter or "%.3f"
    local activeReplacer = (parentReplacer ~= nil) and parentReplacer or self.enableReplacer

    local windowFlags = ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoCollapse
    if self.locked then
        windowFlags = windowFlags + ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoResize
    end
    if not isOverlay then
        windowFlags = windowFlags + ImGuiWindowFlags.NoFocusOnAppearing
    end

    ImGui.SetNextWindowPos(30 * self.viewSize, 30 * self.viewSize, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowBgAlpha(self.backgroundAlpha)

    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 8 * self.viewSize, 6 * self.viewSize)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5 * self.viewSize, 4 * self.viewSize)

    local title = "Coordinates HUD##WDH_CoordWidget"
    if ImGui.Begin(title, windowFlags) then
        ImGui.PushStyleColor(ImGuiCol.Text, 0xFFE0E0E0)

        local posXStr = formatCoordinate(position.x, activeFmt, activeReplacer)
        local posYStr = formatCoordinate(position.y, activeFmt, activeReplacer)
        local posZStr = formatCoordinate(position.z, activeFmt, activeReplacer)

        if self.compact then
            -- -------------------------------------------------------------
            -- Compact Horizontal HUD Layout
            -- -------------------------------------------------------------
            ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "X:")
            ImGui.SameLine()
            ImGui.Text(posXStr)
            ImGui.SameLine()

            ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "Y:")
            ImGui.SameLine()
            ImGui.Text(posYStr)
            ImGui.SameLine()

            ImGui.TextColored(1.0, 0.8, 0.4, 1.0, "Z:")
            ImGui.SameLine()
            ImGui.Text(posZStr)

            if self.showYaw and orient then
                local euler = orient:ToEulerAngles()
                local yawStr = string.format("%.1f°", euler.yaw)
                if activeReplacer then
                    yawStr = string.gsub(yawStr, "%.", ",")
                end
                ImGui.SameLine()
                ImGui.TextColored(1.0, 0.5, 0.8, 1.0, "Yaw:")
                ImGui.SameLine()
                ImGui.Text(yawStr)
            end

            ImGui.SameLine()
            if ImGui.SmallButton("Copy##WDH_WidgetCopy") then
                self:copyCoordinates(position)
            end
            self.Utils.tooltip("Copy coordinates to clipboard")
        else
            -- -------------------------------------------------------------
            -- Detailed Layout
            -- -------------------------------------------------------------
            ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "World Position:")

            ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "  X: ")
            ImGui.SameLine()
            ImGui.Text(posXStr)

            ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "  Y: ")
            ImGui.SameLine()
            ImGui.Text(posYStr)

            ImGui.TextColored(1.0, 0.8, 0.4, 1.0, "  Z: ")
            ImGui.SameLine()
            ImGui.Text(posZStr)

            if self.showYaw and orient then
                local euler = orient:ToEulerAngles()
                local yawStr = string.format("%.2f°", euler.yaw)
                if activeReplacer then
                    yawStr = string.gsub(yawStr, "%.", ",")
                end
                ImGui.TextColored(1.0, 0.5, 0.8, 1.0, "  Yaw:")
                ImGui.SameLine()
                ImGui.Text(yawStr)
            end

            if self.showOrientation and orient then
                ImGui.Separator()
                ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Orientation (Quat):")
                local iStr = formatCoordinate(orient.i, activeFmt, activeReplacer)
                local jStr = formatCoordinate(orient.j, activeFmt, activeReplacer)
                local kStr = formatCoordinate(orient.k, activeFmt, activeReplacer)
                local rStr = formatCoordinate(orient.r, activeFmt, activeReplacer)
                ImGui.Text(string.format("  I: %s  J: %s", iStr, jStr))
                ImGui.Text(string.format("  K: %s  R: %s", kStr, rStr))
            end

            ImGui.Spacing()
            if ImGui.Button("Copy Vector4##WDH_WidgetCopyV4") then
                self:copyCoordinates(position)
            end
        end

        -- Overlay-only quick toggles
        if isOverlay then
            ImGui.Separator()
            if ImGui.SmallButton(self.compact and "Expand##WDH_Mode" or "Compact##WDH_Mode") then
                self.compact = not self.compact
            end
            ImGui.SameLine()
            if ImGui.SmallButton(self.locked and "Unlock##WDH_Lock" or "Lock##WDH_Lock") then
                self.locked = not self.locked
            end
            ImGui.SameLine()
            if ImGui.SmallButton("Hide##WDH_Close") then
                self.visible = false
            end
        end

        ImGui.PopStyleColor()
    end
    ImGui.End()

    ImGui.PopStyleVar(2)
end

return Widget
