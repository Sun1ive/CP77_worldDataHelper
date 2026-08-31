---@class worldDataHelper
---@field formatter string
---@field channel integer
local worldDataHelper = {
    GameUI = require("modules/external/GameUI"),
    UI = require('modules/UI'),
    Recorder = require('modules/ui/Recorder'),
    Widget = require('modules/ui/Widget'),

    CodewareProxy = require('modules/Codeware/Proxy'),

    renderUi = false,
    isOverlay = false,
    inGame = false,
    inMenu = false
}

function worldDataHelper:new()
    registerForEvent("onInit", function()
        self.CodewareProxy:Init()
        if self.Recorder and self.Recorder.ActorSpawner then
            self.Recorder.ActorSpawner:init()
        end
        print(string.format("[CP77_worldDataHelper] Initialized v%s", self.UI.version or "0.0.1"))

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu)
            self.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.inGame = true
            print("[CP77_worldDataHelper] Session start")
        end)

        self.GameUI.OnSessionEnd(function()
            self.inGame = false
            self.CodewareProxy:Stop()
            if self.Recorder and self.Recorder.ActorSpawner then
                self.Recorder.ActorSpawner:despawnActor()
            end
            print("[CP77_worldDataHelper] Session end")
        end)

        self.inGame = not self.GameUI.IsDetached()
    end)

    registerForEvent("onOverlayOpen", function()
        self.isOverlay = true
    end)

    registerForEvent("onOverlayClose", function()
        self.isOverlay = false
    end)

    registerForEvent("onUpdate", function(dt)
        if self.inGame and not self.inMenu and self.Recorder then
            self.Recorder:update(dt)
        end
    end)

    registerHotkey('renderUi', 'Render UI Key', function()
        self.renderUi = not self.renderUi
    end)

    registerHotkey('toggleWidget', 'Toggle Coordinates Widget Key', function()
        if self.Widget then
            self.Widget.visible = not self.Widget.visible
        end
    end)

    registerHotkey('recorderAddPointKey', 'Recorder Add Point Key', function()
        if self.Recorder ~= nil and self.Recorder.isStarted == true then
            self.Recorder:insertPoint()
        end
    end)

    registerForEvent('onDraw', function()
        if self.inGame and not self.inMenu then
            if self.isOverlay or self.renderUi then
                self.UI:render()
            end
            if self.Widget and self.Widget.visible then
                self.Widget:render(self.isOverlay, self.UI.formatter, self.UI.enableReplacer)
            end
        end
    end)

    return self
end

return worldDataHelper:new()
