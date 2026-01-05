-- WorldBossGroupHelper: Addon to help manage world boss PUG groups
local WBGH = {}
WBGH.version = "1.0.0"

-- Default settings
local defaults = {
    raidSize = 25,
    spamInterval = 300, -- 5 minutes default
    tradeInterval = 300,
    lfgInterval = 300,
    bosses = {
        ["azuregos"] = { tanks = 1, healers = 6, hr = nil },
        ["kazzak"] = { tanks = 1, healers = 6, hr = nil },
        ["emeriss"] = { tanks = 1, healers = 6, hr = nil },
        ["lethon"] = { tanks = 1, healers = 6, hr = nil },
        ["taerar"] = { tanks = 1, healers = 6, hr = nil },
        ["ysondre"] = { tanks = 1, healers = 6, hr = nil },
    }
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

-- Initialize saved variables
function WBGH:InitDB()
    if not WorldBossGroupHelperDB then
        WorldBossGroupHelperDB = {}
    end

    if not WorldBossGroupHelperDB.raidSize then
        WorldBossGroupHelperDB.raidSize = defaults.raidSize
    end

    if not WorldBossGroupHelperDB.tradeInterval then
        WorldBossGroupHelperDB.tradeInterval = defaults.tradeInterval
    end

    if not WorldBossGroupHelperDB.lfgInterval then
        WorldBossGroupHelperDB.lfgInterval = defaults.lfgInterval
    end

    if not WorldBossGroupHelperDB.bosses then
        WorldBossGroupHelperDB.bosses = {}
    end

    -- Ensure all default bosses exist
    for boss, config in pairs(defaults.bosses) do
        if not WorldBossGroupHelperDB.bosses[boss] then
            WorldBossGroupHelperDB.bosses[boss] = {
                tanks = config.tanks,
                healers = config.healers,
                hr = config.hr
            }
        end
    end
end

-- Get boss config (merge saved with defaults)
function WBGH:GetBossConfig(bossName)
    local boss = string.lower(bossName)
    if WorldBossGroupHelperDB.bosses[boss] then
        return WorldBossGroupHelperDB.bosses[boss]
    else
        -- Create new boss with defaults
        WorldBossGroupHelperDB.bosses[boss] = {
            tanks = defaults.bosses.azuregos.tanks,
            healers = defaults.bosses.azuregos.healers,
            hr = nil
        }
        return WorldBossGroupHelperDB.bosses[boss]
    end
end

-- Check if in major city
function WBGH:InMajorCity()
    local zone = GetRealZoneText()
    return majorCities[zone] == true
end

-- Scan raid composition
function WBGH:ScanRaid()
    if not IsInRaid() then
        return 0, 0, 0, {}
    end

    local numRaid = GetNumGroupMembers()
    if numRaid == 0 then
        return 0, 0, 0, {}
    end

    local tanks = 0
    local healers = 0
    local classCounts = {}

    for i = 1, numRaid do
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

    return numRaid, tanks, healers, classCounts
end

-- Generate recruitment message
function WBGH:GenerateMessage()
    local numRaid, tanks, healers, classCounts = self:ScanRaid()
    local config = self:GetBossConfig(activeSession.boss)
    local raidSize = WorldBossGroupHelperDB.raidSize

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
function WBGH:SendToChannel(channel)
    local msg = self:GenerateMessage()
    local channelNum = GetChannelName(channel)

    if channelNum and channelNum > 0 then
        SendChatMessage(msg, "CHANNEL", nil, channelNum)
        print("|cff00ff00[WBGH]|r Sent to " .. channel .. ": " .. msg)
    else
        print("|cffff0000[WBGH]|r Channel '" .. channel .. "' not found")
    end
end

-- Create or update UI buttons
function WBGH:CreateButtons()
    -- Trade button
    if not tradeButton then
        tradeButton = CreateFrame("Button", "WBGHTradeButton", UIParent, "UIPanelButtonTemplate")
        tradeButton:SetSize(200, 40)
        tradeButton:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        tradeButton:SetText("Trade Chat (Ready)")
        tradeButton:SetScript("OnClick", function()
            WBGH:SendToChannel("Trade")
            activeSession.tradeNextSpam = time() + WorldBossGroupHelperDB.tradeInterval
            WBGH:UpdateButtons()
        end)
    end

    -- LFG button
    if not lfgButton then
        lfgButton = CreateFrame("Button", "WBGHLFGButton", UIParent, "UIPanelButtonTemplate")
        lfgButton:SetSize(200, 40)
        lfgButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        lfgButton:SetText("LFG Chat (Ready)")
        lfgButton:SetScript("OnClick", function()
            WBGH:SendToChannel("LookingForGroup")
            activeSession.lfgNextSpam = time() + WorldBossGroupHelperDB.lfgInterval
            WBGH:UpdateButtons()
        end)
    end

    tradeButton:Show()
    lfgButton:Show()
end

-- Update button states
function WBGH:UpdateButtons()
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
    if IsInRaid() then
        local numRaid = GetNumGroupMembers()
        if numRaid >= WorldBossGroupHelperDB.raidSize then
            print("|cff00ff00[WBGH]|r Raid is full! (" .. numRaid .. "/" .. WorldBossGroupHelperDB.raidSize .. ")")
            print("|cffff9900[WBGH]|r Use /wbgh off to stop recruiting")
        end
    end
end

-- Start recruiting session
function WBGH:StartSession(boss, hrItem)
    if activeSession.active then
        print("|cffff0000[WBGH]|r Session already active! Use /wbgh off first.")
        return
    end

    activeSession.active = true
    activeSession.boss = boss
    activeSession.hr = hrItem
    activeSession.tradeNextSpam = 0
    activeSession.lfgNextSpam = 0

    print("|cff00ff00[WBGH]|r Started recruiting for " .. boss)
    if hrItem then
        print("|cff00ff00[WBGH]|r Hard Reserve: " .. hrItem)
    end

    self:CreateButtons()
    self:UpdateButtons()

    -- Start update timer
    if not activeSession.updateTimer then
        activeSession.updateTimer = self:ScheduleRepeatingTimer("UpdateButtons", 1)
    end
end

-- Stop recruiting session
function WBGH:StopSession()
    if not activeSession.active then
        print("|cffff0000[WBGH]|r No active session to stop.")
        return
    end

    activeSession.active = false

    -- Check for master loot
    if IsInRaid() then
        local lootMethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
        if lootMethod ~= "master" then
            print("|cffff0000[WBGH]|r WARNING: Master Loot is NOT set! Current method: " .. (lootMethod or "unknown"))
        end
    end

    if activeSession.updateTimer then
        self:CancelTimer(activeSession.updateTimer)
        activeSession.updateTimer = nil
    end

    if tradeButton then tradeButton:Hide() end
    if lfgButton then lfgButton:Hide() end

    print("|cff00ff00[WBGH]|r Recruiting stopped.")
end

-- Simple timer system
function WBGH:ScheduleRepeatingTimer(funcName, interval)
    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= interval then
            self.elapsed = 0
            WBGH[funcName](WBGH)
        end
    end)
    return frame
end

function WBGH:CancelTimer(frame)
    if frame then
        frame:SetScript("OnUpdate", nil)
    end
end

-- Command handlers
function WBGH:HandleCommand(input)
    local args = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(args, word)
    end

    if #args == 0 then
        self:ShowHelp()
        return
    end

    local cmd = string.lower(args[1])

    -- /wbgh off
    if cmd == "off" then
        self:StopSession()

    -- /wbgh set
    elseif cmd == "set" then
        if #args < 3 then
            print("|cffff0000[WBGH]|r Usage: /wbgh set <option> <value>")
            return
        end

        local option = string.lower(args[2])

        if option == "raidsize" then
            local size = tonumber(args[3])
            if size and size > 0 and size <= 40 then
                WorldBossGroupHelperDB.raidSize = size
                print("|cff00ff00[WBGH]|r Raid size set to " .. size)
            else
                print("|cffff0000[WBGH]|r Invalid raid size (1-40)")
            end

        elseif option == "tank" or option == "tanks" then
            if #args < 4 then
                print("|cffff0000[WBGH]|r Usage: /wbgh set tank <boss> <count>")
                return
            end
            local boss = string.lower(args[3])
            local count = tonumber(args[4])
            if count and count >= 0 then
                local config = self:GetBossConfig(boss)
                config.tanks = count
                print("|cff00ff00[WBGH]|r " .. boss .. " tanks set to " .. count)
            else
                print("|cffff0000[WBGH]|r Invalid tank count")
            end

        elseif option == "healer" or option == "healers" then
            if #args < 4 then
                print("|cffff0000[WBGH]|r Usage: /wbgh set healer <boss> <count>")
                return
            end
            local boss = string.lower(args[3])
            local count = tonumber(args[4])
            if count and count >= 0 then
                local config = self:GetBossConfig(boss)
                config.healers = count
                print("|cff00ff00[WBGH]|r " .. boss .. " healers set to " .. count)
            else
                print("|cffff0000[WBGH]|r Invalid healer count")
            end

        elseif option == "hr" then
            if #args < 4 then
                print("|cffff0000[WBGH]|r Usage: /wbgh set hr <boss> <item name...>")
                return
            end
            local boss = string.lower(args[3])
            local hrItem = table.concat(args, " ", 4)
            local config = self:GetBossConfig(boss)
            config.hr = hrItem
            print("|cff00ff00[WBGH]|r " .. boss .. " HR set to: " .. hrItem)

        elseif option == "tradeinterval" then
            local interval = tonumber(args[3])
            if interval and interval > 0 then
                WorldBossGroupHelperDB.tradeInterval = interval
                print("|cff00ff00[WBGH]|r Trade interval set to " .. interval .. " seconds")
            else
                print("|cffff0000[WBGH]|r Invalid interval")
            end

        elseif option == "lfginterval" then
            local interval = tonumber(args[3])
            if interval and interval > 0 then
                WorldBossGroupHelperDB.lfgInterval = interval
                print("|cff00ff00[WBGH]|r LFG interval set to " .. interval .. " seconds")
            else
                print("|cffff0000[WBGH]|r Invalid interval")
            end
        else
            print("|cffff0000[WBGH]|r Unknown setting: " .. option)
        end

    -- /wbgh <boss> [hr item]
    else
        local boss = args[1]
        local hrItem = nil
        if #args > 1 then
            hrItem = table.concat(args, " ", 2)
        end
        self:StartSession(boss, hrItem)
    end
end

function WBGH:ShowHelp()
    print("|cff00ff00=== World Boss Group Helper v" .. self.version .. " ===|r")
    print("|cffffcc00/wbgh <boss> [hard reserve item]|r - Start recruiting")
    print("  Example: /wbgh azuregos Mature Blue Dragon Sinew")
    print("|cffffcc00/wbgh off|r - Stop recruiting")
    print("|cffffcc00/wbgh set raidsize <size>|r - Set raid size (default 25)")
    print("|cffffcc00/wbgh set tank <boss> <count>|r - Set tank requirement")
    print("|cffffcc00/wbgh set healer <boss> <count>|r - Set healer requirement")
    print("|cffffcc00/wbgh set hr <boss> <item>|r - Set default HR for boss")
    print("|cffffcc00/wbgh set tradeinterval <seconds>|r - Set Trade spam interval")
    print("|cffffcc00/wbgh set lfginterval <seconds>|r - Set LFG spam interval")
    print(" ")
    print("Buttons appear when recruiting. Click to spam channels.")
    print("Trade chat only works in major cities.")
end

-- Event handlers
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "WorldBossGroupHelper" then
        WBGH:InitDB()
        print("|cff00ff00[WBGH]|r World Boss Group Helper loaded! Type /wbgh for help.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if activeSession.active then
            WBGH:UpdateButtons()
        end
    end
end)

-- Register slash commands
SLASH_WBGH1 = "/wbgh"
SlashCmdList["WBGH"] = function(msg)
    WBGH:HandleCommand(msg)
end
