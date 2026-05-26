_G.GROUPER_TEST_MODE = true
_G.WOW_PROJECT_CLASSIC = 1
_G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 2
_G.WOW_PROJECT_WRATH_CLASSIC = 3
_G.WOW_PROJECT_ID = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
_G.GrouperDB = { raidSize = 25, raidOrganizer = { specs = {}, lockedPlayers = {} } }

local chunk, err = loadfile("Grouper.lua")
if not chunk then error(err) end
chunk()

local G = _G.Grouper
local T = G._test

local tests = {}

local function test(name, fn)
    tests[#tests + 1] = { name = name, fn = fn }
end

local function assertEquals(actual, expected, message)
    if actual ~= expected then
        error((message or "assertEquals failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function assertTrue(value, message)
    if not value then
        error(message or "assertTrue failed", 2)
    end
end

local function unit(name, class, role, spec, subgroup, mainTank)
    local u = {
        name = name,
        fullName = name,
        key = name,
        class = class,
        role = role or "DAMAGER",
        spec = spec,
        subgroup = subgroup or 1,
        mainTank = mainTank == true,
    }
    T.UpdateOrganizerTags(u)
    return u
end

local function context(players)
    return { players = players, groupCount = 5, configuredSize = 25 }
end

local function statsForGroup(plan, index)
    return plan.groups[index] and plan.groups[index].stats or {}
end

local function groupMissingIncludes(plan, index, text)
    local group = plan.groups[index]
    for _, missing in ipairs(group and group.missing or {}) do
        if missing == text then
            return true
        end
    end
    return false
end

local function listIncludes(list, text)
    for _, value in ipairs(list or {}) do
        if value == text then
            return true
        end
    end
    return false
end

local function listIncludesAny(list, values)
    for _, wanted in ipairs(values or {}) do
        if listIncludes(list, wanted) then
            return true
        end
    end
    return false
end

local function logIncludes(log, text)
    for _, entry in ipairs(log or {}) do
        if string.find(entry.text or "", text, 1, true) then
            return true
        end
    end
    return false
end

local function groupForPlayer(plan, playerName)
    for groupIndex, group in ipairs(plan.layout or {}) do
        for _, unit in ipairs(group) do
            if unit.name == playerName then
                return groupIndex
            end
        end
    end
    return nil
end

local function countMatching(players, predicate)
    local count = 0
    for _, unit in ipairs(players or {}) do
        if predicate(unit) then
            count = count + 1
        end
    end
    return count
end

local function addUnits(players, count, prefix, class, role, spec, subgroup)
    for index = 1, count do
        players[#players + 1] = unit(prefix .. tostring(index), class, role, spec, subgroup)
    end
end

test("caster pump groups elemental, boomkin, and three casters", function()
    local players = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Windfury", "SHAMAN", "DAMAGER", "ENHANCEMENT", 5),
        unit("Stormbolt", "SHAMAN", "DAMAGER", "ELEMENTAL", 5),
        unit("Moonchef", "DRUID", "DAMAGER", "BALANCE", 1),
        unit("Dotone", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 2),
        unit("Dottwo", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 4),
        unit("Frosty", "MAGE", "DAMAGER", "MAGE_CASTER", 4),
        unit("Backstab", "ROGUE", "DAMAGER", "ROGUE_DPS", 2),
        unit("Prayer", "PRIEST", "HEALER", "HOLY", 5),
    }

    local plan = T.BuildSmartOrganizePlan(context(players))
    local stats = statsForGroup(plan, 3)
    assertTrue(stats.elemental >= 1, "caster group should have elemental shaman")
    assertTrue(stats.boomkins >= 1, "caster group should have boomkin")
    assertTrue(stats.casterDps >= 3, "caster group should have at least three caster DPS")
end)

test("shadow priest prefers arcane mage mana group", function()
    local players = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Mindtap", "PRIEST", "DAMAGER", "SHADOW", 5),
        unit("Arcanist", "MAGE", "DAMAGER", "ARCANE", 2),
        unit("Heals", "PALADIN", "HEALER", "HOLY", 2),
        unit("Tree", "DRUID", "HEALER", "RESTORATION", 3),
        unit("Dotone", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3),
        unit("Stormbolt", "SHAMAN", "DAMAGER", "ELEMENTAL", 4),
        unit("Moonchef", "DRUID", "DAMAGER", "BALANCE", 4),
    }

    local plan = T.BuildSmartOrganizePlan(context(players))
    local stats = statsForGroup(plan, 4)
    assertTrue(stats.shadowPriests >= 1, "mana group should have shadow priest")
    assertTrue(stats.arcaneMages >= 1, "mana group should have arcane mage")
end)

test("prot paladin tank pulls ret support into threat group", function()
    local players = {
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 4, true),
        unit("Retadin", "PALADIN", "DAMAGER", "RETRIBUTION", 5),
        unit("Windfury", "SHAMAN", "DAMAGER", "ENHANCEMENT", 1),
        unit("Backstab", "ROGUE", "DAMAGER", "ROGUE_DPS", 2),
        unit("Prayer", "PRIEST", "HEALER", "HOLY", 5),
    }

    local plan = T.BuildSmartOrganizePlan(context(players))
    local stats = statsForGroup(plan, 1)
    assertTrue(stats.protPaladinTanks >= 1, "threat group should have prot paladin tank")
    assertTrue(stats.retPaladins >= 1, "threat group should have ret paladin support")
end)

test("already good caster group does not churn moves", function()
    local players = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Stormbolt", "SHAMAN", "DAMAGER", "ELEMENTAL", 3),
        unit("Moonchef", "DRUID", "DAMAGER", "BALANCE", 3),
        unit("Dotone", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3),
        unit("Dottwo", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3),
        unit("Frosty", "MAGE", "DAMAGER", "MAGE_CASTER", 3),
    }

    local plan = T.BuildSmartOrganizePlan(context(players))
    assertEquals(#plan.moves, 0, "good caster group should not be moved")
end)

test("uncertain DPS specs are prompted, tanks and healers are obvious", function()
    local players = {
        unit("Bearwall", "DRUID", "TANK", nil, 1, true),
        unit("Chainheal", "SHAMAN", "HEALER", nil, 5),
        unit("Maybeele", "SHAMAN", "DAMAGER", nil, 2),
        unit("Maybebird", "DRUID", "DAMAGER", nil, 2),
        unit("Maybearcane", "MAGE", "DAMAGER", nil, 2),
        unit("Maybehunter", "HUNTER", "DAMAGER", nil, 2),
    }

    local uncertain = T.GetUncertainOrganizerPlayers(context(players))
    assertEquals(#uncertain, 4, "only ambiguous DPS specs should be prompted")
end)

test("planning mode stages casters in group three even when elemental is missing", function()
    local planningContext = T.BuildOrganizerPlanningContext({ configuredSize = 25, sequence = 1 })
    assertTrue(planningContext.simulation, "planning context should be marked as a simulation")
    assertEquals(planningContext.rosterSize, 23, "first planning scenario should be a partial 23-player raid")
    assertEquals(planningContext.groupCount, 5, "25-player planning should keep groups 1-5 available")

    local plan = T.BuildSmartOrganizePlan(planningContext)
    local stats = statsForGroup(plan, 3)
    assertTrue(plan.simulation, "planning plan should be marked as a simulation")
    assertTrue(stats.casterDps >= 3, "caster group should still be populated before the missing elemental joins")
    assertTrue(stats.mages >= 2, "mages should be teed up in the caster group")
    assertEquals(stats.elemental, 0, "scenario intentionally has no elemental shaman")
    assertTrue(groupMissingIncludes(plan, 3, "Elemental Shaman"), "caster group should call out the missing elemental")
end)

test("planning mode respects 20-player raid sizes", function()
    local planningContext = T.BuildOrganizerPlanningContext({ configuredSize = 20, sequence = 1 })
    assertEquals(planningContext.configuredSize, 20, "configured size should stay at 20")
    assertEquals(planningContext.rosterSize, 20, "20-player planning scenario should fill to 20")
    assertEquals(planningContext.groupCount, 4, "20-player raids should use four groups")
end)

test("planning mode puts prot paladin threat with caster support", function()
    local planningContext = T.BuildOrganizerPlanningContext({ configuredSize = 25, sequence = 3 })
    local plan = T.BuildSmartOrganizePlan(planningContext)

    assertEquals(groupForPlayer(plan, "Ward"), 3, "prot paladin tank should move to caster support")
    assertEquals(groupForPlayer(plan, "Nova"), 4, "fire/frost mage should move to mana group")
    assertEquals(groupForPlayer(plan, "Bloom"), 5, "healer should move to healer overflow")
    assertEquals(groupForPlayer(plan, "Blade"), 1, "rogue should get Windfury in threat group")
    assertEquals(groupForPlayer(plan, "Totem"), 1, "enhancement shaman should support threat melee")
    assertEquals(groupForPlayer(plan, "Aura"), 1, "ret paladin should stay with the threat group")
end)

test("planning mode includes a shaman-heavy 25-player simulation", function()
    local planningContext = T.BuildOrganizerPlanningContext({ configuredSize = 25, sequence = 4 })
    local shamans = countMatching(planningContext.players, function(unit)
        return unit.class == "SHAMAN"
    end)
    local enhancement = countMatching(planningContext.players, function(unit)
        return unit.class == "SHAMAN" and unit.spec == "ENHANCEMENT"
    end)

    assertEquals(planningContext.rosterSize, 25, "shaman-heavy planning scenario should be a full raid")
    assertTrue(shamans >= 4, "planning mode should offer a scenario with at least four shamans")
    assertTrue(enhancement >= 2, "planning mode should offer a scenario with multiple enhancement shamans")
end)

test("smart advertiser respects configured tank and healer needs", function()
    local players = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Bearwall", "DRUID", "TANK", "FERAL_TANK", 1, true),
        unit("Prayer", "PRIEST", "HEALER", "HOLY", 5),
        unit("Lightwell", "PRIEST", "HEALER", "DISCIPLINE", 5),
        unit("Chainheal", "SHAMAN", "HEALER", "RESTORATION", 5),
        unit("Tree", "DRUID", "HEALER", "RESTORATION", 5),
        unit("Holyshield", "PALADIN", "HEALER", "HOLY", 5),
        unit("Cleanse", "PALADIN", "HEALER", "HOLY", 5),
        unit("Windfury", "SHAMAN", "DAMAGER", "ENHANCEMENT", 2),
        unit("Stormbolt", "SHAMAN", "DAMAGER", "ELEMENTAL", 3),
        unit("Moonchef", "DRUID", "DAMAGER", "BALANCE", 3),
        unit("Backstab", "ROGUE", "DAMAGER", "ROGUE_DPS", 2),
        unit("Frosty", "MAGE", "DAMAGER", "MAGE_CASTER", 3),
    }

    local needs = T.BuildSmartAdvertiserNeeds(context(players), { size = 25, tanks = 3, healers = 7 })
    assertTrue(listIncludes(needs.roleNeeds, "1 Tank"), "smart advertiser should keep asking for the configured third tank")
    assertTrue(listIncludes(needs.roleNeeds, "1 Healer"), "smart advertiser should keep asking for the configured seventh healer")
    assertTrue(needs.openSlots > needs.tanksNeeded + needs.healersNeeded, "remaining open slots should stay available for DPS")
end)

test("smart advertiser uses organizer scoring for balanced DPS suggestions", function()
    local players = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 1, true),
        unit("Bearwall", "DRUID", "TANK", "FERAL_TANK", 1, true),
        unit("Prayer", "PRIEST", "HEALER", "HOLY", 5),
        unit("Lightwell", "PRIEST", "HEALER", "DISCIPLINE", 5),
        unit("Chainheal", "SHAMAN", "HEALER", "RESTORATION", 5),
        unit("Tree", "DRUID", "HEALER", "RESTORATION", 5),
        unit("Holyshield", "PALADIN", "HEALER", "HOLY", 5),
        unit("Cleanse", "PALADIN", "HEALER", "HOLY", 5),
        unit("Renew", "PRIEST", "HEALER", "HOLY", 5),
        unit("Windfury", "SHAMAN", "DAMAGER", "ENHANCEMENT", 2),
        unit("Backstab", "ROGUE", "DAMAGER", "ROGUE_DPS", 2),
        unit("Shadowcut", "ROGUE", "DAMAGER", "ROGUE_DPS", 2),
        unit("Slammer", "WARRIOR", "DAMAGER", "WARRIOR_DPS", 2),
        unit("Retadin", "PALADIN", "DAMAGER", "RETRIBUTION", 2),
        unit("Catshift", "DRUID", "DAMAGER", "FERAL", 2),
        unit("Dotone", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3),
        unit("Frosty", "MAGE", "DAMAGER", "MAGE_CASTER", 3),
    }

    local needs = T.BuildSmartAdvertiserNeeds(context(players), { size = 25, tanks = 3, healers = 7 })
    assertTrue(listIncludes(needs.roleNeeds, "DPS"), "smart advertiser should ask for DPS once tank/healer targets are met")
    assertTrue(
        listIncludesAny(needs.specNeeds, { "Ele Shaman", "Boomkin", "Shadow Priest", "Warlock", "Mage", "Arcane Mage" }),
        "physical-heavy rosters should get caster-side smart suggestions"
    )
end)

test("smart advertiser writes human raid-lead messages", function()
    local context4 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 4,
    })
    local msg4 = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 6, hr = "DST", custom = "| gear check at Adal" }, context4)

    assertEquals(msg4, "LFM Gruul (DST HR) - need all | gear check at Adal", "early ads should lead with LFM, attach HR to the raid name, and put custom text last")

    local context9 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 9,
    })
    local msg9 = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 6 }, context9)

    assertEquals(msg9, "LFM Gruul 9/25 - need all", "early counted ads should stay broad")
    assertTrue(string.find(msg9, "Priest Healer", 1, true) == nil, "message should not expose internal candidate labels")
    assertTrue(string.find(msg9, " / ", 1, true) == nil, "message should not use machine-style slash-separated role blocks")
    assertTrue(#msg9 <= 255, "message should stay chat-safe")
end)

test("smart advertiser keeps broad role asks readable near full", function()
    local context20 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 20,
    })
    local msg20 = T.GenerateSmartAdvertiserMessageForContext("Serpentshrine Cavern", { size = 25, tanks = 3, healers = 7 }, context20)

    assertEquals(msg20, "LFM SSC 20/25 - need heals", "late ads should not list every healer subtype when any healer works")
    assertTrue(string.find(msg20, "6 heals", 1, true) == nil, "late fill ads should not ask for more roles than remaining slots")
    assertTrue(#msg20 <= 255, "late fill message should stay concise")
end)

test("smart advertiser flags caster priority when melee is frontloaded", function()
    local context9 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 9,
    })
    local msg9 = T.GenerateSmartAdvertiserMessageForContext("Magtheridon's Lair", { size = 25, tanks = 3, healers = 6 }, context9)

    assertEquals(msg9, "LFM Mag 9/25 - need all", "early ads should stay simple before the roster signal is strong")

    local context12 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 12,
    })
    local msg12 = T.GenerateSmartAdvertiserMessageForContext("Magtheridon's Lair", { size = 25, tanks = 3, healers = 6 }, context12)

    assertEquals(msg12, "LFM Mag 12/25 - need heals + caster dps", "melee-heavy partial raids should advertise caster DPS and healer needs together")

    local context18 = T.BuildOrganizerPlanningContext({
        configuredSize = 25,
        sequence = 2,
        rosterSize = 18,
    })
    local msg18 = T.GenerateSmartAdvertiserMessageForContext("Magtheridon's Lair", { size = 25, tanks = 3, healers = 6 }, context18)

    assertEquals(msg18, "LFM Mag 18/25 - need heals + DPS", "late-mid ads should name broad roles instead of falling back to need all")
end)

test("smart advertiser gets specific only when the slot is specific", function()
    local tankPlayers = {
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 1, true),
        unit("Bearwall", "DRUID", "TANK", "FERAL_TANK", 1, true),
    }
    addUnits(tankPlayers, 7, "Heal", "PRIEST", "HEALER", "HOLY", 5)
    addUnits(tankPlayers, 15, "Dps", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3)
    local tankMsg = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 7 }, context(tankPlayers))

    assertEquals(tankMsg, "LFM Gruul 24/25 - need prot warr", "one missing tank slot should name the missing tank type")

    local manyTankPlayers = {
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 1, true),
    }
    addUnits(manyTankPlayers, 7, "Heal", "PRIEST", "HEALER", "HOLY", 5)
    addUnits(manyTankPlayers, 14, "Dps", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3)
    local manyTankMsg = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 7 }, context(manyTankPlayers))

    assertEquals(manyTankMsg, "LFM Gruul 22/25 - need tanks", "multiple missing tanks should stay broad")
end)

test("smart advertiser can ask for melee or a specific caster", function()
    local meleePlayers = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 1, true),
        unit("Bearwall", "DRUID", "TANK", "FERAL_TANK", 1, true),
    }
    addUnits(meleePlayers, 7, "Heal", "PRIEST", "HEALER", "HOLY", 5)
    addUnits(meleePlayers, 13, "Caster", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3)
    local meleeMsg = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 7 }, context(meleePlayers))

    assertEquals(meleeMsg, "LFM Gruul 23/25 - need melee dps", "physical-light comps should ask for melee DPS")

    local magePlayers = {
        unit("Bulwark", "WARRIOR", "TANK", "PROTECTION", 1, true),
        unit("Tankadin", "PALADIN", "TANK", "PROTECTION", 1, true),
        unit("Bearwall", "DRUID", "TANK", "FERAL_TANK", 1, true),
    }
    addUnits(magePlayers, 7, "Heal", "PRIEST", "HEALER", "HOLY", 5)
    magePlayers[#magePlayers + 1] = unit("Stormbolt", "SHAMAN", "DAMAGER", "ELEMENTAL", 3)
    magePlayers[#magePlayers + 1] = unit("Moonchef", "DRUID", "DAMAGER", "BALANCE", 3)
    magePlayers[#magePlayers + 1] = unit("Mindtap", "PRIEST", "DAMAGER", "SHADOW", 3)
    magePlayers[#magePlayers + 1] = unit("Arcanist", "MAGE", "DAMAGER", "ARCANE", 3)
    addUnits(magePlayers, 3, "Lock", "WARLOCK", "DAMAGER", "WARLOCK_CASTER", 3)
    addUnits(magePlayers, 7, "Melee", "ROGUE", "DAMAGER", "ROGUE_DPS", 2)
    local mageMsg = T.GenerateSmartAdvertiserMessageForContext("Gruul's Lair", { size = 25, tanks = 3, healers = 7 }, context(magePlayers))

    assertEquals(mageMsg, "LFM Gruul 24/25 - need mage", "one caster slot should use the best specific class when clear")
end)

test("fill simulation logs ads and finishes with a scored comp", function()
    local state = T.BuildSmartAdvertiserFillState({
        bossName = "Serpentshrine Cavern",
        configuredSize = 25,
        sequence = 2,
        speed = 8,
        startSize = 4,
    })

    assertEquals(state.speed, 8, "requested fill sim speed should be kept")
    assertEquals(state.currentSize, 4, "fill sim should start at the requested partial roster size")
    assertEquals(state.targetSize, 25, "fill sim should target a full 25-player raid")
    assertTrue(logIncludes(state.log, "SSC") or logIncludes(state.log, "Serpentshrine Cavern"), "initial fill sim log should include an ad")

    local guard = 0
    while not state.complete and guard < 30 do
        T.AdvanceSmartAdvertiserFillState(state)
        guard = guard + 1
    end

    local plan = T.BuildSmartAdvertiserFillPlan(state)
    assertTrue(state.complete, "fill sim should complete")
    assertEquals(plan.rosterSize, 25, "final fill sim plan should contain the full raid")
    assertTrue(plan.score ~= nil, "final fill sim plan should have a Smart Organize score")
    assertTrue(logIncludes(plan.fillLog, "Join:"), "fill sim should log joins")
    assertTrue(logIncludes(plan.fillLog, "heals + caster dps"), "fill sim should steer healer and caster DPS needs together when the sample fill is melee-heavy")
    assertTrue(logIncludes(plan.fillLog, "Final score"), "fill sim should log the final score")
end)

test("fill simulation can surface tank shortages from partial scenarios", function()
    local state = T.BuildSmartAdvertiserFillState({
        bossName = "Magtheridon's Lair",
        configuredSize = 25,
        sequence = 3,
        speed = 8,
        startSize = 16,
    })

    assertEquals(state.scenario.name, "20/25 partial raid", "fill sim should be able to use partial planning scenarios")
    assertEquals(state.targetSize, 25, "partial fill scenarios should be topped up to the raid target size")

    T.AdvanceSmartAdvertiserFillState(state)

    assertTrue(logIncludes(state.log, "need tank"), "fill sim should show tank shortages when tanks are not front-loaded")
end)

test("fill simulation normalizes speed to 2x 4x or 8x", function()
    local slow = T.BuildSmartAdvertiserFillState({ bossName = "Serpentshrine Cavern", configuredSize = 25, speed = 1 })
    local medium = T.BuildSmartAdvertiserFillState({ bossName = "Serpentshrine Cavern", configuredSize = 25, speed = 5 })
    local fast = T.BuildSmartAdvertiserFillState({ bossName = "Serpentshrine Cavern", configuredSize = 25, speed = 99 })

    assertEquals(slow.speed, 2, "low speed values should normalize to 2x")
    assertEquals(medium.speed, 4, "middle speed values should normalize to 4x")
    assertEquals(fast.speed, 8, "high speed values should normalize to 8x")
    assertTrue(fast.delay < medium.delay and medium.delay < slow.delay, "faster fill speeds should use shorter delays")
end)

local failures = 0
for _, entry in ipairs(tests) do
    local ok, err = pcall(entry.fn)
    if ok then
        print("ok - " .. entry.name)
    else
        failures = failures + 1
        print("not ok - " .. entry.name)
        print(err)
    end
end

if failures > 0 then
    error(tostring(failures) .. " test(s) failed")
end

print("All " .. tostring(#tests) .. " tests passed.")
