-- require("modules/GameSession")
-- mod info
mod = {
    ready = false
}

-- print on load
print('My Mod is loaded!')

-- onInit event
registerForEvent('onInit', function()
    -- set as ready
    mod.ready = true

    -- print on initialize
    print('My Mod is initialized!')
end)

registerForEvent('onDraw', function()
    local player = Game.GetPlayer()
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
        local coords = player.GetWorldPosition(player)
        local orient = player.GetWorldOrientation(player)
        ImGui.PushStyleColor(ImGuiCol.Text, 0xFFA5A19B)
        ImGui.PushItemWidth(80 * viewSize)
        drawField("X", coords.x)
        ImGui.SameLine()
        drawField("Y", coords.y)
        ImGui.SameLine()
        drawField("Z", coords.z)
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
    end
    ImGui.End()
end)


-- return mod info
-- for communication between mods
return mod
