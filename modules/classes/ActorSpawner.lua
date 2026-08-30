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
---@field spawnedRecord string
---@field spawnTag string
---@field lastDist number
---@field stuckTimer number
---@field liveActorPos Vector4?
---@field liveTargetPos Vector4?
---@field initialized boolean
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
    tolerance = 1.5,
    characterRecord = "Character.Panam",
    spawnedRecord = "",
    spawnTag = "CP77_worldDataHelper_Actor",
    lastDist = -1,
    stuckTimer = 0,
    liveActorPos = nil,
    liveTargetPos = nil,
    initialized = false
}

---Initialize EntityBuilder Observe hooks for instant attachment
function ActorSpawner:init()
    if self.initialized then
        return
    end

    pcall(function()
        Observe('EntityBuilder', 'OnAttached', function(_, event)
            if not event or type(event.GetEntity) ~= "function" then
                return
            end

            local entity = nil
            pcall(function()
                entity = event:GetEntity()
            end)

            if entity and self.actorEntityID and entity:GetEntityID().hash == self.actorEntityID.hash then
                self.actorHandle = entity
                self.liveActorPos = entity:GetWorldPosition()
                print(string.format("[CP77_worldDataHelper] Test actor attached in engine: %s", tostring(self.characterRecord)))

                if self.isTesting and #self.points > 0 then
                    local targetIndex = (#self.points > 1) and 2 or 1
                    self.currentPointIndex = targetIndex
                    self:sendMoveCommand(self.points[targetIndex])
                end
            end
        end)
        self.initialized = true
    end)
end

---Find the spawned actor entity handle
---@return NPCPuppet?
function ActorSpawner:getActor()
    if self.actorHandle and IsDefined(self.actorHandle) then
        return self.actorHandle
    end

    if self.actorEntityID then
        local entity = Game.FindEntityByID(self.actorEntityID)
        if entity and IsDefined(entity) then
            self.actorHandle = entity
            return entity
        end

        local staticSystem = Game.GetStaticEntitySystem()
        if staticSystem then
            local sEntity = staticSystem:GetEntity(self.actorEntityID)
            if sEntity and IsDefined(sEntity) then
                self.actorHandle = sEntity
                return sEntity
            end
        end
    end
    return nil
end

---Convert any list of points (relative or absolute) to absolute world coordinates
---@param rawPoints Vector4[]
---@param positionType integer? 0 = absolute, 1 = relative
---@param anchorPos Vector4?
---@param anchorOrient Quaternion?
---@return Vector4[]
---@return boolean isRelative
function ActorSpawner:resolveWorldPoints(rawPoints, positionType, anchorPos, anchorOrient)
    local worldPoints = {}
    if not rawPoints or #rawPoints == 0 then
        return worldPoints, false
    end

    local player = Game.GetPlayer()
    local pPos = player and player:GetWorldPosition() or Vector4.new(0, 0, 0, 1)
    local pOrient = player and player:GetWorldOrientation() or Quaternion.new(0, 0, 0, 1)

    local effectiveAnchor = anchorPos or pPos
    local effectiveOrient = anchorOrient or pOrient

    local isRelative = false
    if positionType == 1 then
        isRelative = true
    elseif positionType == 0 then
        isRelative = false
    else
        local pt1 = rawPoints[1]
        if math.abs(pt1.x) < 0.05 and math.abs(pt1.y) < 0.05 and math.abs(pt1.z) < 0.05 then
            isRelative = true
        end
    end

    if isRelative then
        for _, pt in ipairs(rawPoints) do
            local worldPt = self.Utils.localToWorld(effectiveAnchor, effectiveOrient, pt)
            table.insert(worldPoints, worldPt)
        end
    else
        for _, pt in ipairs(rawPoints) do
            table.insert(worldPoints, Vector4.new(pt.x, pt.y, pt.z, 1.0))
        end
    end

    return worldPoints, isRelative
end

---Spawn test actor using Codeware DynamicEntitySystem at target coordinates
---@param record string? TweakDB character record
---@param pos Vector4
---@param orient Quaternion?
---@return boolean
function ActorSpawner:spawnActor(record, pos, orient)
    self:init()

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

    -- If actor is already alive in world with the same record, teleport to pos
    local existingActor = self:getActor()
    if existingActor and self.spawnedRecord == charRecord then
        self:stopMovement()
        self:teleportActor(pos, orient:ToEulerAngles().yaw)
        self.liveActorPos = Vector4.new(pos.x, pos.y, pos.z, 1.0)
        self.Utils.UIshowNotificationMsg(string.format("Teleported %s to WP #1", charRecord))
        return true
    end

    -- Despawn previous entity cleanly if record changed or dead
    self:despawnActor()

    local success = false
    pcall(function()
        local dynamicSystem = Game.GetDynamicEntitySystem()
        if dynamicSystem then
            local spec = DynamicEntitySpec.new()
            spec.recordID = TweakDBID.new(charRecord)
            spec.position = Vector4.new(pos.x, pos.y, pos.z, 1.0)
            spec.orientation = orient
            spec.alwaysSpawned = true
            spec.appearanceName = CName.new("default")
            spec.tags = { self.spawnTag }

            self.actorEntityID = dynamicSystem:CreateEntity(spec)
            self.spawnedRecord = charRecord
            self.liveActorPos = Vector4.new(pos.x, pos.y, pos.z, 1.0)
            success = true
            print(string.format("[CP77_worldDataHelper] DynamicEntity requested: %s at (X: %.2f, Y: %.2f, Z: %.2f)",
                charRecord, pos.x, pos.y, pos.z))
            self.Utils.UIshowNotificationMsg(string.format("Spawned %s on WP #1", charRecord))
        end
    end)

    return success
end

---Despawn the active test actor
function ActorSpawner:despawnActor()
    self.isTesting = false
    self.isPaused = false
    self.currentPointIndex = 1
    self.lastDist = -1
    self.stuckTimer = 0
    self.liveActorPos = nil
    self.liveTargetPos = nil

    if self.actorEntityID then
        pcall(function()
            local dynamicSystem = Game.GetDynamicEntitySystem()
            if dynamicSystem then
                dynamicSystem:DeleteEntity(self.actorEntityID)
            end
        end)
        self.actorEntityID = nil
    end

    self.actorHandle = nil
    self.spawnedRecord = ""
end

---Stop active AI movement commands
function ActorSpawner:stopMovement()
    local actor = self:getActor()
    if not actor then return end

    pcall(function()
        local stopCmd = AIStopCommand.new()
        local ai = actor:GetAIControllerComponent()
        if ai then
            ai:SendCommand(stopCmd)
        end
    end)
end

---Halt active spline test without despawning actor
function ActorSpawner:stopSplineTest()
    self.isTesting = false
    self.isPaused = false
    self.currentPointIndex = 1
    self.lastDist = -1
    self.stuckTimer = 0
    self:stopMovement()
    self.Utils.UIshowNotificationMsg("Spline test stopped")
end

---Send an AI move command to the actor using engine AIPositionSpec
---@param targetPos Vector4
function ActorSpawner:sendMoveCommand(targetPos)
    local actor = self:getActor()
    if not actor then
        return
    end

    self.liveTargetPos = Vector4.new(targetPos.x, targetPos.y, targetPos.z, 1.0)

    pcall(function()
        local dest = NewObject("WorldPosition")
        dest:SetVector4(dest, Vector4.new(targetPos.x, targetPos.y, targetPos.z, 1.0))

        local positionSpec = NewObject("AIPositionSpec")
        positionSpec:SetWorldPosition(positionSpec, dest)

        local cmd = NewObject("handle:AIMoveToCommand")
        cmd.movementTarget = positionSpec
        cmd.rotateEntityTowardsFacingTarget = false
        cmd.ignoreNavigation = false
        cmd.desiredDistanceFromTarget = self.tolerance
        cmd.movementType = self.moveSpeed
        cmd.finishWhenDestinationReached = true

        local aiComponent = actor:GetAIControllerComponent()
        if aiComponent then
            aiComponent:SendCommand(cmd)
        end
    end)
end

---Teleport actor safely to a target waypoint
---@param targetPos Vector4
---@param targetYaw number?
function ActorSpawner:teleportActor(targetPos, targetYaw)
    local actor = self:getActor()
    if not actor then return end

    targetYaw = targetYaw or 0
    pcall(function()
        if actor:IsA("NPCPuppet") then
            local cmd = AITeleportCommand.new()
            cmd.position = Vector4.new(targetPos.x, targetPos.y, targetPos.z, 1.0)
            cmd.rotation = targetYaw
            cmd.doNavTest = false
            local ai = actor:GetAIControllerComponent()
            if ai then
                ai:SendCommand(cmd)
            end
        else
            Game.GetTeleportationFacility():Teleport(actor, targetPos, EulerAngles.new(0, 0, targetYaw))
        end
    end)
end

---Start testing the recorded spline, resolving coordinates and positioning actor at waypoint #1
---@param rawPoints Vector4[]
---@param positionType integer 0 = absolute, 1 = relative
---@param anchorPos Vector4?
---@param anchorOrient Quaternion?
function ActorSpawner:startSplineTest(rawPoints, positionType, anchorPos, anchorOrient)
    self:init()

    if not rawPoints or #rawPoints == 0 then
        self.Utils.UIshowWarningMsg("No waypoints recorded to test!")
        return
    end

    local worldPoints, isRelative = self:resolveWorldPoints(rawPoints, positionType, anchorPos, anchorOrient)
    self.points = worldPoints

    local firstWaypoint = self.points[1]
    local startOrient = anchorOrient or (Game.GetPlayer() and Game.GetPlayer():GetWorldOrientation()) or Quaternion.new(0, 0, 0, 1)

    print(string.format("[CP77_worldDataHelper] Spline test started: %d points (%s mode). WP#1: (%.2f, %.2f, %.2f)",
        #self.points, isRelative and "Relative" or "Absolute", firstWaypoint.x, firstWaypoint.y, firstWaypoint.z))

    self.currentPointIndex = (#self.points > 1) and 2 or 1
    self.isTesting = true
    self.isPaused = false
    self.lastDist = -1
    self.stuckTimer = 0

    local actor = self:getActor()
    if not actor or self.spawnedRecord ~= self.characterRecord then
        self:spawnActor(self.characterRecord, firstWaypoint, startOrient)
    else
        self:stopMovement()
        self:teleportActor(firstWaypoint, startOrient:ToEulerAngles().yaw)
        local targetPt = self.points[self.currentPointIndex]
        self:sendMoveCommand(targetPt)
    end

    self.Utils.UIshowNotificationMsg(string.format("Testing spline: heading to WP #%d", self.currentPointIndex))
end

---Pause spline traversal
function ActorSpawner:pauseSplineTest()
    self.isPaused = true
    self:stopMovement()
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
    local actor = self:getActor()
    if actor then
        pcall(function()
            self.liveActorPos = actor:GetWorldPosition()
        end)
    end

    if not self.isTesting or self.isPaused or #self.points == 0 then
        return
    end

    if not actor then
        actor = self:getActor()
        if not actor then return end
    end

    local targetPt = self.points[self.currentPointIndex]
    if not targetPt or not self.liveActorPos then
        return
    end

    -- Calculate distance to target waypoint
    local dx = targetPt.x - self.liveActorPos.x
    local dy = targetPt.y - self.liveActorPos.y
    local dz = targetPt.z - self.liveActorPos.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    self.lastDist = dist

    -- Periodically refresh move command if actor is moving
    self.stuckTimer = self.stuckTimer + dt
    if self.stuckTimer >= 1.5 then
        self.stuckTimer = 0
        self:sendMoveCommand(targetPt)
    end

    if dist <= self.tolerance then
        if self.currentPointIndex < #self.points then
            self.currentPointIndex = self.currentPointIndex + 1
            local nextPt = self.points[self.currentPointIndex]
            self:sendMoveCommand(nextPt)
            print(string.format("[CP77_worldDataHelper] Reached WP #%d -> Heading to WP #%d (Dist: %.2fm)",
                self.currentPointIndex - 1, self.currentPointIndex, dist))
        else
            if self.isLooping then
                self.currentPointIndex = 1
                self:sendMoveCommand(self.points[1])
                print("[CP77_worldDataHelper] Spline loop completed -> returning to Waypoint #1")
            else
                self.isTesting = false
                self.Utils.UIshowNotificationMsg("Spline traversal completed!")
                print("[CP77_worldDataHelper] Spline traversal completed successfully.")
            end
        end
    end
end

---Render real-time actor coordinate & progress debug panel with copy support
---@param viewSize number
function ActorSpawner:renderDebugPanel(viewSize)
    ImGui.Separator()
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Actor Live Debug Monitor:")

    local actor = self:getActor()
    local isAlive = (actor ~= nil and IsDefined(actor))

    if isAlive then
        ImGui.TextColored(0.2, 1.0, 0.2, 1.0, string.format("● Actor: ALIVE (%s)", self.characterRecord))
        if self.liveActorPos then
            ImGui.Text("Actor Pos:")
            ImGui.SameLine()
            ImGui.PushItemWidth(80 * viewSize)
            self.Utils.drawField("ActorX", self.liveActorPos.x, "%.4f", false)
            ImGui.SameLine()
            self.Utils.drawField("ActorY", self.liveActorPos.y, "%.4f", false)
            ImGui.SameLine()
            self.Utils.drawField("ActorZ", self.liveActorPos.z, "%.4f", false)
            ImGui.PopItemWidth()

            ImGui.SameLine()
            if ImGui.Button("Copy Actor Pos") then
                local text = string.format("Vector4.new(%.4f, %.4f, %.4f, 1.0)",
                    self.liveActorPos.x, self.liveActorPos.y, self.liveActorPos.z)
                ImGui.SetClipboardText(text)
                self.Utils.UIshowNotificationMsg("Copied Actor Position to Clipboard")
            end
        end
    else
        if self.actorEntityID then
            ImGui.TextColored(1.0, 0.8, 0.2, 1.0, "◌ Actor: Spawning / Attaching...")
        else
            ImGui.TextColored(1.0, 0.3, 0.3, 1.0, "○ Actor: NOT SPAWNED")
        end
    end

    if self.isTesting and #self.points > 0 then
        local targetPt = self.points[self.currentPointIndex]
        if targetPt then
            ImGui.Text(string.format("Target WP #%02d:", self.currentPointIndex))
            ImGui.SameLine()
            ImGui.PushItemWidth(80 * viewSize)
            self.Utils.drawField("TargetX", targetPt.x, "%.4f", false)
            ImGui.SameLine()
            self.Utils.drawField("TargetY", targetPt.y, "%.4f", false)
            ImGui.SameLine()
            self.Utils.drawField("TargetZ", targetPt.z, "%.4f", false)
            ImGui.PopItemWidth()

            ImGui.SameLine()
            if ImGui.Button("Copy Target WP") then
                local text = string.format("Vector4.new(%.4f, %.4f, %.4f, 1.0)",
                    targetPt.x, targetPt.y, targetPt.z)
                ImGui.SetClipboardText(text)
                self.Utils.UIshowNotificationMsg("Copied Target Waypoint to Clipboard")
            end
        end

        if self.lastDist >= 0 then
            ImGui.Text(string.format("Distance to WP: %.2f meters (Tolerance: %.1fm)", self.lastDist, self.tolerance))
        end

        local statusStr = string.format("Status: Moving (%s)", self.moveSpeed)
        if self.isPaused then statusStr = "Status: PAUSED" end
        ImGui.TextColored(1.0, 0.9, 0.2, 1.0, statusStr)

        ImGui.SameLine()
        if ImGui.Button("Copy All Debug Info") then
            local info = string.format("Actor: %s\nActor Pos: (%.4f, %.4f, %.4f)\nTarget WP #%d: (%.4f, %.4f, %.4f)\nDistance: %.2fm\nSpeed: %s\nStatus: %s",
                self.characterRecord,
                self.liveActorPos and self.liveActorPos.x or 0,
                self.liveActorPos and self.liveActorPos.y or 0,
                self.liveActorPos and self.liveActorPos.z or 0,
                self.currentPointIndex,
                targetPt and targetPt.x or 0,
                targetPt and targetPt.y or 0,
                targetPt and targetPt.z or 0,
                self.lastDist,
                self.moveSpeed,
                self.isPaused and "PAUSED" or "MOVING")
            ImGui.SetClipboardText(info)
            self.Utils.UIshowNotificationMsg("Copied Full Debug Info to Clipboard")
        end
    end
end

return ActorSpawner
