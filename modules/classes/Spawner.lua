---@class Spawner
---@field emptyEntity string Path to empty entity
---@field spawnedList table list of spawned entities
---@field attachCallbacks table list of attachCallbacks
---@field redProxy table? red proxy
Spawner = {
    emptyEntity = "base\\quest\\main_quests\\part1\\q115\\test\\empty_entity.ent",
    mesh = "engine\\meshes\\editor\\markers\\review\\review_flag_open.w2mesh",
    spawnedList = {},
    attachCallbacks = {},
    redProxy = nil,
    initialized = false
}

function Spawner:Init()
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

                local idHash = entity:GetEntityID().hash

                if self.attachCallbacks[tostring(idHash)] then
                    self.attachCallbacks[tostring(idHash)](entity)
                    self.attachCallbacks[tostring(idHash)] = nil
                end
            end
        }
    })
    Game.GetCallbackSystem():RegisterCallback('Entity/Initialize', self.redProxy:Target(),
        self.redProxy:Function('OnEntityAssemble'), true)
    self.initialized = true
end

--- func desc
---@param entity entEntityID
function Spawner:onAssemble(entity)
    local component = entMeshComponent.new()
    component.name = CName "mesh"
    component.mesh = ResRef.FromString(self.mesh)
    component.visualScale = Vector3.new(1, 1, 1)
    component.meshAppearance = CName "default"
    entity:AddComponent(component)
end

function Spawner:cleanUp()
    if next(self.spawnedList) ~= nil then
        for _, entity in ipairs(self.spawnedList) do
            Game.GetStaticEntitySystem():DespawnEntity(entity)
        end
    end
end

---@param entityID entEntityID
---@param callback function
function Spawner:RegisterCallback(entityID, callback)
    self.attachCallbacks[tostring(entityID.hash)] = callback
end

function Spawner:spawn()
    local spec = StaticEntitySpec.new()
    local player = Game.GetPlayer()
    local pos = player:GetWorldPosition()
    spec.templatePath = ResRef.FromString(self.emptyEntity)
    print(self.emptyEntity)
    spec.position = pos
    spec.orientation = player:GetWorldOrientation();
    spec.attached = true
    spec.appearanceName = "default"
    local entityID = Game.GetStaticEntitySystem():SpawnEntity(spec)
    table.insert(self.spawnedList, entityID)

    self:RegisterCallback(entityID, function(entity)
        self:onAssemble(entity)
    end)
end

return Spawner
