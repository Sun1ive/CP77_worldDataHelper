---@class Recorder
---@field positionType integer # 0 = absolute 1 = relative
---@field isStarted boolean
---@field relativePoint Vector4?
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

    viewSize = 0,
    player = nil
}

function Recorder:cleanUpPoints()
    for key in pairs(self.points) do
        self.points[key] = nil
    end
    self.relativePoint = nil
end

function Recorder:drawField(name, prop, formatter)
    local text = string.format(formatter, prop)
    ImGui.InputTextWithHint("##" .. name, name, text, #text + 1, ImGuiInputTextFlags.ReadOnly)
    self.Utils.tooltip(name)
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

                local array = JsonArray.new()
                for _, value in ipairs(self.points) do
                    local json = JsonObject.new()
                    json:SetKeyDouble("x", value.x)
                    json:SetKeyDouble("y", value.y)
                    json:SetKeyDouble("z", value.z)
                    array:AddItem(json)
                end
                local str = array:ToString()
                Exporter.saveFile('test.json', str)

                self:cleanUpPoints()
            end

        end

        ImGui.PopItemWidth()

        ImGui.Separator()

        if self.isStarted and next(self.points) ~= nil then
            for index, point in ipairs(self.points) do
                ImGui.PushItemWidth(80 * self.viewSize)
                self:drawField("X", tostring(point.x), "%.4f")
                ImGui.SameLine()
                self:drawField("Y", tostring(point.y), "%.4f")
                ImGui.SameLine()
                self:drawField("Z", tostring(point.z), "%.4f")
                ImGui.PopItemWidth()
                ImGui.Separator()
            end
        end
    end
end

return Recorder
