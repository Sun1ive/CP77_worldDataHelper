---@class Proxy
---@field instance any
---@field callbacks table
---@field initialized boolean
---@field streamingSectorResource any
local Proxy = {
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
    if self.initialized then
        return
    end

    pcall(function()
        self.streamingSectorResource = ResRef.FromString("mod\\worlds\\vehicle_sunset_test.streamingsector")
        self.instance = NewProxy({
            OnAfterAttach = {
                args = {'handle:EntityLifecycleEvent'},
                callback = function(event)
                    if not event then return end
                    local entity = event:GetEntity()
                    if not entity then return end
                    print("[CP77_worldDataHelper] Entity Attached: " .. tostring(entity:GetEntityID().hash))
                end
            },
            OnResourceReady = {
                args = {'handle:ResourceEvent'},
                callback = function(event)
                    if not event then return end
                    local resource = event:GetResource()
                    if not resource then return end
                    print("[CP77_worldDataHelper] Sector Resource Ready")
                    for _, value in ipairs(resource:GetNodes()) do
                        print(self.Utils.parseUserData(value))
                    end
                end
            }
        })

        local cbSystem = Game.GetCallbackSystem()
        if cbSystem and self.instance then
            cbSystem:RegisterCallback("Resource/Ready", self.instance:Target(),
                self.instance:Function("OnResourceReady"), true)
                :AddTarget(ResourceTarget.Path(self.streamingSectorResource))
                :SetRunMode(2)
            self.initialized = true
        end
    end)
end

return Proxy
