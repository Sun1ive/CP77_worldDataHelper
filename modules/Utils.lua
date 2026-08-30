---@class Utils
---@field tooltip function
---@field getViewSize function
---@field setCursorRelative function
---@field parseUserData function
---@field isNotEmpty function
local Utils = {}

---Checks if a value is not nil, empty, or None
---@param value any
---@return boolean
function Utils.isNotEmpty(value)
    return value ~= nil and value ~= 0 and value ~= '' and value ~= 'None'
end

---Parse userdata / object for debugging
---@param t any
---@return string
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

---Helper function to stringify a vector
---@param vector table Vector2, Vector3, Vector4
---@return string
function Utils.stringifyVector(vector)
    if not vector then return "" end
    local components = {}
    for _, key in ipairs({"x", "y", "z"}) do
        if vector[key] ~= nil then
            table.insert(components, string.format("%.4f", vector[key]))
        end
    end
    return table.concat(components, ", ")
end

---Show on-screen warning message safely
---@param msg string
function Utils.UIshowWarningMsg(msg)
    pcall(function()
        local text = gameSimpleScreenMessage.new()
        text.duration = 1.5
        text.message = tostring(msg)
        text.isInstant = true
        text.isShown = true
        local bb = Game.GetBlackboardSystem()
        if bb then
            local defs = GetAllBlackboardDefs()
            if defs and defs.UI_Notifications then
                bb:Get(defs.UI_Notifications):SetVariant(
                    defs.UI_Notifications.WarningMessage, ToVariant(text), true)
            end
        end
    end)
end

---Show on-screen notification message safely
---@param msg string
function Utils.UIshowNotificationMsg(msg)
    pcall(function()
        local text = gameSimpleScreenMessage.new()
        text.duration = 1.5
        text.message = tostring(msg)
        text.isInstant = true
        text.isShown = true
        local bb = Game.GetBlackboardSystem()
        if bb then
            local defs = GetAllBlackboardDefs()
            if defs and defs.UI_Notifications then
                bb:Get(defs.UI_Notifications):SetVariant(
                    defs.UI_Notifications.OnscreenMessage, ToVariant(text), true)
            end
        end
    end)
end

---Round float
---@param value number
---@param precision integer?
---@return number
function Utils.roundFloat(value, precision)
    if not value then return 0 end
    precision = precision or 4
    local mult = 10 ^ precision
    return math.floor(value * mult + 0.5) / mult
end

---Get responsive view size scalar based on font size
---@return number
function Utils.getViewSize()
    local fontSize = ImGui.GetFontSize()
    if not fontSize or fontSize <= 0 then
        return 1.0
    end
    return fontSize / 15.0
end

---Set cursor position relative to current mouse pos
---@param x number
---@param y number
function Utils.setCursorRelative(x, y)
    local xC, yC = ImGui.GetMousePos()
    local viewSize = Utils.getViewSize()
    ImGui.SetNextWindowPos(xC + x * viewSize, yC + y * viewSize, ImGuiCond.Always)
end

---Display an item tooltip on hover
---@param text string
function Utils.tooltip(text)
    if ImGui.IsItemHovered() then
        Utils.setCursorRelative(8, 8)
        ImGui.SetTooltip(text)
    end
end

---Handles input fields for a Vector4 coordinate component
---@param name string UI element label prefix
---@param prop string Property name ("x", "y", "z", "w")
---@param vector Vector4 Vector being edited
---@return number
function Utils.handleVector4Input(name, prop, vector)
    if not vector then return 0 end
    local text = string.gsub(tostring(vector[prop] or 0), " ", "")
    local input, updated = ImGui.InputTextWithHint("##" .. name .. prop, name .. " " .. prop, text, 256)

    if updated then
        local normalized = string.gsub(input, ",", ".")
        local numValue = tonumber(normalized)
        if numValue then
            return numValue
        end
    end
    return vector[prop] or 0
end

---Draw read-only formatted coordinate field
---@param name string
---@param prop any
---@param formatter string?
---@param replace boolean?
function Utils.drawField(name, prop, formatter, replace)
    formatter = formatter or "%.4f"
    local val = tonumber(prop) or 0
    local text = string.format(formatter, val)
    if replace then
        text = string.gsub(text, "%.", ",")
    end
    ImGui.InputTextWithHint("##" .. name, name, text, #text + 1, ImGuiInputTextFlags.ReadOnly)
    Utils.tooltip(name)
end

---Return the conjugate (inverse for unit quaternion) of a quaternion
---@param quat Quaternion
---@return Quaternion
function Utils.getQuaternionConjugate(quat)
    return Quaternion.new(-quat.i, -quat.j, -quat.k, quat.r)
end

---Transform a world space position into the local coordinate frame of an anchor
---@param anchorPos Vector4 World position of anchor
---@param anchorQuat Quaternion Orientation of anchor
---@param worldPos Vector4 World position to transform
---@return Vector4 Local delta relative to anchor
function Utils.worldToLocal(anchorPos, anchorQuat, worldPos)
    local rawDiff = Vector4.new(worldPos.x - anchorPos.x, worldPos.y - anchorPos.y, worldPos.z - anchorPos.z, 1.0)
    local invQuat = Utils.getQuaternionConjugate(anchorQuat)
    local localVec = Utils.rotateVectorByQuaternion(rawDiff, invQuat)
    return Vector4.new(
        Utils.roundFloat(localVec.x, 4),
        Utils.roundFloat(localVec.y, 4),
        Utils.roundFloat(localVec.z, 4),
        1.0
    )
end

---Transform a local coordinate offset back into world space
---@param anchorPos Vector4 World position of anchor
---@param anchorQuat Quaternion Orientation of anchor
---@param localPos Vector4 Local offset
---@return Vector4 World position
function Utils.localToWorld(anchorPos, anchorQuat, localPos)
    local rotated = Utils.rotateVectorByQuaternion(localPos, anchorQuat)
    return Vector4.new(
        anchorPos.x + rotated.x,
        anchorPos.y + rotated.y,
        anchorPos.z + rotated.z,
        1.0
    )
end

---Calculates the local difference between two Vector4 coordinates accounting for quaternion rotation
---@param v1 Vector4 Base point
---@param v2 Vector4 Target point
---@param rotationQuat Quaternion? Rotation quaternion of v1 (default identity)
---@return Vector4 Local delta from v1 to v2
function Utils.calculateVector4DifferenceWithQuat(v1, v2, rotationQuat)
    if not v1 or not v2 then
        error("Both vectors must be provided.")
    end
    rotationQuat = rotationQuat or Quaternion.new(0, 0, 0, 1)
    return Utils.worldToLocal(v1, rotationQuat, v2)
end

---Rotates a Vector4 by a given quaternion: v' = q * v * q^-1
---@param vec Vector4
---@param quat Quaternion
---@return Vector4
function Utils.rotateVectorByQuaternion(vec, quat)
    local qi, qj, qk, qr = quat.i, quat.j, quat.k, quat.r
    local vx, vy, vz = vec.x, vec.y, vec.z

    local ix = qr * vx + qj * vz - qk * vy
    local iy = qr * vy + qk * vx - qi * vz
    local iz = qr * vz + qi * vy - qj * vx
    local iw = -qi * vx - qj * vy - qk * vz

    local ci = -qi
    local cj = -qj
    local ck = -qk
    local cr = qr

    local rx = ix * cr + iw * ci + iy * ck - iz * cj
    local ry = iy * cr + iw * cj + iz * ci - ix * ck
    local rz = iz * cr + iw * ck + ix * cj - iy * ci

    return Vector4.new(rx, ry, rz, vec.w or 1.0)
end

---Parse lookup query string to uint64 hash
---@param lookupQuery string
---@return any
function Utils.parseLookupHash(lookupQuery)
    if not lookupQuery then return nil end
    local lookupHex = lookupQuery:match('^0x([0-9A-Fa-f]+)$')
    if lookupHex ~= nil then
        return loadstring('return 0x' .. lookupHex .. 'ULL', '')()
    end

    local lookupDec = lookupQuery:match('^(%d+)ULL$') or lookupQuery:match('^(%d+)$')
    if lookupDec ~= nil then
        return loadstring('return ' .. lookupDec .. 'ULL', '')()
    end

    return nil
end

return Utils
