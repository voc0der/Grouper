-- Grouper: Addon to help manage PUG groups for raids, dungeons, and world bosses
local Grouper = {}
Grouper.version = "1.0.12"

-- Default settings
local defaults = {
    raidSize = 25,
    spamInterval = 300, -- 5 minutes default
    tradeInterval = 300,
    lfgInterval = 300,
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

-- Active session data
local activeSession = {
    active = false,
    boss = nil,
    hr = nil,
    tradeTimer = nil,
    lfgTimer = nil,
    tradeNextSpam = 0,
    lfgNextSpam = 0,
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
local configFrame = nil
local minimapButton = nil

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

    if not GrouperDB.bosses then
        GrouperDB.bosses = {}
    end

    if GrouperDB.minimapButton == nil then
        GrouperDB.minimapButton = {
            show = true,
            position = 200
        }
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

-- Check if in major city
function Grouper:InMajorCity()
    local zone = GetRealZoneText()
    return majorCities[zone] == true
end

-- Scan raid composition
function Grouper:ScanRaid()
    local inRaid = IsInRaid()
    local inParty = IsInGroup()

    if not inRaid and not inParty then
        return 0, 0, 0, {}
    end

    local tanks = 0
    local healers = 0
    local classCounts = {}
    local numMembers = 0

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

    -- Build message
    local msg = string.format("LFM %s %d/%d", activeSession.boss, numRaid, raidSize)

    -- Add needs
    local raidPercent = numRaid / raidSize
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

            for class, name in pairs(classNames) do
                if not classCounts[class] or classCounts[class] == 0 then
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

-- Create or update UI buttons
function Grouper:CreateButtons()
    -- Trade button
    if not tradeButton then
        tradeButton = CreateFrame("Button", "GrouperTradeButton", UIParent, "UIPanelButtonTemplate")
        tradeButton:SetSize(200, 40)
        tradeButton:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        tradeButton:SetText("Trade Chat (Ready)")
        tradeButton:SetScript("OnClick", function()
            Grouper:SendToChannel("Trade")
            activeSession.tradeNextSpam = time() + GrouperDB.tradeInterval
            Grouper:UpdateButtons()
        end)
    end

    -- LFG button
    if not lfgButton then
        lfgButton = CreateFrame("Button", "GrouperLFGButton", UIParent, "UIPanelButtonTemplate")
        lfgButton:SetSize(200, 40)
        lfgButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        lfgButton:SetText("LFG Chat (Ready)")
        lfgButton:SetScript("OnClick", function()
            Grouper:SendToChannel("LookingForGroup")
            activeSession.lfgNextSpam = time() + GrouperDB.lfgInterval
            Grouper:UpdateButtons()
        end)
    end

    tradeButton:Show()
    lfgButton:Show()
end

-- Update button states
function Grouper:UpdateButtons()
    if not activeSession.active then
        if tradeButton then tradeButton:Hide() end
        if lfgButton then lfgButton:Hide() end
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

    -- Check if raid is full
    if IsInRaid() or IsInGroup() then
        local numMembers = GetNumGroupMembers()
        local config = self:GetBossConfig(activeSession.boss)
        local targetSize = config.size or GrouperDB.raidSize or 25
        if numMembers >= targetSize then
            print("|cff00ff00[Grouper]|r Raid is full! (" .. numMembers .. "/" .. targetSize .. ")")
            print("|cffff9900[Grouper]|r Use /grouper off to stop recruiting")
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

    print("|cff00ff00[Grouper]|r Started recruiting for " .. boss)
    if hrItem then
        print("|cff00ff00[Grouper]|r Hard Reserve: " .. hrItem)
    end

    self:CreateButtons()
    self:UpdateButtons()

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

    -- Check for master loot
    if IsInRaid() then
        local lootMethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
        if lootMethod ~= "master" then
            print("|cffff0000[Grouper]|r WARNING: Master Loot is NOT set! Current method: " .. (lootMethod or "unknown"))
        end
    end

    if activeSession.updateTimer then
        self:CancelTimer(activeSession.updateTimer)
        activeSession.updateTimer = nil
    end

    if tradeButton then tradeButton:Hide() end
    if lfgButton then lfgButton:Hide() end

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
    icon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")
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
    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY")
    configFrame.title:SetFontObject("GameFontHighlight")
    configFrame.title:SetPoint("LEFT", configFrame.TitleBg, "LEFT", 5, 0)
    configFrame.title:SetText("Grouper")

    -- Selected boss/dungeon
    configFrame.selectedBoss = "Azuregos"

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
        UIDropDownMenu_SetText(dropdown, self.value)
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
    tradeInput:SetText(tostring(GrouperDB.tradeInterval or 300))
    tradeInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    tradeInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.tradeInterval = value
        end
        self:ClearFocus()
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
    lfgInput:SetText(tostring(GrouperDB.lfgInterval or 300))
    lfgInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    lfgInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value > 0 then
            GrouperDB.lfgInterval = value
        end
        self:ClearFocus()
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

    local stopButton = CreateFrame("Button", "GrouperStopButton", configFrame, "UIPanelButtonTemplate")
    stopButton:SetSize(140, 30)
    stopButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -20, 20)
    stopButton:SetText("Stop Recruiting")
    stopButton:SetScript("OnClick", function()
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

    -- Update dropdown text
    UIDropDownMenu_SetText(GrouperBossDropdown, configFrame.selectedBoss)
end

-- Show Preview Messages
function Grouper:ShowPreviewMessages(bossName)
    local config = self:GetBossConfig(bossName)
    local raidSize = config.size or 25
    local hrItem = config.hr or "Example Item"

    print("|cff00ff00[Grouper]|r |cffffcc00Preview Messages for " .. bossName .. ":|r")
    print(" ")

    -- Example 1: Early recruiting (30%)
    local count1 = math.floor(raidSize * 0.3)
    local msg1 = string.format("LFM %s %d/%d - Need all", bossName, count1, raidSize)
    if hrItem and hrItem ~= "" then
        msg1 = msg1 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 30% full:|r")
    print(msg1)
    print(" ")

    -- Example 2: Mid recruiting (65% - shows roles)
    local count2 = math.floor(raidSize * 0.65)
    local tanksNeeded = math.max(1, config.tanks - math.floor(config.tanks * 0.5))
    local healersNeeded = math.max(1, config.healers - math.floor(config.healers * 0.6))
    local msg2 = string.format("LFM %s %d/%d - Need %d Tank%s, %d Healer%s",
        bossName, count2, raidSize,
        tanksNeeded, tanksNeeded > 1 and "s" or "",
        healersNeeded, healersNeeded > 1 and "s" or "")
    if hrItem and hrItem ~= "" then
        msg2 = msg2 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 65% full (shows roles):|r")
    print(msg2)
    print(" ")

    -- Example 3: Nearly full (85% - shows roles and missing classes)
    local count3 = math.floor(raidSize * 0.85)
    local msg3 = string.format("LFM %s %d/%d - Need 1 Healer / Priests, Warlocks",
        bossName, count3, raidSize)
    if hrItem and hrItem ~= "" then
        msg3 = msg3 .. " - " .. hrItem .. " HR"
    end
    print("|cff888888At 85% full (shows roles + missing classes):|r")
    print(msg3)
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
        self:ShowHelp()
        return
    end

    local cmd = string.lower(args[1])

    -- /grouper ui
    if cmd == "ui" or cmd == "config" or cmd == "gui" then
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
    print("|cffffcc00/grouper ui|r - Open configuration GUI")
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
    print(" ")
    print("Buttons appear when recruiting. Click to spam channels.")
    print("Trade chat only works in major cities.")
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
