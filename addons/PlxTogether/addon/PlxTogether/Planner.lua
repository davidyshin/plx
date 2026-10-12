local _, HT = ...
HT.Planner = {}

function HT.Planner.Rank(catalog, members, now)
    local ranked = {}
    if #members == 0 then return ranked, "No party data." end
    for _, member in ipairs(members) do
        if not member.ready or not member.time or now - member.time > 90 then
            return {}, "Waiting for fresh data from " .. member.name
        end
    end
    for id, quest in pairs(catalog) do
        local eligible, minimum, total, details = true, math.huge, 0, {}
        for _, member in ipairs(members) do
            local state = member.quests[id]
            if not state or state.status == "X" or not state.xp or state.xp <= 0 then
                eligible = false
                break
            end
            local benefit = state.xp / math.max(1, member.xpMax)
            minimum = math.min(minimum, benefit)
            total = total + benefit
            details[#details + 1] = {name = member.name, xp = state.xp,
                retention = state.retention, status = state.status,
                doneMask = state.doneMask, objectiveCount = state.objectiveCount, objectiveKey = state.objectiveKey}
        end
        if eligible then
            ranked[#ranked + 1] = {quest = quest, details = details,
                score = minimum * 0.75 + total / #members * 0.25}
        end
    end
    table.sort(ranked, function(a, b)
        if a.score == b.score then return a.quest.id < b.quest.id end
        return a.score > b.score
    end)
    return ranked
end

local function valid(point, mapID)
    return type(point) == "table" and point.mapID == mapID
        and type(point.x) == "number" and type(point.y) == "number"
        and point.x >= 0 and point.x <= 1 and point.y >= 0 and point.y <= 1
end
function HT.Planner.Stops(ranked, mapID, x, y)
    local pending, stops, notes = {}, {}, {}
    local function add(row, action, text, points, neededBy, index)
        local candidates = {}
        for _, point in ipairs(points or {}) do
            if valid(point, mapID) then candidates[#candidates + 1] = point end
        end
        if #candidates == 0 then
            notes[#notes + 1] = action .. ": " .. row.quest.name .. " — no location in this zone"
        else
            pending[#pending + 1] = {quest = row.quest, points = candidates,
                action = action, text = text, neededBy = neededBy, objectiveIndex = index}
        end
    end
    for i = 1, math.min(8, #ranked) do
        local row, pickup, allReady = ranked[i], {}, true
        for _, detail in ipairs(row.details) do
            if detail.status == "A" then pickup[#pickup + 1] = detail.name end
            if detail.status ~= "T" then allReady = false end
        end
        if #pickup > 0 then
            add(row, "Pick up", nil, row.quest.start and {row.quest.start}, pickup)
        elseif allReady then
            local names = {}
            for _, detail in ipairs(row.details) do names[#names + 1] = detail.name end
            add(row, "Turn in", nil, row.quest.finish and {row.quest.finish}, names)
        else
            local count = 0
            for _, objective in ipairs(row.quest.objectives or {}) do
                local neededBy = {}
                for _, detail in ipairs(row.details) do
                    if detail.status == "L" then
                        local known = detail.doneMask ~= nil and detail.objectiveKey ~= nil
                            and detail.objectiveKey == row.quest.objectiveKey
                            and objective.index <= (detail.objectiveCount or 0)
                        local done = known and math.floor(detail.doneMask / 2^(objective.index - 1)) % 2 == 1
                        if not done then neededBy[#neededBy + 1] = detail.name end
                    end
                end
                if #neededBy > 0 then
                    add(row, "Objective", objective.text, objective.points, neededBy, objective.index)
                    count = count + 1
                end
            end
            if count == 0 then
                notes[#notes + 1] = row.quest.name .. " — check your quest log for the next objective"
            end
        end
    end
    x, y = x or 0.5, y or 0.5
    while #pending > 0 and #stops < 24 do
        local best, point, distance = nil, nil, math.huge
        for i, task in ipairs(pending) do
            for _, candidate in ipairs(task.points) do
                local d = (candidate.x - x)^2 + (candidate.y - y)^2
                if d < distance then best, point, distance = i, candidate, d end
            end
        end
        if not best then break end
        local task = table.remove(pending, best)
        task.point = point
        local previous = stops[#stops]
        -- One numbered stop for nearby tasks, avoiding stacked duplicate pins.
        if previous and (previous.point.x - point.x)^2 + (previous.point.y - point.y)^2 <= 0.000144 then
            previous.tasks[#previous.tasks + 1] = task
        else
            stops[#stops + 1] = {point = point, tasks = {task}, action = task.action,
                quest = task.quest, text = task.text, objectiveIndex = task.objectiveIndex}
        end
        x, y = point.x, point.y
    end
    if #pending > 0 then notes[#notes + 1] = "More stops will appear as this route progresses." end
    return stops, notes
end
function HT.Planner.Title(stop)
    if #stop.tasks > 1 then return "Shared stop · " .. #stop.tasks .. " tasks" end
    local task = stop.tasks[1]
    return (task.action == "Objective" and "Complete" or task.action) .. ": " .. task.quest.name
end
