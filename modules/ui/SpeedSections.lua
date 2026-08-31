---@class SpeedSectionsUI
---@field SpeedGenerator table
---@field Recorder table
---@field Utils table
---@field Exporter table
---@field exportFileName string
---@field viewSize number
local SpeedSections = {
    SpeedGenerator = require('modules/classes/SpeedGenerator'),
    Utils = require('modules/Utils'),
    Exporter = require('modules/classes/Exporter'),
    Recorder = nil,
    exportFileName = "speed_sections.json",
    viewSize = 0
}

---Initialize with Recorder reference
---@param recorder table
function SpeedSections:init(recorder)
    self.Recorder = recorder
end

---Render the Speed Sections generator and editor panel
function SpeedSections:render()
    self.viewSize = self.Utils.getViewSize()

    local rawPoints = self.Recorder and self.Recorder.points or {}
    local totalLength, _ = self.SpeedGenerator:calculateCumulativeDistances(rawPoints)

    -- Spline Info Summary
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Spline Overview:")
    ImGui.Text(string.format("Recorded Points: %d | Total Spline Length: %.2f meters", #rawPoints, totalLength))

    if #rawPoints < 2 then
        ImGui.TextColored(1.0, 0.7, 0.2, 1.0, "(!) Record at least 2 waypoints in 'Spline Recorder' tab first.")
    end

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- Generation Strategy Selector
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Generation Profile / Strategy:")
    ImGui.PushItemWidth(140 * self.viewSize)
    self.SpeedGenerator.currentStrategy = ImGui.RadioButton("Curvature Adaptive", self.SpeedGenerator.currentStrategy, 0)
    self.Utils.tooltip("Slows down on sharp corners based on turn angle, accelerates on straights")

    ImGui.SameLine()
    self.SpeedGenerator.currentStrategy = ImGui.RadioButton("Ease In / Out", self.SpeedGenerator.currentStrategy, 1)
    self.Utils.tooltip("Ramps up at start, cruises at target speed, and brakes before final waypoint")

    ImGui.SameLine()
    self.SpeedGenerator.currentStrategy = ImGui.RadioButton("Linear Ramp", self.SpeedGenerator.currentStrategy, 2)
    self.Utils.tooltip("Continuous speed ramp from Start Speed to End Speed")

    self.SpeedGenerator.currentStrategy = ImGui.RadioButton("Uniform Segments", self.SpeedGenerator.currentStrategy, 3)
    self.Utils.tooltip("Divides spline into equal distance chunks with constant speed")

    ImGui.SameLine()
    self.SpeedGenerator.currentStrategy = ImGui.RadioButton("Traffic Jitter", self.SpeedGenerator.currentStrategy, 4)
    self.Utils.tooltip("Adds natural speed variation along the path for realistic traffic")
    ImGui.PopItemWidth()

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- Strategy Specific Parameters
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Strategy Parameters:")

    if self.SpeedGenerator.currentStrategy == 0 then
        -- Curvature Adaptive Parameters
        ImGui.PushItemWidth(100 * self.viewSize)
        local minSpd, minUpdated = ImGui.InputFloat("Min Speed (m/s)##CurvMin", self.SpeedGenerator.minSpeed, 0.5, 1.0, "%.2f")
        if minUpdated and minSpd >= 0 then self.SpeedGenerator.minSpeed = minSpd end
        self.Utils.tooltip(string.format("Tight turn speed: %.1f km/h", self.SpeedGenerator.minSpeed * 3.6))

        ImGui.SameLine()
        local maxSpd, maxUpdated = ImGui.InputFloat("Max Speed (m/s)##CurvMax", self.SpeedGenerator.maxSpeed, 0.5, 1.0, "%.2f")
        if maxUpdated and maxSpd >= self.SpeedGenerator.minSpeed then self.SpeedGenerator.maxSpeed = maxSpd end
        self.Utils.tooltip(string.format("Straight speed: %.1f km/h", self.SpeedGenerator.maxSpeed * 3.6))

        local sens, sensUpdated = ImGui.SliderFloat("Turn Sensitivity##CurvSens", self.SpeedGenerator.sensitivity, 0.1, 2.0, "%.2f")
        if sensUpdated then self.SpeedGenerator.sensitivity = sens end
        self.Utils.tooltip("Higher value = more aggressive braking on turns")
        ImGui.PopItemWidth()

    elseif self.SpeedGenerator.currentStrategy == 1 then
        -- Trapezoid Parameters
        ImGui.PushItemWidth(100 * self.viewSize)
        local cruise, cruiseUpdated = ImGui.InputFloat("Cruise Speed (m/s)##TrapCruise", self.SpeedGenerator.cruiseSpeed, 0.5, 1.0, "%.2f")
        if cruiseUpdated and cruise >= 0 then self.SpeedGenerator.cruiseSpeed = cruise end
        self.Utils.tooltip(string.format("Cruising speed: %.1f km/h", self.SpeedGenerator.cruiseSpeed * 3.6))

        ImGui.SameLine()
        local endSpd, endUpdated = ImGui.InputFloat("End Braking Speed (m/s)##TrapEnd", self.SpeedGenerator.endSpeed, 0.5, 1.0, "%.2f")
        if endUpdated and endSpd >= 0 then self.SpeedGenerator.endSpeed = endSpd end
        self.Utils.tooltip(string.format("Final stop speed: %.1f km/h", self.SpeedGenerator.endSpeed * 3.6))

        local accel, accelUpdated = ImGui.InputFloat("Accel Distance (m)##TrapAccel", self.SpeedGenerator.accelDist, 1.0, 5.0, "%.1f")
        if accelUpdated and accel > 0 then self.SpeedGenerator.accelDist = accel end
        self.Utils.tooltip("Distance over which the vehicle accelerates to cruise speed")

        ImGui.SameLine()
        local decel, decelUpdated = ImGui.InputFloat("Decel Distance (m)##TrapDecel", self.SpeedGenerator.decelDist, 1.0, 5.0, "%.1f")
        if decelUpdated and decel > 0 then self.SpeedGenerator.decelDist = decel end
        self.Utils.tooltip("Distance before spline end where braking begins")
        ImGui.PopItemWidth()

    elseif self.SpeedGenerator.currentStrategy == 2 then
        -- Linear Ramp Parameters
        ImGui.PushItemWidth(100 * self.viewSize)
        local startSpd, startUpdated = ImGui.InputFloat("Start Speed (m/s)##RampStart", self.SpeedGenerator.startSpeed, 0.5, 1.0, "%.2f")
        if startUpdated and startSpd >= 0 then self.SpeedGenerator.startSpeed = startSpd end
        self.Utils.tooltip(string.format("Start speed: %.1f km/h", self.SpeedGenerator.startSpeed * 3.6))

        ImGui.SameLine()
        local endSpd, endUpdated = ImGui.InputFloat("End Speed (m/s)##RampEnd", self.SpeedGenerator.endSpeed, 0.5, 1.0, "%.2f")
        if endUpdated and endSpd >= 0 then self.SpeedGenerator.endSpeed = endSpd end
        self.Utils.tooltip(string.format("End speed: %.1f km/h", self.SpeedGenerator.endSpeed * 3.6))

        local step, stepUpdated = ImGui.InputFloat("Segment Step (m)##RampStep", self.SpeedGenerator.stepDist, 1.0, 5.0, "%.1f")
        if stepUpdated and step > 1.0 then self.SpeedGenerator.stepDist = step end
        self.Utils.tooltip("Length of each interpolation segment")
        ImGui.PopItemWidth()

    elseif self.SpeedGenerator.currentStrategy == 3 then
        -- Uniform Parameters
        ImGui.PushItemWidth(100 * self.viewSize)
        local cruise, cruiseUpdated = ImGui.InputFloat("Target Speed (m/s)##UniSpeed", self.SpeedGenerator.cruiseSpeed, 0.5, 1.0, "%.2f")
        if cruiseUpdated and cruise >= 0 then self.SpeedGenerator.cruiseSpeed = cruise end
        self.Utils.tooltip(string.format("Speed: %.1f km/h", self.SpeedGenerator.cruiseSpeed * 3.6))

        ImGui.SameLine()
        local step, stepUpdated = ImGui.InputFloat("Segment Step (m)##UniStep", self.SpeedGenerator.stepDist, 1.0, 5.0, "%.1f")
        if stepUpdated and step > 1.0 then self.SpeedGenerator.stepDist = step end
        self.Utils.tooltip("Distance length per segment")
        ImGui.PopItemWidth()

    elseif self.SpeedGenerator.currentStrategy == 4 then
        -- Traffic Jitter Parameters
        ImGui.PushItemWidth(100 * self.viewSize)
        local base, baseUpdated = ImGui.InputFloat("Base Speed (m/s)##JitterBase", self.SpeedGenerator.cruiseSpeed, 0.5, 1.0, "%.2f")
        if baseUpdated and base >= 0 then self.SpeedGenerator.cruiseSpeed = base end
        self.Utils.tooltip(string.format("Base speed: %.1f km/h", self.SpeedGenerator.cruiseSpeed * 3.6))

        ImGui.SameLine()
        local jitter, jitterUpdated = ImGui.InputFloat("Jitter Amount (+/- m/s)##JitterAmt", self.SpeedGenerator.jitterAmount, 0.2, 0.5, "%.2f")
        if jitterUpdated and jitter >= 0 then self.SpeedGenerator.jitterAmount = jitter end
        self.Utils.tooltip("Maximum random speed variation")

        local step, stepUpdated = ImGui.InputFloat("Interval Step (m)##JitterStep", self.SpeedGenerator.stepDist, 1.0, 5.0, "%.1f")
        if stepUpdated and step > 1.0 then self.SpeedGenerator.stepDist = step end
        self.Utils.tooltip("Distance between speed change points")
        ImGui.PopItemWidth()
    end

    ImGui.Spacing()

    -- -------------------------------------------------------------
    -- Main Action Buttons
    -- -------------------------------------------------------------
    if ImGui.Button("Generate from Recorded Spline") then
        if #rawPoints < 2 then
            self.Utils.UIshowWarningMsg("Need at least 2 recorded waypoints!")
        else
            local generated = self.SpeedGenerator:generate(rawPoints)
            self.Utils.UIshowNotificationMsg(string.format("Generated %d speedChangeSections", #generated))
            print(string.format("[CP77_worldDataHelper] Generated %d speedChangeSections for spline (%.2fm)",
                #generated, totalLength))
        end
    end

    ImGui.SameLine()
    if ImGui.Button("Add Section") then
        local lastEnd = 0
        if #self.SpeedGenerator.sections > 0 then
            lastEnd = self.SpeedGenerator.sections[#self.SpeedGenerator.sections].endPos
        end
        self.SpeedGenerator:addSection(lastEnd, math.min(totalLength, lastEnd + 10), self.SpeedGenerator.cruiseSpeed)
    end

    ImGui.SameLine()
    if ImGui.Button("Clear All") then
        self.SpeedGenerator:clear()
        self.Utils.UIshowNotificationMsg("Cleared all speed change sections")
    end

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- Export and Copy Controls
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Export & Clipboard:")
    if ImGui.Button("Copy WolvenKit JSON") then
        local jsonStr = self.SpeedGenerator:toJsonString()
        ImGui.SetClipboardText(jsonStr)
        self.Utils.UIshowNotificationMsg("Copied WolvenKit JSON to Clipboard")
    end

    ImGui.SameLine()
    if ImGui.Button("Copy Lua Array") then
        local lines = { "local speedChangeSections = {" }
        for _, s in ipairs(self.SpeedGenerator.sections) do
            table.insert(lines, string.format("    { start = %.2f, endPos = %.2f, speed = %.2f },", s.start, s.endPos, s.speed))
        end
        table.insert(lines, "}")
        ImGui.SetClipboardText(table.concat(lines, "\n"))
        self.Utils.UIshowNotificationMsg("Copied Lua Array to Clipboard")
    end

    ImGui.SameLine()
    ImGui.PushItemWidth(140 * self.viewSize)
    self.exportFileName = ImGui.InputTextWithHint("##SpeedExportName", "speed_sections.json", self.exportFileName, 128)
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if ImGui.Button("Export JSON File") then
        local jsonStr = self.SpeedGenerator:toJsonString()
        local success, err = self.Exporter.saveFile(self.exportFileName, jsonStr)
        if success then
            self.Utils.UIshowNotificationMsg("Saved speed sections to " .. self.exportFileName)
            print("[CP77_worldDataHelper] Saved speed sections to " .. self.exportFileName)
        else
            self.Utils.UIshowWarningMsg("Failed to save: " .. tostring(err))
        end
    end

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- Interactive Speed Change Sections Table
    -- -------------------------------------------------------------
    ImGui.TextColored(0.2, 1.0, 0.3, 1.0, string.format("Speed Change Sections (%d):", #self.SpeedGenerator.sections))

    if #self.SpeedGenerator.sections > 0 then
        if ImGui.BeginChild("SpeedSectionsTable", 0, 200 * self.viewSize, true) then
            local removeIndex = nil

            for idx, sec in ipairs(self.SpeedGenerator.sections) do
                ImGui.PushID("SpeedRow" .. tostring(idx))

                ImGui.Text(string.format("#%02d", idx))
                ImGui.SameLine()

                -- Start Pos Input
                ImGui.PushItemWidth(70 * self.viewSize)
                local newStart, startChanged = ImGui.InputFloat("##Start", sec.start, 0.5, 1.0, "%.2f")
                if startChanged and newStart >= 0 then sec.start = newStart end
                self.Utils.tooltip(string.format("Start distance: %.2f meters from spline origin", sec.start))
                ImGui.SameLine()
                ImGui.Text("->")
                ImGui.SameLine()

                -- End Pos Input
                local newEnd, endChanged = ImGui.InputFloat("##End", sec.endPos, 0.5, 1.0, "%.2f")
                if endChanged and newEnd >= sec.start then sec.endPos = newEnd end
                self.Utils.tooltip(string.format("End distance: %.2f meters where target speed is reached", sec.endPos))
                ImGui.SameLine()

                -- Target Speed Input
                local newSpd, spdChanged = ImGui.InputFloat("##Spd", sec.speed, 0.5, 1.0, "%.2f")
                if spdChanged and newSpd >= 0 then sec.speed = newSpd end
                self.Utils.tooltip("Target speed in meters per second (m/s)")
                ImGui.PopItemWidth()

                ImGui.SameLine()
                ImGui.TextColored(0.7, 0.7, 0.7, 1.0, string.format("(%.1f km/h)", sec.speed * 3.6))

                ImGui.SameLine()
                if ImGui.Button("X") then
                    removeIndex = idx
                end
                self.Utils.tooltip("Delete this section")

                ImGui.PopID()
            end

            if removeIndex then
                self.SpeedGenerator:removeSection(removeIndex)
            end

            ImGui.EndChild()
        end
    else
        ImGui.TextColored(0.6, 0.6, 0.6, 1.0, "No speedChangeSections generated yet. Click 'Generate from Recorded Spline' above.")
    end
end

return SpeedSections
