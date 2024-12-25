---@class worldDataHelper
---@field formatter string
---@field channel integer
worldDataHelper = {
    GameUI = require("modules/external/GameUI"),
    UI = require('modules/UI'),

    renderUi = true,
    isOverlay = false,
    inGame = false,
    inMenu = false,
}

function worldDataHelper:new()
    registerForEvent("onInit", function()
        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu)
            self.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.inGame = true
        end)

        self.GameUI.OnSessionEnd(function()
            self.inGame = false
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

    registerForEvent('onDraw', function()
        if self.inGame and not self.inMenu and self.renderUi then
            UI:render()
        end
    end)
end

return worldDataHelper:new()
