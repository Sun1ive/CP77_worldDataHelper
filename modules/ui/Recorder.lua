---@class Recorder
---@field positionType integer 0 = absolute, 1 = relative
---@field isStarted boolean
---@field relativePoint Vector4?
---@field relativeOrient Quaternion?
---@field viewSize number
---@field exportFileName string
---@field speedIndex integer 0 = Walk, 1 = Jog, 2 = Sprint
local Recorder = {
    Utils = require('modules/Utils'),
    Exporter = require('modules/classes/Exporter'),
    Spawner = require('modules/classes/Spawner'),
    ActorSpawner = require('modules/classes/ActorSpawner'),

    ---@type Vector4[]
    points = {},
    positionType = 1,
    isStarted = false,
    relativePoint = nil,
    relativeOrient = nil,
    exportFileName = "recorded_spline.json",
    speedIndex = 1,

    viewSize = 0
}

---Clean up all recorded points, in-world markers, and active test actors
function Recorder:cleanUpPoints()
    self.points = {}
    self.relativePoint = nil
    self.relativeOrient = nil
    self.Spawner:cleanUp()
    self.ActorSpawner:despawnActor()

    pcall(function()
        local service = GameInstance.GetScriptableServiceContainer():GetService("WorldStreamingService")
        if service and service.ClearSpline then
            service:ClearSpline()
        end
    end)

    self.Utils.UIshowNotificationMsg("Points, markers, and test actors cleaned up")
end

---Delete the most recently inserted point
function Recorder:deleteLastPoint()
    if #self.points > 0 then
        table.remove(self.points)
        if #self.points == 0 then
            self.relativePoint = nil
            self.relativeOrient = nil
        end
        self.Utils.UIshowNotificationMsg("Removed last waypoint")
    end
end

---Insert a new waypoint at the player's current position
function Recorder:insertPoint()
    local player = Game.GetPlayer()
    if not player then
        self.Utils.UIshowWarningMsg("Player not available")
        return
    end

    local pos = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()

    -- Spawn visual in-world marker
    self.Spawner:spawn(pos, orient)

    -- Attempt to update streaming service if available
    local function updateSplineService(splineVec)
        pcall(function()
            local service = GameInstance.GetScriptableServiceContainer():GetService("WorldStreamingService")
            if service and service.AddToSpline then
                service:AddToSpline(Vector3.new(splineVec.x, splineVec.y, splineVec.z))
            end
        end)
    end

    if self.positionType == 0 then
        -- Absolute coordinates
        table.insert(self.points, pos)
        self.Utils.UIshowWarningMsg(string.format("Point #%d: %s", #self.points, self.Utils.stringifyVector(pos)))
        updateSplineService(pos)
    else
        -- Relative coordinates
        if #self.points == 0 then
            self.relativePoint = pos
            self.relativeOrient = orient
            local initialPoint = Vector4.new(0, 0, 0, 1)
            table.insert(self.points, initialPoint)
            self.Utils.UIshowWarningMsg(string.format("Point #1 (Anchor): %s", self.Utils.stringifyVector(initialPoint)))
            updateSplineService(initialPoint)
        else
            local delta = self.Utils.calculateVector4DifferenceWithQuat(self.relativePoint, pos, self.relativeOrient)
            table.insert(self.points, delta)
            self.Utils.UIshowWarningMsg(string.format("Point #%d (Rel): %s", #self.points, self.Utils.stringifyVector(delta)))
            updateSplineService(delta)
        end
    end
end

---Export recorded points to JSON file
function Recorder:exportData()
    if #self.points == 0 then
        self.Utils.UIshowWarningMsg("No points to export")
        return
    end

    local array = {}
    for i, pt in ipairs(self.points) do
        table.insert(array, string.format('    {"index": %d, "x": %.6f, "y": %.6f, "z": %.6f}', i, pt.x, pt.y, pt.z))
    end

    local modeStr = self.positionType == 0 and "absolute" or "relative"
    local jsonStr = string.format("{\n  \"mode\": \"%s\",\n  \"count\": %d,\n  \"points\": [\n%s\n  ]\n}",
        modeStr, #self.points, table.concat(array, ",\n"))

    local success, err = self.Exporter.saveFile(self.exportFileName, jsonStr)
    if success then
        print(string.format("[CP77_worldDataHelper] Exported %d points to %s", #self.points, self.exportFileName))
        self.Utils.UIshowNotificationMsg("Exported spline to " .. self.exportFileName)
    else
        print(string.format("[CP77_worldDataHelper] Export error: %s", tostring(err)))
        self.Utils.UIshowWarningMsg("Failed to export: " .. tostring(err))
    end
end

---Update loop for actor spline traversal
---@param dt number
function Recorder:update(dt)
    self.ActorSpawner:update(dt)
end

---Render Recorder UI panel
function Recorder:render()
    self.viewSize = self.Utils.getViewSize()

    if ImGui.CollapsingHeader("Spline / Waypoint Recorder") then
        ImGui.PushItemWidth(100 * self.viewSize)
        self.positionType = ImGui.RadioButton("Absolute", self.positionType, 0)
        ImGui.SameLine()
        self.positionType = ImGui.RadioButton("Relative", self.positionType, 1)
        ImGui.PopItemWidth()

        ImGui.Separator()

        -- Recording Controls
        if not self.isStarted then
            if ImGui.Button("Start Recording") then
                self.isStarted = true
                self:insertPoint()
            end
        else
            if ImGui.Button("Add Waypoint") then
                self:insertPoint()
            end
            ImGui.SameLine()
            if ImGui.Button("Stop Recording") then
                self.isStarted = false
                self:exportData()
            end
            ImGui.SameLine()
            if ImGui.Button("Delete Last") then
                self:deleteLastPoint()
            end
        end

        ImGui.SameLine()
        if ImGui.Button("Clean All") then
            self.isStarted = false
            self:cleanUpPoints()
        end

        ImGui.Spacing()

        -- Export Filename
        ImGui.PushItemWidth(200 * self.viewSize)
        self.exportFileName = ImGui.InputTextWithHint("##ExportFileName", "File name (e.g. spline.json)", self.exportFileName, 128)
        ImGui.PopItemWidth()
        ImGui.SameLine()
        if ImGui.Button("Export JSON") then
            self:exportData()
        end

        ImGui.Separator()

        -- Points Count and Display
        ImGui.Text(string.format("Recorded Points: %d", #self.points))

        if #self.points > 0 then
            if ImGui.BeginChild("PointsList", 0, 120 * self.viewSize, true) then
                for i, point in ipairs(self.points) do
                    ImGui.Text(string.format("#%02d | X: %.4f | Y: %.4f | Z: %.4f", i, point.x, point.y, point.z))
                end
                ImGui.EndChild()
            end
        end

        ImGui.Separator()

        -- -------------------------------------------------------------
        -- Test Actor & Spline Traversal Panel
        -- -------------------------------------------------------------
        ImGui.Text("Test Actor & Spline Traversal:")

        -- Character Record Presets
        ImGui.Text("Actor Record:")
        ImGui.PushItemWidth(220 * self.viewSize)
        self.ActorSpawner.characterRecord = ImGui.InputTextWithHint("##ActorRecord", "Character.Panam", self.ActorSpawner.characterRecord, 128)
        ImGui.PopItemWidth()

        ImGui.SameLine()
        if ImGui.Button("Panam") then
            self.ActorSpawner.characterRecord = "Character.Panam"
        end
        ImGui.SameLine()
        if ImGui.Button("Judy") then
            self.ActorSpawner.characterRecord = "Character.Judy"
        end
        ImGui.SameLine()
        if ImGui.Button("Takemura") then
            self.ActorSpawner.characterRecord = "Character.Takemura"
        end
        ImGui.SameLine()
        if ImGui.Button("Johnny") then
            self.ActorSpawner.characterRecord = "Character.Johnny"
        end

        -- Move Speed Selector
        ImGui.Text("Move Speed:")
        ImGui.PushItemWidth(70 * self.viewSize)
        self.speedIndex = ImGui.RadioButton("Walk", self.speedIndex, 0)
        ImGui.SameLine()
        self.speedIndex = ImGui.RadioButton("Jog", self.speedIndex, 1)
        ImGui.SameLine()
        self.speedIndex = ImGui.RadioButton("Sprint", self.speedIndex, 2)
        ImGui.PopItemWidth()

        if self.speedIndex == 0 then
            self.ActorSpawner.moveSpeed = "Walk"
        elseif self.speedIndex == 1 then
            self.ActorSpawner.moveSpeed = "Jog"
        else
            self.ActorSpawner.moveSpeed = "Sprint"
        end

        -- Loop Checkbox
        ImGui.SameLine()
        self.ActorSpawner.isLooping = ImGui.Checkbox("Loop Spline", self.ActorSpawner.isLooping)

        -- Action Buttons
        if not self.ActorSpawner.isTesting then
            if ImGui.Button("Spawn & Run Spline Test") then
                local player = Game.GetPlayer()
                local anchorPos = self.relativePoint or (player and player:GetWorldPosition())
                local anchorOrient = self.relativeOrient or (player and player:GetWorldOrientation())
                self.ActorSpawner:startSplineTest(self.points, self.positionType, anchorPos, anchorOrient)
            end
        else
            if self.ActorSpawner.isPaused then
                if ImGui.Button("Resume") then
                    self.ActorSpawner:resumeSplineTest()
                end
            else
                if ImGui.Button("Pause") then
                    self.ActorSpawner:pauseSplineTest()
                end
            end
            ImGui.SameLine()
            if ImGui.Button("Stop Test") then
                self.ActorSpawner:despawnActor()
            end
        end

        ImGui.SameLine()
        if ImGui.Button("Despawn Actor") then
            self.ActorSpawner:despawnActor()
        end

        -- Progress Status
        if self.ActorSpawner.isTesting then
            local statusText = string.format("Status: Moving to Waypoint #%d of %d (%s)",
                self.ActorSpawner.currentPointIndex, #self.ActorSpawner.points, self.ActorSpawner.moveSpeed)
            if self.ActorSpawner.isPaused then
                statusText = string.format("Status: PAUSED at Waypoint #%d of %d",
                    self.ActorSpawner.currentPointIndex, #self.ActorSpawner.points)
            end
            ImGui.TextColored(0.2, 0.9, 0.3, 1.0, statusText)
        end
    end
end

return Recorder
