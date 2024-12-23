---@class Utils
---@field tooltip function
---@field getViewSize function
---@field setCursorRelative function
Utils = {}

---Calculates the difference between two Vector4 coordinates.
---@param v1 Vector4 The first vector
---@param v2 Vector4 The second vector
---@return Vector4 A new Vector4 representing the difference between v1 and v2
function Utils:calculateVectorDifference(v1, v2)
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

---@return number
function Utils:getViewSize()
    return ImGui.GetFontSize() / 15
end

---@param x any
---@param y any
function Utils:setCursorRelative(x, y)
    local xC, yC = ImGui.GetMousePos()
    local viewSize = Utils:getViewSize()
    ImGui.SetNextWindowPos(xC + x * viewSize, yC + y * viewSize, ImGuiCond.Always)
end

---@param text any
function Utils:tooltip(text)
    if ImGui.IsItemHovered() then
        Utils:setCursorRelative(8, 8)

        ImGui.SetTooltip(text)
    end
end

---Handles input fields for a Vector4.
---@param name string The name prefix for the UI elements
---@param prop string The property of the Vector4 to edit
---@param vector Vector4 The Vector4 object being edited
---@return float
function Utils:handleVector4Input(name, prop, vector)
    -- Create a UI input box
    local input, updated = ImGui.InputTextWithHint(
        "##" .. name .. prop,
        name .. " " .. prop,
        tostring(vector[prop]), -- Convert the current value to a string for the input box
        128
    )

    -- If the value is updated, try to convert it to a number and assign it
    if updated then
        local normalized = string.gsub(input, ",", ".")
        local numValue = tonumber(normalized) -- Convert string to number
        if numValue then
            return numValue
        end
    end
    return vector[prop]
end

return Utils;
