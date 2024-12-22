local Utils = {}

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

return Utils;
