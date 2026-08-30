---@class Spawner
---@field emptyEntity string Path to empty entity template
---@field mesh string Path to marker mesh
---@field spawnedList table List of spawned entity IDs
---@field attachCallbacks table List of attach callbacks by entity hash
---@field redProxy table? RedProxy callback container
---@field initialized boolean
local Spawner = {
    emptyEntity = "base\\quest\\main_quests\\part1\\q115\\test\\empty_entity.ent",
    mesh = "engine\\meshes\\editor\\markers\\review\\review_flag_open.w2mesh",
    spawnedList = {},
    attachCallbacks = {},
    redProxy = nil,
    initialized = false
}

function Spawner:Init()
    if self.initialized then
        return
    end

    pcall(function()
        self.redProxy = NewProxy({
            OnEntityAssemble = {
                args = {'handle:EntityLifecycleEvent'},
                callback = function(event)
                    if not event then
                        return
                    end

                    local entity = event:GetEntity()
                    if not entity then
                        return
                    end

                    local idHash = tostring(entity:GetEntityID().hash)
                    if self.attachCallbacks[idHash] then
                        self.attachCallbacks[idHash](entity)
                        self.attachCallbacks[idHash] = nil
                    end
                end
            }
        })

        local cbSystem = Game.GetCallbackSystem()
        if cbSystem and self.redProxy then
            cbSystem:RegisterCallback('Entity/Initialize', self.redProxy:Target(),
                self.redProxy:Function('OnEntityAssemble'), true)
            self.initialized = true
        end
    end)
end

---Attach marker mesh component to entity on assembly
---@param entity any
function Spawner:onAssemble(entity)
    pcall(function()
        local component = entMeshComponent.new()
        component.name = CName.new("marker_mesh")
        component.mesh = ResRef.FromString(self.mesh)
        component.visualScale = Vector3.new(1.0, 1.0, 1.0)
        component.meshAppearance = CName.new("default")
        entity:AddComponent(component)
    end)
end

---Despawn all active in-world marker entities
function Spawner:cleanUp()
    local staticSystem = Game.GetStaticEntitySystem()
    if staticSystem and next(self.spawnedList) ~= nil then
        for _, entityID in ipairs(self.spawnedList) do
            pcall(function()
                staticSystem:DespawnEntity(entityID)
            end)
        end
    end
    self.spawnedList = {}
    self.attachCallbacks = {}
end

---Register a post-spawn callback for an entity ID
---@param entityID entEntityID
---@param callback function
function Spawner:RegisterCallback(entityID, callback)
    if entityID and entityID.hash then
        self.attachCallbacks[tostring(entityID.hash)] = callback
    end
end

---Spawn a visual marker entity at the given position and orientation (or player pos)
---@param pos Vector4?
---@param orientation Quaternion?
---@return entEntityID?
function Spawner:spawn(pos, orientation)
    if not self.initialized then
        self:Init()
    end

    local player = Game.GetPlayer()
    if not pos and player then
        pos = player:GetWorldPosition()
    end
    if not orientation and player then
        orientation = player:GetWorldOrientation()
    end

    if not pos or not orientation then
        return nil
    end

    local entityID = nil
    pcall(function()
        local spec = StaticEntitySpec.new()
        spec.templatePath = ResRef.FromString(self.emptyEntity)
        spec.position = pos
        spec.orientation = orientation
        spec.attached = true
        spec.appearanceName = CName.new("default")

        entityID = Game.GetStaticEntitySystem():SpawnEntity(spec)
        if entityID then
            table.insert(self.spawnedList, entityID)
            self:RegisterCallback(entityID, function(entity)
                self:onAssemble(entity)
            end)
        end
    end)

    return entityID
end

return Spawner
