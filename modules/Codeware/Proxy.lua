--- func desc
--- @class Proxy Proxy
--- @field instance? any
--- @field callbacks table list of callbacks
--- @field initialized boolean state of proxy
--- @field streamingSectorResource? redResourceReferenceScriptToken of proxy
Proxy = {
    Utils = require('modules/Utils'),

    instance = nil,
    streamingSectorResource = nil,
    callbacks = {},
    initialized = false
}

function Proxy:Stop()
    self.initialized = false
    self.instance = nil
    self.callbacks = {}
end

function Proxy:Init()
    self.streamingSectorResource = ResRef.FromString("mod\\worlds\\vehicle_sunset_test.streamingsector")
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
            callback = function(event)
                print("CET ON RESOURCE")
                if not event then
                    return
                end
                local resource = event:GetResource()
                if not resource then
                    return
                end
                for index, value in ipairs(resource:GetNodes()) do
                    print(value)
                    print(Utils.parseUserData(value))
                end
            end
        }
    })
    -- cbSystem:RegisterCallback('Entity/Attached', self.instance:Target(), self.instance:Function('OnAfterAttach'), true)
    --     :AddTarget(DynamicEntityTarget:Tag("MyMod"))

    Game.GetCallbackSystem():RegisterCallback("Resource/Ready", self.instance:Target(),
        self.instance:Function("OnResourceReady"), true):AddTarget(ResourceTarget.Path(self.streamingSectorResource))
        :SetRunMode(2)

    self.initialized = true;
end

return Proxy;
