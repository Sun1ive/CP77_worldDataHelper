local Utils = require("modules/Utils")
local Cron = require("modules/Cron")

local f = string.format
mod = {
    ready = false,
    tppToggle = false,
    savedPosition = nil,
    positionOffset = nil,
}

---Calculates the difference between two Vector4 coordinates.
---@param v1 Vector4 The first vector
---@param v2 Vector4 The second vector
---@return Vector4 A new Vector4 representing the difference between v1 and v2
local function calculateVectorDifference(v1, v2)
    -- Ensure both vectors are provided
    if not v1 or not v2 then
        error("Both vectors must be provided.")
    end

    -- Calculate the differences for each component
    local diff = Vector4.new(
        v1.x - v2.x,
        v1.y - v2.y,
        v1.z - v2.z,
        v1.w - v2.w -- Optional fourth component
    )

    return diff
end

registerForEvent('onDraw', function()
    local player = Game.GetPlayer()
    local position = player.GetWorldPosition(player)
    local orient = player.GetWorldOrientation(player)
    -- bail early if player doesn't exists
    if not player then
        return
    end

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
            tpptoggle = not tpptoggle
            if tpptoggle then
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
                savedPosition = player.GetWorldPosition(player)
                print(savedPosition.x .. "\n" .. savedPosition.y .. "\n" .. savedPosition.z)
            end
        end
        ImGui.SameLine()
        if savedPosition then
            if ImGui.Button("Calc offset") then
                positionOffset = calculateVectorDifference(savedPosition, position)
            end
        end
        ImGui.PopItemWidth()

        ImGui.Separator()
        if positionOffset then
            ImGui.PushItemWidth(80 * viewSize)
            drawField("X", positionOffset.x)
            ImGui.SameLine()
            drawField("Y", positionOffset.y)
            ImGui.SameLine()
            drawField("Z", positionOffset.z)
            ImGui.PopItemWidth()
        end
    end
    ImGui.End()
end)


-- return mod info
-- for communication between mods
return mod
