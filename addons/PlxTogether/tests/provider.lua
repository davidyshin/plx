local HT = {}
local data = {
    [1] = {name = "Hunt", zoneOrSort = 10, requiredLevel = 10, questLevel = 12,
        startedBy = {{100}}, finishedBy = {{100}}},
    [2] = {name = "Too high", zoneOrSort = 10, requiredLevel = 20, questLevel = 20},
    [3] = {name = "Unknown XP", zoneOrSort = 10, requiredLevel = 1, questLevel = 12},
}
local db = {QuestPointers = {[1] = true, [2] = true, [3] = true}}
db.QueryQuestSingle = function(id, field) return data[id][field] end
db.QueryNPCSingle = function(id, field) if field == "spawns" then return {[10] = {{20, 30}, {40, 50}}} end end
db.QueryObjectSingle = function() return nil end
db.QueryItemSingle = function() return nil end
db.IsDoable = function() return true end
db.GetQuest = function() return {ObjectiveData = {{Type = "monster", Id = 100, Text = "Wolves"}}, Objectives = {}} end
local xp = {db = {[1] = {12, 1000}, [2] = {20, 2000}}}
function xp:GetQuestLogRewardXP() return 1000 end
local modules = {QuestieDB = db, ZoneDB = {GetUiMapIdByAreaId = function(_, area) return area == 10 and 1 or 2 end},
    QuestXP = xp, QuestLogCache = {TryGetQuest = function() return {objectives = {{finished = false, numFulfilled = 1, numRequired = 1}}} end}}
QuestieLoader = {ImportModule = function(_, key) return modules[key] end}
UnitLevel = function() return 15 end
UnitXPMax = function() return 10000 end
C_QuestLog = {GetNumQuestLogEntries = function() return 1 end,
    GetInfo = function() return {questID = 1, isComplete = 0} end}
assert(loadfile("addon/PlxTogether/Provider.lua"))("PlxTogether", HT)
local snapshot = HT.Provider.Scan(1)
assert(snapshot.count == 3 and snapshot.quests[1].status == "L", "Numeric zero is not complete")
assert(snapshot.quests[2].status == "X", "Minimum level must be enforced")
assert(snapshot.quests[3].xp == nil, "Missing XP must remain unknown")
assert(snapshot.quests[1].doneMask == 0, "Forever 1/1 with false finished flag is unfinished")
assert(#snapshot.catalog[1].objectives[1].points == 2, "Read objective spawn alternatives")
print("Questie provider fixture tests passed.")
