local HT = {}
assert(loadfile("addon/PlxTogether/Planner.lua"))("PlxTogether", HT)
local catalog = {
    [1] = {id = 1, name = "Shared", start = {mapID = 1, x = 0.2, y = 0.2}},
    [2] = {id = 2, name = "Unequal", start = {mapID = 1, x = 0.9, y = 0.9}},
    [3] = {id = 3, name = "Locked"},
    [4] = {id = 4, name = "Unknown XP"},
}
local a = {name = "A", ready = true, time = 100, xpMax = 1000, quests = {
    [1] = {status = "A", xp = 100}, [2] = {status = "A", xp = 200},
    [3] = {status = "A", xp = 200}, [4] = {status = "A"}}}
local b = {name = "B", ready = true, time = 100, xpMax = 1000, quests = {
    [1] = {status = "L", xp = 100}, [2] = {status = "A", xp = 10},
    [3] = {status = "X", xp = 200}, [4] = {status = "A", xp = 100}}}
local ranked = HT.Planner.Rank(catalog, {a, b}, 100)
assert(#ranked == 2 and ranked[1].quest.id == 1, "Fair shared route must beat uneven reward")
assert(#HT.Planner.Rank(catalog, {a, b}, 191) == 0, "Stale party data must block recommendations")
b.ready = false
assert(#HT.Planner.Rank(catalog, {a, b}, 100) == 0, "Missing member must block recommendations")
b.ready = true
local stops = HT.Planner.Stops(ranked, 1, 0.1, 0.1)
assert(#stops == 2 and stops[1].quest.id == 1, "Nearest pickup should come first")
assert(#HT.Planner.Stops(ranked, 2, 0, 0) == 0, "Never mix map coordinates")
a.quests[1].status, b.quests[1].status = "L", "L"
ranked = HT.Planner.Rank(catalog, {a, b}, 100)
stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#stops == 1, "Do not route an unfinished quest to its turn-in")
a.quests[1].status, b.quests[1].status = "T", "T"
catalog[1].finish = {mapID = 1, x = 0.3, y = 0.3}
ranked = HT.Planner.Rank(catalog, {a, b}, 100)
stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(stops[1].action == "Turn in", "Ready party should receive a turn-in stop")
print("Planner tests passed: fairness, eligibility, unknown XP, freshness, maps, pickup and turn-in.")
