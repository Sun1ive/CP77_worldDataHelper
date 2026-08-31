---@class Spawner
---@field emptyEntity string Path to empty entity template
---@field markerMesh string Path to 3D marker diamond mesh
---@field arrowMesh string Path to directional arrow/flag mesh
---@field spawnedList table List of spawned entity IDs
---@field attachCallbacks table List of attach callbacks by entity hash
---@field redProxy table? RedProxy callback container
---@field initialized boolean
---@field markerTag string
local Spawner = {
    emptyEntity = "base\\quest\\main_quests\\part1\\q115\\test\\empty_entity.ent",
    markerMesh = "base\\environment\\ld_kit\\marker.mesh",
    arrowMesh = "engine\\meshes\\editor\\markers\\review\\review_flag_open.w2mesh",
    spawnedList = {},
    attachCallbacks = {},
    redProxy = nil,
    initialized = false,
    markerTag = "CP77_worldDataHelper_Marker"
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

---Attach high-visibility marker components, directional arrow, and glow light to entity on assembly
---@param entity any
---@param pointIndex integer?
function Spawner:onAssemble(entity, pointIndex)
    pcall(function()
        local idx = pointIndex or 1
        local isFirst = (idx == 1)

        local colorApp = isFirst and "green" or "yellow"
        local lightR = isFirst and 40 or 255
        local lightG = isFirst and 255 or 210
        local lightB = isFirst and 90 or 40

        -- 1. High-Visibility 3D Marker Diamond
        local markerComponent = entMeshComponent.new()
        markerComponent.name = CName.new("marker_diamond")
        markerComponent.mesh = ResRef.FromString(self.markerMesh)
        markerComponent.visualScale = Vector3.new(0.025, 0.025, 0.025)
        markerComponent.meshAppearance = CName.new(colorApp)
        entity:AddComponent(markerComponent)

        -- 2. Directional Review Flag / Arrow (Oriented along player's heading)
        local arrowComponent = entMeshComponent.new()
        arrowComponent.name = CName.new("marker_arrow")
        arrowComponent.mesh = ResRef.FromString(self.arrowMesh)
        arrowComponent.visualScale = Vector3.new(1.2, 1.2, 1.2)
        arrowComponent.meshAppearance = CName.new("default")
        entity:AddComponent(arrowComponent)

        -- 3. Ambient Glow Point Light for High Visibility at Distance & in Dark
        local lightComponent = entPointLightComponent.new()
        lightComponent.name = CName.new("marker_glow")
        lightComponent.color = Color.new({ Red = lightR, Green = lightG, Blue = lightB, Alpha = 255 })
        lightComponent.radius = 2.5
        lightComponent.intensity = 15.0
        entity:AddComponent(lightComponent)
    end)
end

---Despawn all active in-world marker entities
function Spawner:cleanUp()
    local dynamicSystem = Game.GetDynamicEntitySystem()
    local staticSystem = Game.GetStaticEntitySystem()

    if next(self.spawnedList) ~= nil then
        for _, entityID in ipairs(self.spawnedList) do
            pcall(function()
                if dynamicSystem then
                    dynamicSystem:DeleteEntity(entityID)
                end
            end)
            pcall(function()
                if staticSystem then
                    staticSystem:DespawnEntity(entityID)
                end
            end)
        end
    end

    pcall(function()
        if dynamicSystem then
            dynamicSystem:DeleteTagged(self.markerTag)
        end
    end)

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
---@param pointIndex integer?
---@return entEntityID?
function Spawner:spawn(pos, orientation, pointIndex)
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
    local targetIdx = pointIndex or (#self.spawnedList + 1)

    pcall(function()
        local dynamicSystem = Game.GetDynamicEntitySystem()
        if dynamicSystem then
            local spec = DynamicEntitySpec.new()
            spec.templatePath = self.emptyEntity
            spec.position = Vector4.new(pos.x, pos.y, pos.z, 1.0)
            spec.orientation = orientation
            spec.alwaysSpawned = true
            spec.tags = { self.markerTag }

            entityID = dynamicSystem:CreateEntity(spec)
        else
            local spec = StaticEntitySpec.new()
            spec.templatePath = ResRef.FromString(self.emptyEntity)
            spec.position = pos
            spec.orientation = orientation
            spec.attached = true
            spec.appearanceName = CName.new("default")

            entityID = Game.GetStaticEntitySystem():SpawnEntity(spec)
        end

        if entityID then
            table.insert(self.spawnedList, entityID)
            self:RegisterCallback(entityID, function(entity)
                self:onAssemble(entity, targetIdx)
            end)
        end
    end)

    return entityID
end

return Spawner
