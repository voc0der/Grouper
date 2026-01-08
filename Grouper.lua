-- Grouper: Addon to help manage PUG groups for raids, dungeons, and world bosses
local Grouper = {}
Grouper.version = "1.0.27"

-- Default settings
local defaults = {
    raidSize = 25,
    spamInterval = 60, -- 60 seconds default
    tradeInterval = 60,
    lfgInterval = 60,
    generalInterval = 60,
    bosses = {
        -- World Bosses
        ["Azuregos"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },
        ["Lord Kazzak"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },
        ["Emeriss"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },
        ["Lethon"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },
        ["Taerar"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },
        ["Ysondre"] = { tanks = 1, healers = 6, hr = nil, size = 25, category = "World Boss" },

        -- 40-Man Raids
        ["Molten Core"] = { tanks = 3, healers = 8, hr = nil, size = 40, category = "40-Man Raid" },
        ["Blackwing Lair"] = { tanks = 3, healers = 8, hr = nil, size = 40, category = "40-Man Raid" },
        ["Ahn'Qiraj (AQ40)"] = { tanks = 3, healers = 8, hr = nil, size = 40, category = "40-Man Raid" },
        ["Naxxramas"] = { tanks = 4, healers = 10, hr = nil, size = 40, category = "40-Man Raid" },

        -- 20-Man Raids
        ["Zul'Gurub"] = { tanks = 2, healers = 5, hr = nil, size = 20, category = "20-Man Raid" },
        ["Ruins of Ahn'Qiraj (AQ20)"] = { tanks = 2, healers = 4, hr = nil, size = 20, category = "20-Man Raid" },

        -- 10-Man Raids
        ["Onyxia's Lair"] = { tanks = 2, healers = 3, hr = nil, size = 10, category = "10-Man Raid" },

        -- 5-Man Dungeons
        ["Stratholme"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
        ["Scholomance"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
        ["Upper Blackrock Spire"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
        ["Lower Blackrock Spire"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
        ["Dire Maul"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
        ["Blackrock Depths"] = { tanks = 1, healers = 1, hr = nil, size = 5, category = "5-Man Dungeon" },
    }
}

-- Boss categories for UI
local bossCategories = {
    "World Boss",
    "40-Man Raid",
    "20-Man Raid",
    "10-Man Raid",
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

    -- Ensure all default bosses exist
    for boss, config in pairs(defaults.bosses) do
        if not GrouperDB.bosses[boss] then
            GrouperDB.bosses[boss] = {
                tanks = config.tanks,
                healers = config.healers,
                hr = config.hr,
                size = config.size,
                category = config.category
            }
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
    if NWB and NWB.currentLayer then
        return NWB.currentLayer
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
    killLogFrame:SetFrameStrata("DIALOG")
    killLogFrame:SetFrameLevel(100)

    -- Raise frame when shown or clicked
    killLogFrame:SetScript("OnShow", function(self)
        self:Raise()
    end)
    killLogFrame:SetScript("OnMouseDown", function(self)
        self:Raise()
    end)

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

    -- Add Kill button
    local addButton = CreateFrame("Button", "GrouperAddKillButton", killLogFrame, "UIPanelButtonTemplate")
    addButton:SetSize(120, 30)
    addButton:SetPoint("BOTTOMLEFT", killLogFrame, "BOTTOMLEFT", 20, 15)
    addButton:SetText("Add Kill")
    addButton:SetScript("OnClick", function()
        Grouper:ShowAddKillDialog(killLogFrame.currentBoss)
    end)

    -- Close button (bottom right)
    local closeButton = CreateFrame("Button", "GrouperKillLogCloseButton", killLogFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 30)
    closeButton:SetPoint("BOTTOMRIGHT", killLogFrame, "BOTTOMRIGHT", -20, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        killLogFrame:Hide()
    end)

    killLogFrame:Hide()
    return killLogFrame
end

-- Show Add Kill Dialog
function Grouper:ShowAddKillDialog(bossName)
    if not bossName then return end

    -- Create a simple popup dialog
    StaticPopupDialogs["GROUPER_ADD_KILL"] = {
        text = "Add kill entry for " .. bossName .. "\n\nLayer (optional, leave blank if unknown):",
        button1 = "Add",
        button2 = "Cancel",
        hasEditBox = true,
        OnShow = function(self)
            -- Try to auto-detect layer from Nova World Buffs
            local currentLayer = Grouper:GetCurrentLayer()
            if currentLayer then
                self.editBox:SetText(tostring(currentLayer))
            end
        end,
        OnAccept = function(self)
            local layerText = self.editBox:GetText()
            local layer = nil
            if layerText and layerText ~= "" then
                layer = tonumber(layerText)
            end
            Grouper:AddKillManually(bossName, layer)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("GROUPER_ADD_KILL")
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
                print("|cffff9900[Grouper]|r Use left-click to open config and start recruiting")
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
    configFrame:SetSize(500, 600)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetFrameLevel(100)

    -- Raise frame when shown or clicked
    configFrame:SetScript("OnShow", function(self)
        self:Raise()
    end)
    configFrame:SetScript("OnMouseDown", function(self)
        self:Raise()
    end)

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
    configFrame.hrInput = hrInput

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

    yOffset = yOffset - 60

    -- Preview Button
    local previewButton = CreateFrame("Button", "GrouperPreviewButton", configFrame, "UIPanelButtonTemplate")
    previewButton:SetSize(200, 30)
    previewButton:SetPoint("BOTTOM", configFrame, "BOTTOM", 0, 60)
    previewButton:SetText("Preview Messages")
    previewButton:SetScript("OnClick", function()
        Grouper:ShowPreviewMessages(configFrame.selectedBoss)
    end)

    -- Start/Stop Buttons
    local startButton = CreateFrame("Button", "GrouperStartButton", configFrame, "UIPanelButtonTemplate")
    startButton:SetSize(140, 30)
    startButton:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 20, 20)
    startButton:SetText("Start Recruiting")
    startButton:SetScript("OnClick", function()
        Grouper:StartSession(configFrame.selectedBoss, nil)
        configFrame:Hide()
    end)

    local configStopButton = CreateFrame("Button", "GrouperConfigStopButton", configFrame, "UIPanelButtonTemplate")
    configStopButton:SetSize(140, 30)
    configStopButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -20, 20)
    configStopButton:SetText("Stop Recruiting")
    configStopButton:SetScript("OnClick", function()
        Grouper:StopSession()
    end)

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

-- Register slash commands
SLASH_GROUPER1 = "/grouper"
SlashCmdList["GROUPER"] = function(msg)
    Grouper:HandleCommand(msg)
end
