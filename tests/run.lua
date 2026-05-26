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
