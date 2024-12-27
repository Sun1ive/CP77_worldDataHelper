--- func desc
--- @class Proxy Proxy
--- @field instance? any
--- @field callbacks table list of callbacks
--- @field initialized boolean state of proxy
Proxy = {
    instance = nil,
    callbacks = {},
    initialized = false
}

function Proxy:Init()
    self.instance = NewProxy({
        OnAfterAttach = {
            args = {'handle:EntityLifecycleEvent'},
            callback = function(event)
                if not event then
                    return
                end

                local entity = event:GetEntity()

                if not entity then
                    return
                end

                print("Entity Attached " .. entity.GetEntity().GetEntityID())
            end
        },
        OnResourceReady = {
            args = {'handle:ResourceEvent'},
            callback = function(resource)
                print(resource)
            end
        }
    })
    -- local cbSystem = Game.GetCallbackSystem()
    -- cbSystem:RegisterCallback('Entity/Attached', self.instance:Target(), self.instance:Function('OnAfterAttach'), true)
    --     :AddTarget(DynamicEntityTarget:Tag("MyMod"))
    -- cbSystem:RegisterCallback("Resource/Ready", self.instance:Target(), "OnResourceReady"):AddTarget(ResRef.FromString(''))

    self.initialized = true;
end

return Proxy;
