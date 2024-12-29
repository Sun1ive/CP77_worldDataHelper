---@class worldDataHelper
---@field formatter string
---@field channel integer
worldDataHelper = {
    GameUI = require("modules/external/GameUI"),
    UI = require('modules/UI'),
    Recorder = require('modules/ui/Recorder'),

    CodewareProxy = require('modules/Codeware/Proxy'),

    renderUi = false,
    isOverlay = false,
    inGame = false,
    inMenu = false
}

function worldDataHelper:new()
    registerForEvent("onInit", function()
        self.CodewareProxy:Init()
        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu)
            self.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.inGame = true
            print("====Session start");
        end)

        self.GameUI.OnSessionEnd(function()
            self.inGame = false
            self.CodewareProxy:Stop()
            print("====Session end");
        end)

        self.inGame = not self.GameUI.IsDetached()

    end)

    registerForEvent("onOverlayOpen", function()
        self.isOverlay = true
    end)

    registerForEvent("onOverlayClose", function()
        self.isOverlay = false
    end)

    registerHotkey('renderUi', 'Render UI Key', function()
        self.renderUi = not self.renderUi
    end)

    registerHotkey('recorderAddPointKey', 'Recorder Add Point Key', function()
        if self.Recorder ~= nil and self.Recorder.isStarted == true then
            self.Recorder:insertPoint()
        end
    end)

    registerForEvent('onDraw', function()
        if self.inGame and not self.inMenu and self.renderUi then
            self.UI:render()
        end
    end)
end

return worldDataHelper:new()
