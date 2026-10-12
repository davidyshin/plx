local HT = {}
assert(loadfile("addon/PlxTogether/Planner.lua"))("PlxTogether", HT)
local quest = {id = 1, objectiveKey = 77, name = "Hunt", start = {mapID = 1, x = 0.1, y = 0.1},
    finish = {mapID = 1, x = 0.9, y = 0.9}, objectives = {
    {index = 1, text = "Wolves", points = {{mapID = 1, x = 0.8, y = 0.8}, {mapID = 1, x = 0.2, y = 0.2}}},
    {index = 2, text = "Boars", points = {{mapID = 1, x = 0.4, y = 0.4}}},
}}
local a = {name = "A", objectiveKey = 77, status = "L", doneMask = 1, objectiveCount = 2}
local b = {name = "B", objectiveKey = 77, status = "L", doneMask = 0, objectiveCount = 2}
local ranked = {{quest = quest, details = {a, b}}}
local stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#stops == 2 and stops[1].text == "Wolves" and stops[1].point.x == 0.2,
    "Keep objectives needed by a peer, selecting the nearest spawn")
b.doneMask = 1
stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#stops == 1 and stops[1].text == "Boars", "Skip objectives completed by all members")
b.objectiveKey = 88
assert(#HT.Planner.Stops(ranked, 1, 0, 0) == 2, "Mismatched database mappings must not suppress objectives")
b.objectiveKey = 77
b.doneMask = nil
assert(#HT.Planner.Stops(ranked, 1, 0, 0) == 2, "Unknown progress must not suppress an objective")
b.status = "A"
stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#stops == 1 and stops[1].action == "Pick up", "Pickup precedes objectives")
a.status, b.status = "T", "T"
stops = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#stops == 1 and stops[1].action == "Turn in", "Ready quests precede turn-in")
quest.finish.mapID = 2
assert(#HT.Planner.Stops(ranked, 1, 0, 0) == 0, "Never plot a finisher on the wrong map")
local missing, notes = HT.Planner.Stops(ranked, 1, 0, 0)
assert(#missing == 0 and #notes == 1, "Explain off-zone locations instead of silently hiding them")
quest.finish = {mapID = 1, x = -1, y = 2}
assert(#HT.Planner.Stops(ranked, 1, 0, 0) == 0, "Reject invalid map coordinates")
quest.finish = {mapID = 1, x = 0.3, y = 0.3}
a.status, b.status = "A", "L"
local sameHub = {{quest = quest, details = {a, b}}, {quest = {id = 2, name = "Other",
    start = {mapID = 1, x = 0.105, y = 0.105}}, details = {a, b}}}
local hubs = HT.Planner.Stops(sameHub, 1, 0, 0)
assert(#hubs == 1 and #hubs[1].tasks == 2, "One marker should cover nearby pickups")
assert(#hubs[1].tasks[1].neededBy == 1 and hubs[1].tasks[1].neededBy[1] == "A", "Name only members who need a pickup")
assert(quest.start.x == 0.1, "Routing must not mutate the provider's coordinates")
print("Objective routing tests passed.")
