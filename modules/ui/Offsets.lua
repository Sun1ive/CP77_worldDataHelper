---@class Calculator
---@field from Vector4?
---@field to Vector4?
---@field result Vector4?
---@field viewSize number
Offsets = {
    Utils = require('modules/Utils'),
    from = nil,
    to = nil,
    result = nil,
    viewSize = 0
}

---@param formatter string
---@param enableReplacer boolean
---@return nil
function Offsets:render(formatter, enableReplacer)
    if self.viewSize == 0 then
        self.viewSize = self.Utils.getViewSize()
    end
    if not self.from then
        self.from = Vector4.new(0, 0, 0, 1)
    end
    if not self.to then
        self.to = Vector4.new(0, 0, 0, 1)
    end
    if not self.result then
        self.result = Vector4.new(0, 0, 0, 1)
    end

    if ImGui.CollapsingHeader("Offsets") then
        ImGui.PushItemWidth(300 * self.viewSize)
        ImGui.Text("From X")
        ImGui.SameLine()
        ImGui.Text("From Y")
        ImGui.SameLine()
        ImGui.Text("From Z")
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(100 * self.viewSize)
        self.from.x = Utils.handleVector4Input("From", "x", self.from)
        ImGui.SameLine()
        self.from.y = Utils.handleVector4Input("From", "y", self.from)
        ImGui.SameLine()
        self.from.z = Utils.handleVector4Input("From", "z", self.from)
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(300 * self.viewSize)
        ImGui.Text("To X")
        ImGui.SameLine()
        ImGui.Text("To Y")
        ImGui.SameLine()
        ImGui.Text("To Z")
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(100 * self.viewSize)
        self.to.x = Utils.handleVector4Input("To", "x", self.to)
        ImGui.SameLine()
        self.to.y = Utils.handleVector4Input("To", "y", self.to)
        ImGui.SameLine()
        self.to.z = Utils.handleVector4Input("To", "z", self.to)
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(300 * self.viewSize)
        ImGui.Text("Result X")
        ImGui.SameLine()
        ImGui.Text("Result Y")
        ImGui.SameLine()
        ImGui.Text("Result Z")
        ImGui.PopItemWidth()

        ImGui.PushItemWidth(100 * self.viewSize)
        local result = Utils.calculateVector4Difference(self.from, self.to)
        self.Utils.drawField("ResultX", result.x, formatter, enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("ResultY", result.y, formatter, enableReplacer)
        ImGui.SameLine()
        self.Utils.drawField("ResultZ", result.z, formatter, enableReplacer)
        ImGui.PopItemWidth()
    end
end

return Offsets
