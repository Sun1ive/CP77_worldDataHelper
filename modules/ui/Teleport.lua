---@class Teleport
---@field destination Vector4
---@field destinationType number 0 = coords; 1 = NodeRef
---@field viewSize number
---@field nodeRef string
local Teleport = {
    Utils = require('modules/Utils'),
    destination = Vector4.new(0, 0, 0, 1),
    destinationType = 0,
    viewSize = 0,
    nodeRef = ''
}

---Teleport the player to the selected destination or node
function Teleport:teleportPlayer()
    local player = Game.GetPlayer()
    if not player then
        self.Utils.UIshowWarningMsg("Player not available for teleport")
        return
    end

    if self.destinationType == 0 then
        local dest = Vector4.new(self.destination.x, self.destination.y, self.destination.z, 1.0)
        local orient = player:GetWorldOrientation()
        local euler = orient and orient:ToEulerAngles() or EulerAngles.new(0, 0, 0)

        pcall(function()
            Game.GetTeleportationFacility():Teleport(player, dest, euler)
            self.Utils.UIshowNotificationMsg(string.format("Teleported to %.2f, %.2f, %.2f", dest.x, dest.y, dest.z))
        end)
    else
        if not self.Utils.isNotEmpty(self.nodeRef) then
            self.Utils.UIshowWarningMsg("NodeRef is empty")
            return
        end

        pcall(function()
            local resolvedRef = ResolveNodeRef(CreateEntityReference(self.nodeRef, {}).reference, GlobalNodeID.GetRoot())
            if self.Utils.isNotEmpty(resolvedRef.hash) then
                local entity = Game.FindEntityByID(EntityID.new({ hash = resolvedRef.hash }))
                if IsDefined(entity) then
                    local targetPos = entity:GetWorldPosition()
                    local orient = player:GetWorldOrientation()
                    Game.GetTeleportationFacility():Teleport(player, targetPos, orient:ToEulerAngles())
                    self.Utils.UIshowNotificationMsg("Teleported to Entity: " .. self.nodeRef)
                else
                    local streamingData = Game.GetWorldInspector():FindStreamedNode(resolvedRef.hash)
                    if streamingData and streamingData.nodeInstance then
                        print("[CP77_worldDataHelper] Fetched Streamed Node:")
                        print(self.Utils.parseUserData(streamingData.nodeInstance))
                        self.Utils.UIshowNotificationMsg("Inspected Streamed Node: " .. self.nodeRef)
                    else
                        self.Utils.UIshowWarningMsg("Streamed Node not found: " .. self.nodeRef)
                    end
                end
            else
                self.Utils.UIshowWarningMsg("Could not resolve NodeRef hash")
            end
        end)
    end
end

---Render Teleport panel
function Teleport:render()
    self.viewSize = self.Utils.getViewSize()
    local player = Game.GetPlayer()

    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Destination Type:")
    ImGui.PushItemWidth(100 * self.viewSize)
    self.destinationType = ImGui.RadioButton("Coordinates", self.destinationType, 0)
    ImGui.SameLine()
    self.destinationType = ImGui.RadioButton("NodeRef", self.destinationType, 1)
    ImGui.PopItemWidth()

    ImGui.Separator()

    if self.destinationType == 0 then
        if player then
            local playerPos = player:GetWorldPosition()
            if ImGui.Button("Copy Current Position") then
                self.destination = Vector4.new(playerPos.x, playerPos.y, playerPos.z, 1.0)
            end
            ImGui.SameLine()
            if ImGui.Button("Zero Coordinates") then
                self.destination = Vector4.new(0, 0, 0, 1.0)
            end
        end

        ImGui.Text("Target Coordinates:")
        ImGui.PushItemWidth(100 * self.viewSize)
        self.destination.x = self.Utils.handleVector4Input("TPDest", "x", self.destination)
        ImGui.SameLine()
        self.destination.y = self.Utils.handleVector4Input("TPDest", "y", self.destination)
        ImGui.SameLine()
        self.destination.z = self.Utils.handleVector4Input("TPDest", "z", self.destination)
        ImGui.PopItemWidth()
    else
        ImGui.Text("NodeRef Reference:")
        ImGui.PushItemWidth(280 * self.viewSize)
        self.nodeRef = ImGui.InputTextWithHint("##NodeRefInput", "e.g. #01_q001_sub_01", self.nodeRef, 1024, ImGuiInputTextFlags.CharsNoBlank)
        self.Utils.tooltip("Enter NodeRef string to resolve and teleport")
        ImGui.PopItemWidth()
    end

    ImGui.Spacing()
    if ImGui.Button("Teleport Player Now") then
        self:teleportPlayer()
    end
end

return Teleport
