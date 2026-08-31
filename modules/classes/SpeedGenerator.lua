---@class SpeedSection
---@field start number Distance from spline start where transition begins (m)
---@field endPos number Distance where target speed is reached (m)
---@field speed number Target speed in meters per second (m/s)

---@class SpeedGenerator
---@field sections SpeedSection[]
---@field minSpeed number
---@field maxSpeed number
---@field cruiseSpeed number
---@field startSpeed number
---@field endSpeed number
---@field stepDist number
---@field accelDist number
---@field decelDist number
---@field sensitivity number
---@field jitterAmount number
---@field currentStrategy integer 0 = Curvature, 1 = Trapezoid, 2 = Linear Ramp, 3 = Uniform, 4 = Traffic Jitter
local SpeedGenerator = {
    Utils = require('modules/Utils'),
    sections = {},
    minSpeed = 3.0,
    maxSpeed = 15.0,
    cruiseSpeed = 12.0,
    startSpeed = 2.0,
    endSpeed = 2.0,
    stepDist = 10.0,
    accelDist = 15.0,
    decelDist = 20.0,
    sensitivity = 0.8,
    jitterAmount = 2.5,
    currentStrategy = 0
}

---Calculate 3D Euclidean distance between two Vector4 points
---@param p1 Vector4
---@param p2 Vector4
---@return number
function SpeedGenerator.getDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local dz = p2.z - p1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---Calculate cumulative distances along a list of waypoints
---@param points Vector4[]
---@return number totalLength Total length in meters
---@return number[] cumulative Cumulative distance at each point index
function SpeedGenerator:calculateCumulativeDistances(points)
    local cumulative = { 0 }
    local totalLength = 0

    if not points or #points < 2 then
        return 0, cumulative
    end

    for i = 2, #points do
        local dist = self.getDistance(points[i - 1], points[i])
        totalLength = totalLength + dist
        table.insert(cumulative, totalLength)
    end

    return totalLength, cumulative
end

---Calculate angular turn in radians (0 = straight, pi/2 = 90 deg, pi = 180 deg) at each interior waypoint
---@param points Vector4[]
---@return number[] angles Array of turn angles in radians per point (index 1 and N are 0)
function SpeedGenerator:calculateAngles(points)
    local angles = {}
    if not points or #points < 2 then
        return angles
    end

    table.insert(angles, 0) -- Point 1 has no incoming turn

    for i = 2, #points - 1 do
        local pPrev = points[i - 1]
        local pCurr = points[i]
        local pNext = points[i + 1]

        local v1x = pCurr.x - pPrev.x
        local v1y = pCurr.y - pPrev.y
        local v1z = pCurr.z - pPrev.z
        local len1 = math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z)

        local v2x = pNext.x - pCurr.x
        local v2y = pNext.y - pCurr.y
        local v2z = pNext.z - pCurr.z
        local len2 = math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z)

        if len1 > 0.001 and len2 > 0.001 then
            local dot = (v1x * v2x + v1y * v2y + v1z * v2z) / (len1 * len2)
            dot = math.max(-1.0, math.min(1.0, dot))
            local angle = math.acos(dot) -- Radians
            table.insert(angles, angle)
        else
            table.insert(angles, 0)
        end
    end

    table.insert(angles, 0) -- Last point has no outgoing turn
    return angles
end

---Generate speedChangeSections dynamically based on corner curvature
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generateCurvatureAdaptive(points)
    self.sections = {}
    if not points or #points < 2 then
        return self.sections
    end

    local totalLength, cumulative = self:calculateCumulativeDistances(points)
    local angles = self:calculateAngles(points)

    if totalLength <= 0.01 then
        return self.sections
    end

    -- Base section at start
    table.insert(self.sections, {
        start = 0.0,
        endPos = math.min(cumulative[2] or 5.0, totalLength),
        speed = self.maxSpeed
    })

    for i = 2, #points - 1 do
        local angle = angles[i]
        local turnFactor = (angle / math.pi) * self.sensitivity
        turnFactor = math.max(0.0, math.min(1.0, turnFactor))

        local targetSpeed = self.maxSpeed - (self.maxSpeed - self.minSpeed) * turnFactor
        targetSpeed = self.Utils.roundFloat(math.max(self.minSpeed, targetSpeed), 2)

        local currDist = cumulative[i]
        local prevDist = cumulative[i - 1]
        local nextDist = cumulative[i + 1]

        -- Deceleration into corner
        local startDist = math.max(0, currDist - (currDist - prevDist) * 0.5)
        local endDist = math.min(totalLength, currDist + (nextDist - currDist) * 0.5)

        table.insert(self.sections, {
            start = self.Utils.roundFloat(startDist, 2),
            endPos = self.Utils.roundFloat(endDist, 2),
            speed = targetSpeed
        })
    end

    -- Return to max speed at end of spline
    if #self.sections > 0 then
        local lastSection = self.sections[#self.sections]
        if lastSection.endPos < totalLength then
            table.insert(self.sections, {
                start = lastSection.endPos,
                endPos = self.Utils.roundFloat(totalLength, 2),
                speed = self.maxSpeed
            })
        end
    end

    return self.sections
end

---Generate a Trapezoid profile: Ease-In -> Cruise -> Ease-Out
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generateTrapezoid(points)
    self.sections = {}
    if not points or #points < 2 then
        return self.sections
    end

    local totalLength, _ = self:calculateCumulativeDistances(points)
    if totalLength <= 0.01 then
        return self.sections
    end

    local actualAccel = math.min(self.accelDist, totalLength * 0.4)
    local actualDecel = math.min(self.decelDist, totalLength * 0.4)
    local cruiseStart = actualAccel
    local cruiseEnd = math.max(cruiseStart, totalLength - actualDecel)

    -- 1. Acceleration section
    table.insert(self.sections, {
        start = 0.0,
        endPos = self.Utils.roundFloat(cruiseStart, 2),
        speed = self.Utils.roundFloat(self.cruiseSpeed, 2)
    })

    -- 2. Cruise section
    if cruiseEnd > cruiseStart + 1.0 then
        table.insert(self.sections, {
            start = self.Utils.roundFloat(cruiseStart, 2),
            endPos = self.Utils.roundFloat(cruiseEnd, 2),
            speed = self.Utils.roundFloat(self.cruiseSpeed, 2)
        })
    end

    -- 3. Deceleration section
    if cruiseEnd < totalLength then
        table.insert(self.sections, {
            start = self.Utils.roundFloat(cruiseEnd, 2),
            endPos = self.Utils.roundFloat(totalLength, 2),
            speed = self.Utils.roundFloat(self.endSpeed, 2)
        })
    end

    return self.sections
end

---Generate a Linear Ramp: smoothly transitions from startSpeed to endSpeed
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generateLinearRamp(points)
    self.sections = {}
    if not points or #points < 2 then
        return self.sections
    end

    local totalLength, _ = self:calculateCumulativeDistances(points)
    if totalLength <= 0.01 then
        return self.sections
    end

    local step = math.max(2.0, self.stepDist)
    local numSteps = math.max(2, math.ceil(totalLength / step))

    for i = 1, numSteps do
        local startPos = (i - 1) * (totalLength / numSteps)
        local endPos = i * (totalLength / numSteps)
        local t = (i / numSteps)
        local speed = self.startSpeed + (self.endSpeed - self.startSpeed) * t

        table.insert(self.sections, {
            start = self.Utils.roundFloat(startPos, 2),
            endPos = self.Utils.roundFloat(endPos, 2),
            speed = self.Utils.roundFloat(speed, 2)
        })
    end

    return self.sections
end

---Generate Uniform Segments with fixed speed
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generateUniform(points)
    self.sections = {}
    if not points or #points < 2 then
        return self.sections
    end

    local totalLength, _ = self:calculateCumulativeDistances(points)
    if totalLength <= 0.01 then
        return self.sections
    end

    local step = math.max(2.0, self.stepDist)
    local numSteps = math.max(1, math.ceil(totalLength / step))

    for i = 1, numSteps do
        local startPos = (i - 1) * (totalLength / numSteps)
        local endPos = i * (totalLength / numSteps)

        table.insert(self.sections, {
            start = self.Utils.roundFloat(startPos, 2),
            endPos = self.Utils.roundFloat(endPos, 2),
            speed = self.Utils.roundFloat(self.cruiseSpeed, 2)
        })
    end

    return self.sections
end

---Generate Traffic Jitter: realistic speed variations along the path
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generateTrafficJitter(points)
    self.sections = {}
    if not points or #points < 2 then
        return self.sections
    end

    local totalLength, _ = self:calculateCumulativeDistances(points)
    if totalLength <= 0.01 then
        return self.sections
    end

    local step = math.max(3.0, self.stepDist)
    local numSteps = math.max(2, math.ceil(totalLength / step))

    for i = 1, numSteps do
        local startPos = (i - 1) * (totalLength / numSteps)
        local endPos = i * (totalLength / numSteps)
        local jitter = (math.random() * 2.0 - 1.0) * self.jitterAmount
        local speed = math.max(1.0, self.cruiseSpeed + jitter)

        table.insert(self.sections, {
            start = self.Utils.roundFloat(startPos, 2),
            endPos = self.Utils.roundFloat(endPos, 2),
            speed = self.Utils.roundFloat(speed, 2)
        })
    end

    return self.sections
end

---Generate sections based on current selected strategy
---@param points Vector4[]
---@return SpeedSection[]
function SpeedGenerator:generate(points)
    if self.currentStrategy == 0 then
        return self:generateCurvatureAdaptive(points)
    elseif self.currentStrategy == 1 then
        return self:generateTrapezoid(points)
    elseif self.currentStrategy == 2 then
        return self:generateLinearRamp(points)
    elseif self.currentStrategy == 3 then
        return self:generateUniform(points)
    elseif self.currentStrategy == 4 then
        return self:generateTrafficJitter(points)
    else
        return self:generateCurvatureAdaptive(points)
    end
end

---Add a manual speed change section
---@param startPos number
---@param endPos number
---@param speed number
function SpeedGenerator:addSection(startPos, endPos, speed)
    table.insert(self.sections, {
        start = self.Utils.roundFloat(startPos or 0, 2),
        endPos = self.Utils.roundFloat(endPos or 10, 2),
        speed = self.Utils.roundFloat(speed or self.cruiseSpeed, 2)
    })
end

---Remove section by index
---@param index integer
function SpeedGenerator:removeSection(index)
    if index and self.sections[index] then
        table.remove(self.sections, index)
    end
end

---Clear all speed change sections
function SpeedGenerator:clear()
    self.sections = {}
end

---Format speedChangeSections for WolvenKit REDengine 4 worldSpeedSplineNode
---@return table
function SpeedGenerator:toWolvenKitData()
    local output = {}
    for _, sec in ipairs(self.sections) do
        table.insert(output, {
            ["$type"] = "worldSpeedSplineNodeSpeedChangeSection",
            ["start"] = sec.start,
            ["end"] = sec.endPos,
            ["targetSpeed_M_P_S"] = sec.speed
        })
    end
    return output
end

---Export speedChangeSections to formatted JSON string
---@return string
function SpeedGenerator:toJsonString()
    local data = self:toWolvenKitData()
    return json.encode(data)
end

return SpeedGenerator
