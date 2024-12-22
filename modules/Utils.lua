local Utils = {}


function Utils:GetPlayerGender()
    playerBodyGender = playerBodyGender or Game.GetPlayer():GetResolvedGenderName()
    return (string.find(tostring(playerBodyGender), "Female") and "_Female") or "_Male"
end

function Utils:AddToInventory(item)
    local equipRequest = EquipRequest.new()
    local itemID = ItemID.FromTDBID(TweakDBID.new(item))
    local quantity = 1

    Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), itemID, quantity)
    equipRequest.owner = Game.GetPlayer()
    Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):QueueRequest(equipRequest)
end

function Utils:CalculateDelay(base)
    local currentFPS = 1
    local targetFPS = 30
    local baseDelay = base
    local maxDelay = base + 10

    -- Calculate the scaling factor
    local scalingFactor = 0.2 -- You can adjust this factor based on your preference

    -- Calculate the adjusted delay
    local adjustedDelay = baseDelay + (currentFPS - targetFPS) * scalingFactor

    -- Ensure the delay is not lower than base delay
    if adjustedDelay < base then
        adjustedDelay = base

        -- Ensure the delay isn't too high
    elseif adjustedDelay > maxDelay then
        adjustedDelay = maxDelay
    end

    return adjustedDelay
end

return Utils;
