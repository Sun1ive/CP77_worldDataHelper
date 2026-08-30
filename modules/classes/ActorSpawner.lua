---@class ActorSpawner
---@field actorEntityID entEntityID?
---@field actorHandle NPCPuppet?
---@field isTesting boolean
---@field isPaused boolean
---@field isLooping boolean
---@field currentPointIndex integer
---@field points Vector4[]
---@field moveSpeed string "Walk" | "Jog" | "Sprint"
---@field tolerance number
---@field characterRecord string
---@field isSpawning boolean
local ActorSpawner = {
    Utils = require('modules/Utils'),
    actorEntityID = nil,
    actorHandle = nil,
    isTesting = false,
    isPaused = false,
    isLooping = false,
    currentPointIndex = 1,
    points = {},
    moveSpeed = "Jog",
    tolerance = 1.8,
    characterRecord = "Character.Panam",
    isSpawning = false
}

---Find the spawned actor entity in world
---@return NPCPuppet?
function ActorSpawner:getActor()
    if self.actorHandle and IsDefined(self.actorHandle) then
        return self.actorHandle
    end

    if self.actorEntityID then
        local entity = Game.FindEntityByID(self.actorEntityID)
        if IsDefined(entity) then
            self.actorHandle = entity
            return entity
        end
    end
    return nil
end

---Spawn a test actor at the given position and orientation
---@param record string? TweakDB character record
---@param pos Vector4
---@param orient Quaternion?
---@return boolean
function ActorSpawner:spawnActor(record, pos, orient)
    self:despawnActor()

    local charRecord = record or self.characterRecord
    if not charRecord or charRecord == "" then
        charRecord = "Character.Panam"
    end
    self.characterRecord = charRecord

    local player = Game.GetPlayer()
    if not pos and player then
        pos = player:GetWorldPosition()
    end
    if not orient and player then
        orient = player:GetWorldOrientation()
    end

    if not pos or not orient then
        self.Utils.UIshowWarningMsg("Invalid spawn coordinates")
        return false
    end

    local success = false
    pcall(function()
        local transform = WorldTransform.new()
        transform:SetPosition(pos)
        transform:SetOrientation(orient)

        local spawnSystem = Game.GetPreventionSpawnSystem()
        if spawnSystem then
            local tweakID = TweakDBID.new(charRecord)
            self.actorEntityID = spawnSystem:RequestSpawn(tweakID, -1, transform)
            self.isSpawning = true
            success = true
            print(string.format("[CP77_worldDataHelper] Requested spawn for %s at %.2f, %.2f, %.2f",
                charRecord, pos.x, pos.y, pos.z))
            self.Utils.UIshowNotificationMsg(string.format("Spawned %s for spline test", charRecord))
        end
    end)

    return success
end

---Despawn the active test actor
function ActorSpawner:despawnActor()
    self.isTesting = false
    self.isPaused = false
    self.currentPointIndex = 1

    local actor = self:getActor()
    if actor then
        pcall(function()
            actor:Dispose()
        end)
    end

    if self.actorEntityID then
        pcall(function()
            local spawnSystem = Game.GetPreventionSpawnSystem()
            if spawnSystem and spawnSystem.DespawnEntity then
                spawnSystem:DespawnEntity(self.actorEntityID)
            end
        end)
    end

    self.actorEntityID = nil
    self.actorHandle = nil
    self.isSpawning = false
end

---Send an AI move command to the actor for a given target position
---@param targetPos Vector4
function ActorSpawner:sendMoveCommand(targetPos)
    local actor = self:getActor()
    if not actor then
        return
    end

    pcall(function()
        local moveCmd = AIMoveToCommand.new()
        moveCmd.movementTarget = targetPos
        moveCmd.movementType = self.moveSpeed
        moveCmd.rotateEntityTowardsFacingDirection = true
        moveCmd.ignoreNavigation = false
        moveCmd.tolerance = self.tolerance

        local aiComponent = actor:GetAIControllerComponent()
        if aiComponent then
            aiComponent:SendCommand(moveCmd)
        end
    end)
end

---Start testing the recorded spline with the spawned actor
---@param rawPoints Vector4[]
---@param positionType integer 0 = absolute, 1 = relative
---@param anchorPos Vector4?
---@param anchorOrient Quaternion?
function ActorSpawner:startSplineTest(rawPoints, positionType, anchorPos, anchorOrient)
    if not rawPoints or #rawPoints == 0 then
        self.Utils.UIshowWarningMsg("No waypoints recorded to test!")
        return
    end

    -- Convert points to absolute world coordinates if relative
    self.points = {}
    if positionType == 1 and anchorPos and anchorOrient then
        for _, pt in ipairs(rawPoints) do
            local rotated = self.Utils.rotateVectorByQuaternion(pt, anchorOrient)
            local worldPt = Vector4.new(anchorPos.x + rotated.x, anchorPos.y + rotated.y, anchorPos.z + rotated.z, 1.0)
            table.insert(self.points, worldPt)
        end
    else
        for _, pt in ipairs(rawPoints) do
            table.insert(self.points, Vector4.new(pt.x, pt.y, pt.z, 1.0))
        end
    end

    local startPos = self.points[1]
    local startOrient = anchorOrient or (Game.GetPlayer() and Game.GetPlayer():GetWorldOrientation()) or Quaternion.new(0, 0, 0, 1)

    -- Spawn actor at initial waypoint if not already spawned
    local actor = self:getActor()
    if not actor then
        self:spawnActor(self.characterRecord, startPos, startOrient)
    end

    self.currentPointIndex = 1
    self.isTesting = true
    self.isPaused = false

    -- Issue first move command
    self:sendMoveCommand(self.points[1])
    self.Utils.UIshowNotificationMsg(string.format("Spline test started with %s (%d points)", self.characterRecord, #self.points))
end

---Pause spline traversal
function ActorSpawner:pauseSplineTest()
    self.isPaused = true
    local actor = self:getActor()
    if actor then
        pcall(function()
            local stopCmd = AIStopCommand.new()
            local aiComponent = actor:GetAIControllerComponent()
            if aiComponent then
                aiComponent:SendCommand(stopCmd)
            end
        end)
    end
    self.Utils.UIshowNotificationMsg("Spline test paused")
end

---Resume spline traversal
function ActorSpawner:resumeSplineTest()
    self.isPaused = false
    if self.isTesting and self.points[self.currentPointIndex] then
        self:sendMoveCommand(self.points[self.currentPointIndex])
        self.Utils.UIshowNotificationMsg("Spline test resumed")
    end
end

---Tick update called each frame from onUpdate
---@param dt number
function ActorSpawner:update(dt)
    if not self.isTesting or self.isPaused or #self.points == 0 then
        return
    end

    local actor = self:getActor()
    if not actor then
        return
    end

    local targetPt = self.points[self.currentPointIndex]
    if not targetPt then
        return
    end

    local actorPos = actor:GetWorldPosition()
    if not actorPos then
        return
    end

    -- Calculate distance to target waypoint
    local dx = targetPt.x - actorPos.x
    local dy = targetPt.y - actorPos.y
    local dz = targetPt.z - actorPos.z
    local distSq = dx * dx + dy * dy + dz * dz

    if distSq <= (self.tolerance * self.tolerance) then
        -- Reached waypoint, advance to next
        if self.currentPointIndex < #self.points then
            self.currentPointIndex = self.currentPointIndex + 1
            local nextPt = self.points[self.currentPointIndex]
            self:sendMoveCommand(nextPt)
            print(string.format("[CP77_worldDataHelper] Actor reached waypoint #%d -> heading to #%d",
                self.currentPointIndex - 1, self.currentPointIndex))
        else
            -- Reached final waypoint
            if self.isLooping then
                self.currentPointIndex = 1
                self:sendMoveCommand(self.points[1])
                print("[CP77_worldDataHelper] Loop reached end -> returning to waypoint #1")
            else
                self.isTesting = false
                self.Utils.UIshowNotificationMsg("Spline test completed!")
                print("[CP77_worldDataHelper] Spline test completed successfully.")
            end
        end
    end
end

return ActorSpawner
