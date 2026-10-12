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
                level = db.QueryQuestSingle(id, "questLevel"), start = start, finish = finish}
            local minimum = db.QueryQuestSingle(id, "requiredLevel") or 1
            local maximum = db.QueryQuestSingle(id, "requiredMaxLevel")
            local levelOK = UnitLevel("player") >= minimum
                and (not maximum or maximum == 0 or UnitLevel("player") <= maximum)
            local available = log[id] or (levelOK and db.IsDoable(id) and "A" or "X")
            local reward, retention
            local raw = xp.db[id]
            if raw and raw[1] > 0 and raw[2] > 0 then
                reward = xp:GetQuestLogRewardXP(id)
                -- Level-only reduction, excluding aura bonuses and XP rounding.
                retention = math.max(0.1, math.min(1, (2 * (raw[1] - UnitLevel("player")) + 20) / 10))
            end
            states[id] = {status = available, xp = reward, retention = retention}
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
            if count >= 300 then break end
        end
    end
    return {catalog = catalog, quests = states, mapID = mapID,
        level = UnitLevel("player"), xpMax = UnitXPMax("player"), count = count}
end
