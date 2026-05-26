-- Grouper: Addon to help manage PUG groups for raids, dungeons, and world bosses
local Grouper = {}
Grouper.version = "1.0.53"
Grouper.peerSpecs = Grouper.peerSpecs or {}

-- Detect expansion
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

-- Expansion-specific boss configurations
local classicBosses = {
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

local tbcBosses = {
    -- World Bosses
    ["Doom Lord Kazzak"] = { tanks = 2, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
    ["Doomwalker"] = { tanks = 2, healers = 6, hr = nil, custom = nil, size = 25, category = "World Boss" },
    -- 10-Man Raids
    ["Karazhan"] = { tanks = 2, healers = 3, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Zul'Aman"] = { tanks = 2, healers = 3, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    -- 25-Man Raids
    ["Gruul's Lair"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Magtheridon's Lair"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Serpentshrine Cavern"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Tempest Keep"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Mount Hyjal"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Black Temple"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Sunwell Plateau"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    -- 5-Man Dungeons
    ["Hellfire Ramparts"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["The Blood Furnace"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["The Slave Pens"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["The Underbog"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Mana-Tombs"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Auchenai Crypts"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Sethekk Halls"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Shadow Labyrinth"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
}

local wrathBosses = {
    -- 10-Man Raids
    ["Vault of Archavon (10)"] = { tanks = 2, healers = 2, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Naxxramas (10)"] = { tanks = 2, healers = 3, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["The Obsidian Sanctum (10)"] = { tanks = 2, healers = 2, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Eye of Eternity (10)"] = { tanks = 2, healers = 2, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Ulduar (10)"] = { tanks = 2, healers = 3, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Trial of the Crusader (10)"] = { tanks = 2, healers = 2, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Icecrown Citadel (10)"] = { tanks = 2, healers = 3, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    ["Ruby Sanctum (10)"] = { tanks = 2, healers = 2, hr = nil, custom = nil, size = 10, category = "10-Man Raid" },
    -- 25-Man Raids
    ["Vault of Archavon (25)"] = { tanks = 2, healers = 5, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Naxxramas (25)"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["The Obsidian Sanctum (25)"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Eye of Eternity (25)"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Ulduar (25)"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Trial of the Crusader (25)"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Icecrown Citadel (25)"] = { tanks = 3, healers = 7, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    ["Ruby Sanctum (25)"] = { tanks = 3, healers = 6, hr = nil, custom = nil, size = 25, category = "25-Man Raid" },
    -- 5-Man Dungeons
    ["Utgarde Keep"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["The Nexus"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Azjol-Nerub"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Ahn'kahet"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Drak'Tharon Keep"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Violet Hold"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Gundrak"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Halls of Stone"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["Halls of Lightning"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
    ["The Culling of Stratholme"] = { tanks = 1, healers = 1, hr = nil, custom = nil, size = 5, category = "5-Man Dungeon" },
}

-- Select appropriate boss list based on expansion
local selectedBosses = classicBosses
if isTBC then
    selectedBosses = tbcBosses
elseif isWrath then
    selectedBosses = wrathBosses
end

-- Default settings
local defaults = {
    raidSize = 25,
    spamInterval = 60, -- 60 seconds default
    tradeInterval = 60,
    lfgInterval = 60,
    generalInterval = 60,
    bosses = selectedBosses
}

-- Boss categories for UI (expansion-specific)
local bossCategories
if isClassic then
    bossCategories = {
        "World Boss",
        "40-Man Raid",
        "20-Man Raid",
        "5-Man Dungeon"
    }
elseif isTBC then
    bossCategories = {
        "World Boss",
        "25-Man Raid",
        "10-Man Raid",
        "5-Man Dungeon"
    }
elseif isWrath then
    bossCategories = {
        "World Boss",
        "25-Man Raid",
        "10-Man Raid",
        "5-Man Dungeon"
    }
end

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
local smartOrganizeFrame = nil
local smartOrganizeSpecFrame = nil
local topFrameLevel = 100 -- Track highest frame level for proper z-ordering

-- Version checking data
local versionCheck = {
    messagePrefix = "GrouperVer",
    hasAlerted = false,           -- Alert once per login session
    broadcastDelay = 5,            -- 5 second delay on login
    highestVersion = nil,
    guildVersions = {},
}

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

-- Raid Organizer constants and helpers
local ROLE_TANK = "TANK"
local ROLE_HEALER = "HEALER"
local ROLE_DAMAGER = "DAMAGER"
local ROLE_NONE = "NONE"

local RAID_ORGANIZER_SPEC_PREFIX = "GrouperSpec"
local RAID_ORGANIZER_SPEC_VERSION = 1
local RAID_GROUP_SIZE = 5

local ORGANIZER_GROUPS = {
    [1] = { key = "threat", label = "MT threat group" },
    [2] = { key = "physical", label = "Physical DPS group" },
    [3] = { key = "caster", label = "Caster pump group" },
    [4] = { key = "mana", label = "Shadow priest mana group" },
    [5] = { key = "healer", label = "Healer / overflow group" },
}

local CLASS_LABELS = {
    WARRIOR = "Warrior",
    PALADIN = "Paladin",
    HUNTER = "Hunter",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    SHAMAN = "Shaman",
    MAGE = "Mage",
    WARLOCK = "Warlock",
    DRUID = "Druid",
}

local CLASS_COLORS = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER = { 0.67, 0.83, 0.45 },
    ROGUE = { 1.00, 0.96, 0.41 },
    PRIEST = { 1.00, 1.00, 1.00 },
    SHAMAN = { 0.00, 0.44, 0.87 },
    MAGE = { 0.25, 0.78, 0.92 },
    WARLOCK = { 0.53, 0.53, 0.93 },
    DRUID = { 1.00, 0.49, 0.04 },
}

local SPEC_LABELS = {
    PROTECTION = "Protection",
    HOLY = "Holy",
    RETRIBUTION = "Retribution",
    ARMS = "Arms",
    FURY = "Fury",
    FERAL_TANK = "Feral Tank",
    FERAL = "Feral",
    BALANCE = "Balance",
    RESTORATION = "Restoration",
    SHADOW = "Shadow",
    DISCIPLINE = "Discipline",
    ELEMENTAL = "Elemental",
    ENHANCEMENT = "Enhancement",
    BEAST_MASTERY = "Beast Mastery",
    MARKSMANSHIP = "Marksmanship",
    SURVIVAL = "Survival",
    ARCANE = "Arcane",
    MAGE_CASTER = "Fire/Frost",
    WARLOCK_CASTER = "Caster",
    ROGUE_DPS = "DPS",
    WARRIOR_DPS = "DPS",
    HUNTER_UNKNOWN = "Unknown Hunter",
}

local ORGANIZER_MANUAL_CHOICES = {
    WARRIOR = {
        { label = "Tank", role = ROLE_TANK, spec = "PROTECTION" },
        { label = "Arms", role = ROLE_DAMAGER, spec = "ARMS" },
        { label = "Fury", role = ROLE_DAMAGER, spec = "FURY" },
    },
    PRIEST = {
        { label = "Healer", role = ROLE_HEALER, spec = "HOLY" },
        { label = "Shadow", role = ROLE_DAMAGER, spec = "SHADOW" },
    },
    DRUID = {
        { label = "Bear", role = ROLE_TANK, spec = "FERAL_TANK" },
        { label = "Cat", role = ROLE_DAMAGER, spec = "FERAL" },
        { label = "Balance", role = ROLE_DAMAGER, spec = "BALANCE" },
        { label = "Resto", role = ROLE_HEALER, spec = "RESTORATION" },
    },
    PALADIN = {
        { label = "Prot", role = ROLE_TANK, spec = "PROTECTION" },
        { label = "Ret", role = ROLE_DAMAGER, spec = "RETRIBUTION" },
        { label = "Holy", role = ROLE_HEALER, spec = "HOLY" },
    },
    SHAMAN = {
        { label = "Enh", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
        { label = "Ele", role = ROLE_DAMAGER, spec = "ELEMENTAL" },
        { label = "Resto", role = ROLE_HEALER, spec = "RESTORATION" },
    },
    HUNTER = {
        { label = "BM", role = ROLE_DAMAGER, spec = "BEAST_MASTERY" },
        { label = "Marks", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
        { label = "Survival", role = ROLE_DAMAGER, spec = "SURVIVAL" },
    },
    MAGE = {
        { label = "Arcane", role = ROLE_DAMAGER, spec = "ARCANE" },
        { label = "Fire/Frost", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
    },
}

local LOCAL_TALENT_TAB_SPECS = {
    WARRIOR = { "ARMS", "FURY", "PROTECTION" },
    PALADIN = { "HOLY", "PROTECTION", "RETRIBUTION" },
    HUNTER = { "BEAST_MASTERY", "MARKSMANSHIP", "SURVIVAL" },
    PRIEST = { "DISCIPLINE", "HOLY", "SHADOW" },
    SHAMAN = { "ELEMENTAL", "ENHANCEMENT", "RESTORATION" },
    MAGE = { "ARCANE", "MAGE_CASTER", "MAGE_CASTER" },
    WARLOCK = { "WARLOCK_CASTER", "WARLOCK_CASTER", "WARLOCK_CASTER" },
    DRUID = { "BALANCE", "FERAL", "RESTORATION" },
    ROGUE = { "ROGUE_DPS", "ROGUE_DPS", "ROGUE_DPS" },
}

local ORGANIZER_PLANNING_SCENARIOS_25 = {
    {
        name = "23/25 caster setup, missing Elemental",
        configuredSize = 25,
        rosterSize = 23,
        players = {
            { name = "Aegis", class = "WARRIOR", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Brick", class = "PALADIN", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Rootguard", class = "DRUID", role = ROLE_TANK, spec = "FERAL_TANK" },
            { name = "Windline", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Ironcall", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Slice", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Quickstep", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Longshot", class = "HUNTER", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
            { name = "Arrowline", class = "HUNTER", role = ROLE_DAMAGER, spec = "SURVIVAL" },
            { name = "Starfall", class = "DRUID", role = ROLE_DAMAGER, spec = "BALANCE" },
            { name = "Frostline", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Ember", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Arcanum", class = "MAGE", role = ROLE_DAMAGER, spec = "ARCANE" },
            { name = "Hexlight", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Dotweaver", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Mindwell", class = "PRIEST", role = ROLE_DAMAGER, spec = "SHADOW" },
            { name = "Grace", class = "PRIEST", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Beacon", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Wave", class = "SHAMAN", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Grove", class = "DRUID", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Renewal", class = "PRIEST", role = ROLE_HEALER, spec = "DISCIPLINE" },
            { name = "Resolve", class = "PALADIN", role = ROLE_DAMAGER, spec = "RETRIBUTION" },
            { name = "Claws", class = "DRUID", role = ROLE_DAMAGER, spec = "FERAL" },
        },
    },
    {
        name = "Full 25/25 mixed raid",
        configuredSize = 25,
        rosterSize = 25,
        players = {
            { name = "Bulwark", class = "WARRIOR", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Tankadin", class = "PALADIN", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Bearwall", class = "DRUID", role = ROLE_TANK, spec = "FERAL_TANK" },
            { name = "Windfury", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Stormbolt", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ELEMENTAL" },
            { name = "Moonchef", class = "DRUID", role = ROLE_DAMAGER, spec = "BALANCE" },
            { name = "Backstab", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Shadowcut", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Slammer", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Retadin", class = "PALADIN", role = ROLE_DAMAGER, spec = "RETRIBUTION" },
            { name = "Catshift", class = "DRUID", role = ROLE_DAMAGER, spec = "FERAL" },
            { name = "Marks", class = "HUNTER", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
            { name = "Surv", class = "HUNTER", role = ROLE_DAMAGER, spec = "SURVIVAL" },
            { name = "Dotone", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Dottwo", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Frosty", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Flare", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Arcanist", class = "MAGE", role = ROLE_DAMAGER, spec = "ARCANE" },
            { name = "Mindtap", class = "PRIEST", role = ROLE_DAMAGER, spec = "SHADOW" },
            { name = "Prayer", class = "PRIEST", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Lightwell", class = "PRIEST", role = ROLE_HEALER, spec = "DISCIPLINE" },
            { name = "Chainheal", class = "SHAMAN", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Tree", class = "DRUID", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Holyshield", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Cleanse", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
        },
    },
    {
        name = "20/25 partial raid",
        configuredSize = 25,
        rosterSize = 20,
        players = {
            { name = "Anchor", class = "WARRIOR", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Ward", class = "PALADIN", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Totem", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Spark", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ELEMENTAL" },
            { name = "Moonbeam", class = "DRUID", role = ROLE_DAMAGER, spec = "BALANCE" },
            { name = "Blade", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Shout", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Aura", class = "PALADIN", role = ROLE_DAMAGER, spec = "RETRIBUTION" },
            { name = "Arrow", class = "HUNTER", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
            { name = "Volley", class = "HUNTER", role = ROLE_DAMAGER, spec = "BEAST_MASTERY" },
            { name = "Bolt", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Curse", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Nova", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Arc", class = "MAGE", role = ROLE_DAMAGER, spec = "ARCANE" },
            { name = "Vamp", class = "PRIEST", role = ROLE_DAMAGER, spec = "SHADOW" },
            { name = "Mend", class = "PRIEST", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Tide", class = "SHAMAN", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Bloom", class = "DRUID", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Flash", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Renew", class = "PRIEST", role = ROLE_HEALER, spec = "DISCIPLINE" },
        },
    },
    {
        name = "Full 25/25 shaman-heavy raid",
        configuredSize = 25,
        rosterSize = 25,
        players = {
            { name = "Granite", class = "WARRIOR", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Oakwall", class = "DRUID", role = ROLE_TANK, spec = "FERAL_TANK", mainTank = true },
            { name = "Sunward", class = "PALADIN", role = ROLE_TANK, spec = "PROTECTION" },
            { name = "Windlash", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Stormstrike", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Thunderhead", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ELEMENTAL" },
            { name = "Chainwave", class = "SHAMAN", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Cleaver", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Sunder", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Shiv", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Vanish", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Prowl", class = "DRUID", role = ROLE_DAMAGER, spec = "FERAL" },
            { name = "Zeal", class = "PALADIN", role = ROLE_DAMAGER, spec = "RETRIBUTION" },
            { name = "Bullseye", class = "HUNTER", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
            { name = "Tracker", class = "HUNTER", role = ROLE_DAMAGER, spec = "SURVIVAL" },
            { name = "Eclipse", class = "DRUID", role = ROLE_DAMAGER, spec = "BALANCE" },
            { name = "Glacier", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Leyline", class = "MAGE", role = ROLE_DAMAGER, spec = "ARCANE" },
            { name = "Ruin", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Emberhex", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Veilmind", class = "PRIEST", role = ROLE_DAMAGER, spec = "SHADOW" },
            { name = "Serenity", class = "PRIEST", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Radiance", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
            { name = "Wildbloom", class = "DRUID", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Aegispray", class = "PRIEST", role = ROLE_HEALER, spec = "DISCIPLINE" },
        },
    },
}

local ORGANIZER_PLANNING_SCENARIOS_20 = {
    {
        name = "20/20 raid",
        configuredSize = 20,
        rosterSize = 20,
        players = ORGANIZER_PLANNING_SCENARIOS_25[3].players,
    },
    {
        name = "18/20 raid, missing support",
        configuredSize = 20,
        rosterSize = 18,
        players = {
            { name = "Stone", class = "WARRIOR", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Shield", class = "PALADIN", role = ROLE_TANK, spec = "PROTECTION", mainTank = true },
            { name = "Wind", class = "SHAMAN", role = ROLE_DAMAGER, spec = "ENHANCEMENT" },
            { name = "Starlit", class = "DRUID", role = ROLE_DAMAGER, spec = "BALANCE" },
            { name = "Steel", class = "WARRIOR", role = ROLE_DAMAGER, spec = "WARRIOR_DPS" },
            { name = "Dagger", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Ambush", class = "ROGUE", role = ROLE_DAMAGER, spec = "ROGUE_DPS" },
            { name = "Aim", class = "HUNTER", role = ROLE_DAMAGER, spec = "MARKSMANSHIP" },
            { name = "Frost", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Pyre", class = "MAGE", role = ROLE_DAMAGER, spec = "MAGE_CASTER" },
            { name = "Rune", class = "MAGE", role = ROLE_DAMAGER, spec = "ARCANE" },
            { name = "Malice", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Siphon", class = "WARLOCK", role = ROLE_DAMAGER, spec = "WARLOCK_CASTER" },
            { name = "Veil", class = "PRIEST", role = ROLE_DAMAGER, spec = "SHADOW" },
            { name = "Light", class = "PRIEST", role = ROLE_HEALER, spec = "HOLY" },
            { name = "River", class = "SHAMAN", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Leaf", class = "DRUID", role = ROLE_HEALER, spec = "RESTORATION" },
            { name = "Bless", class = "PALADIN", role = ROLE_HEALER, spec = "HOLY" },
        },
    },
}

local function PrintGrouper(message, color)
    local prefix = "|cff00ff00[Grouper]|r "
    if color then
        prefix = color .. "[Grouper]|r "
    end
    print(prefix .. tostring(message))
end

local function SafeNumber(value, fallback)
    value = tonumber(value)
    if value == nil then
        return fallback or 0
    end
    return value
end

local function Clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function RemoveRealmName(name)
    if not name then return nil end
    return string.match(name, "^([^-]+)") or name
end

local function UnitNamesMatch(left, right)
    if not left or not right then return false end
    if left == right then return true end
    return RemoveRealmName(left) == RemoveRealmName(right)
end

local function NormalizeOrganizerRole(role)
    if role == "MAINTANK" then
        return ROLE_TANK
    elseif role == "MAINASSIST" then
        return ROLE_DAMAGER
    elseif role == ROLE_TANK or role == ROLE_HEALER or role == ROLE_DAMAGER then
        return role
    end
    return ROLE_NONE
end

local function RoleLabel(role)
    role = NormalizeOrganizerRole(role)
    if role == ROLE_TANK then return "Tank" end
    if role == ROLE_HEALER then return "Healer" end
    if role == ROLE_DAMAGER then return "DPS" end
    return "Unassigned"
end

local function SpecLabel(spec)
    return SPEC_LABELS[spec] or spec or "Unknown"
end

local function ClassLabel(classFile)
    return CLASS_LABELS[classFile] or classFile or "Unknown"
end

local function ClassColor(classFile)
    return CLASS_COLORS[classFile] or { 0.55, 0.55, 0.55 }
end

local function ShortText(text, maxLength)
    text = tostring(text or "")
    if maxLength and string.len(text) > maxLength then
        return string.sub(text, 1, math.max(1, maxLength - 1)) .. "."
    end
    return text
end

local function AddName(list, unit)
    if unit and unit.name then
        list[#list + 1] = unit.name
    end
end

local function JoinNames(list)
    if not list or #list == 0 then
        return ""
    end
    return table.concat(list, ", ")
end

local function CountListText(count, singular, plural)
    if count == 1 then
        return "1 " .. singular
    end
    return tostring(count) .. " " .. (plural or (singular .. "s"))
end

local function IsOrganizerSpec(unit, spec)
    return unit and unit.spec == spec
end

local function IsOrganizerTank(unit)
    return NormalizeOrganizerRole(unit and unit.role) == ROLE_TANK
end

local function IsOrganizerHealer(unit)
    return NormalizeOrganizerRole(unit and unit.role) == ROLE_HEALER
end

local function IsOrganizerDamager(unit)
    return NormalizeOrganizerRole(unit and unit.role) == ROLE_DAMAGER
end

local function IsOrganizerWarriorOrBearTank(unit)
    if not IsOrganizerTank(unit) then
        return false
    end
    return unit.class == "WARRIOR" or unit.class == "DRUID"
end

local function IsOrganizerProtPaladinTank(unit)
    return IsOrganizerTank(unit) and unit.class == "PALADIN"
end

local function IsOrganizerEnhancement(unit)
    return unit and unit.class == "SHAMAN" and unit.spec == "ENHANCEMENT"
end

local function IsOrganizerElemental(unit)
    return unit and unit.class == "SHAMAN" and unit.spec == "ELEMENTAL"
end

local function IsOrganizerRestoShaman(unit)
    return unit and unit.class == "SHAMAN" and IsOrganizerHealer(unit)
end

local function IsOrganizerBoomkin(unit)
    return unit and unit.class == "DRUID" and unit.spec == "BALANCE"
end

local function IsOrganizerShadowPriest(unit)
    return unit and unit.class == "PRIEST" and unit.spec == "SHADOW"
end

local function IsOrganizerRetPaladin(unit)
    return unit and unit.class == "PALADIN" and unit.spec == "RETRIBUTION"
end

local function IsOrganizerCatDruid(unit)
    return unit and unit.class == "DRUID" and unit.spec == "FERAL" and IsOrganizerDamager(unit)
end

local function IsOrganizerArcaneMage(unit)
    return unit and unit.class == "MAGE" and unit.spec == "ARCANE"
end

local function IsOrganizerHunter(unit)
    return unit and unit.class == "HUNTER"
end

local function IsOrganizerPremiumShaman(unit)
    return IsOrganizerEnhancement(unit) or IsOrganizerElemental(unit)
end

local function IsOrganizerCasterDPS(unit)
    if not unit or not IsOrganizerDamager(unit) then
        return false
    end
    if unit.class == "MAGE" or unit.class == "WARLOCK" then
        return true
    end
    return IsOrganizerElemental(unit) or IsOrganizerBoomkin(unit) or IsOrganizerShadowPriest(unit)
end

local function IsOrganizerPhysicalDPS(unit)
    if not unit or not IsOrganizerDamager(unit) then
        return false
    end
    if unit.class == "ROGUE" or unit.class == "HUNTER" then
        return true
    end
    if unit.class == "WARRIOR" then
        return true
    end
    return IsOrganizerEnhancement(unit) or IsOrganizerRetPaladin(unit) or IsOrganizerCatDruid(unit)
end

local function IsOrganizerManaUser(unit)
    if not unit then return false end
    if IsOrganizerHealer(unit) then return true end
    if unit.class == "MAGE" then return true end
    if IsOrganizerCasterDPS(unit) and unit.class ~= "WARLOCK" then return true end
    return false
end

local function RoleFromSpec(classFile, spec, assignedRole)
    assignedRole = NormalizeOrganizerRole(assignedRole)
    if assignedRole ~= ROLE_NONE then
        return assignedRole
    end
    if spec == "PROTECTION" or spec == "FERAL_TANK" then
        return ROLE_TANK
    elseif spec == "RESTORATION" or (spec == "HOLY" and classFile ~= "PRIEST") then
        return ROLE_HEALER
    elseif classFile == "PRIEST" and (spec == "HOLY" or spec == "DISCIPLINE") then
        return ROLE_HEALER
    end
    return ROLE_DAMAGER
end

local function SpecFromAssignedRole(classFile, role)
    role = NormalizeOrganizerRole(role)
    if role == ROLE_TANK then
        if classFile == "WARRIOR" then return "PROTECTION" end
        if classFile == "PALADIN" then return "PROTECTION" end
        if classFile == "DRUID" then return "FERAL_TANK" end
    elseif role == ROLE_HEALER then
        if classFile == "PRIEST" then return "HOLY" end
        if classFile == "PALADIN" then return "HOLY" end
        if classFile == "DRUID" or classFile == "SHAMAN" then return "RESTORATION" end
    elseif role == ROLE_DAMAGER then
        if classFile == "PRIEST" then return "SHADOW" end
        if classFile == "PALADIN" then return "RETRIBUTION" end
        if classFile == "ROGUE" then return "ROGUE_DPS" end
        if classFile == "WARLOCK" then return "WARLOCK_CASTER" end
        if classFile == "WARRIOR" then return "WARRIOR_DPS" end
    end
    return nil
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

    if type(GrouperDB.raidOrganizer) ~= "table" then
        GrouperDB.raidOrganizer = {}
    end
    if type(GrouperDB.raidOrganizer.specs) ~= "table" then
        GrouperDB.raidOrganizer.specs = {}
    end
    if type(GrouperDB.raidOrganizer.lockedPlayers) ~= "table" then
        GrouperDB.raidOrganizer.lockedPlayers = {}
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

    -- Initialize version check settings
    if not GrouperDB.versionCheck then
        GrouperDB.versionCheck = {
            enabled = true,
            suppressedVersion = nil,
        }
    end
end

function Grouper:EnsureRaidOrganizerDB()
    if not GrouperDB then
        GrouperDB = {}
    end
    if type(GrouperDB.raidOrganizer) ~= "table" then
        GrouperDB.raidOrganizer = {}
    end
    if type(GrouperDB.raidOrganizer.specs) ~= "table" then
        GrouperDB.raidOrganizer.specs = {}
    end
    if type(GrouperDB.raidOrganizer.lockedPlayers) ~= "table" then
        GrouperDB.raidOrganizer.lockedPlayers = {}
    end
    return GrouperDB.raidOrganizer
end

function Grouper:GetOrganizerManualChoice(unit)
    if not unit then return nil end
    local db = self:EnsureRaidOrganizerDB()
    return db.specs[unit.key] or db.specs[unit.fullName] or db.specs[unit.name]
end

function Grouper:SaveOrganizerManualChoice(unit, choice)
    if not unit or not choice then return end
    local db = self:EnsureRaidOrganizerDB()
    db.specs[unit.key or unit.fullName or unit.name] = {
        role = choice.role,
        spec = choice.spec,
        label = choice.label,
    }
end

function Grouper:ApplyOrganizerManualChoice(unit)
    local choice = self:GetOrganizerManualChoice(unit)
    if type(choice) ~= "table" then
        if type(choice) == "string" then
            unit.spec = choice
        end
        return false
    end
    if choice.role then
        unit.role = NormalizeOrganizerRole(choice.role)
    end
    if choice.spec then
        unit.spec = choice.spec
    end
    unit.manual = true
    return true
end

function Grouper:GetOrganizerChoiceList(unit)
    if not unit then return nil end
    local choices = ORGANIZER_MANUAL_CHOICES[unit.class]
    if not choices then return nil end

    local role = NormalizeOrganizerRole(unit.role)
    if role == ROLE_TANK or role == ROLE_HEALER then
        local filtered = {}
        for _, choice in ipairs(choices) do
            if NormalizeOrganizerRole(choice.role) == role then
                filtered[#filtered + 1] = choice
            end
        end
        if #filtered > 0 then
            return filtered
        end
    elseif role == ROLE_DAMAGER then
        local filtered = {}
        for _, choice in ipairs(choices) do
            if NormalizeOrganizerRole(choice.role) == ROLE_DAMAGER then
                filtered[#filtered + 1] = choice
            end
        end
        if #filtered > 0 then
            return filtered
        end
    end

    return choices
end

function Grouper:ReadLocalOrganizerSpec()
    if not UnitClass then return nil end
    local _, classFile = UnitClass("player")
    local tabSpecs = classFile and LOCAL_TALENT_TAB_SPECS[classFile]
    if not tabSpecs then return nil end

    local activeGroup = 1
    if GetActiveTalentGroup then
        activeGroup = GetActiveTalentGroup() or 1
    end

    local bestTab = 1
    local bestPoints = -1
    local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
    for tab = 1, numTabs do
        local pointsSpent = 0
        if GetTalentTabInfo then
            local _, _, _, _, points = GetTalentTabInfo(tab, false, false, activeGroup)
            pointsSpent = points or 0
        end
        if pointsSpent > bestPoints then
            bestPoints = pointsSpent
            bestTab = tab
        end
    end

    local assignedRole = ROLE_NONE
    if UnitGroupRolesAssigned then
        assignedRole = NormalizeOrganizerRole(UnitGroupRolesAssigned("player"))
    end

    local spec = tabSpecs[bestTab]
    if classFile == "DRUID" and spec == "FERAL" and assignedRole == ROLE_TANK then
        spec = "FERAL_TANK"
    end

    return {
        class = classFile,
        role = RoleFromSpec(classFile, spec, assignedRole),
        spec = spec,
    }
end

function Grouper:BroadcastOrganizerSpec()
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
    local specData = self:ReadLocalOrganizerSpec()
    if not specData or not specData.spec then return end

    local channel
    if IsInRaid and IsInRaid() then
        channel = "RAID"
    elseif IsInGroup and IsInGroup() then
        channel = "PARTY"
    end
    if not channel then return end

    local message = string.format("SPEC:%s|R:%s|C:%s|v:%d",
        specData.spec,
        specData.role or ROLE_NONE,
        specData.class or "",
        RAID_ORGANIZER_SPEC_VERSION)
    C_ChatInfo.SendAddonMessage(RAID_ORGANIZER_SPEC_PREFIX, message, channel)
end

function Grouper:HandleOrganizerSpecMessage(sender, message)
    if not sender or not message then return end
    local spec = string.match(message, "SPEC:([^|]+)")
    if not spec then return end

    self.peerSpecs = self.peerSpecs or {}
    local name = RemoveRealmName(sender)
    self.peerSpecs[name] = {
        spec = spec,
        role = NormalizeOrganizerRole(string.match(message, "|R:([^|]+)") or ROLE_NONE),
        class = string.match(message, "|C:([^|]+)"),
        version = SafeNumber(string.match(message, "|v:(%d+)"), 0),
    }
end

function Grouper:ApplyOrganizerKnownSpec(unit)
    if not unit then return end

    self:ApplyOrganizerManualChoice(unit)

    local playerName = UnitName and UnitName("player")
    if playerName and UnitNamesMatch(unit.name, playerName) then
        local localSpec = self:ReadLocalOrganizerSpec()
        if localSpec and localSpec.spec and localSpec.class == unit.class then
            unit.spec = localSpec.spec
            if NormalizeOrganizerRole(unit.role) == ROLE_NONE then
                unit.role = localSpec.role
            end
            unit.localSpec = true
        end
    end

    local peer = self.peerSpecs and self.peerSpecs[unit.name]
    if peer and peer.spec and (not peer.class or peer.class == "" or peer.class == unit.class) then
        unit.spec = peer.spec
        if NormalizeOrganizerRole(unit.role) == ROLE_NONE and peer.role and peer.role ~= ROLE_NONE then
            unit.role = peer.role
        end
        unit.peerSpec = true
    end

    if not unit.spec then
        unit.spec = SpecFromAssignedRole(unit.class, unit.role)
    end
end

function Grouper:ApplyOrganizerGuess(unit)
    if not unit then return end
    local role = NormalizeOrganizerRole(unit.role)

    if role == ROLE_NONE then
        if unit.mainTank then
            role = ROLE_TANK
        elseif unit.class == "PRIEST" or unit.class == "PALADIN" or unit.class == "DRUID" or unit.class == "SHAMAN" then
            role = ROLE_DAMAGER
        else
            role = ROLE_DAMAGER
        end
        unit.role = role
        unit.guessed = true
    end

    if not unit.spec then
        if role == ROLE_TANK or role == ROLE_HEALER then
            unit.spec = SpecFromAssignedRole(unit.class, role)
        elseif unit.class == "SHAMAN" then
            unit.spec = "ENHANCEMENT"
        elseif unit.class == "DRUID" then
            unit.spec = "FERAL"
        elseif unit.class == "PALADIN" then
            unit.spec = "RETRIBUTION"
        elseif unit.class == "PRIEST" then
            unit.spec = "SHADOW"
        elseif unit.class == "MAGE" then
            unit.spec = "MAGE_CASTER"
        elseif unit.class == "HUNTER" then
            unit.spec = "HUNTER_UNKNOWN"
        elseif unit.class == "WARRIOR" then
            unit.spec = "WARRIOR_DPS"
        elseif unit.class == "WARLOCK" then
            unit.spec = "WARLOCK_CASTER"
        elseif unit.class == "ROGUE" then
            unit.spec = "ROGUE_DPS"
        end
        unit.guessed = true
    end
end

function Grouper:UpdateOrganizerTags(unit)
    if not unit then return unit end
    unit.role = NormalizeOrganizerRole(unit.role)

    if unit.mainTank and unit.role == ROLE_NONE then
        unit.role = ROLE_TANK
    end

    unit.isTank = IsOrganizerTank(unit)
    unit.isHealer = IsOrganizerHealer(unit)
    unit.isDamager = IsOrganizerDamager(unit)
    unit.isEnhancement = IsOrganizerEnhancement(unit)
    unit.isElemental = IsOrganizerElemental(unit)
    unit.isRestoShaman = IsOrganizerRestoShaman(unit)
    unit.isBoomkin = IsOrganizerBoomkin(unit)
    unit.isShadowPriest = IsOrganizerShadowPriest(unit)
    unit.isRetPaladin = IsOrganizerRetPaladin(unit)
    unit.isCatDruid = IsOrganizerCatDruid(unit)
    unit.isArcaneMage = IsOrganizerArcaneMage(unit)
    unit.isHunter = IsOrganizerHunter(unit)
    unit.isCasterDPS = IsOrganizerCasterDPS(unit)
    unit.isPhysicalDPS = IsOrganizerPhysicalDPS(unit)
    unit.isManaUser = IsOrganizerManaUser(unit)
    unit.isPremiumShaman = IsOrganizerPremiumShaman(unit)

    if unit.isTank then
        unit.category = "TANK"
        if unit.class == "PALADIN" then
            unit.tankType = "MT_PROT_PAL"
        elseif unit.class == "DRUID" then
            unit.tankType = "MT_FERAL"
        elseif unit.class == "WARRIOR" then
            unit.tankType = "MT_WARRIOR"
        else
            unit.tankType = "TANK"
        end
    elseif unit.isHealer then
        unit.category = "HEAL"
    elseif unit.isPhysicalDPS then
        unit.category = unit.class == "HUNTER" and "RANGED_PHYS" or "MELEE"
    elseif unit.isCasterDPS then
        unit.category = "CASTER"
    else
        unit.category = "UNKNOWN"
    end

    return unit
end

function Grouper:GetUncertainOrganizerPlayers(context)
    local uncertain = {}
    for _, unit in ipairs(context and context.players or {}) do
        local role = NormalizeOrganizerRole(unit.role)
        local choices = self:GetOrganizerChoiceList(unit)
        if choices then
            if role == ROLE_NONE then
                uncertain[#uncertain + 1] = unit
            elseif role == ROLE_DAMAGER then
                if unit.class == "DRUID" and unit.spec ~= "FERAL" and unit.spec ~= "BALANCE" then
                    uncertain[#uncertain + 1] = unit
                elseif unit.class == "SHAMAN" and unit.spec ~= "ENHANCEMENT" and unit.spec ~= "ELEMENTAL" then
                    uncertain[#uncertain + 1] = unit
                elseif unit.class == "HUNTER"
                    and unit.spec ~= "BEAST_MASTERY"
                    and unit.spec ~= "MARKSMANSHIP"
                    and unit.spec ~= "SURVIVAL"
                    and unit.spec ~= "HUNTER_UNKNOWN"
                then
                    uncertain[#uncertain + 1] = unit
                elseif unit.class == "MAGE" and unit.spec ~= "ARCANE" and unit.spec ~= "MAGE_CASTER" then
                    uncertain[#uncertain + 1] = unit
                end
            end
        end
    end
    return uncertain
end

function Grouper:SetOrganizerPlayerLocked(name, locked)
    if not name or name == "" then
        PrintGrouper("Usage: /grouper organize lock <player> or /grouper organize unlock <player>", "|cffff9900")
        return
    end

    local db = self:EnsureRaidOrganizerDB()
    local shortName = RemoveRealmName(name)
    db.lockedPlayers[shortName] = locked == true or nil

    if locked then
        PrintGrouper(shortName .. " locked for Smart Organize.")
    else
        PrintGrouper(shortName .. " unlocked for Smart Organize.")
    end
end

function Grouper:ClearOrganizerLocks()
    local db = self:EnsureRaidOrganizerDB()
    db.lockedPlayers = {}
    PrintGrouper("Smart Organize locks cleared.")
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

-- Parse version string into major, minor, patch components
function Grouper:ParseVersion(versionString)
    if not versionString or type(versionString) ~= "string" then
        return nil
    end

    local major, minor, patch = versionString:match("(%d+)%.(%d+)%.(%d+)")
    if not major then
        return nil
    end

    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch),
    }
end

-- Compare two version strings
-- Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal, nil on error
function Grouper:CompareVersions(v1String, v2String)
    local v1 = self:ParseVersion(v1String)
    local v2 = self:ParseVersion(v2String)

    if not v1 or not v2 then
        return nil
    end

    -- Compare major version
    if v1.major ~= v2.major then
        return v1.major > v2.major and 1 or -1
    end

    -- Compare minor version
    if v1.minor ~= v2.minor then
        return v1.minor > v2.minor and 1 or -1
    end

    -- Compare patch version
    if v1.patch ~= v2.patch then
        return v1.patch > v2.patch and 1 or -1
    end

    return 0
end

-- Broadcast addon version to guild members
function Grouper:BroadcastVersion()
    if not IsInGuild() then
        return
    end

    if not GrouperDB.versionCheck.enabled then
        return
    end

    local message = "VERSION|" .. self.version .. "|" .. UnitName("player")
    C_ChatInfo.RegisterAddonMessagePrefix(versionCheck.messagePrefix)
    C_ChatInfo.SendAddonMessage(versionCheck.messagePrefix, message, "GUILD")
end

-- Handle incoming version message from guild member
function Grouper:HandleVersionMessage(sender, message)
    if not GrouperDB.versionCheck.enabled then
        return
    end

    -- Parse message
    local msgType, version, senderName = strsplit("|", message)
    if msgType ~= "VERSION" or not version then
        return
    end

    -- Extract character name without realm
    local playerName = UnitName("player")
    if senderName == playerName then
        return  -- Don't compare to ourselves
    end

    -- Store in cache
    versionCheck.guildVersions[sender] = version

    -- Compare versions
    local comparison = self:CompareVersions(version, self.version)
    if comparison and comparison > 0 then
        -- Their version is newer
        if not versionCheck.highestVersion or
           self:CompareVersions(version, versionCheck.highestVersion) > 0 then
            versionCheck.highestVersion = version
            self:AlertNewVersion(version, senderName)
        end
    end
end

-- Alert user about newer version
function Grouper:AlertNewVersion(newerVersion, playerName)
    -- Check if we should alert
    if not GrouperDB.versionCheck.enabled then
        return
    end

    if versionCheck.hasAlerted then
        return  -- Already alerted this session
    end

    if GrouperDB.versionCheck.suppressedVersion == newerVersion then
        return  -- User chose to ignore this version
    end

    -- Show alert
    print("|cffff9900=== Grouper Update Available ===|r")
    print("|cffff9900[Grouper]|r A newer version is available!")
    print("|cffff9900[Grouper]|r Your version: " .. self.version)
    print("|cffff9900[Grouper]|r Latest version: " .. newerVersion .. " (seen on " .. playerName .. ")")
    print("|cffff9900[Grouper]|r Visit CurseForge to download the latest version.")
    print("|cffff9900====================================|r")

    -- Mark as alerted for this session
    versionCheck.hasAlerted = true
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

function Grouper:GetConfiguredOrganizerSize()
    local bossName = nil
    if activeSession and activeSession.active then
        bossName = activeSession.boss
    elseif configFrame and configFrame.selectedBoss then
        bossName = configFrame.selectedBoss
    end

    if bossName then
        local config = self:GetBossConfig(bossName)
        if config and config.size then
            return config.size
        end
    end

    return GrouperDB and GrouperDB.raidSize or defaults.raidSize or 25
end

function Grouper:CollectOrganizerRoster(options)
    options = options or {}
    self:EnsureRaidOrganizerDB()

    local players = {}
    local maxSubgroup = 1

    local function addPlayer(unitToken, raidIndex, rosterName, subgroup, classFile, rank, raidRole, online)
        if online == false or not rosterName or not classFile then
            return
        end

        local name = RemoveRealmName(rosterName)
        local role = NormalizeOrganizerRole(raidRole)
        if UnitGroupRolesAssigned and unitToken then
            local assignedRole = NormalizeOrganizerRole(UnitGroupRolesAssigned(unitToken))
            if assignedRole ~= ROLE_NONE then
                role = assignedRole
            end
        end
        if raidRole == "MAINTANK" then
            role = ROLE_TANK
        end

        local mainTank = raidRole == "MAINTANK" or role == ROLE_TANK
        local key = rosterName
        local db = self:EnsureRaidOrganizerDB()

        local unit = {
            unit = unitToken,
            raidIndex = raidIndex,
            key = key,
            name = name,
            fullName = rosterName,
            class = classFile,
            subgroup = subgroup or 1,
            rank = rank or 0,
            role = role,
            mainTank = mainTank,
            locked = db.lockedPlayers[key] == true or db.lockedPlayers[name] == true,
        }

        self:ApplyOrganizerKnownSpec(unit)
        if options.guess then
            self:ApplyOrganizerGuess(unit)
        end
        self:UpdateOrganizerTags(unit)

        players[#players + 1] = unit
        if unit.subgroup and unit.subgroup > maxSubgroup then
            maxSubgroup = unit.subgroup
        end
    end

    if IsInRaid and IsInRaid() then
        local numMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
        for i = 1, numMembers do
            local name, rank, subgroup, _, _, classFile, _, online, _, raidRole = GetRaidRosterInfo(i)
            addPlayer("raid" .. i, i, name, subgroup, classFile, rank, raidRole, online)
        end
    elseif IsInGroup and IsInGroup() then
        local playerName = GetUnitName and GetUnitName("player", true) or (UnitName and UnitName("player"))
        local _, playerClass = UnitClass("player")
        addPlayer("player", nil, playerName, 1, playerClass, 2, nil, true)

        local partyMembers = (GetNumGroupMembers and GetNumGroupMembers() or 1) - 1
        for i = 1, partyMembers do
            local unitToken = "party" .. i
            if UnitExists and UnitExists(unitToken) then
                local memberName = GetUnitName and GetUnitName(unitToken, true) or (UnitName and UnitName(unitToken))
                local _, classFile = UnitClass(unitToken)
                addPlayer(unitToken, nil, memberName, 1, classFile, 0, nil, true)
            end
        end
    else
        local playerName = GetUnitName and GetUnitName("player", true) or (UnitName and UnitName("player"))
        local _, playerClass = UnitClass("player")
        addPlayer("player", nil, playerName, 1, playerClass, 2, nil, true)
    end

    table.sort(players, function(a, b)
        if (a.subgroup or 1) ~= (b.subgroup or 1) then
            return (a.subgroup or 1) < (b.subgroup or 1)
        end
        return (a.name or "") < (b.name or "")
    end)

    return players, maxSubgroup
end

function Grouper:BuildOrganizerContext(options)
    options = options or {}
    local players, maxSubgroup = self:CollectOrganizerRoster(options)
    local configuredSize = self:GetConfiguredOrganizerSize()
    local desiredSize = math.max(#players, configuredSize or #players)
    local groupCount = math.ceil(desiredSize / RAID_GROUP_SIZE)

    if #players <= 25 and (configuredSize or 25) >= 25 then
        groupCount = math.max(groupCount, 5)
    end

    groupCount = Clamp(math.max(groupCount, maxSubgroup or 1), 1, 8)

    return {
        players = players,
        groupCount = groupCount,
        configuredSize = configuredSize,
        guess = options.guess == true,
    }
end

local function GetOrganizerPlanningScenarios(configuredSize)
    if (configuredSize or 25) <= 20 then
        return ORGANIZER_PLANNING_SCENARIOS_20
    end
    return ORGANIZER_PLANNING_SCENARIOS_25
end

local function GetOrganizerPlanningSubgroup(playerIndex, sequence, groupCount)
    if not groupCount or groupCount <= 1 then
        return 1
    end
    return ((playerIndex * 3 + sequence * 2) % groupCount) + 1
end

function Grouper:BuildOrganizerPlanningContext(options)
    options = options or {}
    local configuredSize = math.floor(SafeNumber(options.configuredSize or self:GetConfiguredOrganizerSize(), 25) + 0.5)
    configuredSize = Clamp(configuredSize, RAID_GROUP_SIZE, 40)

    local scenarios = GetOrganizerPlanningScenarios(configuredSize)
    local sequence = math.max(1, SafeNumber(options.sequence, 1))
    local scenario = scenarios[((sequence - 1) % #scenarios) + 1]
    local rosterSize = math.min(scenario.rosterSize or #scenario.players, #scenario.players)
    if configuredSize <= 20 then
        rosterSize = math.min(rosterSize, configuredSize)
    end

    local desiredSize = math.max(rosterSize, configuredSize)
    local groupCount = math.ceil(desiredSize / RAID_GROUP_SIZE)
    if rosterSize <= 25 and configuredSize >= 25 then
        groupCount = math.max(groupCount, 5)
    end
    groupCount = Clamp(groupCount, 1, 8)

    local players = {}
    for index = 1, rosterSize do
        local entry = scenario.players[index]
        local role = entry.role or RoleFromSpec(entry.class, entry.spec, ROLE_NONE)
        local unit = {
            unit = nil,
            raidIndex = index,
            key = "Planning:" .. entry.name,
            name = entry.name,
            fullName = entry.name,
            class = entry.class,
            subgroup = GetOrganizerPlanningSubgroup(index, sequence, groupCount),
            rank = 0,
            role = role,
            spec = entry.spec,
            mainTank = entry.mainTank == true,
            simulated = true,
        }
        self:UpdateOrganizerTags(unit)
        players[#players + 1] = unit
    end

    table.sort(players, function(a, b)
        if (a.subgroup or 1) ~= (b.subgroup or 1) then
            return (a.subgroup or 1) < (b.subgroup or 1)
        end
        return (a.name or "") < (b.name or "")
    end)

    return {
        players = players,
        groupCount = groupCount,
        configuredSize = configuredSize,
        guess = true,
        simulation = true,
        scenarioName = scenario.name,
        sequence = sequence,
        rosterSize = #players,
    }
end

function Grouper:BuildNextOrganizerPlanningContext(options)
    options = options or {}
    self.smartOrganizePlanningCounter = (self.smartOrganizePlanningCounter or 0) + 1
    options.sequence = self.smartOrganizePlanningCounter
    return self:BuildOrganizerPlanningContext(options)
end

local function NewOrganizerLayout(groupCount)
    local layout = {}
    for groupIndex = 1, groupCount do
        layout[groupIndex] = {}
    end
    return layout
end

local function CopyOrganizerLayout(layout)
    local copy = {}
    for groupIndex, group in ipairs(layout or {}) do
        copy[groupIndex] = {}
        for index, unit in ipairs(group) do
            copy[groupIndex][index] = unit
        end
    end
    return copy
end

local function AddOrganizerUnitToGroup(layout, groupIndex, unit)
    if not layout[groupIndex] or #layout[groupIndex] >= RAID_GROUP_SIZE then
        return false
    end
    layout[groupIndex][#layout[groupIndex] + 1] = unit
    return true
end

local function RemoveOrganizerUnitFromGroup(layout, groupIndex, unitIndex)
    local group = layout[groupIndex]
    if not group or not group[unitIndex] then
        return nil
    end
    local unit = group[unitIndex]
    table.remove(group, unitIndex)
    return unit
end

local function BuildCurrentOrganizerLayout(context)
    local layout = NewOrganizerLayout(context.groupCount or 1)
    local overflow = {}

    for _, unit in ipairs(context.players or {}) do
        local groupIndex = Clamp(unit.subgroup or 1, 1, context.groupCount or 1)
        if not AddOrganizerUnitToGroup(layout, groupIndex, unit) then
            overflow[#overflow + 1] = unit
        end
    end

    for _, unit in ipairs(overflow) do
        for groupIndex = 1, #layout do
            if AddOrganizerUnitToGroup(layout, groupIndex, unit) then
                break
            end
        end
    end

    return layout
end

local function CountOrganizerMoves(layout)
    local moves = 0
    for groupIndex, group in ipairs(layout or {}) do
        for _, unit in ipairs(group) do
            if (unit.subgroup or 1) ~= groupIndex then
                moves = moves + 1
            end
        end
    end
    return moves
end

local function GetOrganizerGroupInfo(groupIndex, groupCount)
    if groupCount <= 1 then
        return { key = "mixed", label = "Mixed group" }
    elseif groupCount == 2 then
        if groupIndex == 1 then
            return ORGANIZER_GROUPS[1]
        end
        return { key = "support", label = "Caster / healer support group" }
    elseif groupCount == 3 then
        if groupIndex == 1 then return ORGANIZER_GROUPS[1] end
        if groupIndex == 2 then return ORGANIZER_GROUPS[2] end
        return { key = "caster", label = "Caster / mana group" }
    elseif groupCount == 4 then
        if groupIndex == 1 then return ORGANIZER_GROUPS[1] end
        if groupIndex == 2 then return ORGANIZER_GROUPS[2] end
        if groupIndex == 3 then return ORGANIZER_GROUPS[3] end
        return { key = "mana", label = "Mana / healer group" }
    end

    return ORGANIZER_GROUPS[groupIndex] or { key = "overflow", label = "Overflow group" }
end

local function BuildOrganizerGroupStats(group)
    local stats = {
        total = 0,
        tanks = 0,
        healers = 0,
        damagers = 0,
        physicalDps = 0,
        casterDps = 0,
        manaUsers = 0,
        premiumShamans = 0,
        shamans = 0,
        melee = 0,
        rangedPhysical = 0,
        warlocks = 0,
        mages = 0,
        hunters = 0,
        arcaneMages = 0,
        shadowPriests = 0,
        elemental = 0,
        enhancement = 0,
        restoShamans = 0,
        boomkins = 0,
        retPaladins = 0,
        catDruids = 0,
        warriors = 0,
        rogues = 0,
        mainTanks = 0,
        protPaladinTanks = 0,
        warriorOrBearTanks = 0,
        names = {},
        tankNames = {},
        healerNames = {},
        casterNames = {},
        physicalNames = {},
        manaNames = {},
        elementalNames = {},
        enhancementNames = {},
        boomkinNames = {},
        shadowNames = {},
        arcaneMageNames = {},
        retNames = {},
        warriorNames = {},
        feralNames = {},
        hunterNames = {},
        restoShamanNames = {},
    }

    for _, unit in ipairs(group or {}) do
        stats.total = stats.total + 1
        AddName(stats.names, unit)

        if unit.class == "SHAMAN" then
            stats.shamans = stats.shamans + 1
        end
        if unit.class == "WARLOCK" and IsOrganizerDamager(unit) then
            stats.warlocks = stats.warlocks + 1
        end
        if unit.class == "MAGE" and IsOrganizerDamager(unit) then
            stats.mages = stats.mages + 1
        end
        if unit.class == "HUNTER" and IsOrganizerDamager(unit) then
            stats.hunters = stats.hunters + 1
            AddName(stats.hunterNames, unit)
        end
        if unit.class == "WARRIOR" then
            stats.warriors = stats.warriors + 1
            AddName(stats.warriorNames, unit)
        end
        if unit.class == "ROGUE" and IsOrganizerDamager(unit) then
            stats.rogues = stats.rogues + 1
        end

        if IsOrganizerTank(unit) then
            stats.tanks = stats.tanks + 1
            AddName(stats.tankNames, unit)
            if unit.mainTank then
                stats.mainTanks = stats.mainTanks + 1
            end
            if IsOrganizerProtPaladinTank(unit) then
                stats.protPaladinTanks = stats.protPaladinTanks + 1
            end
            if IsOrganizerWarriorOrBearTank(unit) then
                stats.warriorOrBearTanks = stats.warriorOrBearTanks + 1
            end
        elseif IsOrganizerHealer(unit) then
            stats.healers = stats.healers + 1
            AddName(stats.healerNames, unit)
        elseif IsOrganizerDamager(unit) then
            stats.damagers = stats.damagers + 1
        end

        if IsOrganizerPhysicalDPS(unit) then
            stats.physicalDps = stats.physicalDps + 1
            AddName(stats.physicalNames, unit)
            if unit.class == "HUNTER" then
                stats.rangedPhysical = stats.rangedPhysical + 1
            else
                stats.melee = stats.melee + 1
            end
        end
        if IsOrganizerCasterDPS(unit) then
            stats.casterDps = stats.casterDps + 1
            AddName(stats.casterNames, unit)
        end
        if IsOrganizerManaUser(unit) then
            stats.manaUsers = stats.manaUsers + 1
            AddName(stats.manaNames, unit)
        end
        if IsOrganizerPremiumShaman(unit) then
            stats.premiumShamans = stats.premiumShamans + 1
        end
        if IsOrganizerElemental(unit) then
            stats.elemental = stats.elemental + 1
            AddName(stats.elementalNames, unit)
        end
        if IsOrganizerEnhancement(unit) then
            stats.enhancement = stats.enhancement + 1
            AddName(stats.enhancementNames, unit)
        end
        if IsOrganizerRestoShaman(unit) then
            stats.restoShamans = stats.restoShamans + 1
            AddName(stats.restoShamanNames, unit)
        end
        if IsOrganizerBoomkin(unit) then
            stats.boomkins = stats.boomkins + 1
            AddName(stats.boomkinNames, unit)
        end
        if IsOrganizerShadowPriest(unit) then
            stats.shadowPriests = stats.shadowPriests + 1
            AddName(stats.shadowNames, unit)
        end
        if IsOrganizerRetPaladin(unit) then
            stats.retPaladins = stats.retPaladins + 1
            AddName(stats.retNames, unit)
        end
        if IsOrganizerCatDruid(unit) or (IsOrganizerTank(unit) and unit.class == "DRUID") then
            stats.catDruids = stats.catDruids + 1
            AddName(stats.feralNames, unit)
        end
        if IsOrganizerArcaneMage(unit) then
            stats.arcaneMages = stats.arcaneMages + 1
            AddName(stats.arcaneMageNames, unit)
        end
    end

    return stats
end

local function ScoreOrganizerPairOneWay(anchor, other)
    local score = 0

    if IsOrganizerElemental(anchor) then
        if IsOrganizerProtPaladinTank(other) then
            score = score + 12
        elseif other.class == "WARLOCK" and IsOrganizerDamager(other) then
            score = score + 10
        elseif other.class == "MAGE" and IsOrganizerDamager(other) then
            score = score + 8
        elseif IsOrganizerBoomkin(other) then
            score = score + 10
        elseif IsOrganizerCasterDPS(other) then
            score = score + 6
        elseif IsOrganizerHealer(other) or IsOrganizerPhysicalDPS(other) or IsOrganizerTank(other) then
            score = score - 4
        end
    end

    if IsOrganizerBoomkin(anchor) then
        if IsOrganizerProtPaladinTank(other) then
            score = score + 10
        elseif other.class == "WARLOCK" and IsOrganizerDamager(other) then
            score = score + 9
        elseif other.class == "MAGE" and IsOrganizerDamager(other) then
            score = score + 7
        elseif IsOrganizerCasterDPS(other) then
            score = score + 5
        elseif IsOrganizerPhysicalDPS(other) then
            score = score - 2
        end
    end

    if IsOrganizerEnhancement(anchor) then
        if IsOrganizerWarriorOrBearTank(other) then
            score = score + 10
        elseif other.class == "WARRIOR" and IsOrganizerDamager(other) then
            score = score + 10
        elseif other.class == "ROGUE" and IsOrganizerDamager(other) then
            score = score + 9
        elseif IsOrganizerRetPaladin(other) then
            score = score + 8
        elseif IsOrganizerCatDruid(other) then
            score = score + 8
        elseif IsOrganizerHunter(other) and IsOrganizerDamager(other) then
            score = score + 5
        elseif IsOrganizerCasterDPS(other) then
            score = score - 8
        elseif IsOrganizerHealer(other) then
            score = score - 5
        end
    end

    if IsOrganizerShadowPriest(anchor) then
        if IsOrganizerArcaneMage(other) then
            score = score + 10
        elseif other.class == "MAGE" and IsOrganizerDamager(other) then
            score = score + 7
        elseif IsOrganizerHealer(other) then
            score = score + 5
        elseif other.class == "WARLOCK" and IsOrganizerDamager(other) then
            score = score + 3
        elseif IsOrganizerCasterDPS(other) then
            score = score + 4
        end
    end

    if IsOrganizerRetPaladin(anchor) then
        if IsOrganizerProtPaladinTank(other) then
            score = score + 8
        elseif IsOrganizerPhysicalDPS(other) or IsOrganizerTank(other) then
            score = score + 3
        end
    end

    if IsOrganizerProtPaladinTank(anchor) then
        if IsOrganizerElemental(other) then
            score = score + 12
        elseif IsOrganizerBoomkin(other) then
            score = score + 10
        elseif IsOrganizerCasterDPS(other) then
            score = score + 4
        end
    end

    if (IsOrganizerCatDruid(anchor) or (IsOrganizerTank(anchor) and anchor.class == "DRUID")) and (IsOrganizerPhysicalDPS(other) or IsOrganizerTank(other)) then
        score = score + 7
    end

    if anchor.class == "WARRIOR" and (IsOrganizerPhysicalDPS(other) or IsOrganizerTank(other)) then
        score = score + 5
    end

    if anchor.class == "HUNTER" and anchor.spec == "MARKSMANSHIP" and IsOrganizerPhysicalDPS(other) then
        score = score + 4
    elseif anchor.class == "HUNTER" and anchor.spec == "BEAST_MASTERY" and IsOrganizerDamager(other) then
        score = score + 3
    elseif anchor.class == "HUNTER" and anchor.spec == "HUNTER_UNKNOWN" and IsOrganizerPhysicalDPS(other) then
        score = score + 2
    end

    return score
end

local function ScoreOrganizerPair(left, right)
    return ScoreOrganizerPairOneWay(left, right) + ScoreOrganizerPairOneWay(right, left)
end

local function ScoreOrganizerGroupByArchetype(group, groupIndex, groupCount)
    local info = GetOrganizerGroupInfo(groupIndex, groupCount)
    local stats = BuildOrganizerGroupStats(group)
    local score = 0

    if info.key == "threat" then
        score = score + stats.mainTanks * 18
        score = score + stats.tanks * 6
        score = score + stats.physicalDps * 3
        score = score + stats.warriors * 4
        score = score + stats.retPaladins * 4
        if stats.warriorOrBearTanks > 0 and stats.enhancement > 0 then
            score = score + 15
        end
        if stats.warriorOrBearTanks > 0 and stats.enhancement > 0 and stats.rogues > 0 then
            score = score + 12
        end
        if stats.protPaladinTanks > 0 and stats.retPaladins > 0 then
            score = score + 10
        end
        if stats.catDruids > 0 and (stats.physicalDps + stats.tanks) >= 3 then
            score = score + 8
        end
        if stats.elemental > 0 then
            score = score - 8
        end
        if stats.boomkins > 0 and stats.casterDps <= 1 then
            score = score - 6
        end
    elseif info.key == "physical" then
        score = score + stats.enhancement * 12
        score = score + stats.physicalDps * 5
        score = score + stats.warriors * 3
        score = score + stats.rogues * 3
        score = score + stats.retPaladins * 4
        score = score + stats.catDruids * 4
        score = score + stats.hunters * 2
        score = score - stats.casterDps * 3
    elseif info.key == "caster" then
        score = score + stats.elemental * 14
        score = score + stats.boomkins * 12
        score = score + stats.protPaladinTanks * 8
        score = score + stats.casterDps * 5
        score = score + stats.warlocks * 4
        score = score + stats.mages * 3
        if stats.elemental > 0 and stats.boomkins > 0 and stats.casterDps >= 3 then
            score = score + 28
        elseif stats.elemental > 0 and stats.casterDps >= 2 then
            score = score + 12
        elseif stats.boomkins > 0 and stats.casterDps >= 2 then
            score = score + 10
        end
        if stats.protPaladinTanks > 0 and stats.elemental > 0 and stats.boomkins > 0 then
            score = score + 26
        elseif stats.protPaladinTanks > 0 and (stats.elemental > 0 or stats.boomkins > 0) then
            score = score + 12
        end
        score = score - stats.healers * 2
        score = score - stats.physicalDps * 3
    elseif info.key == "mana" then
        score = score + stats.shadowPriests * 14
        score = score + stats.arcaneMages * 8
        score = score + stats.mages * 3
        score = score + stats.healers * 3
        score = score + stats.manaUsers * 2
        if stats.shadowPriests > 0 and stats.arcaneMages > 0 then
            score = score + 18
        elseif stats.shadowPriests > 0 and stats.manaUsers >= 2 then
            score = score + 9
        end
        score = score - stats.physicalDps * 2
    elseif info.key == "healer" then
        score = score + stats.healers * 5
        score = score + stats.restoShamans * 6
        score = score + stats.shadowPriests * 3
        score = score - stats.elemental * 8
        score = score - stats.enhancement * 5
        score = score - stats.boomkins * 5
    elseif info.key == "support" then
        score = score + stats.casterDps * 4
        score = score + stats.healers * 3
        score = score + stats.shadowPriests * 5
        score = score + stats.elemental * 5
        score = score + stats.boomkins * 5
    end

    if stats.total > RAID_GROUP_SIZE then
        score = score - 1000
    end

    for i = 1, #group do
        for j = i + 1, #group do
            score = score + ScoreOrganizerPair(group[i], group[j])
        end
    end

    if stats.elemental > 0 and stats.casterDps <= 1 then
        score = score - 8
    end
    if stats.boomkins > 0 and stats.casterDps <= 1 then
        score = score - 8
    end
    if stats.enhancement > 0 and (stats.casterDps + stats.healers) > (stats.physicalDps + stats.tanks) then
        score = score - 8
    end
    if stats.premiumShamans > 1 then
        score = score - 10
    end

    return score
end

function Grouper:ScoreOrganizerLayout(layout)
    local rawScore = 0
    local groupCount = #layout

    for groupIndex, group in ipairs(layout or {}) do
        rawScore = rawScore + ScoreOrganizerGroupByArchetype(group, groupIndex, groupCount)
    end

    local moves = CountOrganizerMoves(layout)
    return rawScore - moves, rawScore, moves
end

local function OrganizerLayoutIsBetter(candidate, best)
    if not best then return true end
    if candidate.netScore ~= best.netScore then
        return candidate.netScore > best.netScore
    end
    if candidate.moves ~= best.moves then
        return candidate.moves < best.moves
    end
    return candidate.rawScore > best.rawScore
end

function Grouper:ImproveOrganizerLayout(layout)
    local bestLayout = CopyOrganizerLayout(layout)
    local netScore, rawScore, moves = self:ScoreOrganizerLayout(bestLayout)
    local best = { layout = bestLayout, netScore = netScore, rawScore = rawScore, moves = moves }

    local improved = true
    local pass = 0
    while improved and pass < 20 do
        pass = pass + 1
        improved = false

        local passBest = best
        for groupA = 1, #best.layout do
            for indexA, unitA in ipairs(best.layout[groupA]) do
                if not unitA.locked then
                    for groupB = groupA + 1, #best.layout do
                        for indexB, unitB in ipairs(best.layout[groupB]) do
                            if not unitB.locked then
                                local candidateLayout = CopyOrganizerLayout(best.layout)
                                candidateLayout[groupA][indexA], candidateLayout[groupB][indexB] = candidateLayout[groupB][indexB], candidateLayout[groupA][indexA]
                                local candidateNet, candidateRaw, candidateMoves = self:ScoreOrganizerLayout(candidateLayout)
                                local candidate = {
                                    layout = candidateLayout,
                                    netScore = candidateNet,
                                    rawScore = candidateRaw,
                                    moves = candidateMoves,
                                }
                                if OrganizerLayoutIsBetter(candidate, passBest) then
                                    passBest = candidate
                                end
                            end
                        end
                    end
                end
            end
        end

        for groupA = 1, #best.layout do
            for indexA, unitA in ipairs(best.layout[groupA]) do
                if not unitA.locked then
                    for groupB = 1, #best.layout do
                        if groupA ~= groupB and #best.layout[groupB] < RAID_GROUP_SIZE then
                            local candidateLayout = CopyOrganizerLayout(best.layout)
                            local moved = RemoveOrganizerUnitFromGroup(candidateLayout, groupA, indexA)
                            if moved then
                                AddOrganizerUnitToGroup(candidateLayout, groupB, moved)
                                local candidateNet, candidateRaw, candidateMoves = self:ScoreOrganizerLayout(candidateLayout)
                                local candidate = {
                                    layout = candidateLayout,
                                    netScore = candidateNet,
                                    rawScore = candidateRaw,
                                    moves = candidateMoves,
                                }
                                if OrganizerLayoutIsBetter(candidate, passBest) then
                                    passBest = candidate
                                end
                            end
                        end
                    end
                end
            end
        end

        if passBest ~= best and OrganizerLayoutIsBetter(passBest, best) then
            best = passBest
            improved = true
        end
    end

    return best.layout, best.netScore, best.rawScore, best.moves
end

function Grouper:ScoreOrganizerUnitForSeed(unit, groupIndex, layout)
    local group = layout[groupIndex] or {}
    local beforeNet = self:ScoreOrganizerLayout(layout)
    local candidate = CopyOrganizerLayout(layout)
    AddOrganizerUnitToGroup(candidate, groupIndex, unit)
    local afterNet = self:ScoreOrganizerLayout(candidate)
    local score = afterNet - beforeNet

    if (unit.subgroup or 1) == groupIndex then
        score = score + 2
    end

    if #group >= RAID_GROUP_SIZE then
        return -100000
    end

    return score
end

function Grouper:BuildOrganizerSeedLayout(context)
    local groupCount = context.groupCount or 1
    local layout = NewOrganizerLayout(groupCount)
    local remaining = {}

    for _, unit in ipairs(context.players or {}) do
        remaining[unit] = true
        if unit.locked then
            local groupIndex = Clamp(unit.subgroup or 1, 1, groupCount)
            if AddOrganizerUnitToGroup(layout, groupIndex, unit) then
                remaining[unit] = nil
            end
        end
    end

    local function takeBest(groupIndex, predicate, valueFn)
        if not layout[groupIndex] or #layout[groupIndex] >= RAID_GROUP_SIZE then
            return nil
        end

        local bestUnit
        local bestScore = -100000
        for unit in pairs(remaining) do
            if predicate(unit) then
                local score = valueFn and valueFn(unit) or self:ScoreOrganizerUnitForSeed(unit, groupIndex, layout)
                if (unit.subgroup or 1) == groupIndex then
                    score = score + 1
                end
                if score > bestScore or (score == bestScore and (unit.name or "") < (bestUnit and bestUnit.name or "\255")) then
                    bestUnit = unit
                    bestScore = score
                end
            end
        end

        if bestUnit and AddOrganizerUnitToGroup(layout, groupIndex, bestUnit) then
            remaining[bestUnit] = nil
            return bestUnit
        end
        return nil
    end

    if groupCount >= 1 then
        takeBest(1, function(unit) return unit.mainTank and IsOrganizerTank(unit) end, function(unit)
            local score = 100
            if unit.class == "PALADIN" then score = score + 4 end
            return score
        end)
        takeBest(1, function(unit) return IsOrganizerTank(unit) end, function(unit)
            return unit.mainTank and 95 or 80
        end)
        if (layout[1][1] and IsOrganizerProtPaladinTank(layout[1][1])) then
            takeBest(1, IsOrganizerRetPaladin)
        end
        if layout[1][1] and IsOrganizerWarriorOrBearTank(layout[1][1]) then
            takeBest(1, IsOrganizerEnhancement)
        end
        takeBest(1, function(unit) return unit.class == "WARRIOR" end)
        takeBest(1, function(unit) return IsOrganizerCatDruid(unit) end)
        while #layout[1] < RAID_GROUP_SIZE do
            local added = takeBest(1, function(unit) return IsOrganizerPhysicalDPS(unit) end)
            if not added then break end
        end
    end

    local casterGroup = groupCount >= 3 and 3 or groupCount
    if casterGroup and casterGroup >= 1 then
        takeBest(casterGroup, IsOrganizerElemental)
        takeBest(casterGroup, IsOrganizerBoomkin)
        while #layout[casterGroup] < RAID_GROUP_SIZE do
            local added = takeBest(casterGroup, function(unit)
                return IsOrganizerCasterDPS(unit) and not IsOrganizerShadowPriest(unit)
            end)
            if not added then break end
        end
    end

    local manaGroup = groupCount >= 4 and 4 or casterGroup
    if manaGroup and manaGroup >= 1 then
        takeBest(manaGroup, IsOrganizerShadowPriest)
        takeBest(manaGroup, IsOrganizerArcaneMage)
        takeBest(manaGroup, IsOrganizerArcaneMage)
        while #layout[manaGroup] < RAID_GROUP_SIZE do
            local added = takeBest(manaGroup, function(unit)
                return IsOrganizerManaUser(unit) or (unit.class == "MAGE" and IsOrganizerDamager(unit))
            end)
            if not added then break end
        end
    end

    if groupCount >= 2 then
        takeBest(2, IsOrganizerEnhancement)
        while #layout[2] < RAID_GROUP_SIZE do
            local added = takeBest(2, function(unit) return IsOrganizerPhysicalDPS(unit) end)
            if not added then break end
        end
    end

    local healerGroup = groupCount >= 5 and 5 or groupCount
    if healerGroup and healerGroup >= 1 then
        takeBest(healerGroup, IsOrganizerRestoShaman)
        while #layout[healerGroup] < RAID_GROUP_SIZE do
            local added = takeBest(healerGroup, function(unit) return IsOrganizerHealer(unit) end)
            if not added then break end
        end
    end

    while true do
        local bestUnit
        local bestGroup
        local bestScore = -100000

        for unit in pairs(remaining) do
            for groupIndex = 1, groupCount do
                if #layout[groupIndex] < RAID_GROUP_SIZE then
                    local score = self:ScoreOrganizerUnitForSeed(unit, groupIndex, layout)
                    if score > bestScore or (score == bestScore and (unit.name or "") < (bestUnit and bestUnit.name or "\255")) then
                        bestUnit = unit
                        bestGroup = groupIndex
                        bestScore = score
                    end
                end
            end
        end

        if not bestUnit or not bestGroup then
            break
        end

        AddOrganizerUnitToGroup(layout, bestGroup, bestUnit)
        remaining[bestUnit] = nil
    end

    return layout
end

local function OrganizerGroupHasUnit(group, predicate)
    for _, unit in ipairs(group or {}) do
        if predicate(unit) then return true end
    end
    return false
end

local function FormatOrganizerUnit(unit)
    local detail = ClassLabel(unit.class)
    if unit.spec and unit.spec ~= "" then
        detail = detail .. " " .. SpecLabel(unit.spec)
    else
        detail = detail .. " " .. RoleLabel(unit.role)
    end
    if unit.guessed then
        detail = detail .. "?"
    end
    return string.format("%s (%s)", unit.name or "Unknown", detail)
end

function Grouper:DescribeOrganizerGroup(group, groupIndex, groupCount)
    local info = GetOrganizerGroupInfo(groupIndex, groupCount)
    local stats = BuildOrganizerGroupStats(group)
    local reasons = {}
    local missing = {}

    if info.key == "threat" then
        if stats.mainTanks > 0 or stats.tanks > 0 then
            reasons[#reasons + 1] = "+ Main tank / tank: " .. JoinNames(stats.tankNames)
        end
        if stats.enhancement > 0 then
            reasons[#reasons + 1] = "+ Enhancement Shaman: " .. JoinNames(stats.enhancementNames)
        end
        if stats.warriors > 0 then
            reasons[#reasons + 1] = "+ Warrior shout support: " .. JoinNames(stats.warriorNames)
        end
        if stats.retPaladins > 0 then
            reasons[#reasons + 1] = "+ Ret aura support: " .. JoinNames(stats.retNames)
        end
        if stats.catDruids > 0 then
            reasons[#reasons + 1] = "+ Feral / LotP support: " .. JoinNames(stats.feralNames)
        end
        if stats.tanks == 0 then
            missing[#missing + 1] = "main tank"
        end
    elseif info.key == "physical" then
        if stats.enhancement > 0 then
            reasons[#reasons + 1] = "+ Enhancement Shaman for physical DPS"
        else
            missing[#missing + 1] = "Enhancement Shaman"
        end
        if stats.physicalDps > 0 then
            reasons[#reasons + 1] = "+ " .. CountListText(stats.physicalDps, "physical DPS") .. ": " .. JoinNames(stats.physicalNames)
        end
        if stats.hunters > 0 then
            reasons[#reasons + 1] = "+ Hunter AP/FI candidates: " .. JoinNames(stats.hunterNames)
        end
    elseif info.key == "caster" then
        if stats.elemental > 0 then
            reasons[#reasons + 1] = "+ Elemental Shaman / Totem of Wrath: " .. JoinNames(stats.elementalNames)
        else
            missing[#missing + 1] = "Elemental Shaman"
        end
        if stats.boomkins > 0 then
            reasons[#reasons + 1] = "+ Boomkin / Moonkin Aura: " .. JoinNames(stats.boomkinNames)
        else
            missing[#missing + 1] = "Boomkin"
        end
        if stats.casterDps > 0 then
            reasons[#reasons + 1] = "+ " .. CountListText(stats.casterDps, "caster DPS", "caster DPS") .. ": " .. JoinNames(stats.casterNames)
        end
        if stats.casterDps < 3 then
            missing[#missing + 1] = tostring(3 - stats.casterDps) .. " caster DPS"
        end
    elseif info.key == "mana" then
        if stats.shadowPriests > 0 then
            reasons[#reasons + 1] = "+ Shadow Priest mana battery: " .. JoinNames(stats.shadowNames)
        else
            missing[#missing + 1] = "Shadow Priest"
        end
        if stats.arcaneMages > 0 then
            reasons[#reasons + 1] = "+ Arcane Mage mana target: " .. JoinNames(stats.arcaneMageNames)
        end
        if stats.healers > 0 then
            reasons[#reasons + 1] = "+ Healer mana support: " .. JoinNames(stats.healerNames)
        end
        if stats.manaUsers < 2 then
            missing[#missing + 1] = "mana-hungry caster/healer"
        end
    elseif info.key == "healer" then
        if stats.healers > 0 then
            reasons[#reasons + 1] = "+ Healers: " .. JoinNames(stats.healerNames)
        end
        if stats.restoShamans > 0 then
            reasons[#reasons + 1] = "+ Resto Shaman Mana Tide/Spring: " .. JoinNames(stats.restoShamanNames)
        end
        if stats.healers == 0 then
            missing[#missing + 1] = "healers / utility"
        end
    else
        if stats.casterDps > 0 then
            reasons[#reasons + 1] = "+ Casters: " .. JoinNames(stats.casterNames)
        end
        if stats.healers > 0 then
            reasons[#reasons + 1] = "+ Healers: " .. JoinNames(stats.healerNames)
        end
        if stats.physicalDps > 0 then
            reasons[#reasons + 1] = "+ Physical DPS: " .. JoinNames(stats.physicalNames)
        end
    end

    return {
        index = groupIndex,
        label = info.label,
        key = info.key,
        players = group,
        stats = stats,
        reasons = reasons,
        missing = missing,
    }
end

function Grouper:BuildOrganizerWarnings(groups)
    local warnings = {}
    local groupsNeedingShaman = 0
    local groupsWithPremiumShaman = 0

    for _, groupInfo in ipairs(groups or {}) do
        local stats = groupInfo.stats
        if groupInfo.key == "physical" or groupInfo.key == "caster" or groupInfo.key == "threat" then
            groupsNeedingShaman = groupsNeedingShaman + 1
            if stats.premiumShamans > 0 then
                groupsWithPremiumShaman = groupsWithPremiumShaman + 1
            end
        end

        if stats.elemental > 0 and (stats.casterDps <= 1 or (stats.healers + stats.physicalDps) > stats.casterDps) then
            warnings[#warnings + 1] = "Warning: Elemental Shaman in Group " .. groupInfo.index .. " is not powering a caster-heavy group."
        end
        if stats.enhancement > 0 and (stats.casterDps + stats.healers) > (stats.physicalDps + stats.tanks) then
            warnings[#warnings + 1] = "Warning: Enhancement Shaman in Group " .. groupInfo.index .. " is mostly grouped with casters/healers."
        end
        if stats.boomkins > 0 and stats.casterDps <= 1 then
            warnings[#warnings + 1] = "Warning: Boomkin aura in Group " .. groupInfo.index .. " is not benefiting a caster group."
        end
        if stats.shadowPriests > 0 and stats.manaUsers <= 1 then
            warnings[#warnings + 1] = "Warning: Shadow Priest in Group " .. groupInfo.index .. " is not grouped with mana users."
        end
        if stats.premiumShamans > 1 then
            warnings[#warnings + 1] = "Warning: Two premium Shamans are stacked in Group " .. groupInfo.index .. "."
        end
    end

    if groupsNeedingShaman > groupsWithPremiumShaman then
        for _, groupInfo in ipairs(groups or {}) do
            if groupInfo.stats.premiumShamans > 1 then
                warnings[#warnings + 1] = "Warning: A DPS group lacks a premium Shaman while Group " .. groupInfo.index .. " has multiple."
                break
            end
        end
    end

    return warnings
end

function Grouper:GetOrganizerMoveReason(unit, targetGroup)
    local stats = targetGroup and targetGroup.stats or nil
    local label = targetGroup and targetGroup.label or "target group"

    if IsOrganizerElemental(unit) and stats then
        return "gives Totem of Wrath to " .. CountListText(stats.casterDps, "caster DPS", "caster DPS")
    elseif IsOrganizerBoomkin(unit) and stats then
        return "gives Moonkin Aura to " .. CountListText(stats.casterDps, "caster DPS", "caster DPS")
    elseif IsOrganizerEnhancement(unit) and stats then
        return "gives Windfury/Grace support to " .. CountListText(stats.physicalDps + stats.tanks, "physical player")
    elseif IsOrganizerShadowPriest(unit) and stats then
        return "feeds mana to " .. CountListText(stats.manaUsers, "mana user")
    elseif IsOrganizerRetPaladin(unit) and stats and stats.protPaladinTanks > 0 then
        return "supports prot paladin threat with Sanctity Aura"
    elseif IsOrganizerArcaneMage(unit) and stats and stats.shadowPriests > 0 then
        return "pairs Arcane Mage with Shadow Priest mana"
    end

    return "improves " .. label
end

function Grouper:BuildOrganizerMoves(layout, groups)
    local moves = {}
    for groupIndex, group in ipairs(layout or {}) do
        for _, unit in ipairs(group) do
            if (unit.subgroup or 1) ~= groupIndex then
                moves[#moves + 1] = {
                    unit = unit,
                    name = unit.name,
                    from = unit.subgroup or 1,
                    to = groupIndex,
                    reason = self:GetOrganizerMoveReason(unit, groups[groupIndex]),
                }
            end
        end
    end

    table.sort(moves, function(a, b)
        if a.to ~= b.to then return a.to < b.to end
        return (a.name or "") < (b.name or "")
    end)

    return moves
end

function Grouper:BuildSmartOrganizePlan(context)
    context = context or self:BuildOrganizerContext()

    local currentLayout = BuildCurrentOrganizerLayout(context)
    local improvedCurrentLayout, currentNet, currentRaw, currentMoves = self:ImproveOrganizerLayout(currentLayout)

    local seedLayout = self:BuildOrganizerSeedLayout(context)
    local improvedSeedLayout, seedNet, seedRaw, seedMoves = self:ImproveOrganizerLayout(seedLayout)

    local currentCandidate = {
        layout = improvedCurrentLayout,
        netScore = currentNet,
        rawScore = currentRaw,
        moves = currentMoves,
    }
    local seedCandidate = {
        layout = improvedSeedLayout,
        netScore = seedNet,
        rawScore = seedRaw,
        moves = seedMoves,
    }

    local chosen = OrganizerLayoutIsBetter(seedCandidate, currentCandidate) and seedCandidate or currentCandidate
    local groups = {}
    for groupIndex, group in ipairs(chosen.layout) do
        groups[groupIndex] = self:DescribeOrganizerGroup(group, groupIndex, #chosen.layout)
    end

    local plan = {
        context = context,
        layout = chosen.layout,
        groups = groups,
        score = chosen.netScore,
        rawScore = chosen.rawScore,
        moveCount = chosen.moves,
        simulation = context.simulation == true,
        scenarioName = context.scenarioName,
        rosterSize = context.rosterSize or #(context.players or {}),
        configuredSize = context.configuredSize,
    }
    plan.moves = self:BuildOrganizerMoves(chosen.layout, groups)
    plan.warnings = self:BuildOrganizerWarnings(groups)
    return plan
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
    configFrame:SetSize(560, 650)
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
    hrInput:SetSize(480, 20)
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
    customInput:SetSize(480, 20)
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
    tradeInput:SetSize(120, 20)
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

    -- LFG Interval
    local lfgLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lfgLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 200, yOffset)
    lfgLabel:SetText("LFG Chat:")

    local lfgInput = CreateFrame("EditBox", "GrouperLFGIntervalInput", configFrame, "InputBoxTemplate")
    lfgInput:SetPoint("TOPLEFT", lfgLabel, "BOTTOMLEFT", 5, -5)
    lfgInput:SetSize(120, 20)
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

    -- General Interval
    local generalLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    generalLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 380, yOffset)
    generalLabel:SetText("General Chat:")

    local generalInput = CreateFrame("EditBox", "GrouperGeneralIntervalInput", configFrame, "InputBoxTemplate")
    generalInput:SetPoint("TOPLEFT", generalLabel, "BOTTOMLEFT", 5, -5)
    generalInput:SetSize(120, 20)
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

    -- Version Check Toggle
    local versionCheckLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionCheckLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, yOffset)
    versionCheckLabel:SetText("Enable Version Checking:")

    local versionCheckBox = CreateFrame("CheckButton", "GrouperVersionCheckBox", configFrame, "UICheckButtonTemplate")
    versionCheckBox:SetPoint("LEFT", versionCheckLabel, "RIGHT", 10, 0)
    versionCheckBox:SetSize(24, 24)
    versionCheckBox:SetChecked(GrouperDB.versionCheck.enabled)
    versionCheckBox:SetScript("OnClick", function(self)
        GrouperDB.versionCheck.enabled = self:GetChecked()
        if GrouperDB.versionCheck.enabled then
            print("|cff00ff00[Grouper]|r Version checking enabled")
        else
            print("|cffff9900[Grouper]|r Version checking disabled")
        end
    end)

    local versionCheckTooltip = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionCheckTooltip:SetPoint("TOPLEFT", versionCheckLabel, "BOTTOMLEFT", 0, -5)
    versionCheckTooltip:SetText("(Notifies you when guild members have a newer version)")
    versionCheckTooltip:SetTextColor(0.7, 0.7, 0.7)

    -- Smart Organize Button
    local organizeButton = CreateFrame("Button", "GrouperSmartOrganizeButton", configFrame, "UIPanelButtonTemplate")
    organizeButton:SetSize(230, 30)
    organizeButton:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 40, 60)
    organizeButton:SetText("Smart Organize Raid")
    organizeButton:SetScript("OnClick", function()
        Grouper:ShowSmartOrganizePreview()
    end)
    ApplyElvUISkin(organizeButton, "button")

    -- Preview Button
    local previewButton = CreateFrame("Button", "GrouperPreviewButton", configFrame, "UIPanelButtonTemplate")
    previewButton:SetSize(230, 30)
    previewButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -40, 60)
    previewButton:SetText("Preview Messages")
    previewButton:SetScript("OnClick", function()
        Grouper:ShowPreviewMessages(configFrame.selectedBoss)
    end)
    ApplyElvUISkin(previewButton, "button")

    -- Start/Stop Buttons
    local startButton = CreateFrame("Button", "GrouperStartButton", configFrame, "UIPanelButtonTemplate")
    startButton:SetSize(230, 30)
    startButton:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 40, 20)
    startButton:SetText("Start Recruiting")
    startButton:SetScript("OnClick", function()
        Grouper:StartSession(configFrame.selectedBoss, nil)
        configFrame:Hide()
    end)
    ApplyElvUISkin(startButton, "button")

    local configStopButton = CreateFrame("Button", "GrouperConfigStopButton", configFrame, "UIPanelButtonTemplate")
    configStopButton:SetSize(230, 30)
    configStopButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -40, 20)
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

function Grouper:CanApplySmartOrganize()
    if InCombatLockdown and InCombatLockdown() then
        PrintGrouper("Smart Organize cannot move raid members in combat.", "|cffff9900")
        return false
    end
    if not (IsInRaid and IsInRaid()) then
        PrintGrouper("Smart Organize can only apply moves in a raid.", "|cffff9900")
        return false
    end

    if UnitIsGroupLeader and UnitIsGroupLeader("player") then
        return true
    end
    if UnitIsGroupAssistant and UnitIsGroupAssistant("player") then
        return true
    end

    if GetNumGroupMembers and GetRaidRosterInfo and UnitName then
        local playerName = UnitName("player")
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name and UnitNamesMatch(name, playerName) and (rank == 2 or rank == 1) then
                return true
            end
        end
    end

    PrintGrouper("Smart Organize needs raid leader or assistant.", "|cffff9900")
    return false
end

function Grouper:FindRaidIndexByName(name)
    if not name or not GetNumGroupMembers or not GetRaidRosterInfo then
        return nil
    end
    for i = 1, GetNumGroupMembers() do
        local rosterName = GetRaidRosterInfo(i)
        if rosterName and UnitNamesMatch(rosterName, name) then
            return i
        end
    end
    return nil
end

local function BuildApplyStateFromPlan(plan)
    local state = {
        players = {},
        actions = 0,
        maxActions = 80,
        plan = plan,
    }

    for targetGroup, group in ipairs(plan.layout or {}) do
        for _, unit in ipairs(group) do
            state.players[#state.players + 1] = {
                name = unit.fullName or unit.name,
                shortName = unit.name,
                current = unit.subgroup or 1,
                target = targetGroup,
            }
        end
    end
    return state
end

local function CountApplyStateGroups(state)
    local counts = {}
    for _, player in ipairs(state.players or {}) do
        counts[player.current] = (counts[player.current] or 0) + 1
    end
    return counts
end

local function FindApplyPlayer(state, predicate)
    for _, player in ipairs(state.players or {}) do
        if predicate(player) then
            return player
        end
    end
    return nil
end

local function ApplyStateComplete(state)
    for _, player in ipairs(state.players or {}) do
        if player.current ~= player.target then
            return false
        end
    end
    return true
end

function Grouper:ApplySmartOrganizeOperation(state, playerA, playerB)
    if not playerA then return false end

    local indexA = self:FindRaidIndexByName(playerA.name)
    if not indexA then
        PrintGrouper("Could not find " .. tostring(playerA.shortName or playerA.name) .. " in the raid roster.", "|cffff0000")
        return false
    end

    if playerB then
        local indexB = self:FindRaidIndexByName(playerB.name)
        if not indexB then
            PrintGrouper("Could not find " .. tostring(playerB.shortName or playerB.name) .. " in the raid roster.", "|cffff0000")
            return false
        end
        if SwapRaidSubgroup then
            SwapRaidSubgroup(indexA, indexB)
            playerA.current, playerB.current = playerB.current, playerA.current
            return true
        end
    elseif SetRaidSubgroup then
        SetRaidSubgroup(indexA, playerA.target)
        playerA.current = playerA.target
        return true
    end

    PrintGrouper("Raid move API is unavailable in this client.", "|cffff0000")
    return false
end

function Grouper:ApplyNextSmartOrganizeMove(state)
    if not state then return end
    if not self:CanApplySmartOrganize() then return end

    if ApplyStateComplete(state) then
        PrintGrouper("Smart Organize complete.")
        return
    end

    state.actions = state.actions + 1
    if state.actions > state.maxActions then
        PrintGrouper("Smart Organize stopped after too many move attempts. Please retry after the roster settles.", "|cffff9900")
        return
    end

    local playerA
    local playerB

    playerA = FindApplyPlayer(state, function(player)
        return player.current ~= player.target
    end)

    if not playerA then
        PrintGrouper("Smart Organize complete.")
        return
    end

    playerB = FindApplyPlayer(state, function(player)
        return player ~= playerA and player.current == playerA.target and player.target == playerA.current
    end)

    local moved = false
    if playerB then
        moved = self:ApplySmartOrganizeOperation(state, playerA, playerB)
    else
        local counts = CountApplyStateGroups(state)
        if (counts[playerA.target] or 0) < RAID_GROUP_SIZE then
            moved = self:ApplySmartOrganizeOperation(state, playerA, nil)
        else
            playerB = FindApplyPlayer(state, function(player)
                return player ~= playerA and player.current == playerA.target and player.current ~= player.target
            end)
            if playerB then
                moved = self:ApplySmartOrganizeOperation(state, playerA, playerB)
            end
        end
    end

    if not moved then
        PrintGrouper("Smart Organize could not find a safe next move.", "|cffff9900")
        return
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, function()
            Grouper:ApplyNextSmartOrganizeMove(state)
        end)
    else
        self:ApplyNextSmartOrganizeMove(state)
    end
end

function Grouper:ApplySmartOrganizePlan(plan)
    plan = plan or self.pendingSmartOrganizePlan
    if not plan then
        PrintGrouper("No Smart Organize preview is ready yet.", "|cffff9900")
        return
    end
    if plan.simulation then
        PrintGrouper("Smart Organize planning previews cannot be applied to the live raid.", "|cffff9900")
        return
    end
    if #plan.moves == 0 then
        PrintGrouper("Raid groups already match the Smart Organize plan.")
        return
    end
    if not self:CanApplySmartOrganize() then
        return
    end

    PrintGrouper("Applying Smart Organize with " .. #plan.moves .. " planned move(s).")
    self:ApplyNextSmartOrganizeMove(BuildApplyStateFromPlan(plan))
end

function Grouper:BuildSmartOrganizePreviewLines(plan)
    local lines = {}
    lines[#lines + 1] = { text = plan.simulation and "Smart Organize Planning Mode" or "Smart Organize Preview", kind = "header" }
    if plan.simulation then
        lines[#lines + 1] = {
            text = string.format("Simulated raid: %d/%d - %s", plan.rosterSize or 0, plan.configuredSize or 0, plan.scenarioName or "sample raid"),
            kind = "normal",
        }
    end
    lines[#lines + 1] = { text = string.format("Score: %d (%d raw), Moves: %d", plan.score or 0, plan.rawScore or 0, #plan.moves), kind = "normal" }
    lines[#lines + 1] = { text = " " }

    for _, groupInfo in ipairs(plan.groups or {}) do
        lines[#lines + 1] = {
            text = string.format("Group %d: %s", groupInfo.index, groupInfo.label),
            kind = "group",
        }

        local playerNames = {}
        for _, unit in ipairs(groupInfo.players or {}) do
            playerNames[#playerNames + 1] = FormatOrganizerUnit(unit)
        end
        lines[#lines + 1] = { text = "  " .. (#playerNames > 0 and table.concat(playerNames, " | ") or "(empty)") }

        for _, reason in ipairs(groupInfo.reasons or {}) do
            lines[#lines + 1] = { text = "  " .. reason, kind = "good" }
        end
        if #groupInfo.missing > 0 then
            lines[#lines + 1] = { text = "  Missing: " .. table.concat(groupInfo.missing, ", "), kind = "missing" }
        end
        lines[#lines + 1] = { text = " " }
    end

    if #plan.warnings > 0 then
        lines[#lines + 1] = { text = "Warnings", kind = "header" }
        for _, warning in ipairs(plan.warnings) do
            lines[#lines + 1] = { text = "  " .. warning, kind = "warning" }
        end
        lines[#lines + 1] = { text = " " }
    end

    lines[#lines + 1] = { text = "Planned Moves", kind = "header" }
    if #plan.moves == 0 then
        lines[#lines + 1] = { text = "  No moves needed.", kind = "good" }
    else
        for _, move in ipairs(plan.moves) do
            lines[#lines + 1] = {
                text = string.format("  %s: Group %d -> Group %d (%s)", move.name, move.from, move.to, move.reason),
                kind = "move",
            }
        end
    end

    return lines
end

function Grouper:SetSmartOrganizeFrameLines(lines)
    local frame = smartOrganizeFrame
    if not frame then return end

    local rowHeight = 16
    frame.Rows = frame.Rows or {}
    for index, line in ipairs(lines or {}) do
        local row = frame.Rows[index]
        if not row then
            row = frame.ScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row:SetJustifyH("LEFT")
            row:SetWidth(620)
            frame.Rows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.ScrollChild, "TOPLEFT", 0, -((index - 1) * rowHeight))
        row:SetText(line.text or "")
        if line.kind == "warning" then
            row:SetTextColor(1.0, 0.55, 0.15)
        elseif line.kind == "good" then
            row:SetTextColor(0.35, 1.0, 0.35)
        elseif line.kind == "missing" then
            row:SetTextColor(1.0, 0.82, 0.25)
        elseif line.kind == "header" or line.kind == "group" then
            row:SetTextColor(1.0, 0.9, 0.45)
        elseif line.kind == "move" then
            row:SetTextColor(0.65, 0.85, 1.0)
        else
            row:SetTextColor(1.0, 1.0, 1.0)
        end
        row:Show()
    end

    for index = #(lines or {}) + 1, #frame.Rows do
        frame.Rows[index]:Hide()
    end

    frame.ScrollChild:SetHeight(math.max(1, #(lines or {}) * rowHeight))
end

local GROUP_BOARD_LABELS = {
    threat = "Threat",
    physical = "Physical",
    caster = "Caster",
    mana = "Mana",
    healer = "Heals",
    support = "Support",
    mixed = "Mixed",
    overflow = "Overflow",
}

local function SetTextureColor(texture, r, g, b, a)
    if not texture then return end
    if texture.SetColorTexture then
        texture:SetColorTexture(r, g, b, a)
    else
        texture:SetTexture(r, g, b, a)
    end
end

local function OrganizerRoleCode(unit)
    if IsOrganizerTank(unit) then return "T" end
    if IsOrganizerHealer(unit) then return "H" end
    if IsOrganizerDamager(unit) then return "D" end
    return "-"
end

local function OrganizerUnitBoardDetail(unit)
    if not unit then return "" end
    local detail = unit.spec and SpecLabel(unit.spec) or RoleLabel(unit.role)
    return OrganizerRoleCode(unit) .. " " .. detail
end

local function CreateSmartOrganizeBoardGroup(parent)
    local groupFrame = CreateFrame("Frame", nil, parent)
    groupFrame.Header = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    groupFrame.Header:SetPoint("TOPLEFT", 0, 0)
    groupFrame.Header:SetJustifyH("LEFT")
    groupFrame.Rows = {}

    for slot = 1, RAID_GROUP_SIZE do
        local row = CreateFrame("Frame", nil, groupFrame)
        row:SetHeight(17)
        row.Bg = row:CreateTexture(nil, "BACKGROUND")
        row.Bg:SetAllPoints()
        SetTextureColor(row.Bg, 0.03, 0.03, 0.03, 0.82)
        row.Fill = row:CreateTexture(nil, "ARTWORK")
        row.Fill:SetPoint("TOPLEFT", 1, -1)
        row.Fill:SetPoint("BOTTOMRIGHT", -1, 1)
        row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.Name:SetPoint("LEFT", 4, 0)
        row.Name:SetJustifyH("LEFT")
        row.Detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.Detail:SetPoint("RIGHT", -4, 0)
        row.Detail:SetJustifyH("RIGHT")
        groupFrame.Rows[slot] = row
    end

    return groupFrame
end

function Grouper:UpdateSmartOrganizeRaidBoard(plan)
    local frame = smartOrganizeFrame
    if not frame or not frame.RaidBoard then return 0 end

    local board = frame.RaidBoard
    local layout = plan and plan.layout or {}
    local groupCount = math.max(1, #layout)
    local columns = groupCount > 5 and 4 or groupCount
    local gap = 8
    local boardWidth = 646
    local groupWidth = math.floor((boardWidth - ((columns - 1) * gap)) / columns)
    local groupHeight = 112
    local rows = math.ceil(groupCount / columns)
    local boardHeight = (rows * groupHeight) + ((rows - 1) * gap)

    board:SetHeight(boardHeight)

    for groupIndex = 1, groupCount do
        local groupFrame = board.Groups[groupIndex]
        if not groupFrame then
            groupFrame = CreateSmartOrganizeBoardGroup(board)
            board.Groups[groupIndex] = groupFrame
        end

        local column = (groupIndex - 1) % columns
        local rowIndex = math.floor((groupIndex - 1) / columns)
        groupFrame:ClearAllPoints()
        groupFrame:SetPoint("TOPLEFT", board, "TOPLEFT", column * (groupWidth + gap), -(rowIndex * (groupHeight + gap)))
        groupFrame:SetSize(groupWidth, groupHeight)

        local info = GetOrganizerGroupInfo(groupIndex, groupCount)
        local label = GROUP_BOARD_LABELS[info.key] or info.label or "Group"
        groupFrame.Header:SetWidth(groupWidth)
        groupFrame.Header:SetText(string.format("G%d %s", groupIndex, label))

        local group = layout[groupIndex] or {}
        for slot = 1, RAID_GROUP_SIZE do
            local unit = group[slot]
            local row = groupFrame.Rows[slot]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, -(18 + ((slot - 1) * 18)))
            row:SetWidth(groupWidth)
            row.Name:SetWidth(math.floor(groupWidth * 0.46))
            row.Detail:SetWidth(math.floor(groupWidth * 0.48))

            if unit then
                local color = ClassColor(unit.class)
                SetTextureColor(row.Fill, color[1], color[2], color[3], 0.72)
                row.Fill:Show()
                row.Name:SetText(ShortText(unit.name, groupWidth <= 125 and 8 or 11))
                row.Name:SetTextColor(1, 1, 1)
                row.Detail:SetText(ShortText(OrganizerUnitBoardDetail(unit), groupWidth <= 125 and 10 or 14))
                row.Detail:SetTextColor(1, 1, 1)
            else
                row.Fill:Hide()
                row.Name:SetText("Open")
                row.Name:SetTextColor(0.48, 0.48, 0.48)
                row.Detail:SetText("")
            end
            row:Show()
        end

        groupFrame:Show()
    end

    for groupIndex = groupCount + 1, #(board.Groups or {}) do
        board.Groups[groupIndex]:Hide()
    end

    return boardHeight
end

function Grouper:ConfigureSmartOrganizeFrame(plan)
    local frame = smartOrganizeFrame
    if not frame then return end

    frame.Scroll:ClearAllPoints()
    frame.ApplyButton:ClearAllPoints()
    frame.GuessButton:ClearAllPoints()
    frame.SpecsButton:ClearAllPoints()
    frame.CloseButton:ClearAllPoints()

    frame.ApplyButton:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.GuessButton:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -8, 0)

    if plan and plan.simulation then
        frame.Title:SetText("Grouper Smart Organize Planning")
        frame.RaidBoard:Show()
        local boardHeight = self:UpdateSmartOrganizeRaidBoard(plan)
        frame.Scroll:SetPoint("TOPLEFT", 18, -(44 + boardHeight + 10))
        frame.Scroll:SetPoint("BOTTOMRIGHT", -36, 58)
        frame.ApplyButton:Disable()
        frame.GuessButton:SetText("New Sim")
        frame.GuessButton:SetScript("OnClick", function()
            Grouper:ShowSmartOrganizePlanningPreview()
        end)
        frame.SpecsButton:Hide()
        frame.CloseButton:SetPoint("RIGHT", frame.GuessButton, "LEFT", -8, 0)
    else
        frame.Title:SetText("Grouper Smart Organize")
        frame.RaidBoard:Hide()
        frame.Scroll:SetPoint("TOPLEFT", 18, -36)
        frame.Scroll:SetPoint("BOTTOMRIGHT", -36, 58)
        frame.GuessButton:SetText("Guess")
        frame.GuessButton:SetScript("OnClick", function()
            Grouper:ShowSmartOrganizePreview({ guess = true })
        end)
        frame.SpecsButton:Show()
        frame.SpecsButton:SetPoint("RIGHT", frame.GuessButton, "LEFT", -8, 0)
        frame.CloseButton:SetPoint("RIGHT", frame.SpecsButton, "LEFT", -8, 0)
    end
end

function Grouper:EnsureSmartOrganizeFrame()
    if smartOrganizeFrame then
        return smartOrganizeFrame
    end

    local frame = CreateFrame("Frame", "GrouperSmartOrganizeFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(700, 560)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.Title:SetPoint("TOP", 0, -8)
    frame.Title:SetText("Grouper Smart Organize")

    frame.RaidBoard = CreateFrame("Frame", nil, frame)
    frame.RaidBoard:SetPoint("TOPLEFT", 18, -36)
    frame.RaidBoard:SetPoint("TOPRIGHT", -36, -36)
    frame.RaidBoard.Groups = {}
    frame.RaidBoard:Hide()

    frame.Scroll = CreateFrame("ScrollFrame", "GrouperSmartOrganizeScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.Scroll:SetPoint("TOPLEFT", 18, -36)
    frame.Scroll:SetPoint("BOTTOMRIGHT", -36, 58)

    frame.ScrollChild = CreateFrame("Frame", "GrouperSmartOrganizeScrollChild", frame.Scroll)
    frame.ScrollChild:SetSize(620, 1)
    frame.Scroll:SetScrollChild(frame.ScrollChild)

    frame.ApplyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ApplyButton:SetSize(110, 24)
    frame.ApplyButton:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.ApplyButton:SetText("Apply")
    frame.ApplyButton:SetScript("OnClick", function()
        Grouper:ApplySmartOrganizePlan(Grouper.pendingSmartOrganizePlan)
    end)
    ApplyElvUISkin(frame.ApplyButton, "button")

    frame.GuessButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.GuessButton:SetSize(110, 24)
    frame.GuessButton:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -8, 0)
    frame.GuessButton:SetText("Guess")
    frame.GuessButton:SetScript("OnClick", function()
        Grouper:ShowSmartOrganizePreview({ guess = true })
    end)
    ApplyElvUISkin(frame.GuessButton, "button")

    frame.SpecsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.SpecsButton:SetSize(110, 24)
    frame.SpecsButton:SetPoint("RIGHT", frame.GuessButton, "LEFT", -8, 0)
    frame.SpecsButton:SetText("Assign Specs")
    frame.SpecsButton:SetScript("OnClick", function()
        local context = Grouper:BuildOrganizerContext()
        Grouper:ShowOrganizerSpecFrame(Grouper:GetUncertainOrganizerPlayers(context))
    end)
    ApplyElvUISkin(frame.SpecsButton, "button")

    frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.CloseButton:SetSize(110, 24)
    frame.CloseButton:SetPoint("RIGHT", frame.SpecsButton, "LEFT", -8, 0)
    frame.CloseButton:SetText("Close")
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    ApplyElvUISkin(frame.CloseButton, "button")

    ApplyElvUISkin(frame, "frame")

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "GrouperSmartOrganizeFrame")
    end

    smartOrganizeFrame = frame
    return frame
end

local function SetOrganizerSpecButtonSelected(button, selected)
    if not button then return end
    if selected then
        button:Disable()
        if button.GetFontString and button:GetFontString() then
            button:GetFontString():SetTextColor(0.2, 1.0, 0.2)
        end
    else
        button:Enable()
        if button.GetFontString and button:GetFontString() then
            button:GetFontString():SetTextColor(1.0, 1.0, 1.0)
        end
    end
end

function Grouper:EnsureOrganizerSpecFrame()
    if smartOrganizeSpecFrame then
        return smartOrganizeSpecFrame
    end

    local frame = CreateFrame("Frame", "GrouperSmartOrganizeSpecFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(640, 430)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.Title:SetPoint("TOP", 0, -8)
    frame.Title:SetText("Smart Organize: Assign Specs")

    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.Text:SetPoint("TOPLEFT", 18, -36)
    frame.Text:SetPoint("TOPRIGHT", -18, -36)
    frame.Text:SetJustifyH("LEFT")
    frame.Text:SetText("Select specs for players Grouper cannot infer, then preview Smart Organize again.")

    frame.Scroll = CreateFrame("ScrollFrame", "GrouperSmartOrganizeSpecScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.Scroll:SetPoint("TOPLEFT", 18, -62)
    frame.Scroll:SetPoint("BOTTOMRIGHT", -38, 52)

    frame.ScrollChild = CreateFrame("Frame", "GrouperSmartOrganizeSpecScrollChild", frame.Scroll)
    frame.ScrollChild:SetSize(560, 1)
    frame.Scroll:SetScrollChild(frame.ScrollChild)
    frame.Rows = {}

    frame.ApplyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ApplyButton:SetSize(110, 24)
    frame.ApplyButton:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.ApplyButton:SetText("Preview")
    frame.ApplyButton:SetScript("OnClick", function()
        Grouper:ApplyOrganizerSpecSelections()
    end)
    ApplyElvUISkin(frame.ApplyButton, "button")

    frame.GuessButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.GuessButton:SetSize(110, 24)
    frame.GuessButton:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -8, 0)
    frame.GuessButton:SetText("Guess")
    frame.GuessButton:SetScript("OnClick", function()
        frame:Hide()
        Grouper:ShowSmartOrganizePreview({ guess = true })
    end)
    ApplyElvUISkin(frame.GuessButton, "button")

    frame.CancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.CancelButton:SetSize(110, 24)
    frame.CancelButton:SetPoint("RIGHT", frame.GuessButton, "LEFT", -8, 0)
    frame.CancelButton:SetText("Cancel")
    frame.CancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    ApplyElvUISkin(frame.CancelButton, "button")

    ApplyElvUISkin(frame, "frame")

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "GrouperSmartOrganizeSpecFrame")
    end

    smartOrganizeSpecFrame = frame
    return frame
end

function Grouper:UpdateOrganizerSpecRow(row, selected)
    for _, button in ipairs(row.Buttons or {}) do
        SetOrganizerSpecButtonSelected(button, button.choice == selected)
    end
end

function Grouper:ShowOrganizerSpecFrame(uncertain)
    if not uncertain or #uncertain == 0 then
        PrintGrouper("No uncertain role/spec assignments were found.")
        return
    end

    local frame = self:EnsureOrganizerSpecFrame()
    if not frame then
        PrintGrouper("Could not create the Smart Organize spec frame.", "|cffff0000")
        return
    end

    self.pendingOrganizerSpecUnits = uncertain
    self.organizerSpecSelections = {}

    local rowHeight = 34
    for index, unit in ipairs(uncertain) do
        local row = frame.Rows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.ScrollChild)
            row:SetSize(560, rowHeight)
            row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.Name:SetPoint("LEFT", 0, 0)
            row.Name:SetSize(165, 18)
            row.Name:SetJustifyH("LEFT")
            row.Buttons = {}
            frame.Rows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((index - 1) * rowHeight))
        row.unit = unit
        row:Show()
        row.Name:SetText(unit.name .. " (" .. ClassLabel(unit.class) .. ")")

        local choices = self:GetOrganizerChoiceList(unit) or {}
        local selected = choices[1]
        self.organizerSpecSelections[unit.key or unit.name] = selected

        for buttonIndex, choice in ipairs(choices) do
            local button = row.Buttons[buttonIndex]
            if not button then
                button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                button:SetSize(82, 22)
                row.Buttons[buttonIndex] = button
            end
            button:ClearAllPoints()
            button:SetPoint("LEFT", 175 + ((buttonIndex - 1) * 88), 0)
            button:SetText(choice.label)
            button.choice = choice
            local unitRef = unit
            local rowRef = row
            button:SetScript("OnClick", function(selfButton)
                Grouper.organizerSpecSelections[unitRef.key or unitRef.name] = selfButton.choice
                Grouper:UpdateOrganizerSpecRow(rowRef, selfButton.choice)
            end)
            button:Show()
            SetOrganizerSpecButtonSelected(button, choice == selected)
        end

        for buttonIndex = #choices + 1, #row.Buttons do
            row.Buttons[buttonIndex]:Hide()
        end
    end

    for index = #uncertain + 1, #frame.Rows do
        frame.Rows[index]:Hide()
    end

    frame.ScrollChild:SetHeight(math.max(1, #uncertain * rowHeight))
    frame:SetHeight(math.min(520, math.max(220, 122 + (#uncertain * rowHeight))))
    frame:Show()
end

function Grouper:ApplyOrganizerSpecSelections()
    local frame = smartOrganizeSpecFrame
    if not frame then return end

    for _, unit in ipairs(self.pendingOrganizerSpecUnits or {}) do
        local choice = self.organizerSpecSelections and self.organizerSpecSelections[unit.key or unit.name]
        if choice then
            self:SaveOrganizerManualChoice(unit, choice)
        end
    end

    frame:Hide()
    self:ShowSmartOrganizePreview({ noPrompt = true })
end

function Grouper:ShowOrganizerGuessPrompt(uncertain)
    if type(StaticPopupDialogs) == "table" and type(StaticPopup_Show) == "function" then
        StaticPopupDialogs.GROUPER_SMART_ORGANIZE_GUESS = {
            text = "Grouper is unsure about %s role/spec assignment(s).",
            button1 = "Guess specs",
            button2 = "Assign specs",
            OnAccept = function()
                Grouper:ShowSmartOrganizePreview({ guess = true })
            end,
            OnCancel = function(_, data)
                Grouper:ShowOrganizerSpecFrame(data or uncertain)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            noCancelOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GROUPER_SMART_ORGANIZE_GUESS", tostring(#uncertain), nil, uncertain)
    else
        self:ShowOrganizerSpecFrame(uncertain)
    end
end

function Grouper:ShowSmartOrganizePlanningPreview(options)
    local context = self:BuildNextOrganizerPlanningContext(options)
    local plan = self:BuildSmartOrganizePlan(context)
    self.pendingSmartOrganizePlan = nil
    self.pendingSmartOrganizeSimulationPlan = plan

    local frame = self:EnsureSmartOrganizeFrame()
    self:ConfigureSmartOrganizeFrame(plan)
    self:SetSmartOrganizeFrameLines(self:BuildSmartOrganizePreviewLines(plan))
    frame.ApplyButton:Disable()
    frame:Show()

    PrintGrouper(string.format("Smart Organize planning mode: showing %d/%d simulated raid members.", plan.rosterSize or 0, plan.configuredSize or 0))
end

function Grouper:ShowSmartOrganizePreview(options)
    options = options or {}
    if not (IsInRaid and IsInRaid()) and not _G.GROUPER_TEST_MODE then
        self:ShowSmartOrganizePlanningPreview(options)
        return
    end

    local context = self:BuildOrganizerContext({ guess = options.guess == true })
    if #context.players == 0 then
        PrintGrouper("No raid members found for Smart Organize.", "|cffff9900")
        return
    end

    local uncertain = self:GetUncertainOrganizerPlayers(context)
    if #uncertain > 0 and not options.guess and not options.noPrompt then
        self:ShowOrganizerGuessPrompt(uncertain)
        return
    end

    local plan = self:BuildSmartOrganizePlan(context)
    self.pendingSmartOrganizePlan = plan

    for _, warning in ipairs(plan.warnings or {}) do
        PrintGrouper(warning, "|cffff9900")
    end

    local frame = self:EnsureSmartOrganizeFrame()
    self:ConfigureSmartOrganizeFrame(plan)
    self:SetSmartOrganizeFrameLines(self:BuildSmartOrganizePreviewLines(plan))
    if #plan.moves > 0 then
        frame.ApplyButton:Enable()
    else
        frame.ApplyButton:Disable()
    end
    frame:Show()
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

    -- /grouper organize
    elseif cmd == "organize" or cmd == "organise" or cmd == "smart" or cmd == "raidorg" then
        local subcmd = args[2] and string.lower(args[2]) or nil
        if subcmd == "guess" then
            self:ShowSmartOrganizePreview({ guess = true })
        elseif subcmd == "apply" then
            self:ApplySmartOrganizePlan(self.pendingSmartOrganizePlan)
        elseif subcmd == "specs" then
            local context = self:BuildOrganizerContext()
            self:ShowOrganizerSpecFrame(self:GetUncertainOrganizerPlayers(context))
        elseif subcmd == "lock" then
            local name = args[3] or (UnitName and UnitName("target"))
            self:SetOrganizerPlayerLocked(name, true)
        elseif subcmd == "unlock" then
            local name = args[3] or (UnitName and UnitName("target"))
            self:SetOrganizerPlayerLocked(name, false)
        elseif subcmd == "clearlocks" then
            self:ClearOrganizerLocks()
        else
            self:ShowSmartOrganizePreview()
        end

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
    print("|cffffcc00/grouper organize|r - Preview Smart Organize raid groups")
    print("|cffffcc00/grouper organize guess|r - Preview using guessed specs")
    print("|cffffcc00/grouper organize apply|r - Apply the last Smart Organize preview")
    print("|cffffcc00/grouper organize lock <player>|r - Pin a player in their current group")
    print("|cffffcc00/grouper organize unlock <player>|r - Remove a Smart Organize pin")
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

_G.Grouper = Grouper
Grouper._test = {
    BuildSmartOrganizePlan = function(context)
        return Grouper:BuildSmartOrganizePlan(context)
    end,
    ScoreOrganizerLayout = function(layout)
        return Grouper:ScoreOrganizerLayout(layout)
    end,
    BuildOrganizerGroupStats = function(group)
        return BuildOrganizerGroupStats(group)
    end,
    UpdateOrganizerTags = function(unit)
        return Grouper:UpdateOrganizerTags(unit)
    end,
    ApplyOrganizerGuess = function(unit)
        return Grouper:ApplyOrganizerGuess(unit)
    end,
    GetUncertainOrganizerPlayers = function(context)
        return Grouper:GetUncertainOrganizerPlayers(context)
    end,
    BuildCurrentOrganizerLayout = function(context)
        return BuildCurrentOrganizerLayout(context)
    end,
    BuildOrganizerPlanningContext = function(options)
        return Grouper:BuildOrganizerPlanningContext(options)
    end,
}

if not _G.GROUPER_TEST_MODE then

-- Event handlers
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" and arg1 == "Grouper" then
        Grouper:InitDB()

        -- Register addon message prefix for version checking
        C_ChatInfo.RegisterAddonMessagePrefix(versionCheck.messagePrefix)
        C_ChatInfo.RegisterAddonMessagePrefix(RAID_ORGANIZER_SPEC_PREFIX)

        -- Initialize minimap button
        if GrouperDB.minimapButton.show then
            Grouper:CreateMinimapButton()
        end

        print("|cff00ff00[Grouper]|r Grouper loaded! Type /grouper for help.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if activeSession.active then
            Grouper:UpdateButtons()
        end

        -- Broadcast version to guild after delay
        C_Timer.After(versionCheck.broadcastDelay, function()
            Grouper:BroadcastVersion()
        end)
        C_Timer.After(3, function()
            Grouper:BroadcastOrganizerSpec()
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        if prefix == versionCheck.messagePrefix and channel == "GUILD" then
            Grouper:HandleVersionMessage(sender, message)
        elseif prefix == RAID_ORGANIZER_SPEC_PREFIX then
            Grouper:HandleOrganizerSpecMessage(sender, message)
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        Grouper:BroadcastOrganizerSpec()
    end
end)

-- World boss zone IDs (expansion-specific)
local worldBossZones
if isClassic then
    worldBossZones = {
        [16] = true,  -- Azshara (Azuregos)
        [17] = true,  -- Blasted Lands (Lord Kazzak)
        [47] = true,  -- Duskwood (Emeriss)
        [26] = true,  -- The Hinterlands (Lethon)
        [43] = true,  -- Ashenvale (Taerar)
        [69] = true,  -- Feralas (Ysondre)
    }
elseif isTBC then
    worldBossZones = {
        [111] = true,  -- Shadowmoon Valley (Doom Lord Kazzak)
        [122] = true,  -- Shadowmoon Valley (Doomwalker)
    }
elseif isWrath then
    worldBossZones = {}  -- WOTLK has no outdoor world bosses
end

-- Combat log event handler for automatic world boss kill detection
local combatLogFrame = CreateFrame("Frame")
local combatLogActive = false

-- Function to check if we should listen to combat log
local function shouldListenToCombatLog()
    -- Only listen if in a raid or group
    if not (IsInRaid() or IsInGroup()) then
        return false
    end

    -- Only listen if in a world boss zone
    local zoneID = C_Map.GetBestMapForUnit("player")
    if not zoneID or not worldBossZones[zoneID] then
        return false
    end

    return true
end

-- Function to update combat log registration
local function updateCombatLogRegistration()
    local shouldListen = shouldListenToCombatLog()

    if shouldListen and not combatLogActive then
        combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        combatLogActive = true
    elseif not shouldListen and combatLogActive then
        combatLogFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        combatLogActive = false
    end
end

-- Register zone change and group roster events to update combat log registration
combatLogFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
combatLogFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

combatLogFrame:SetScript("OnEvent", function(self, event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "GROUP_ROSTER_UPDATE" then
        updateCombatLogRegistration()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
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
    end
end)

-- Initial check on load
C_Timer.After(2, updateCombatLogRegistration)

-- Register slash commands
SLASH_GROUPER1 = "/grouper"
SlashCmdList["GROUPER"] = function(msg)
    Grouper:HandleCommand(msg)
end

end
