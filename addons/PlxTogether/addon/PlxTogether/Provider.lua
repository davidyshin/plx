local _, HT = ...
HT.Provider = {}
local function objectiveKey(objectives)
    local hash = 7
    for index, objective in ipairs(objectives or {}) do
        local signature = index .. ":" .. tostring(objective.Type) .. ":" .. tostring(objective.Id)
            .. ":" .. tostring(objective.RootId) .. ":" .. table.concat(objective.IdList or {}, ",")
        for i = 1, #signature do hash = (hash * 33 + signature:byte(i)) % 2147483647 end
    end
    return hash
end
local function module(name)
    if not QuestieLoader then return end
    local ok, value = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
    if ok then return value end
end

function HT.Provider.Scan(mapID)
    local db, zones, xp = module("QuestieDB"), module("ZoneDB"), module("QuestXP")
    local cache = module("QuestLogCache")
    local compat = module("QuestieCompat")
    if not db or not zones or not xp or not xp.db or not db.QuestPointers then
        return nil, "Install a current Forever-compatible Questie and wait for it to finish loading."
    end
    local function coordinates(spawns, points)
        points = points or {}
        if type(spawns) ~= "table" or #points >= 12 then return points end
        local areas = {}
        for area in pairs(spawns or {}) do areas[#areas + 1] = area end
        table.sort(areas)
        for _, area in ipairs(areas) do
            if zones:GetUiMapIdByAreaId(area) == mapID then
                for _, coord in ipairs(spawns[area]) do
                    if type(coord[1]) == "number" and type(coord[2]) == "number"
                        and coord[1] >= 0 and coord[1] <= 100 and coord[2] >= 0 and coord[2] <= 100 then
                        points[#points + 1] = {mapID = mapID, x = coord[1] / 100, y = coord[2] / 100}
                        if #points >= 12 then return points end
                    end
                end
            end
        end
        return points
    end
    local function entityPoints(kind, id, points)
        if kind == "monster" or kind == "killcredit" then
            coordinates(db.QueryNPCSingle(id, "spawns"), points)
        elseif kind == "object" then
            coordinates(db.QueryObjectSingle(id, "spawns"), points)
        elseif kind == "item" then
            for _, npc in ipairs(db.QueryItemSingle(id, "npcDrops") or {}) do
                coordinates(db.QueryNPCSingle(npc, "spawns"), points)
                if #points >= 12 then break end
            end
            for _, object in ipairs(db.QueryItemSingle(id, "objectDrops") or {}) do
                if #points >= 12 then break end
                coordinates(db.QueryObjectSingle(object, "spawns"), points)
            end
        end
    end
    local function point(givers)
        if not givers then return end
        for kind = 1, 2 do
            for _, entityID in ipairs(givers[kind] or {}) do
                local spawns
                if kind == 1 then spawns = db.QueryNPCSingle(entityID, "spawns")
                else spawns = db.QueryObjectSingle(entityID, "spawns") end
                for area, coords in pairs(spawns or {}) do
                    if zones:GetUiMapIdByAreaId(area) == mapID then
                        for _, coord in ipairs(coords) do
                            if coord[1] and coord[2] and coord[1] >= 0 and coord[1] <= 100
                                and coord[2] >= 0 and coord[2] <= 100 then
                                return {mapID = mapID, x = coord[1] / 100, y = coord[2] / 100}
                            end
                        end
                    end
                end
            end
        end
    end
    local catalog, states, count = {}, {}, 0
    local log = {}
    if C_QuestLog and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and info.questID and not info.isHeader then
                log[info.questID] = (info.isComplete == true or info.isComplete == 1) and "T" or "L"
            end
        end
    else
        for i = 1, GetNumQuestLogEntries() do
            local _, _, _, header, _, complete, _, id = GetQuestLogTitle(i)
            if id and not header then log[id] = complete == 1 and "T" or "L" end
        end
    end
    -- Sorted, bounded selection gives every client the same candidate window.
    local ids = {}
    for id in pairs(db.QuestPointers) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local area = db.QueryQuestSingle(id, "zoneOrSort")
        if area and area > 0 and zones:GetUiMapIdByAreaId(area) == mapID then
            local start = point(db.QueryQuestSingle(id, "startedBy"))
            local finish = point(db.QueryQuestSingle(id, "finishedBy"))
            catalog[id] = {id = id, name = db.QueryQuestSingle(id, "name") or tostring(id),
                level = db.QueryQuestSingle(id, "questLevel"), start = start, finish = finish,
                requiredLevel = db.QueryQuestSingle(id, "requiredLevel") or 1,
                requiredMaxLevel = db.QueryQuestSingle(id, "requiredMaxLevel"),
                preQuestGroup = db.QueryQuestSingle(id, "preQuestGroup"),
                preQuestSingle = db.QueryQuestSingle(id, "preQuestSingle")}
            local minimum = db.QueryQuestSingle(id, "requiredLevel") or 1
            local maximum = db.QueryQuestSingle(id, "requiredMaxLevel")
            local levelOK = UnitLevel("player") >= minimum
                and (not maximum or maximum == 0 or UnitLevel("player") <= maximum)
            local completed = false
            if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
                local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
                completed = ok and result == true
            end
            if not completed and compat and compat.IsQuestFlaggedCompleted then
                local ok, result = pcall(compat.IsQuestFlaggedCompleted, id)
                completed = ok and result == true
            end
            local doable = not completed and db.IsDoable(id)
            local available = log[id] or (completed and "C" or (doable and (levelOK and "A" or "V") or "X"))
            if available == "X" and not levelOK and minimum - UnitLevel("player") <= 2
                and db.IsDoableVerbose and db.DoableStates then
                local ok, _, _, reason = pcall(db.IsDoableVerbose, id, false, true, true)
                if ok and reason == db.DoableStates.LEVEL_TOO_LOW then available = "V" end
            end
            local reward, retention
            local raw = xp.db[id]
            if raw and raw[1] > 0 and raw[2] > 0 then
                reward = xp:GetQuestLogRewardXP(id)
                -- Level-only reduction, excluding aura bonuses and XP rounding.
                retention = math.max(0.1, math.min(1, (2 * (raw[1] - UnitLevel("player")) + 20) / 10))
            end
            states[id] = {status = available, xp = reward, retention = retention}
            if (not reward or reward <= 0) and raw and raw[2] and raw[2] > 0 then
                states[id].xp = math.floor(raw[2] * (retention or 1))
            end
            if log[id] then
                local quest = db.GetQuest(id)
                local key = objectiveKey(quest and quest.ObjectiveData)
                catalog[id].objectiveKey, states[id].objectiveKey = key, key
                local snapshot = cache and cache.TryGetQuest and cache.TryGetQuest(id)
                if snapshot and snapshot.objectives then
                    local mask, objectiveCount = 0, 0
                    for index, objective in ipairs(snapshot.objectives) do
                        if index > 32 then break end
                        objectiveCount = index
                        if objective.finished == true then mask = mask + 2^(index - 1) end
                    end
                    states[id].doneMask, states[id].objectiveCount = mask, objectiveCount
                end
                catalog[id].objectives = {}
                local sequenced = compat and compat.IsQuestSequenced and compat.IsQuestSequenced(id)
                for index, objective in ipairs(not sequenced and quest and quest.ObjectiveData or {}) do
                    if index > 32 then break end
                    local points = {}
                    local live = quest.Objectives and quest.Objectives[index]
                    for _, spawn in ipairs(live and live.spawnList or {}) do
                        coordinates(spawn.Spawns, points)
                        if #points >= 12 then break end
                    end
                    if #points == 0 then
                        if objective.Id then entityPoints(objective.Type, objective.Id, points) end
                        if objective.Type == "killcredit" then
                            for _, npc in ipairs(objective.IdList or {}) do
                                entityPoints("monster", npc, points)
                                if #points >= 12 then break end
                            end
                        end
                    end
                    if #points > 0 then
                        catalog[id].objectives[#catalog[id].objectives + 1] = {
                            index = index, text = (live and live.Description) or objective.Text or "Quest objective",
                            points = points}
                    end
                end
            end
            count = count + 1
            if count >= 270 then break end
        end
    end
    -- Include nearby chain prerequisites even when they belong to another zone.
    -- Their status is needed for an honest short-chain suggestion, never a live stop.
    local queue, seen = {}, {}
    local zoneIDs = {}
    for id in pairs(catalog) do zoneIDs[#zoneIDs + 1] = id end
    table.sort(zoneIDs)
    for _, id in ipairs(zoneIDs) do
        local quest = catalog[id]
        if not quest.prerequisiteOnly then
            for _, prereq in ipairs(quest.preQuestGroup or {}) do queue[#queue + 1] = {prereq, 1} end
            for _, prereq in ipairs(quest.preQuestSingle or {}) do queue[#queue + 1] = {prereq, 1} end
        end
    end
    local head = 1
    while head <= #queue and count < 300 do
        local id, depth = queue[head][1], queue[head][2]
        head = head + 1
        if type(id) == "number" and id > 0 and not seen[id] then
            seen[id] = true
            if not catalog[id] and db.QuestPointers[id] then
                local group = db.QueryQuestSingle(id, "preQuestGroup")
                local single = db.QueryQuestSingle(id, "preQuestSingle")
                catalog[id] = {id = id, name = db.QueryQuestSingle(id, "name") or tostring(id),
                    prerequisiteOnly = true, requiredLevel = db.QueryQuestSingle(id, "requiredLevel") or 1,
                    preQuestGroup = group, preQuestSingle = single}
                local completed = false
                if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
                    local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
                    completed = ok and result == true
                end
                if not completed and compat and compat.IsQuestFlaggedCompleted then
                    local ok, result = pcall(compat.IsQuestFlaggedCompleted, id)
                    completed = ok and result == true
                end
                states[id] = {status = log[id] or (completed and "C" or "X")}
                count = count + 1
                if depth < 2 then
                    for _, prereq in ipairs(group or {}) do queue[#queue + 1] = {prereq, depth + 1} end
                    for _, prereq in ipairs(single or {}) do queue[#queue + 1] = {prereq, depth + 1} end
                end
            end
        end
    end
    return {catalog = catalog, quests = states, mapID = mapID,
        level = UnitLevel("player"), xpMax = UnitXPMax("player"), count = count}
end
