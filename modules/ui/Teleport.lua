---@class FavoriteLocation
---@field id string
---@field name string
---@field type integer 0 = coords, 1 = nodeRef
---@field x number?
---@field y number?
---@field z number?
---@field yaw number?
---@field nodeRef string?

---@class Teleport
---@field destination Vector4
---@field destinationType number 0 = coords; 1 = NodeRef
---@field viewSize number
---@field nodeRef string
---@field favorites FavoriteLocation[]
---@field favoritesLoaded boolean
---@field favoritesFileName string
---@field newFavName string
---@field searchQuery string
local Teleport = {
    Utils = require('modules/Utils'),
    Exporter = require('modules/classes/Exporter'),
    destination = Vector4.new(0, 0, 0, 1),
    destinationType = 0,
    viewSize = 0,
    nodeRef = '',

    favorites = {},
    favoritesLoaded = false,
    favoritesFileName = "teleport_favorites.json",
    newFavName = '',
    searchQuery = ''
}

---Returns default Night City landmarks for initial favorites
---@return FavoriteLocation[]
function Teleport:getDefaultFavorites()
    return {
        {
            id = "fav_h10_apt",
            name = "V's Apartment (Megabuilding H10)",
            type = 0,
            x = -1390.28,
            y = 1269.95,
            z = 122.95,
            yaw = -90.0
        },
        {
            id = "fav_afterlife",
            name = "Afterlife Club",
            type = 0,
            x = -1376.15,
            y = 2083.56,
            z = 30.85,
            yaw = 0.0
        },
        {
            id = "fav_lizzies",
            name = "Lizzie's Bar",
            type = 0,
            x = -1014.28,
            y = 1729.85,
            z = 17.50,
            yaw = 90.0
        },
        {
            id = "fav_embers",
            name = "Embers Restaurant",
            type = 0,
            x = -689.44,
            y = 866.72,
            z = 179.35,
            yaw = 180.0
        },
        {
            id = "fav_judy",
            name = "Judy's Apartment",
            type = 0,
            x = -1025.10,
            y = 2185.30,
            z = 49.20,
            yaw = -45.0
        },
        {
            id = "fav_nomads",
            name = "Aldecaldos Nomad Camp",
            type = 0,
            x = 2341.25,
            y = 110.82,
            z = 70.30,
            yaw = 35.0
        },
        {
            id = "fav_kabuki",
            name = "Kabuki Market",
            type = 0,
            x = -1186.20,
            y = 1826.40,
            z = 17.20,
            yaw = 0.0
        },
        {
            id = "fav_gim_pacifica",
            name = "Grand Imperial Mall (Pacifica)",
            type = 0,
            x = -1700.50,
            y = -2150.00,
            z = 13.50,
            yaw = 0.0
        }
    }
end

---Load favorites from JSON file or fall back to defaults
function Teleport:loadFavorites()
    if self.favoritesLoaded then return end
    self.favoritesLoaded = true

    local content, err = self.Exporter.loadFile(self.favoritesFileName)
    if content and #content > 0 then
        local success, decoded = pcall(function()
            return json.decode(content)
        end)
        if success and type(decoded) == "table" and #decoded > 0 then
            self.favorites = decoded
            print(string.format("[CP77_worldDataHelper] Loaded %d favorite teleport locations", #self.favorites))
            return
        end
    end

    -- Fallback to default presets
    self.favorites = self:getDefaultFavorites()
    self:saveFavorites(true)
end

---Save favorites array to JSON file
---@param silent boolean?
---@return boolean
function Teleport:saveFavorites(silent)
    local success, jsonStr = pcall(function()
        return json.encode(self.favorites)
    end)
    if not success or not jsonStr then
        if not silent then
            self.Utils.UIshowWarningMsg("Failed to encode favorites to JSON")
        end
        return false
    end

    local saved, err = self.Exporter.saveFile(self.favoritesFileName, jsonStr)
    if saved then
        if not silent then
            self.Utils.UIshowNotificationMsg(string.format("Saved %d favorites to %s", #self.favorites, self.favoritesFileName))
        end
        return true
    else
        if not silent then
            self.Utils.UIshowWarningMsg("Failed to save favorites: " .. tostring(err))
        end
        return false
    end
end

---Add current player position as a favorite location
---@param customName string?
function Teleport:addFavoriteFromCurrent(customName)
    local player = Game.GetPlayer()
    if not player then
        self.Utils.UIshowWarningMsg("Player not available")
        return
    end

    local pos = player:GetWorldPosition()
    local orient = player:GetWorldOrientation()
    local euler = orient and orient:ToEulerAngles()
    local yaw = euler and euler.yaw or 0.0

    local name = (customName and customName:match("%S")) and customName or string.format("Waypoint #%d (%.1f, %.1f)", #self.favorites + 1, pos.x, pos.y)
    local newFav = {
        id = "fav_" .. tostring(os.time()) .. "_" .. tostring(#self.favorites + 1),
        name = name,
        type = 0,
        x = self.Utils.roundFloat(pos.x, 4),
        y = self.Utils.roundFloat(pos.y, 4),
        z = self.Utils.roundFloat(pos.z, 4),
        yaw = self.Utils.roundFloat(yaw, 2)
    }

    table.insert(self.favorites, newFav)
    self:saveFavorites()
    self.newFavName = ''
    self.Utils.UIshowNotificationMsg("Added favorite: " .. name)
end

---Add current input field values as a favorite location
---@param customName string?
function Teleport:addFavoriteFromInputs(customName)
    local name = (customName and customName:match("%S")) and customName or string.format("Waypoint #%d", #self.favorites + 1)
    local newFav = {
        id = "fav_" .. tostring(os.time()) .. "_" .. tostring(#self.favorites + 1),
        name = name,
        type = self.destinationType
    }

    if self.destinationType == 0 then
        newFav.x = self.Utils.roundFloat(self.destination.x, 4)
        newFav.y = self.Utils.roundFloat(self.destination.y, 4)
        newFav.z = self.Utils.roundFloat(self.destination.z, 4)
        newFav.yaw = 0.0
    else
        if not self.Utils.isNotEmpty(self.nodeRef) then
            self.Utils.UIshowWarningMsg("Cannot save empty NodeRef")
            return
        end
        newFav.nodeRef = self.nodeRef
    end

    table.insert(self.favorites, newFav)
    self:saveFavorites()
    self.newFavName = ''
    self.Utils.UIshowNotificationMsg("Added favorite: " .. name)
end

---Delete a favorite location by index
---@param index integer
function Teleport:deleteFavorite(index)
    if index >= 1 and index <= #self.favorites then
        local removed = table.remove(self.favorites, index)
        self:saveFavorites(true)
        self.Utils.UIshowNotificationMsg("Removed favorite: " .. (removed.name or "Entry"))
    end
end

---Teleport player directly to a coordinate vector and optional yaw
---@param pos Vector4
---@param yaw number?
function Teleport:teleportToCoords(pos, yaw)
    local player = Game.GetPlayer()
    if not player then
        self.Utils.UIshowWarningMsg("Player not available for teleport")
        return
    end

    local dest = Vector4.new(pos.x, pos.y, pos.z, 1.0)
    local euler
    if yaw then
        euler = EulerAngles.new(0, 0, yaw)
    else
        local orient = player:GetWorldOrientation()
        euler = orient and orient:ToEulerAngles() or EulerAngles.new(0, 0, 0)
    end

    pcall(function()
        Game.GetTeleportationFacility():Teleport(player, dest, euler)
        self.Utils.UIshowNotificationMsg(string.format("Teleported to %.2f, %.2f, %.2f", dest.x, dest.y, dest.z))
    end)
end

---Teleport player directly to a resolved NodeRef
---@param nodeRefStr string
function Teleport:teleportToNodeRefString(nodeRefStr)
    local player = Game.GetPlayer()
    if not player then
        self.Utils.UIshowWarningMsg("Player not available for teleport")
        return
    end

    if not self.Utils.isNotEmpty(nodeRefStr) then
        self.Utils.UIshowWarningMsg("NodeRef is empty")
        return
    end

    pcall(function()
        local resolvedRef = ResolveNodeRef(CreateEntityReference(nodeRefStr, {}).reference, GlobalNodeID.GetRoot())
        if self.Utils.isNotEmpty(resolvedRef.hash) then
            local entity = Game.FindEntityByID(EntityID.new({ hash = resolvedRef.hash }))
            if IsDefined(entity) then
                local targetPos = entity:GetWorldPosition()
                local orient = player:GetWorldOrientation()
                Game.GetTeleportationFacility():Teleport(player, targetPos, orient:ToEulerAngles())
                self.Utils.UIshowNotificationMsg("Teleported to Entity: " .. nodeRefStr)
            else
                local streamingData = Game.GetWorldInspector():FindStreamedNode(resolvedRef.hash)
                if streamingData and streamingData.nodeInstance then
                    print("[CP77_worldDataHelper] Fetched Streamed Node:")
                    print(self.Utils.parseUserData(streamingData.nodeInstance))
                    self.Utils.UIshowNotificationMsg("Inspected Streamed Node: " .. nodeRefStr)
                else
                    self.Utils.UIshowWarningMsg("Streamed Node not found: " .. nodeRefStr)
                end
            end
        else
            self.Utils.UIshowWarningMsg("Could not resolve NodeRef hash")
        end
    end)
end

---Teleport player to a specific FavoriteLocation entry
---@param fav FavoriteLocation
function Teleport:teleportToFavorite(fav)
    if not fav then return end
    if fav.type == 0 or fav.type == "coords" or (fav.x and fav.y and fav.z) then
        local pos = Vector4.new(tonumber(fav.x) or 0, tonumber(fav.y) or 0, tonumber(fav.z) or 0, 1.0)
        self:teleportToCoords(pos, fav.yaw)
    elseif fav.type == 1 or fav.type == "noderef" or fav.nodeRef then
        self:teleportToNodeRefString(fav.nodeRef or "")
    end
end

---Load a favorite location into the destination input fields
---@param fav FavoriteLocation
function Teleport:loadFavoriteToForm(fav)
    if not fav then return end
    if fav.type == 1 or fav.nodeRef then
        self.destinationType = 1
        self.nodeRef = fav.nodeRef or ""
        self.Utils.UIshowNotificationMsg("Loaded NodeRef: " .. (fav.name or ""))
    else
        self.destinationType = 0
        self.destination = Vector4.new(tonumber(fav.x) or 0, tonumber(fav.y) or 0, tonumber(fav.z) or 0, 1.0)
        self.Utils.UIshowNotificationMsg("Loaded coordinates: " .. (fav.name or ""))
    end
end

---Copy a favorite location's coordinates or NodeRef to clipboard
---@param fav FavoriteLocation
function Teleport:copyFavoriteCoordinates(fav)
    if not fav then return end
    if fav.type == 1 or fav.nodeRef then
        ImGui.SetClipboardText(fav.nodeRef or "")
        self.Utils.UIshowNotificationMsg("Copied NodeRef to Clipboard")
    else
        local text = string.format("Vector4.new(%.4f, %.4f, %.4f, 1.0)", tonumber(fav.x) or 0, tonumber(fav.y) or 0, tonumber(fav.z) or 0)
        ImGui.SetClipboardText(text)
        self.Utils.UIshowNotificationMsg("Copied Vector4 to Clipboard")
    end
end

---Teleport the player to the selected destination or node from form
function Teleport:teleportPlayer()
    if self.destinationType == 0 then
        self:teleportToCoords(self.destination)
    else
        self:teleportToNodeRefString(self.nodeRef)
    end
end

---Render Teleport panel
function Teleport:render()
    self.viewSize = self.Utils.getViewSize()
    local player = Game.GetPlayer()

    -- Ensure favorites are loaded
    self:loadFavorites()

    -- -------------------------------------------------------------
    -- SECTION 1: Target Destination Inputs
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Destination Type:")
    ImGui.PushItemWidth(100 * self.viewSize)
    self.destinationType = ImGui.RadioButton("Coordinates", self.destinationType, 0)
    ImGui.SameLine()
    self.destinationType = ImGui.RadioButton("NodeRef", self.destinationType, 1)
    ImGui.PopItemWidth()

    ImGui.Separator()

    if self.destinationType == 0 then
        if player then
            local playerPos = player:GetWorldPosition()
            if ImGui.Button("Copy Current Position") then
                self.destination = Vector4.new(playerPos.x, playerPos.y, playerPos.z, 1.0)
            end
            ImGui.SameLine()
            if ImGui.Button("Zero Coordinates") then
                self.destination = Vector4.new(0, 0, 0, 1.0)
            end
        end

        ImGui.Text("Target Coordinates:")
        ImGui.PushItemWidth(100 * self.viewSize)
        self.destination.x = self.Utils.handleVector4Input("TPDest", "x", self.destination)
        ImGui.SameLine()
        self.destination.y = self.Utils.handleVector4Input("TPDest", "y", self.destination)
        ImGui.SameLine()
        self.destination.z = self.Utils.handleVector4Input("TPDest", "z", self.destination)
        ImGui.PopItemWidth()
    else
        ImGui.Text("NodeRef Reference:")
        ImGui.PushItemWidth(280 * self.viewSize)
        self.nodeRef = ImGui.InputTextWithHint("##NodeRefInput", "e.g. #01_q001_sub_01", self.nodeRef, 1024, ImGuiInputTextFlags.CharsNoBlank)
        self.Utils.tooltip("Enter NodeRef string to resolve and teleport")
        ImGui.PopItemWidth()
    end

    ImGui.Spacing()
    if ImGui.Button("Teleport Player Now") then
        self:teleportPlayer()
    end

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- SECTION 2: Save to Favorites
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, "Save Location as Favorite:")
    ImGui.PushItemWidth(220 * self.viewSize)
    self.newFavName = ImGui.InputTextWithHint("##NewFavName", "Custom Name (optional)", self.newFavName, 128)
    self.Utils.tooltip("Enter a memorable label for this location")
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if ImGui.Button("Save Live Pos") then
        self:addFavoriteFromCurrent(self.newFavName)
    end
    self.Utils.tooltip("Save current live player position and facing orientation as a favorite")

    ImGui.SameLine()
    if ImGui.Button("Save Target") then
        self:addFavoriteFromInputs(self.newFavName)
    end
    self.Utils.tooltip("Save the destination coordinates or NodeRef entered above")

    ImGui.Separator()

    -- -------------------------------------------------------------
    -- SECTION 3: Favorite Locations List
    -- -------------------------------------------------------------
    ImGui.TextColored(0.4, 0.8, 1.0, 1.0, string.format("Favorite Locations (%d):", #self.favorites))

    ImGui.PushItemWidth(200 * self.viewSize)
    self.searchQuery = ImGui.InputTextWithHint("##FavSearch", "Search favorites...", self.searchQuery, 128)
    ImGui.PopItemWidth()

    ImGui.SameLine()
    if ImGui.Button("Reset Presets") then
        self.favorites = self:getDefaultFavorites()
        self:saveFavorites()
        self.Utils.UIshowNotificationMsg("Reset favorites to default landmarks")
    end
    self.Utils.tooltip("Restore built-in Night City landmark favorites")

    ImGui.Spacing()

    -- Filter favorites based on search query
    local query = self.searchQuery:lower():gsub("^%s*(.-)%s*$", "%1")
    local matchingFavorites = {}
    for i, fav in ipairs(self.favorites) do
        local matches = true
        if query ~= '' then
            local nameMatch = fav.name and fav.name:lower():find(query, 1, true)
            local coordsMatch = false
            if fav.type == 0 and fav.x and fav.y and fav.z then
                local coordsStr = string.format("%.1f %.1f %.1f", fav.x, fav.y, fav.z)
                coordsMatch = coordsStr:find(query, 1, true) ~= nil
            elseif fav.type == 1 and fav.nodeRef then
                coordsMatch = fav.nodeRef:lower():find(query, 1, true) ~= nil
            end
            matches = (nameMatch ~= nil) or coordsMatch
        end

        if matches then
            table.insert(matchingFavorites, { index = i, data = fav })
        end
    end

    if #matchingFavorites == 0 then
        if #self.favorites == 0 then
            ImGui.TextColored(0.7, 0.7, 0.7, 1.0, "No saved favorites yet. Save a location above!")
        else
            ImGui.TextColored(0.7, 0.7, 0.7, 1.0, "No favorites match your search filter.")
        end
    else
        ImGui.BeginChild("FavoritesListRegion", 0, 220 * self.viewSize, true)

        for _, item in ipairs(matchingFavorites) do
            local originalIndex = item.index
            local fav = item.data
            local favId = fav.id or tostring(originalIndex)

            ImGui.PushID("FavRow_" .. favId)

            -- Name and location detail
            ImGui.TextColored(1.0, 0.85, 0.3, 1.0, tostring(fav.name or "Unnamed"))
            ImGui.SameLine()

            if fav.type == 0 or (fav.x and fav.y and fav.z) then
                ImGui.TextColored(0.6, 0.6, 0.6, 1.0, string.format("(%.2f, %.2f, %.2f)", tonumber(fav.x) or 0, tonumber(fav.y) or 0, tonumber(fav.z) or 0))
            else
                ImGui.TextColored(0.6, 0.6, 0.6, 1.0, string.format("[NodeRef: %s]", tostring(fav.nodeRef or "")))
            end

            -- Action buttons
            if ImGui.Button("Teleport##" .. favId) then
                self:teleportToFavorite(fav)
            end
            self.Utils.tooltip("Teleport immediately to this location")

            ImGui.SameLine()
            if ImGui.Button("Load##" .. favId) then
                self:loadFavoriteToForm(fav)
            end
            self.Utils.tooltip("Load coordinates into inputs for editing")

            ImGui.SameLine()
            if ImGui.Button("Copy##" .. favId) then
                self:copyFavoriteCoordinates(fav)
            end
            self.Utils.tooltip("Copy coordinates to clipboard")

            ImGui.SameLine()
            if ImGui.Button("Delete##" .. favId) then
                self:deleteFavorite(originalIndex)
                ImGui.PopID()
                break
            end
            self.Utils.tooltip("Delete this favorite location")

            ImGui.Separator()
            ImGui.PopID()
        end

        ImGui.EndChild()
    end
end

return Teleport

