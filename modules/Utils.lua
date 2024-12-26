---@class Utils
---@field tooltip function
---@field getViewSize function
---@field setCursorRelative function
Utils = {}

--- Helper function to stringify a vector
--- @param vector table A vector object (Vector2, Vector3, Vector4)
--- @return string The stringified vector
function Utils.stringifyVector(vector)
    local components = {}
    for _, key in ipairs({"x", "y", "z"}) do
        if vector[key] ~= nil then
            table.insert(components, tostring(vector[key]))
        end
    end

    return table.concat(components, ", ")
end

---Show warning message
---@param msg string
function Utils.UIshowWarningMsg(msg)
    local text = gameSimpleScreenMessage.new()
    text.duration = 1.0
    text.message = msg
    text.isInstant = true
    text.isShown = true
    Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UI_Notifications):SetVariant(
        GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(text), true)
end

---Show notification message
---@param msg string
function Utils.UIshowNotificationMsg(msg)
    local text = gameSimpleScreenMessage.new()
    text.duration = 1.0
    text.message = msg
    text.isInstant = true
    text.isShown = true
    Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UI_Notifications):SetVariant(
        GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(text), true)
end

---Round float
---@param value number
---@param precision integer -- 1 | 2 | 3 | 4 | etc
function Utils.roundFloat(value, precision)
    local formatStr = string.format("%%.%df", precision)
    local converted = tonumber(string.format(formatStr, value))
    return converted
end

---Calculates the difference between two Vector4 coordinates.
---@param v1 Vector4 The first vector
---@param v2 Vector4 The second vector
---@return Vector4 DVector new Vector4 representing the difference between v1 and v2
function Utils.calculateVector4Difference(v1, v2)
    -- Ensure both vectors are provided
    if not v1 or not v2 then
        error("Both vectors must be provided.")
    end

    local x1, y1, z1 = Utils.roundFloat(v1.x, 4), Utils.roundFloat(v1.y, 4), Utils.roundFloat(v1.z, 4)
    local x2, y2, z2 = Utils.roundFloat(v2.x, 4), Utils.roundFloat(v2.y, 4), Utils.roundFloat(v2.z, 4)

    return Vector4.new(x1 - x2, y1 - y2, z1 - z2, 1.0)
end

---@return number
function Utils.getViewSize()
    return ImGui.GetFontSize() / 15
end

---@param x any
---@param y any
function Utils.setCursorRelative(x, y)
    local xC, yC = ImGui.GetMousePos()
    local viewSize = Utils.getViewSize()
    ImGui.SetNextWindowPos(xC + x * viewSize, yC + y * viewSize, ImGuiCond.Always)
end

---@param text any
function Utils.tooltip(text)
    if ImGui.IsItemHovered() then
        Utils.setCursorRelative(8, 8)

        ImGui.SetTooltip(text)
    end
end

---Handles input fields for a Vector4.
---@param name string The name prefix for the UI elements
---@param prop string The property of the Vector4 to edit
---@param vector Vector4 The Vector4 object being edited
---@return float
function Utils.handleVector4Input(name, prop, vector)
    local text = tostring(vector[prop])
    local input, updated = ImGui.InputTextWithHint("##" .. name .. prop, name .. " " .. prop, text, 256)

    if updated then
        local normalized = string.gsub(input, ",", ".")
        local numValue = tonumber(normalized) -- Convert string to number
        if numValue then
            return numValue
        end
    end
    return vector[prop]
end

---ImGui.InputTextWithHint DrawField
---@param name string
---@param prop any
---@param formatter string
---@param replace boolean?
function Utils.drawField(name, prop, formatter, replace)
    local text = string.format(formatter, prop)
    if replace ~= nil and replace == true then
        text = string.gsub(text, "%.", ",")
    end
    ImGui.InputTextWithHint("##" .. name, name, text, #text + 1, ImGuiInputTextFlags.ReadOnly)
    Utils.tooltip(name)
end

return Utils;
