-- Grouper: Addon to help manage PUG groups for raids, dungeons, and world bosses
local Grouper = {}
Grouper.version = "1.0.40"

-- Default settings
local defaults = {
    raidSize = 25,
    spamInterval = 60, -- 60 seconds default
    tradeInterval = 60,
    lfgInterval = 60,
    generalInterval = 60,
    bosses = {
        -- World Bosses
        ["Azuregos"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
        ["Lord Kazzak"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
        ["Emeriss"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
        ["Lethon"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
        ["Taerar"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
        ["Ysondre"] = { tanks = 1, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },

        -- 40-Man Raids
        ["Molten Core"] = { tanks = 3, healers = 8, hr = nil, custom = nil, size = 40, category = "40-Man Raid" },
        ["Onyxia's Lair"] = { tanks = 2, healers = 8, hr = nil, custom = nil, size = 40, category = "40-Man Raid" },
        ["Blackwing Lair"] = { tanks = 3, healers = 8, hr = nil, custom = nil, size = 40, category = "40-Man Raid" },
        ["Ahn'Qiraj (AQ40)"] = { tanks = 3, healers = 8, hr = nil, custom = nil, size = 40, category = "40-Man Raid" },
        ["Naxxramas"] = { tanks = 4, healers = 10, hr = nil, custom = nil, size = 40, category = "40-Man Raid" },

        -- 20-Man Raids
        ["Zul'Gurub"] = { tanks = 2, healers = 5, hr = nil, custom = nil, size = 20, category = "20-Man Raid" },
        ["Ruins of Ahn'Qiraj (AQ20)"] = { tanks = 2, healers = 4, hr = nil, custom = nil, size = 20, category = "20-Man Raid" },

        -- 5-Man Dungeons
        ["Stratholme"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
        ["Scholomance"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
        ["Upper Blackrock Spire"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
        ["Lower Blackrock Spire"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
        ["Dire Maul"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
        ["Blackrock Depths"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    }
}

-- Boss categories for UI
local bossCategories = {
    "World Boss",
    "40-Man Raid",
    "20-Man Raid",
    "5-Man Dungeon"
}

-- LFG Activity ID mappings (for Group Finder)
-- These IDs may vary by version - will use "Other" category if specific IDs don't work
local lfgActivityMap = {
    -- If specific activity IDs are available, they can be added here
    -- For now, we'll use the generic approach with activity search
}

-- Active session data
local activeSession = {
    active = false,
    boss = nil,
    hr = nil,
    tradeTimer = nil,
    lfgTimer = nil,
    tradeNextSpam = 0,
    lfgNextSpam = 0,
    generalNextSpam = 0,
    lfgListingID = nil,
    hasShownFullWarning = false,
}

-- Major cities for Trade chat
local majorCities = {
    ["Ironforge"] = true,
    ["Stormwind City"] = true,
    ["Orgrimmar"] = true,
    ["Thunder Bluff"] = true,
    ["Undercity"] = true,
    ["Darnassus"] = true,
}

-- UI Frame references
local tradeButton = nil
local lfgButton = nil
local generalButton = nil
local stopButton = nil
local buttonContainer = nil
local configFrame = nil
local minimapButton = nil
local killLogFrame = nil
local topFrameLevel = 100 -- Track highest frame level for proper z-ordering

-- ElvUI Integration
local E, L, V, P, G
local S -- ElvUI Skins module

-- Check if ElvUI is loaded
local function IsElvUILoaded()
    if not ElvUI then return false end
    E, L, V, P, G = unpack(ElvUI)
    S = E:GetModule('Skins', true)
    return S ~= nil
end

-- Apply ElvUI skin to a frame
local function ApplyElvUISkin(frame, frameType)
    if not IsElvUILoaded() then return end

    if frameType == "frame" then
        S:HandleFrame(frame, true)
    elseif frameType == "button" then
        S:HandleButton(frame)
    elseif frameType == "editbox" then
        S:HandleEditBox(frame)
    elseif frameType == "dropdown" then
        S:HandleDropDownBox(frame)
    elseif frameType == "slider" then
        S:HandleSliderFrame(frame)
    elseif frameType == "scrollbar" then
        S:HandleScrollBar(frame)
    end
end

-- Initialize saved variables
function Grouper:InitDB()
    if not GrouperDB then
        GrouperDB = {}
    end

    if not GrouperDB.raidSize then
        GrouperDB.raidSize = defaults.raidSize
    end

    if not GrouperDB.tradeInterval then
        GrouperDB.tradeInterval = defaults.tradeInterval
    end

    if not GrouperDB.lfgInterval then
        GrouperDB.lfgInterval = defaults.lfgInterval
    end

    if not GrouperDB.generalInterval then
        GrouperDB.generalInterval = defaults.generalInterval
    end

    if not GrouperDB.bosses then
        GrouperDB.bosses = {}
    end

    if not GrouperDB.bossKills then
        GrouperDB.bossKills = {}
    end

    if GrouperDB.minimapButton == nil then
        GrouperDB.minimapButton = {
            show = true,
            position = 200
        }
    end

    -- Initialize button container position
    if not GrouperDB.buttonContainerPosition then
        GrouperDB.buttonContainerPosition = {}
    end

    -- Initialize last boss setting
    if not GrouperDB.lastBoss then
        GrouperDB.lastBoss = nil
    end

    -- Ensure all default bosses exist
    for boss, config in pairs(defaults.bosses) do
        if not GrouperDB.bosses[boss] then
            GrouperDB.bosses[boss] = {
                tanks = config.tanks,
                healers = config.healers,
                hr = config.hr,
                custom = config.custom,
                size = config.size,
                category = config.category
            }
        else
            -- Ensure custom field exists on existing boss configs
            if GrouperDB.bosses[boss].custom == nil then
                GrouperDB.bosses[boss].custom = config.custom
            end
        end
    end
end

-- Get boss config (merge saved with defaults)
function Grouper:GetBossConfig(bossName)
    if not bossName or bossName == "" then
        return nil
    end

    -- Try exact match first
    if GrouperDB.bosses[bossName] then
        return GrouperDB.bosses[bossName]
    end

    -- Try lowercase match (backwards compatibility)
    local bossLower = string.lower(bossName)
    for name, config in pairs(GrouperDB.bosses) do
        if string.lower(name) == bossLower then
            return config
        end
    end

    -- Create new boss with defaults
    GrouperDB.bosses[bossName] = {
        tanks = 1,
        healers = 6,
        hr = nil,
        size = 25,
        category = "Custom"
    }
    return GrouperDB.bosses[bossName]
end

-- Get current layer from Nova World Buffs addon
function Grouper:GetCurrentLayer()
    -- Check if Nova World Buffs is installed and has layer info
    -- NWB uses AceAddon-3.0, so we need to get it via LibStub
    local NWB = nil
    if LibStub then
        local success, addon = pcall(LibStub, "AceAddon-3.0")
        if success and addon then
            NWB = addon:GetAddon("NovaWorldBuffs", true)
        end
    end

    if NWB then
        -- Try NWB function first (most reliable)
        if NWB.getCurrentLayerNum then
            local layer = NWB:getCurrentLayerNum()
            if layer and layer > 0 then
                return layer
            end
        end

        -- Try direct variables as fallback
        if NWB.currentLayer and NWB.currentLayer > 0 then
            return NWB.currentLayer
        elseif NWB.currentLayerShared and NWB.currentLayerShared > 0 then
            return NWB.currentLayerShared
        end
    end
    return nil
end

-- Mark boss as killed
function Grouper:MarkBossKilled(bossName)
    if not bossName or bossName == "" then
        return
    end

    local layer = self:GetCurrentLayer()
    local killData = {
        timestamp = time(),
        layer = layer
    }

    -- Initialize kills table for this boss if needed
    if not GrouperDB.bossKills[bossName] then
        GrouperDB.bossKills[bossName] = {}
    end

    -- If old format (just a timestamp), convert it
    if type(GrouperDB.bossKills[bossName]) == "number" then
        GrouperDB.bossKills[bossName] = {
            {
                timestamp = GrouperDB.bossKills[bossName],
                layer = nil
            }
        }
    end

    -- Add new kill
    table.insert(GrouperDB.bossKills[bossName], killData)

    local layerText = layer and (" on Layer " .. layer) or ""
    print("|cff00ff00[Grouper]|r Marked " .. bossName .. " as killed" .. layerText)
    if configFrame then
        self:UpdateConfigUI()
    end
end

-- Get all kills for a boss
function Grouper:GetBossKills(bossName)
    if not bossName or not GrouperDB.bossKills[bossName] then
        return {}
    end

    local kills = GrouperDB.bossKills[bossName]

    -- Handle old format (single timestamp)
    if type(kills) == "number" then
        return {{timestamp = kills, layer = nil}}
    end

    return kills
end

-- Get time since last kill
function Grouper:GetTimeSinceKill(bossName)
    local kills = self:GetBossKills(bossName)
    if #kills == 0 then
        return nil
    end

    -- Find most recent kill
    local mostRecent = kills[1].timestamp
    for i = 2, #kills do
        if kills[i].timestamp > mostRecent then
            mostRecent = kills[i].timestamp
        end
    end

    return time() - mostRecent
end

-- Format time since kill for display
function Grouper:FormatTimeSinceKill(bossName)
    local kills = self:GetBossKills(bossName)
    if #kills == 0 then
        return "Never killed"
    end

    -- Sort kills by timestamp (most recent first)
    local sortedKills = {}
    for i, kill in ipairs(kills) do
        sortedKills[i] = kill
    end
    table.sort(sortedKills, function(a, b) return a.timestamp > b.timestamp end)

    -- Build display text with recent kills
    local lines = {}
    local now = time()

    for i = 1, math.min(3, #sortedKills) do
        local kill = sortedKills[i]
        local timeSince = now - kill.timestamp
        local days = math.floor(timeSince / 86400)
        local hours = math.floor((timeSince % 86400) / 3600)

        local timeText
        if days > 0 then
            timeText = string.format("%dd %dh ago", days, hours)
        elseif hours > 0 then
            timeText = string.format("%dh ago", hours)
        else
            timeText = "<1h ago"
        end

        local layerText = kill.layer and (" L" .. kill.layer) or ""
        table.insert(lines, timeText .. layerText)
    end

    return table.concat(lines, ", ")
end

-- Get instance lockout info
function Grouper:GetInstanceLockout(bossName)
    local numSaved = GetNumSavedInstances()

    for i = 1, numSaved do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)

        -- Try to match instance name with boss name
        if name and locked and string.find(bossName, name) or string.find(name, bossName) then
            local hours = math.floor(reset / 3600)
            local days = math.floor(hours / 24)
            local remainingHours = hours % 24

            if days > 0 then
                return string.format("Locked out - %dd %dh remaining", days, remainingHours)
            elseif hours > 0 then
                return string.format("Locked out - %d hour%s remaining", hours, hours > 1 and "s" or "")
            else
                local minutes = math.floor(reset / 60)
                return string.format("Locked out - %d min remaining", minutes)
            end
        end
    end

    return "Not saved"
end

-- Create Kill Log Popup
function Grouper:CreateKillLogPopup()
    if killLogFrame then
        return killLogFrame
    end

    -- Main frame
    killLogFrame = CreateFrame("Frame", "GrouperKillLogFrame", UIParent, "BasicFrameTemplateWithInset")
    killLogFrame:SetSize(500, 400)
    killLogFrame:SetPoint("CENTER")
    killLogFrame:SetMovable(true)
    killLogFrame:EnableMouse(true)
    killLogFrame:RegisterForDrag("LeftButton")
    killLogFrame:SetScript("OnDragStart", killLogFrame.StartMoving)
    killLogFrame:SetScript("OnDragStop", killLogFrame.StopMovingOrSizing)
    killLogFrame:SetFrameStrata("HIGH")
    killLogFrame:SetToplevel(true)

    -- Raise frame when shown or clicked with proper z-ordering
    local function raiseKillLogFrame(self)
        topFrameLevel = topFrameLevel + 1
        self:SetFrameLevel(topFrameLevel)
        self:Raise()
    end

    killLogFrame:SetScript("OnShow", raiseKillLogFrame)
    killLogFrame:SetScript("OnMouseDown", raiseKillLogFrame)

    -- Apply ElvUI skin
    ApplyElvUISkin(killLogFrame, "frame")

    killLogFrame.title = killLogFrame:CreateFontString(nil, "OVERLAY")
    killLogFrame.title:SetFontObject("GameFontHighlight")
    killLogFrame.title:SetPoint("LEFT", killLogFrame.TitleBg, "LEFT", 5, 0)
    killLogFrame.title:SetText("Kill Log")

    -- Boss name label
    local bossLabel = killLogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bossLabel:SetPoint("TOP", killLogFrame, "TOP", 0, -30)
    bossLabel:SetText("Boss Name")
    killLogFrame.bossLabel = bossLabel

    -- Scroll frame for kill entries
    local scrollFrame = CreateFrame("ScrollFrame", "GrouperKillLogScrollFrame", killLogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", killLogFrame, "TOPLEFT", 10, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", killLogFrame, "BOTTOMRIGHT", -30, 50)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(450, 1)
    scrollFrame:SetScrollChild(scrollChild)
    killLogFrame.scrollChild = scrollChild

    -- Apply ElvUI skin to scroll bar
    ApplyElvUISkin(scrollFrame.ScrollBar or scrollFrame, "scrollbar")

    -- Add Kill button
    local addButton = CreateFrame("Button", "GrouperAddKillButton", killLogFrame, "UIPanelButtonTemplate")
    addButton:SetSize(120, 30)
    addButton:SetPoint("BOTTOMLEFT", killLogFrame, "BOTTOMLEFT", 20, 15)
    addButton:SetText("Add Kill")
    addButton:SetScript("OnClick", function()
        Grouper:ShowAddKillDialog(killLogFrame.currentBoss)
    end)
    ApplyElvUISkin(addButton, "button")

    -- Close button (bottom right)
    local closeButton = CreateFrame("Button", "GrouperKillLogCloseButton", killLogFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 30)
    closeButton:SetPoint("BOTTOMRIGHT", killLogFrame, "BOTTOMRIGHT", -20, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        killLogFrame:Hide()
    end)
    ApplyElvUISkin(closeButton, "button")

    killLogFrame:Hide()
    return killLogFrame
end

-- Show Add Kill Dialog
function Grouper:ShowAddKillDialog(bossName)
    if not bossName then return end

    -- Create dialog frame
    local dialog = CreateFrame("Frame", "GrouperAddKillDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(350, 180)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetToplevel(true)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)

    -- Apply ElvUI skin
    ApplyElvUISkin(dialog, "frame")

    dialog.title = dialog:CreateFontString(nil, "OVERLAY")
    dialog.title:SetFontObject("GameFontHighlight")
    dialog.title:SetPoint("LEFT", dialog.TitleBg, "LEFT", 5, 0)
    dialog.title:SetText("Add Kill Entry")

    -- Boss name label
    local bossLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bossLabel:SetPoint("TOP", dialog, "TOP", 0, -30)
    bossLabel:SetText(bossName)

    -- Layer label
    local layerLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layerLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -65)
    layerLabel:SetText("Layer:")

    -- Layer dropdown
    local layerDropdown = CreateFrame("Frame", "GrouperLayerDropdown", dialog, "UIDropDownMenuTemplate")
    layerDropdown:SetPoint("TOPLEFT", layerLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(layerDropdown, 120)

    local selectedLayer = nil

    -- Try to auto-detect layer from Nova World Buffs
    local currentLayer = Grouper:GetCurrentLayer()
    if currentLayer then
        selectedLayer = currentLayer
    end

    local function OnLayerClick(self)
        selectedLayer = self.value
        UIDropDownMenu_SetSelectedValue(layerDropdown, self.value)
        UIDropDownMenu_SetText(layerDropdown, self.value == 0 and "Unknown" or "Layer " .. self.value)
    end

    local function InitializeLayerDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- Unknown option
        info.text = "Unknown"
        info.value = 0
        info.func = OnLayerClick
        UIDropDownMenu_AddButton(info)

        -- Layers 1-10 (should cover most servers)
        for i = 1, 10 do
            info = UIDropDownMenu_CreateInfo()
            info.text = "Layer " .. i
            info.value = i
            info.func = OnLayerClick
            UIDropDownMenu_AddButton(info)
        end
    end

    UIDropDownMenu_Initialize(layerDropdown, InitializeLayerDropdown)

    if selectedLayer then
        UIDropDownMenu_SetSelectedValue(layerDropdown, selectedLayer)
        UIDropDownMenu_SetText(layerDropdown, "Layer " .. selectedLayer)
    else
        UIDropDownMenu_SetSelectedValue(layerDropdown, 0)
        UIDropDownMenu_SetText(layerDropdown, "Unknown")
        selectedLayer = 0
    end

    -- Note: ElvUI skin not applied to dropdown as it interferes with functionality

    -- Add button
    local addButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    addButton:SetSize(100, 30)
    addButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 15)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local layer = selectedLayer == 0 and nil or selectedLayer
        Grouper:AddKillManually(bossName, layer)
        dialog:Hide()
    end)
    ApplyElvUISkin(addButton, "button")

    -- Cancel button
    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 30)
    cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 15)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    ApplyElvUISkin(cancelButton, "button")

    -- Close on escape
    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)

    dialog:Show()
end

-- Add kill manually
function Grouper:AddKillManually(bossName, layer)
    local killData = {
        timestamp = time(),
        layer = layer
    }

    -- Initialize kills table for this boss if needed
    if not GrouperDB.bossKills[bossName] then
        GrouperDB.bossKills[bossName] = {}
    end

    -- If old format (just a timestamp), convert it
    if type(GrouperDB.bossKills[bossName]) == "number" then
        GrouperDB.bossKills[bossName] = {
            {
                timestamp = GrouperDB.bossKills[bossName],
                layer = nil
            }
        }
    end

    -- Add new kill
    table.insert(GrouperDB.bossKills[bossName], killData)

    local layerText = layer and (" on Layer " .. layer) or ""
    print("|cff00ff00[Grouper]|r Added kill entry for " .. bossName .. layerText)

    -- Refresh the kill log if it's open
    if killLogFrame and killLogFrame:IsShown() and killLogFrame.currentBoss == bossName then
        self:UpdateKillLog(bossName)
    end

    -- Update config UI if open
    if configFrame then
        self:UpdateConfigUI()
    end
end

-- Update Kill Log display
function Grouper:UpdateKillLog(bossName)
    if not killLogFrame then
        self:CreateKillLogPopup()
    end

    killLogFrame.currentBoss = bossName
    killLogFrame.bossLabel:SetText(bossName)

    -- Clear existing entries
    local scrollChild = killLogFrame.scrollChild
    for i, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Get kills
    local kills = self:GetBossKills(bossName)

    if #kills == 0 then
        -- Show "No kills recorded" message
        local noKillsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noKillsText:SetPoint("TOP", scrollChild, "TOP", 0, -10)
        noKillsText:SetText("No kills recorded for this boss")
        noKillsText:SetTextColor(0.7, 0.7, 0.7)
        return
    end

    -- Sort kills by timestamp (most recent first)
    local sortedKills = {}
    for i, kill in ipairs(kills) do
        sortedKills[i] = kill
    end
    table.sort(sortedKills, function(a, b) return a.timestamp > b.timestamp end)

    -- Create header
    local headerFrame = CreateFrame("Frame", nil, scrollChild)
    headerFrame:SetSize(450, 25)
    headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)

    local dateHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dateHeader:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
    dateHeader:SetText("Date & Time")
    dateHeader:SetTextColor(1, 0.82, 0)

    local layerHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    layerHeader:SetPoint("RIGHT", headerFrame, "RIGHT", -10, 0)
    layerHeader:SetText("Layer")
    layerHeader:SetTextColor(1, 0.82, 0)

    -- Create kill entries
    local yOffset = -30
    for i, kill in ipairs(sortedKills) do
        local entryFrame = CreateFrame("Frame", nil, scrollChild)
        entryFrame:SetSize(450, 20)
        entryFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)

        -- Date text
        local dateText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dateText:SetPoint("LEFT", entryFrame, "LEFT", 10, 0)
        dateText:SetText(date("%Y-%m-%d %H:%M:%S", kill.timestamp))

        -- Layer text
        local layerText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        layerText:SetPoint("RIGHT", entryFrame, "RIGHT", -10, 0)
        if kill.layer then
            layerText:SetText("Layer " .. kill.layer)
            layerText:SetTextColor(0.5, 1, 0.5)
        else
            layerText:SetText("Unknown")
            layerText:SetTextColor(0.7, 0.7, 0.7)
        end

        yOffset = yOffset - 25
    end

    -- Update scroll child height
    scrollChild:SetHeight(math.max(300, math.abs(yOffset) + 30))
end

-- Show Kill Log
function Grouper:ShowKillLog(bossName)
    if not killLogFrame then
        self:CreateKillLogPopup()
    end

    self:UpdateKillLog(bossName)
    killLogFrame:Show()
end

-- Check if in major city
function Grouper:InMajorCity()
    local zone = GetRealZoneText()
    return majorCities[zone] == true
end

-- Scan raid composition
function Grouper:ScanRaid()
    local inRaid = IsInRaid()
    local inParty = IsInGroup()

    local tanks = 0
    local healers = 0
    local classCounts = {}
    local numMembers = 0

    -- Handle solo (not in group or raid yet)
    if not inRaid and not inParty then
        numMembers = 1
        local _, playerClass = UnitClass("player")
        classCounts[playerClass] = 1
        local playerRole = UnitGroupRolesAssigned("player")
        if playerRole == "TANK" then
            tanks = 1
        elseif playerRole == "HEALER" then
            healers = 1
        end
        return numMembers, tanks, healers, classCounts
    end

    if inRaid then
        -- Raid group
        numMembers = GetNumGroupMembers()
        for i = 1, numMembers do
            local _, _, subgroup, _, _, class, _, online, isDead = GetRaidRosterInfo(i)

            if online and not isDead then
                -- Count classes
                classCounts[class] = (classCounts[class] or 0) + 1

                -- Check role (if available)
                local role = UnitGroupRolesAssigned("raid" .. i)
                if role == "TANK" then
                    tanks = tanks + 1
                elseif role == "HEALER" then
                    healers = healers + 1
                end
            end
        end
    else
        -- Party group (not converted to raid yet)
        local partyMembers = GetNumGroupMembers() - 1 -- Excludes player
        numMembers = partyMembers + 1 -- Include player

        -- Count player first
        local _, playerClass = UnitClass("player")
        classCounts[playerClass] = (classCounts[playerClass] or 0) + 1
        local playerRole = UnitGroupRolesAssigned("player")
        if playerRole == "TANK" then
            tanks = tanks + 1
        elseif playerRole == "HEALER" then
            healers = healers + 1
        end

        -- Count party members
        for i = 1, partyMembers do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local _, class = UnitClass(unit)
                classCounts[class] = (classCounts[class] or 0) + 1

                local role = UnitGroupRolesAssigned(unit)
                if role == "TANK" then
                    tanks = tanks + 1
                elseif role == "HEALER" then
                    healers = healers + 1
                end
            end
        end
    end

    return numMembers, tanks, healers, classCounts
end

-- Generate recruitment message
function Grouper:GenerateMessage()
    local numRaid, tanks, healers, classCounts = self:ScanRaid()
    local config = self:GetBossConfig(activeSession.boss)
    local raidSize = config.size or GrouperDB.raidSize or 25

    -- Calculate needs
    local tanksNeeded = math.max(0, config.tanks - tanks)
    local healersNeeded = math.max(0, config.healers - healers)

    -- Calculate raid percentage
    local raidPercent = numRaid / raidSize

    -- Build message (exclude count if under 20% filled)
    local msg
    if raidPercent < 0.2 then
        msg = string.format("LFM %s", activeSession.boss)
    else
        msg = string.format("LFM %s %d/%d", activeSession.boss, numRaid, raidSize)
    end

    -- Add needs
    if raidPercent < 0.6 then
        -- Under 60%: simple "Need all" message
        msg = msg .. " - Need all"
    else
        -- At 60%+: show role needs (tanks/healers)
        -- At 80%+: also show missing classes
        local roleNeeds = {}
        local classNeeds = {}

        if tanksNeeded > 0 then
            table.insert(roleNeeds, tanksNeeded .. " Tank" .. (tanksNeeded > 1 and "s" or ""))
        end
        if healersNeeded > 0 then
            table.insert(roleNeeds, healersNeeded .. " Healer" .. (healersNeeded > 1 and "s" or ""))
        end

        -- Only check for missing classes at 80%+
        if raidPercent >= 0.8 then
            local classNames = {
                ["WARRIOR"] = "Warriors",
                ["PALADIN"] = "Paladins",
                ["HUNTER"] = "Hunters",
                ["ROGUE"] = "Rogues",
                ["PRIEST"] = "Priests",
                ["SHAMAN"] = "Shamans",
                ["MAGE"] = "Mages",
                ["WARLOCK"] = "Warlocks",
                ["DRUID"] = "Druids"
            }

            -- Get player faction for pre-TBC class filtering
            local playerFaction = UnitFactionGroup("player")

            for class, name in pairs(classNames) do
                -- Skip Paladins for Horde (pre-TBC)
                if class == "PALADIN" and playerFaction == "Horde" then
                    -- Skip
                -- Skip Shamans for Alliance (pre-TBC)
                elseif class == "SHAMAN" and playerFaction == "Alliance" then
                    -- Skip
                elseif not classCounts[class] or classCounts[class] == 0 then
                    table.insert(classNeeds, name)
                end
            end
        end

        -- Format: "Need [roles] / [classes]"
        if #roleNeeds > 0 or #classNeeds > 0 then
            msg = msg .. " - Need "
            if #roleNeeds > 0 and #classNeeds > 0 then
                msg = msg .. table.concat(roleNeeds, ", ") .. " / " .. table.concat(classNeeds, ", ")
            elseif #roleNeeds > 0 then
                msg = msg .. table.concat(roleNeeds, ", ")
            else
                msg = msg .. table.concat(classNeeds, ", ")
            end
        end
    end

    -- Add HR at the end
    local hrItem = activeSession.hr or config.hr
    if hrItem then
        msg = msg .. " - " .. hrItem .. " HR"
    end

    -- Add custom text at the end
    local customText = config.custom
    if customText and customText ~= "" then
        msg = msg .. " - " .. customText
    end

    return msg, numRaid, raidSize
end

-- Send message to channel
function Grouper:SendToChannel(channel)
    local msg = self:GenerateMessage()
    local channelNum = GetChannelName(channel)

    if channelNum and channelNum > 0 then
        SendChatMessage(msg, "CHANNEL", nil, channelNum)
        print("|cff00ff00[Grouper]|r Sent to " .. channel .. ": " .. msg)
    else
        print("|cffff0000[Grouper]|r Channel '" .. channel .. "' not found")
    end
end

-- Find appropriate LFG activity ID for boss/dungeon
function Grouper:FindLFGActivity(bossName)
    -- Check if C_LFGList API is available (Anniversary/Season of Discovery)
    if not C_LFGList or not C_LFGList.GetAvailableActivities then
        return nil
    end

    -- Try to find a matching activity
    -- This is a simplified approach - activity IDs can be added to lfgActivityMap for specific matches
    local categoryID = 2 -- Dungeons category, can be adjusted
    local activities = C_LFGList.GetAvailableActivities(categoryID)

    if activities then
        for _, activityID in ipairs(activities) do
            local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
            if activityInfo and activityInfo.fullName then
                -- Try to match activity name with boss name
                if string.find(string.lower(activityInfo.fullName), string.lower(bossName)) then
                    return activityID
                end
            end
        end
    end

    -- Fall back to "Other" category if available
    -- Activity ID for "Other" varies, but typically around 1-50 range
    return nil
end

-- Update or create LFG listing
function Grouper:UpdateLFGListing()
    -- Only proceed if C_LFGList is available
    if not C_LFGList or not C_LFGList.CreateListing then
        return
    end

    if not activeSession.active then
        return
    end

    local msg = self:GenerateMessage()
    local config = self:GetBossConfig(activeSession.boss)
    local activityID = self:FindLFGActivity(activeSession.boss)

    -- If we don't have a specific activity, try using a generic one
    -- Many Classic versions support creating listings even without perfect activity match
    if not activityID then
        activityID = 1 -- Generic "Other" activity, may vary by version
    end

    if activeSession.lfgListingID then
        -- Update existing listing
        if C_LFGList.UpdateListing then
            local success = pcall(function()
                C_LFGList.UpdateListing(activeSession.lfgListingID, {
                    name = msg,
                    comment = msg,
                    voiceChat = "",
                    iLvl = 0,
                    honorLevel = 0,
                    isPrivate = false,
                    isAutoAccept = false,
                })
            end)
        end
    else
        -- Create new listing
        local success, result = pcall(function()
            return C_LFGList.CreateListing(activityID, msg, 0, 0, "", false, false, false)
        end)

        if success and result then
            activeSession.lfgListingID = result
            print("|cff00ff00[Grouper]|r Created Group Finder listing")
        end
    end
end

-- Remove LFG listing
function Grouper:RemoveLFGListing()
    if activeSession.lfgListingID and C_LFGList and C_LFGList.RemoveListing then
        pcall(function()
            C_LFGList.RemoveListing(activeSession.lfgListingID)
        end)
        activeSession.lfgListingID = nil
        print("|cff00ff00[Grouper]|r Removed Group Finder listing")
    end
end

-- Create or update UI buttons
function Grouper:CreateButtons()
    -- Create container frame if it doesn't exist
    if not buttonContainer then
        buttonContainer = CreateFrame("Frame", "GrouperButtonContainer", UIParent)
        buttonContainer:SetSize(200, 210) -- Height for 4 buttons + spacing
        buttonContainer:SetMovable(true)
        buttonContainer:EnableMouse(true)
        buttonContainer:RegisterForDrag("LeftButton")

        -- Make container draggable
        buttonContainer:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        buttonContainer:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            GrouperDB.buttonContainerPosition = {
                point = point,
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs
            }
        end)

        -- Restore saved position or use default
        local saved = GrouperDB.buttonContainerPosition
        if saved and saved.point then
            buttonContainer:SetPoint(saved.point, UIParent, saved.relativePoint, saved.xOfs, saved.yOfs)
        else
            buttonContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

    -- Stop button
    if not stopButton then
        stopButton = CreateFrame("Button", "GrouperStopButton", buttonContainer, "UIPanelButtonTemplate")
        stopButton:SetSize(200, 40)
        stopButton:SetPoint("TOP", buttonContainer, "TOP", 0, 0)
        stopButton:SetText("Stop Recruiting")
        stopButton:SetScript("OnClick", function()
            Grouper:StopSession()
        end)
        ApplyElvUISkin(stopButton, "button")
    end

    -- Trade button
    if not tradeButton then
        tradeButton = CreateFrame("Button", "GrouperTradeButton", buttonContainer, "UIPanelButtonTemplate")
        tradeButton:SetSize(200, 40)
        tradeButton:SetPoint("TOP", stopButton, "BOTTOM", 0, -10)
        tradeButton:SetText("Trade Chat (Ready)")
        tradeButton:SetScript("OnClick", function()
            Grouper:SendToChannel("Trade")
            activeSession.tradeNextSpam = time() + GrouperDB.tradeInterval
            Grouper:UpdateButtons()
        end)
        ApplyElvUISkin(tradeButton, "button")
    end

    -- LFG button
    if not lfgButton then
        lfgButton = CreateFrame("Button", "GrouperLFGButton", buttonContainer, "UIPanelButtonTemplate")
        lfgButton:SetSize(200, 40)
        lfgButton:SetPoint("TOP", tradeButton, "BOTTOM", 0, -10)
        lfgButton:SetText("LFG Chat (Ready)")
        lfgButton:SetScript("OnClick", function()
            Grouper:SendToChannel("LookingForGroup")
            activeSession.lfgNextSpam = time() + GrouperDB.lfgInterval
            Grouper:UpdateButtons()
        end)
        ApplyElvUISkin(lfgButton, "button")
    end

    -- General button
    if not generalButton then
        generalButton = CreateFrame("Button", "GrouperGeneralButton", buttonContainer, "UIPanelButtonTemplate")
        generalButton:SetSize(200, 40)
        generalButton:SetPoint("TOP", lfgButton, "BOTTOM", 0, -10)
        generalButton:SetText("General Chat (Ready)")
        generalButton:SetScript("OnClick", function()
            Grouper:SendToChannel("General")
            activeSession.generalNextSpam = time() + GrouperDB.generalInterval
            Grouper:UpdateButtons()
        end)
        ApplyElvUISkin(generalButton, "button")
    end

    buttonContainer:Show()
    stopButton:Show()
    tradeButton:Show()
    lfgButton:Show()
    generalButton:Show()
end

-- Update button states
function Grouper:UpdateButtons()
    if not activeSession.active then
        if buttonContainer then buttonContainer:Hide() end
        return
    end

    local now = time()

    -- Update Trade button
    if self:InMajorCity() then
        if tradeButton then
            local tradeWait = activeSession.tradeNextSpam - now
            if tradeWait > 0 then
                tradeButton:SetText(string.format("Trade Chat (%ds)", tradeWait))
                tradeButton:Disable()
            else
                tradeButton:SetText("Trade Chat (Ready)")
                tradeButton:Enable()
            end
        end
    else
        if tradeButton then
            tradeButton:SetText("Trade Chat (Not in city)")
            tradeButton:Disable()
        end
    end

    -- Update LFG button
    if lfgButton then
        local lfgWait = activeSession.lfgNextSpam - now
        if lfgWait > 0 then
            lfgButton:SetText(string.format("LFG Chat (%ds)", lfgWait))
            lfgButton:Disable()
        else
            lfgButton:SetText("LFG Chat (Ready)")
            lfgButton:Enable()
        end
    end

    -- Update General button
    if generalButton then
        local generalWait = activeSession.generalNextSpam - now
        if generalWait > 0 then
            generalButton:SetText(string.format("General Chat (%ds)", generalWait))
            generalButton:Disable()
        else
            generalButton:SetText("General Chat (Ready)")
            generalButton:Enable()
        end
    end

    -- Check if raid is full (only warn once)
    if IsInRaid() or IsInGroup() then
        local numMembers = GetNumGroupMembers()
        local config = self:GetBossConfig(activeSession.boss)
        local targetSize = config.size or GrouperDB.raidSize or 25
        if numMembers >= targetSize and not activeSession.hasShownFullWarning then
            print("|cff00ff00[Grouper]|r Raid is full! (" .. numMembers .. "/" .. targetSize .. ")")
            activeSession.hasShownFullWarning = true
        end
    end
end

-- Start recruiting session
function Grouper:StartSession(boss, hrItem)
    if activeSession.active then
        print("|cffff0000[Grouper]|r Session already active! Use /grouper off first.")
        return
    end

    activeSession.active = true
    activeSession.boss = boss
    activeSession.hr = hrItem
    activeSession.tradeNextSpam = 0
    activeSession.lfgNextSpam = 0
    activeSession.generalNextSpam = 0
    activeSession.hasShownFullWarning = false

    -- Save last used boss
    GrouperDB.lastBoss = boss

    print("|cff00ff00[Grouper]|r Started recruiting for " .. boss)
    if hrItem then
        print("|cff00ff00[Grouper]|r Hard Reserve: " .. hrItem)
    end

    self:CreateButtons()
    self:UpdateButtons()

    -- Create Group Finder listing (only on user-initiated start)
    self:UpdateLFGListing()

    -- Start update timer
    if not activeSession.updateTimer then
        activeSession.updateTimer = self:ScheduleRepeatingTimer("UpdateButtons", 1)
    end
end

-- Stop recruiting session
function Grouper:StopSession()
    if not activeSession.active then
        print("|cffff0000[Grouper]|r No active session to stop.")
        return
    end

    activeSession.active = false

    -- Check for master loot (if API is available)
    if IsInRaid() and GetLootMethod then
        local lootMethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
        if lootMethod ~= "master" then
            print("|cffff0000[Grouper]|r WARNING: Master Loot is NOT set! Current method: " .. (lootMethod or "unknown"))
        end
    end

    if activeSession.updateTimer then
        self:CancelTimer(activeSession.updateTimer)
        activeSession.updateTimer = nil
    end

    -- Remove Group Finder listing
    self:RemoveLFGListing()

    if buttonContainer then buttonContainer:Hide() end

    print("|cff00ff00[Grouper]|r Recruiting stopped.")
end

-- Simple timer system
function Grouper:ScheduleRepeatingTimer(funcName, interval)
    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= interval then
            self.elapsed = 0
            Grouper[funcName](Grouper)
        end
    end)
    return frame
end

function Grouper:CancelTimer(frame)
    if frame then
        frame:SetScript("OnUpdate", nil)
    end
end

-- Create Minimap Button
function Grouper:CreateMinimapButton()
    if minimapButton then return end

    minimapButton = CreateFrame("Button", "GrouperMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon
    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Fish_27")
    minimapButton.icon = icon

    -- Border
    local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    -- Tooltip
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Grouper", 1, 1, 1)
        GameTooltip:AddLine("Left-click to open config", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click to start/stop", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Click handlers
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            Grouper:ShowConfigUI()
        elseif button == "RightButton" then
            if activeSession.active then
                Grouper:StopSession()
            else
                -- Try to start with last used boss
                if GrouperDB.lastBoss then
                    local config = Grouper:GetBossConfig(GrouperDB.lastBoss)
                    Grouper:StartSession(GrouperDB.lastBoss, config.hr)
                else
                    print("|cffff9900[Grouper]|r No previous session found. Use left-click to open config and start recruiting.")
                end
            end
        end
    end)

    -- Dragging
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.dragging = true
    end)

    minimapButton:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.dragging = false
    end)

    minimapButton:SetScript("OnUpdate", function(self)
        if self.dragging then
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.atan2(py - my, px - mx)
            GrouperDB.minimapButton.position = math.deg(angle)
            Grouper:UpdateMinimapButtonPosition()
        else
            Grouper:UpdateMinimapButtonPosition()
        end
    end)

    Grouper:UpdateMinimapButtonPosition()
end

-- Update Minimap Button Position
function Grouper:UpdateMinimapButtonPosition()
    if not minimapButton then return end

    local angle = math.rad(GrouperDB.minimapButton.position or 200)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Toggle Minimap Button
function Grouper:ToggleMinimapButton()
    if not GrouperDB.minimapButton then
        GrouperDB.minimapButton = { show = true, position = 200 }
    end

    GrouperDB.minimapButton.show = not GrouperDB.minimapButton.show

    if GrouperDB.minimapButton.show then
        if not minimapButton then
            self:CreateMinimapButton()
        end
        minimapButton:Show()
        print("|cff00ff00[Grouper]|r Minimap button shown")
    else
        if minimapButton then
            minimapButton:Hide()
        end
        print("|cff00ff00[Grouper]|r Minimap button hidden")
    end
end

-- Create Configuration UI
function Grouper:CreateConfigUI()
    if configFrame then
        configFrame:Show()
        return
    end

    -- Main frame
    configFrame = CreateFrame("Frame", "GrouperConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(500, 670)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetFrameStrata("HIGH")
    configFrame:SetToplevel(true)

    -- Raise frame when shown or clicked with proper z-ordering
    local function raiseConfigFrame(self)
        topFrameLevel = topFrameLevel + 1
        self:SetFrameLevel(topFrameLevel)
        self:Raise()
    end

    configFrame:SetScript("OnShow", raiseConfigFrame)
    configFrame:SetScript("OnMouseDown", raiseConfigFrame)

    -- Apply ElvUI skin
    ApplyElvUISkin(configFrame, "frame")

    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY")
    configFrame.title:SetFontObject("GameFontHighlight")
    configFrame.title:SetPoint("LEFT", configFrame.TitleBg, "LEFT", 5, 0)
    configFrame.title:SetText("Grouper")

    -- Selected boss/dungeon (restore last selection or default to Azuregos)
    configFrame.selectedBoss = GrouperDB.lastSelectedBoss or "Azuregos"

    local yOffset = -35

    -- Boss/Dungeon Dropdown
    local dropdownLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    dropdownLabel:SetText("Select Boss/Dungeon:")

    -- Create dropdown using UIDropDownMenu
    local dropdown = CreateFrame("Frame", "GrouperBossDropdown", configFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(dropdown, 250)

    -- Populate dropdown
    local function OnClick(self)
        configFrame.selectedBoss = self.value
        UIDropDownMenu_SetSelectedValue(dropdown, self.value)
        UIDropDownMenu_SetText(dropdown, self.value)
        -- Save selection for persistence
        GrouperDB.lastSelectedBoss = self.value
        Grouper:UpdateConfigUI()
        CloseDropDownMenus()
    end

    local function initialize(self, level)
        -- Group bosses by category
        for _, category in ipairs(bossCategories) do
            local foundInCategory = false

            -- Check if category has bosses
            for bossName, config in pairs(defaults.bosses) do
                if config.category == category then
                    foundInCategory = true
                    break
                end
            end

            if foundInCategory then
                local info = UIDropDownMenu_CreateInfo()
                info.text = category
                info.isTitle = true
                info.notCheckable = true
                info.disabled = false
                UIDropDownMenu_AddButton(info)

                -- Add bosses in this category
                for bossName, config in pairs(defaults.bosses) do
                    if config.category == category then
                        info = UIDropDownMenu_CreateInfo()
                        info.text = bossName
                        info.value = bossName
                        info.isTitle = false
                        info.disabled = false
                        info.notCheckable = true
                        info.func = OnClick
                        UIDropDownMenu_AddButton(info)
                    end
                end
            end
        end
    end

    UIDropDownMenu_Initialize(dropdown, initialize)
    UIDropDownMenu_SetSelectedValue(dropdown, configFrame.selectedBoss)
    -- Note: ElvUI skin not applied to dropdown as it interferes with functionality

    -- Kill tracking label (right side)
    local killLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killLabel:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -20, -35)
    killLabel:SetText("Never killed")
    killLabel:SetJustifyH("RIGHT")
    configFrame.killLabel = killLabel

    -- Kill Log button (right side, below label)
    local killButton = CreateFrame("Button", "GrouperKillLogButton", configFrame, "UIPanelButtonTemplate")
    killButton:SetSize(120, 25)
    killButton:SetPoint("TOPRIGHT", killLabel, "BOTTOMRIGHT", 0, -5)
    killButton:SetText("Kill Log")
    killButton:SetScript("OnClick", function()
        Grouper:ShowKillLog(configFrame.selectedBoss)
    end)
    ApplyElvUISkin(killButton, "button")
    configFrame.killButton = killButton

    yOffset = yOffset - 60

    -- Raid Size Slider
    local sizeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    sizeLabel:SetText("Raid/Group Size:")

    local sizeSlider = CreateFrame("Slider", "GrouperSizeSlider", configFrame, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 5, -10)
    sizeSlider:SetMinMaxValues(5, 40)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider:SetWidth(200)
    sizeSlider.tooltipText = "Set the expected group/raid size for this boss/dungeon"
    _G[sizeSlider:GetName().."Low"]:SetText("5")
    _G[sizeSlider:GetName().."High"]:SetText("40")
    _G[sizeSlider:GetName().."Text"]:SetText("Size: 25")
    sizeSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName().."Text"]:SetText("Size: " .. value)
        local config = Grouper:GetBossConfig(configFrame.selectedBoss)
        config.size = value
    end)
    ApplyElvUISkin(sizeSlider, "slider")
    configFrame.sizeSlider = sizeSlider

    yOffset = yOffset - 70

    -- Tanks Slider
    local tankLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tankLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    tankLabel:SetText("Tanks Needed:")

    local tankSlider = CreateFrame("Slider", "GrouperTankSlider", configFrame, "OptionsSliderTemplate")
    tankSlider:SetPoint("TOPLEFT", tankLabel, "BOTTOMLEFT", 5, -10)
    tankSlider:SetMinMaxValues(1, 8)
    tankSlider:SetValueStep(1)
    tankSlider:SetObeyStepOnDrag(true)
    tankSlider:SetWidth(200)
    tankSlider.tooltipText = "Number of tanks needed"
    _G[tankSlider:GetName().."Low"]:SetText("1")
    _G[tankSlider:GetName().."High"]:SetText("8")
    _G[tankSlider:GetName().."Text"]:SetText("Tanks: 1")
    tankSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName().."Text"]:SetText("Tanks: " .. value)
        local config = Grouper:GetBossConfig(configFrame.selectedBoss)
        config.tanks = value
    end)
    ApplyElvUISkin(tankSlider, "slider")
    configFrame.tankSlider = tankSlider

    yOffset = yOffset - 70

    -- Healers Slider
    local healerLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healerLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    healerLabel:SetText("Healers Needed:")

    local healerSlider = CreateFrame("Slider", "GrouperHealerSlider", configFrame, "OptionsSliderTemplate")
    healerSlider:SetPoint("TOPLEFT", healerLabel, "BOTTOMLEFT", 5, -10)
    healerSlider:SetMinMaxValues(1, 15)
    healerSlider:SetValueStep(1)
    healerSlider:SetObeyStepOnDrag(true)
    healerSlider:SetWidth(200)
    healerSlider.tooltipText = "Number of healers needed"
    _G[healerSlider:GetName().."Low"]:SetText("1")
    _G[healerSlider:GetName().."High"]:SetText("15")
    _G[healerSlider:GetName().."Text"]:SetText("Healers: 6")
    healerSlider:SetScript("OnValueChanged", function(self, value)
        _G[self:GetName().."Text"]:SetText("Healers: " .. value)
        local config = Grouper:GetBossConfig(configFrame.selectedBoss)
        config.healers = value
    end)
    ApplyElvUISkin(healerSlider, "slider")
    configFrame.healerSlider = healerSlider

    yOffset = yOffset - 70

    -- Hard Reserve Input
    local hrLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hrLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    hrLabel:SetText("Hard Reserve (HR) Item:")

    local hrInput = CreateFrame("EditBox", "GrouperHRInput", configFrame, "InputBoxTemplate")
    hrInput:SetPoint("TOPLEFT", hrLabel, "BOTTOMLEFT", 5, -5)
    hrInput:SetSize(300, 20)
    hrInput:SetAutoFocus(false)
    hrInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    hrInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    hrInput:SetScript("OnTextChanged", function(self)
        local config = Grouper:GetBossConfig(configFrame.selectedBoss)
        local text = self:GetText()
        config.hr = (text ~= "" and text) or nil
    end)
    ApplyElvUISkin(hrInput, "editbox")
    configFrame.hrInput = hrInput

    yOffset = yOffset - 60

    -- Custom Text Input
    local customLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    customLabel:SetText("Custom Text:")

    local customInput = CreateFrame("EditBox", "GrouperCustomInput", configFrame, "InputBoxTemplate")
    customInput:SetPoint("TOPLEFT", customLabel, "BOTTOMLEFT", 5, -5)
    customInput:SetSize(300, 20)
    customInput:SetAutoFocus(false)
    customInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    customInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    customInput:SetScript("OnTextChanged", function(self)
        local config = Grouper:GetBossConfig(configFrame.selectedBoss)
        local text = self:GetText()
        config.custom = (text ~= "" and text) or nil
    end)
    ApplyElvUISkin(customInput, "editbox")
    configFrame.customInput = customInput

    yOffset = yOffset - 60

    -- Interval Settings
    local intervalLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    intervalLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    intervalLabel:SetText("Spam Intervals (seconds)")

    yOffset = yOffset - 30

    -- Trade Interval
    local tradeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tradeLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    tradeLabel:SetText("Trade Chat:")

    local tradeInput = CreateFrame("EditBox", "GrouperTradeIntervalInput", configFrame, "InputBoxTemplate")
    tradeInput:SetPoint("TOPLEFT", tradeLabel, "BOTTOMLEFT", 5, -5)
    tradeInput:SetSize(80, 20)
    tradeInput:SetAutoFocus(false)
    tradeInput:SetNumeric(true)
    tradeInput:SetText(tostring(GrouperDB.tradeInterval or 60))
    tradeInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    tradeInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.tradeInterval = value
            print("|cff00ff00[Grouper]|r Trade interval set to " .. value .. " seconds")
        else
            print("|cffff0000[Grouper]|r Invalid interval (must be > 0)")
            self:SetText(tostring(GrouperDB.tradeInterval or 60))
        end
        self:ClearFocus()
    end)
    tradeInput:SetScript("OnTextChanged", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.tradeInterval = value
        end
    end)
    ApplyElvUISkin(tradeInput, "editbox")

    yOffset = yOffset - 50

    -- LFG Interval
    local lfgLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lfgLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    lfgLabel:SetText("LFG Chat:")

    local lfgInput = CreateFrame("EditBox", "GrouperLFGIntervalInput", configFrame, "InputBoxTemplate")
    lfgInput:SetPoint("TOPLEFT", lfgLabel, "BOTTOMLEFT", 5, -5)
    lfgInput:SetSize(80, 20)
    lfgInput:SetAutoFocus(false)
    lfgInput:SetNumeric(true)
    lfgInput:SetText(tostring(GrouperDB.lfgInterval or 60))
    lfgInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    lfgInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.lfgInterval = value
            print("|cff00ff00[Grouper]|r LFG interval set to " .. value .. " seconds")
        else
            print("|cffff0000[Grouper]|r Invalid interval (must be > 0)")
            self:SetText(tostring(GrouperDB.lfgInterval or 60))
        end
        self:ClearFocus()
    end)
    lfgInput:SetScript("OnTextChanged", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.lfgInterval = value
        end
    end)
    ApplyElvUISkin(lfgInput, "editbox")

    yOffset = yOffset - 50

    -- General Interval
    local generalLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    generalLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    generalLabel:SetText("General Chat:")

    local generalInput = CreateFrame("EditBox", "GrouperGeneralIntervalInput", configFrame, "InputBoxTemplate")
    generalInput:SetPoint("TOPLEFT", generalLabel, "BOTTOMLEFT", 5, -5)
    generalInput:SetSize(80, 20)
    generalInput:SetAutoFocus(false)
    generalInput:SetNumeric(true)
    generalInput:SetText(tostring(GrouperDB.generalInterval or 60))
    generalInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    generalInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.generalInterval = value
            print("|cff00ff00[Grouper]|r General interval set to " .. value .. " seconds")
        else
            print("|cffff0000[Grouper]|r Invalid interval (must be > 0)")
            self:SetText(tostring(GrouperDB.generalInterval or 60))
        end
        self:ClearFocus()
    end)
    generalInput:SetScript("OnTextChanged", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.generalInterval = value
        end
    end)
    ApplyElvUISkin(generalInput, "editbox")

    yOffset = yOffset - 60

    -- Preview Button
    local previewButton = CreateFrame("Button", "GrouperPreviewButton", configFrame, "UIPanelButtonTemplate")
    previewButton:SetSize(200, 30)
    previewButton:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 60)
    previewButton:SetText("Preview Messages")
    previewButton:SetScript("OnClick", function()
        Grouper:ShowPreviewMessages(configFrame.selectedBoss)
    end)
    ApplyElvUISkin(previewButton, "button")

    -- Start/Stop Buttons
    local startButton = CreateFrame("Button", "GrouperStartButton", configFrame, "UIPanelButtonTemplate")
    startButton:SetSize(140, 30)
    startButton:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 20, 20)
    startButton:SetText("Start Recruiting")
    startButton:SetScript("OnClick", function()
        Grouper:StartSession(configFrame.selectedBoss, nil)
        configFrame:Hide()
    end)
    ApplyElvUISkin(startButton, "button")

    local configStopButton = CreateFrame("Button", "GrouperConfigStopButton", configFrame, "UIPanelButtonTemplate")
    configStopButton:SetSize(140, 30)
    configStopButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -20, 20)
    configStopButton:SetText("Stop Recruiting")
    configStopButton:SetScript("OnClick", function()
        Grouper:StopSession()
    end)
    ApplyElvUISkin(configStopButton, "button")

    -- Update UI with current values
    Grouper:UpdateConfigUI()

    configFrame:Hide()
end

-- Update Config UI with selected boss values
function Grouper:UpdateConfigUI()
    if not configFrame then return end

    local config = self:GetBossConfig(configFrame.selectedBoss)

    -- Update sliders
    configFrame.sizeSlider:SetValue(config.size or defaults.raidSize)
    configFrame.tankSlider:SetValue(config.tanks or 1)
    configFrame.healerSlider:SetValue(config.healers or 6)

    -- Update HR input
    configFrame.hrInput:SetText(config.hr or "")

    -- Update custom text input
    configFrame.customInput:SetText(config.custom or "")

    -- Update dropdown selection and text
    UIDropDownMenu_SetSelectedValue(GrouperBossDropdown, configFrame.selectedBoss)
    UIDropDownMenu_SetText(GrouperBossDropdown, configFrame.selectedBoss)

    -- Update tracking label based on category
    if configFrame.killLabel and configFrame.killButton then
        local isWorldBoss = config.category == "World Boss"

        if isWorldBoss then
            -- Show kill tracking for world bosses
            local timeText = self:FormatTimeSinceKill(configFrame.selectedBoss)
            configFrame.killLabel:SetText(timeText)
            configFrame.killButton:Show()
        else
            -- Show instance lockout for raids/dungeons
            local lockoutText = self:GetInstanceLockout(configFrame.selectedBoss)
            configFrame.killLabel:SetText(lockoutText)
            configFrame.killButton:Hide()
        end
    end
end

-- Show Preview Messages
function Grouper:ShowPreviewMessages(bossName)
    local config = self:GetBossConfig(bossName)
    local raidSize = config.size or 25
    local hrItem = config.hr or "Example Item"

    print("|cff00ff00[Grouper]|r |cffffcc00Preview Messages for " .. bossName .. ":|r")
    print(" ")

    -- Example 1: Very early recruiting (10% - no count shown)
    local msg1 = string.format("LFM %s - Need all", bossName)
    if hrItem and hrItem ~= "" then
        msg1 = msg1 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 10% full (no count shown):|r")
    print(msg1)
    print(" ")

    -- Example 2: Early recruiting (30%)
    local count2 = math.floor(raidSize * 0.3)
    local msg2 = string.format("LFM %s %d/%d - Need all", bossName, count2, raidSize)
    if hrItem and hrItem ~= "" then
        msg2 = msg2 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 30% full:|r")
    print(msg2)
    print(" ")

    -- Example 3: Mid recruiting (65% - shows roles)
    local count3 = math.floor(raidSize * 0.65)
    local tanksNeeded = math.max(1, config.tanks - math.floor(config.tanks * 0.5))
    local healersNeeded = math.max(1, config.healers - math.floor(config.healers * 0.6))
    local msg3 = string.format("LFM %s %d/%d - Need %d Tank%s, %d Healer%s",
        bossName, count3, raidSize,
        tanksNeeded, tanksNeeded > 1 and "s" or "",
        healersNeeded, healersNeeded > 1 and "s" or "")
    if hrItem and hrItem ~= "" then
        msg3 = msg3 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 65% full (shows roles):|r")
    print(msg3)
    print(" ")

    -- Example 4: Nearly full (85% - shows roles and missing classes)
    local count4 = math.floor(raidSize * 0.85)
    local msg4 = string.format("LFM %s %d/%d - Need 1 Healer / Priests, Warlocks",
        bossName, count4, raidSize)
    if hrItem and hrItem ~= "" then
        msg4 = msg4 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 85% full (shows roles + missing classes):|r")
    print(msg4)
    print(" ")

    print("|cff00ff00[Grouper]|r These are examples based on your current settings.")
    print("|cff00ff00[Grouper]|r Actual messages will vary based on real raid composition.")
end

-- Show Configuration UI
function Grouper:ShowConfigUI()
    if not configFrame then
        self:CreateConfigUI()
    end
    configFrame:Show()
end

-- Command handlers
function Grouper:HandleCommand(input)
    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    if #args == 0 then
        self:ShowConfigUI()
        return
    end

    local cmd = string.lower(args[1])

    -- /grouper help
    if cmd == "help" or cmd == "?" then
        self:ShowHelp()

    -- /grouper about
    elseif cmd == "about" then
        self:ShowAbout()

    -- /grouper ui (kept for compatibility)
    elseif cmd == "ui" or cmd == "config" or cmd == "gui" then
        self:ShowConfigUI()

    -- /grouper minimap
    elseif cmd == "minimap" or cmd == "mm" then
        self:ToggleMinimapButton()

    -- /grouper off
    elseif cmd == "off" then
        self:StopSession()

    -- /grouper debug
    elseif cmd == "debug" then
        if #args < 2 then
            print("|cff00ff00[Grouper Debug]|r Available debug commands:")
            print("|cffffcc00/grouper debug layer|r - Check current layer detection")
            print("|cffffcc00/grouper debug nwb|r - Check Nova World Buffs status")
            print("|cffffcc00/grouper debug nwbdeep|r - Deep search of NWB data structure")
            print("|cffffcc00/grouper debug kills|r - Show all recorded kills")
            return
        end

        local subcmd = string.lower(args[2])

        if subcmd == "layer" then
            local layer = self:GetCurrentLayer()
            if layer then
                print("|cff00ff00[Grouper Debug]|r Current layer: " .. layer)
            else
                print("|cffff9900[Grouper Debug]|r No layer detected")
                print("Make sure Nova World Buffs is installed and has detected your layer")
            end

        elseif subcmd == "nwb" then
            local NWB = nil
            if LibStub then
                local success, addon = pcall(LibStub, "AceAddon-3.0")
                if success and addon then
                    NWB = addon:GetAddon("NovaWorldBuffs", true)
                end
            end

            if NWB then
                print("|cff00ff00[Grouper Debug]|r Nova World Buffs addon is loaded")

                -- Check common layer variables
                if NWB.currentLayer then
                    print("NWB.currentLayer = " .. tostring(NWB.currentLayer))
                else
                    print("NWB.currentLayer = nil")
                end

                if NWB.layerID then
                    print("NWB.layerID = " .. tostring(NWB.layerID))
                end

                if NWB.data then
                    if NWB.data.myLayerID then
                        print("NWB.data.myLayerID = " .. tostring(NWB.data.myLayerID))
                    end
                    if NWB.data.layer then
                        print("NWB.data.layer = " .. tostring(NWB.data.layer))
                    end
                end

                -- Try to call NWB functions if they exist
                if NWB.getCurrentLayerID then
                    local layer = NWB:getCurrentLayerID()
                    print("NWB:getCurrentLayerID() = " .. tostring(layer))
                end

                if NWB.getLayerID then
                    local layer = NWB:getLayerID()
                    print("NWB:getLayerID() = " .. tostring(layer))
                end

                -- Show all top-level keys in NWB
                print(" ")
                print("All NWB keys (looking for layer-related data):")
                local foundLayer = false
                for key, value in pairs(NWB) do
                    local vtype = type(value)
                    if vtype == "number" or vtype == "string" or vtype == "boolean" then
                        if string.find(string.lower(key), "layer") then
                            print("  " .. key .. " = " .. tostring(value) .. " (" .. vtype .. ")")
                            foundLayer = true
                        end
                    elseif vtype == "function" then
                        if string.find(string.lower(key), "layer") then
                            print("  " .. key .. " (function)")
                            foundLayer = true
                        end
                    end
                end
                if not foundLayer then
                    print("  No layer-related keys found in NWB table")
                end
            else
                print("|cffff9900[Grouper Debug]|r Nova World Buffs addon is NOT loaded")
                print("Install Nova World Buffs for automatic layer detection")
            end

        elseif subcmd == "nwbdeep" then
            local NWB = nil
            if LibStub then
                local success, addon = pcall(LibStub, "AceAddon-3.0")
                if success and addon then
                    NWB = addon:GetAddon("NovaWorldBuffs", true)
                end
            end

            if not NWB then
                print("|cffff9900[Grouper Debug]|r Nova World Buffs addon is NOT loaded")
                return
            end

            print("|cff00ff00[Grouper Debug]|r Deep searching NWB structure for layer data...")
            print(" ")

            -- Function to recursively search for layer-related data
            local function searchTable(t, path, depth)
                if depth > 3 then return end -- Limit recursion depth

                for key, value in pairs(t) do
                    local currentPath = path .. "." .. tostring(key)
                    local vtype = type(value)

                    -- Check if key or value contains layer info
                    local keyLower = string.lower(tostring(key))
                    if string.find(keyLower, "layer") then
                        if vtype == "table" then
                            print(currentPath .. " = <table>")
                            searchTable(value, currentPath, depth + 1)
                        else
                            print(currentPath .. " = " .. tostring(value) .. " (" .. vtype .. ")")
                        end
                    elseif vtype == "number" and value >= 1 and value <= 10 then
                        -- Might be a layer number (1-10)
                        if string.find(keyLower, "id") or string.find(keyLower, "current") or string.find(keyLower, "my") then
                            print(currentPath .. " = " .. tostring(value) .. " (possible layer)")
                        end
                    elseif vtype == "table" and depth < 3 then
                        searchTable(value, currentPath, depth + 1)
                    end
                end
            end

            print("Searching NWB table:")
            searchTable(NWB, "NWB", 0)

            print(" ")
            print("Checking other potential NWB global variables:")
            -- Check for other common NWB-related globals
            if NWBData then
                print("NWBData exists:")
                searchTable(NWBData, "NWBData", 0)
            end
            if NovaWorldBuffs then
                print("NovaWorldBuffs exists:")
                searchTable(NovaWorldBuffs, "NovaWorldBuffs", 0)
            end

        elseif subcmd == "kills" then
            print("|cff00ff00[Grouper Debug]|r Recorded boss kills:")
            local hasKills = false
            for boss, kills in pairs(GrouperDB.bossKills) do
                hasKills = true
                if type(kills) == "table" then
                    print(boss .. ": " .. #kills .. " kill(s)")
                    for i, kill in ipairs(kills) do
                        local timeStr = date("%Y-%m-%d %H:%M", kill.timestamp)
                        local layerStr = kill.layer and ("Layer " .. kill.layer) or "Unknown"
                        print("  " .. i .. ". " .. timeStr .. " - " .. layerStr)
                    end
                end
            end
            if not hasKills then
                print("No kills recorded yet")
            end
        end

    -- /grouper testkill (for debugging)
    elseif cmd == "testkill" then
        if #args < 2 then
            print("|cffff0000[Grouper]|r Usage: /grouper testkill <boss>")
            return
        end
        local boss = table.concat(args, " ", 2)
        self:MarkBossKilled(boss)
        print("|cff00ff00[Grouper]|r Test kill recorded for " .. boss)

    -- /grouper set
    elseif cmd == "set" then
        if #args < 3 then
            print("|cffff0000[Grouper]|r Usage: /grouper set <option> <value>")
            return
        end

        local option = string.lower(args[2])

        if option == "raidsize" then
            local size = tonumber(args[3])
            if size and size > 0 and size <= 40 then
                GrouperDB.raidSize = size
                print("|cff00ff00[Grouper]|r Raid size set to " .. size)
            else
                print("|cffff0000[Grouper]|r Invalid raid size (1-40)")
            end

        elseif option == "tank" or option == "tanks" then
            if #args < 4 then
                print("|cffff0000[Grouper]|r Usage: /grouper set tank <boss> <count>")
                return
            end
            local boss = string.lower(args[3])
            local count = tonumber(args[4])
            if count and count >= 0 then
                local config = self:GetBossConfig(boss)
                config.tanks = count
                print("|cff00ff00[Grouper]|r " .. boss .. " tanks set to " .. count)
            else
                print("|cffff0000[Grouper]|r Invalid tank count")
            end

        elseif option == "healer" or option == "healers" then
            if #args < 4 then
                print("|cffff0000[Grouper]|r Usage: /grouper set healer <boss> <count>")
                return
            end
            local boss = string.lower(args[3])
            local count = tonumber(args[4])
            if count and count >= 0 then
                local config = self:GetBossConfig(boss)
                config.healers = count
                print("|cff00ff00[Grouper]|r " .. boss .. " healers set to " .. count)
            else
                print("|cffff0000[Grouper]|r Invalid healer count")
            end

        elseif option == "hr" then
            if #args < 4 then
                print("|cffff0000[Grouper]|r Usage: /grouper set hr <boss> <item name...>")
                return
            end
            local boss = string.lower(args[3])
            local hrItem = table.concat(args, " ", 4)
            local config = self:GetBossConfig(boss)
            config.hr = hrItem
            print("|cff00ff00[Grouper]|r " .. boss .. " HR set to: " .. hrItem)

        elseif option == "tradeinterval" then
            local interval = tonumber(args[3])
            if interval and interval > 0 then
                GrouperDB.tradeInterval = interval
                print("|cff00ff00[Grouper]|r Trade interval set to " .. interval .. " seconds")
            else
                print("|cffff0000[Grouper]|r Invalid interval")
            end

        elseif option == "lfginterval" then
            local interval = tonumber(args[3])
            if interval and interval > 0 then
                GrouperDB.lfgInterval = interval
                print("|cff00ff00[Grouper]|r LFG interval set to " .. interval .. " seconds")
            else
                print("|cffff0000[Grouper]|r Invalid interval")
            end

        elseif option == "generalinterval" then
            local interval = tonumber(args[3])
            if interval and interval > 0 then
                GrouperDB.generalInterval = interval
                print("|cff00ff00[Grouper]|r General interval set to " .. interval .. " seconds")
            else
                print("|cffff0000[Grouper]|r Invalid interval")
            end
        else
            print("|cffff0000[Grouper]|r Unknown setting: " .. option)
        end

    -- /grouper <boss> [hr item]
    else
        local boss = args[1]
        local hrItem = nil
        if #args > 1 then
            hrItem = table.concat(args, " ", 2)
        end
        self:StartSession(boss, hrItem)
    end
end

function Grouper:ShowHelp()
    print("|cff00ff00=== Grouper v" .. self.version .. " ===|r")
    print("|cffffcc00/grouper|r - Open configuration GUI")
    print("|cffffcc00/grouper help|r - Show this help")
    print("|cffffcc00/grouper about|r - Show author and addon information")
    print("|cffffcc00/grouper minimap|r - Toggle minimap button")
    print("|cffffcc00/grouper <boss> [hard reserve item]|r - Start recruiting")
    print("  Example: /grouper Azuregos Mature Blue Dragon Sinew")
    print("|cffffcc00/grouper off|r - Stop recruiting")
    print(" ")
    print("Chat Commands:")
    print("|cffffcc00/grouper set raidsize <size>|r - Set raid size (default 25)")
    print("|cffffcc00/grouper set tank <boss> <count>|r - Set tank requirement")
    print("|cffffcc00/grouper set healer <boss> <count>|r - Set healer requirement")
    print("|cffffcc00/grouper set hr <boss> <item>|r - Set default HR for boss")
    print("|cffffcc00/grouper set tradeinterval <seconds>|r - Set Trade spam interval")
    print("|cffffcc00/grouper set lfginterval <seconds>|r - Set LFG spam interval")
    print("|cffffcc00/grouper set generalinterval <seconds>|r - Set General spam interval")
    print(" ")
    print("Debug Commands:")
    print("|cffffcc00/grouper debug|r - Show debug options")
    print("|cffffcc00/grouper testkill <boss>|r - Record a test kill")
    print(" ")
    print("Buttons appear when recruiting. Click to spam channels.")
    print("Drag the buttons together as a unit to reposition them.")
    print("Trade chat only works in major cities.")
end

function Grouper:ShowAbout()
    print("|cff00ff00=== Grouper v" .. self.version .. " ===|r")
    print(" ")
    print("|cffffcc00Author:|r voc0der")
    print("|cffffcc00GitHub:|r https://github.com/voc0der/Grouper")
    print("|cffffcc00CurseForge:|r https://www.curseforge.com/wow/addons/grouper-classic")
    print(" ")
    print("Grouper helps manage PUG groups for raids, dungeons, and world bosses.")
    print("Features smart recruitment messages, boss kill tracking, and more!")
    print(" ")
    print("Type |cffffcc00/grouper help|r for command list.")
end

-- Event handlers
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Grouper" then
        Grouper:InitDB()

        -- Initialize minimap button
        if GrouperDB.minimapButton.show then
            Grouper:CreateMinimapButton()
        end

        print("|cff00ff00[Grouper]|r Grouper loaded! Type /grouper for help.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if activeSession.active then
            Grouper:UpdateButtons()
        end
    end
end)

-- Combat log event handler for automatic world boss kill detection
local combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatLogFrame:SetScript("OnEvent", function(self, event)
    local _, subEvent, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()

    if subEvent == "UNIT_DIED" and destName then
        -- Check if the dead unit is a world boss
        for bossName, config in pairs(defaults.bosses) do
            if config.category == "World Boss" and destName == bossName then
                -- Auto-record the kill
                Grouper:MarkBossKilled(bossName)

                -- Get layer info for the message
                local layer = Grouper:GetCurrentLayer()
                local layerText = layer and ("Layer " .. layer) or "Unknown layer"

                -- Print confirmation message
                print("|cff00ff00[Grouper]|r Auto-recorded " .. bossName .. " kill on " .. layerText)
                break
            end
        end
    end
end)

-- Register slash commands
SLASH_GROUPER1 = "/grouper"
SlashCmdList["GROUPER"] = function(msg)
    Grouper:HandleCommand(msg)
end
