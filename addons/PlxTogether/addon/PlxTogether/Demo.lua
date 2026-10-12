local _, HT = ...
HT.Demo = {}
local function point(x, y) return {mapID = 1413, x = x, y = y} end
function HT.Demo.Start()
    HT.guideShown = false
    local catalog = {
        [9000001] = {id = 9000001, name = "Crossroads supply run", start = point(0.28, 0.3), finish = point(0.28, 0.3),
            objectives = {{index = 1, text = "Gather supplies from the camp", points = {point(0.43, 0.4), point(0.75, 0.8)}},
                {index = 2, text = "Recover the missing crate", points = {point(0.55, 0.5)}}}},
        [9000002] = {id = 9000002, name = "A shared hunt", start = point(0.285, 0.305), finish = point(0.28, 0.3),
            objectives = {{index = 1, text = "Clear the hunting grounds", points = {point(0.47, 0.55), point(0.8, 0.2)}}}},
        [9000003] = {id = 9000003, name = "An old errand", start = point(0.82, 0.78), finish = point(0.82, 0.78),
            objectives = {{index = 1, text = "Collect the abandoned parcel", points = {point(0.87, 0.7)}}}},
    }
    local members = {}
    for i, info in ipairs({{"You (demo)", 12, 9000}, {"Mira", 15, 13000}, {"Throk", 17, 17000}}) do
        local quests = {}
        for id in pairs(catalog) do
            local old = id == 9000003
            local retention = old and ({0.8, 0.2, 0.1})[i] or 1
            quests[id] = {status = "A", xp = math.floor((old and 450 or 950) * retention),
                retention = retention, doneMask = 0, objectiveCount = id == 9000001 and 2 or 1, objectiveKey = id}
            catalog[id].objectiveKey = id
        end
        if i == 2 then quests[9000001].status, quests[9000001].doneMask = "L", 1 end
        members[i] = {name = info[1], level = info[2], xpMax = info[3], quests = quests,
            mapID = 1413, ready = true, time = GetTime(), count = 3}
    end
    HT.demo = {members = members, x = 0.18, y = 0.2, steps = 0}
    HT.queue, HT.nextSnapshot, HT.error, HT.waiting = {}, nil, nil, nil
    HT.catalog, HT.me, HT.routeKey = catalog, members[1], nil
    HT.Demo.Rebuild()
    if HT.ShowWindow then HT.ShowWindow() end
end
function HT.Demo.Rebuild()
    if not HT.demo then return end
    local now = GetTime()
    for _, member in ipairs(HT.demo.members) do member.time = now end
    HT.ranked, HT.waiting = HT.Planner.Rank(HT.catalog, HT.demo.members, now)
    HT.stops, HT.notes = HT.Planner.Stops(HT.ranked, 1413, HT.demo.x, HT.demo.y)
end
function HT.Demo.Next()
    if not HT.demo then return end
    local stop = HT.stops[1]
    if not stop then return end
    for _, task in ipairs(stop.tasks) do
        for _, member in ipairs(HT.demo.members) do
            local state = member.quests[task.quest.id]
            if task.action == "Pick up" and state.status == "A" then state.status = "L"
            elseif task.action == "Turn in" and state.status == "T" then state.status = "X"
            elseif task.action == "Objective" and state.status == "L" then
                local bit = 2^(task.objectiveIndex - 1)
                if math.floor(state.doneMask / bit) % 2 == 0 then state.doneMask = state.doneMask + bit end
                if state.doneMask == 2^state.objectiveCount - 1 then state.status = "T" end
            end
        end
    end
    HT.demo.x, HT.demo.y = stop.point.x, stop.point.y
    HT.demo.steps = HT.demo.steps + 1
    HT.Demo.Rebuild()
    if HT.ResetScroll then HT.ResetScroll() end
end
function HT.Demo.Stop()
    HT.demo, HT.me, HT.routeKey, HT.waiting, HT.error = nil, nil, nil, nil, nil
    HT.peers, HT.pending, HT.queue, HT.catalog, HT.stops, HT.notes, HT.ranked = {}, {}, {}, {}, {}, {}, {}
    HT.nextSnapshot = nil
    if HT.ResetScroll then HT.ResetScroll() end
    HT.Scan()
end
