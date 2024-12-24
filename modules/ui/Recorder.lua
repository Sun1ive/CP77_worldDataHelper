---@class Recorder
---@field positionType integer # 0 = absolute 1 = relative
---@field isStarted boolean
---@field relativePoint Vector4?
---MOVE THIS PROPS TO BASE
---@field viewSize number
---@field player PlayerPuppet?
Recorder = {
    Utils = require('modules/Utils'),
    Exporter = require('modules/classes/Exporter'),

    ---@type Vector4[]
    points = {},
    positionType = 1,
    isStarted = false,
    relativePoint = nil,

    -- MOVE THIS TO BASE CLASS
    viewSize = 0,
    player = nil
}

function Recorder:cleanUpPoints()
    for key in pairs(self.points) do
        self.points[key] = nil
    end
    self.relativePoint = nil
end

function Recorder:insertPoint()
    local pos = self.player:GetWorldPosition()

    if self.positionType == 0 then
        table.insert(self.points, pos)
    else
        if next(self.points) == nil then
            self.relativePoint = pos
            table.insert(self.points, Vector4.new(0, 0, 0, 1))
        else
            table.insert(self.points, Utils.calculateVectorDifference(pos, self.relativePoint))
        end
    end
end

function Recorder:render()
    if self.viewSize == 0 then
        self.viewSize = self.Utils.getViewSize()
    end

    self.player = Game.GetPlayer()

    if ImGui.CollapsingHeader("Recorder") then
        ImGui.PushItemWidth(100 * self.viewSize)
        self.positionType = ImGui.RadioButton("absolute", self.positionType, 0)
        ImGui.SameLine()
        self.positionType = ImGui.RadioButton("relative", self.positionType, 1)
        ImGui.PopItemWidth()

        ImGui.Separator()

        ImGui.PushItemWidth(100 * self.viewSize)
        if not self.isStarted then
            if ImGui.Button("Start record") then
                self.isStarted = true
                self:insertPoint()
            end
        else
            if ImGui.Button("Add point") then
                self:insertPoint()
            end

            ImGui.SameLine()

            if ImGui.Button("Stop record") then
                self:insertPoint()
                self.isStarted = false
                for _, pos in ipairs(self.points) do
                    print(string.format("Recorded Position: x=%.2f, y=%.2f, z=%.2f", pos.x, pos.y, pos.z))
                end

                local result = {}
                for _, value in ipairs(self.points) do
                    local json = JsonObject.new()
                    json:SetKeyDouble("x", value.x)
                    json:SetKeyDouble("y", value.y)
                    json:SetKeyDouble("z", value.z)
                    local str = json:ToString()
                    table.insert(result, str)
                end

                -- fix it later
                result = '[' .. table.concat(result, ",") .. ']'
                Exporter.saveFile('test.json', result)

                self:cleanUpPoints()
            end

        end

        ImGui.PopItemWidth()
    end
end

return Recorder
