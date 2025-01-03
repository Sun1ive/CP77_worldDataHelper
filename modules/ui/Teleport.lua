---@class Teleport 
---@field destination Vector4?
---@field destinationType number 0 = coords; 1 = NodeRef
---@field viewSize number
---@field NodeRef string 
Teleport = {
    Utils = require('modules/Utils'),

    destination = nil,
    destinationType = 0,
    viewSize = 0,
    NodeRef = ''
}

function Teleport:teleportPlayer()
    if self.destinationType == 0 then
        print('teleport' .. self.destination.x, self.destination.y, self.destination.z)
        local player = Game.GetPlayer()
        Game.GetTeleportationFacility():Teleport(player, self.destination, EulerAngles.new(0, 0, 45))
    else
        local target = {}
        local resolvedRef = ResolveNodeRef(CreateEntityReference(self.NodeRef, {}).reference, GlobalNodeID.GetRoot())
        if Utils.isNotEmpty(resolvedRef.hash) then
            local entity = Game.FindEntityByID(EntityID.new({
                hash = resolvedRef.hash
            }))
            if IsDefined(entity) then
                print("ENTITY")
                target.entity = entity
            else
                local streamingData = Game.GetWorldInspector():FindStreamedNode(resolvedRef.hash)
                print("FETCHED DATA")
                target.nodeInstance = streamingData.nodeInstance
                target.nodeDefinition = streamingData.nodeDefinition
                target.nodeID = resolvedRef.hash
                Utils.parseUserData(target.nodeInstance)
            end

            for _, value in ipairs(target) do
                Utils.parseUserData(value)
            end
        end
    end
end

function Teleport:render()
    if self.viewSize == 0 then
        self.viewSize = self.Utils.getViewSize()
    end
    if ImGui.CollapsingHeader("Teleport Player") then
        if self.destination == nil then
            self.destination = Vector4.new(0, 0, 0, 1)
        end

        ImGui.PushItemWidth(100 * self.viewSize)
        self.destinationType = ImGui.RadioButton("Coords", self.destinationType, 0)
        ImGui.SameLine()
        self.destinationType = ImGui.RadioButton("NodeRef", self.destinationType, 1)
        ImGui.PopItemWidth()

        ImGui.Separator()

        if self.destinationType == 0 then
            ImGui.PushItemWidth(100 * self.viewSize)
            self.destination.x = Utils.handleVector4Input("TPDest", "x", self.destination)
            ImGui.SameLine()
            self.destination.y = Utils.handleVector4Input("TPDest", "y", self.destination)
            ImGui.SameLine()
            self.destination.z = Utils.handleVector4Input("TPDest", "z", self.destination)
            ImGui.PopItemWidth()
        else
            ImGui.PushItemWidth(300 * self.viewSize)
            self.NodeRef = ImGui.InputText("", self.NodeRef, 1024, ImGuiInputTextFlags.CharsNoBlank)
            if ImGui.IsItemHovered() then
                ImGui.SetTooltip("NodeRef")
            end
            ImGui.PopItemWidth()
        end

        if ImGui.Button("tp to point") then
            print('call btn')
            self:teleportPlayer()
        end
    end
end

return Teleport
