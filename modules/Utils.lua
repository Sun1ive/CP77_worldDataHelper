---@class Utils
---@field tooltip function
---@field getViewSize function
---@field setCursorRelative function
---@field parseUserData function
Utils = {}

function Utils.isNotEmpty(value)
    return value ~= nil and value ~= 0 and value ~= '' and value ~= 'None'
end

--- parse userdata
---@param t any
function Utils.parseUserData(t)
    local tstr = tostring(t)

    if tstr:find('^ToCName{') then
        tstr = NameToString(t)
    elseif tstr:find('^userdata:') or tstr:find('^sol%.') then

        local gdump = false
        local ddump = false
        pcall(function()
            gdump = GameDump(t)
        end)
        pcall(function()
            ddump = Dump(t, true)
        end)

        if gdump then
            tstr = GameDump(t)
        elseif ddump then
            tstr = ddump
        end
    end

    return tstr

end

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
    local text = string.gsub(tostring(vector[prop]), " ", "")
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

---Calculates the difference between two Vector4 coordinates, accounting for rotation using a quaternion.
---@param v1 Vector4 The first vector (base point)
---@param v2 Vector4 The second vector (target point)
---@param rotationQuat Quaternion The quaternion representing rotation of v1 (using i, j, k, r)
---@return Vector4 DVector new Vector4 representing the adjusted difference between v1 and v2
function Utils.calculateVector4DifferenceWithQuat(v1, v2, rotationQuat)
    -- Ensure both vectors are provided
    if not v1 or not v2 then
        error("Both vectors must be provided.")
    end

    -- Ensure a valid quaternion is provided
    if not rotationQuat then
        error("Rotation quaternion must be provided.")
    end

    -- Step 1: Calculate the raw difference
    local dx = v2.x - v1.x
    local dy = v2.y - v1.y
    local dz = v2.z - v1.z
    local rawDiff = Vector4.new(dx, dy, dz, 1.0)

    -- Step 2: Apply the quaternion rotation to the raw difference
    local adjustedDiff = Utils.rotateVectorByQuaternion(rawDiff, rotationQuat)

    -- Step 3: Return the adjusted vector
    return Vector4.new(Utils.roundFloat(adjustedDiff.x, 4), Utils.roundFloat(adjustedDiff.y, 4),
        Utils.roundFloat(adjustedDiff.z, 4), 1.0)
end

---Rotates a Vector4 by a given quaternion.
---@param vec Vector4 The vector to rotate
---@param quat Quaternion The quaternion to use for rotation (using i, j, k, r)
---@return Vector4 The rotated vector
function Utils.rotateVectorByQuaternion(vec, quat)
    -- Quaternion rotation formula: v' = q * v * q^-1
    local qi, qj, qk, qr = quat.i, quat.j, quat.k, quat.r
    local vx, vy, vz = vec.x, vec.y, vec.z

    -- Quaternion-vector multiplication
    local ix = qr * vx + qj * vz - qk * vy
    local iy = qr * vy + qk * vx - qi * vz
    local iz = qr * vz + qi * vy - qj * vx
    local iw = -qi * vx - qj * vy - qk * vz

    -- Conjugate of the quaternion
    local ci = -qi
    local cj = -qj
    local ck = -qk
    local cr = qr

    -- Quaternion-vector-conjugate multiplication
    local rx = ix * cr + iw * ci + iy * ck - iz * cj
    local ry = iy * cr + iw * cj + iz * ci - ix * ck
    local rz = iz * cr + iw * ck + ix * cj - iy * ci

    -- Return the rotated vector
    return Vector4.new(rx, ry, rz, vec.w)
end

-- credit to psiberx
function Utils.parseLookupHash(lookupQuery)
    local lookupHex = lookupQuery:match('^0x([0-9A-F]+)$')
    if lookupHex ~= nil then
        return loadstring('return 0x' .. lookupHex .. 'ULL', '')()
    end

    local lookupDec = lookupQuery:match('^(%d+)ULL$') or lookupQuery:match('^(%d+)$')
    if lookupDec ~= nil then
        return loadstring('return ' .. lookupDec .. 'ULL', '')()
    end

    return nil
end

return Utils;
