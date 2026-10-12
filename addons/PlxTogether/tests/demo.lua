local HT = {queue = {"real-message"}, peers = {}}
assert(loadfile("addon/PlxTogether/Planner.lua"))("PlxTogether", HT)
assert(loadfile("addon/PlxTogether/Demo.lua"))("PlxTogether", HT)
local clock, scans = 100, 0
GetTime = function() return clock end
HT.Scan = function() scans = scans + 1 end
HT.Demo.Start()
assert(HT.demo and #HT.demo.members == 3 and #HT.ranked == 3, "Demo works without Questie or party APIs")
assert(#HT.queue == 0 and not HT.nextSnapshot, "Entering demo cancels live transmissions")
assert(#HT.stops[1].tasks == 2, "Combine nearby pickups into one clear hub")
assert(HT.ranked[#HT.ranked].quest.id == 9000003, "Penalized old quest ranks behind shared full-XP quests")
HT.Demo.Next()
assert(HT.demo.members[1].quests[9000001].status == "L", "Demo advances pickups")
assert(HT.demo.members[2].quests[9000001].doneMask == 1, "Pickup does not reset an ahead member's progress")
clock = 10000
HT.Demo.Rebuild()
assert(not HT.waiting, "Demo stays fresh without real snapshots")
local steps = 0
while #HT.stops > 0 and steps < 50 do HT.Demo.Next(); steps = steps + 1 end
assert(steps < 50 and #HT.ranked == 0, "Demo reaches completion without route loops")
HT.Demo.Next()
HT.Demo.Start()
assert(HT.demo.steps == 0 and #HT.stops > 0, "Demo reset restores the initial scenario")
HT.Demo.Stop()
assert(not HT.demo and #HT.stops == 0 and scans == 1, "Exit clears simulated data and resumes live scanning")
print("Solo demo lifecycle tests passed.")
