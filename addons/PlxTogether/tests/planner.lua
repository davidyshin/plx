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

local futureCatalog = {
 [10]={id=10,name="Small shared",start={mapID=1,x=0.1,y=0.1}},
 [11]={id=11,name="Better shared",start={mapID=1,x=0.3,y=0.3},requiredLevel=17,preQuestGroup={12}},
 [12]={id=12,name="Missing chain step",prerequisiteOnly=true}
}
local first={name="First",ready=true,time=100,level=17,xpMax=1000,quests={
 [10]={status="A",xp=100},[11]={status="A",xp=500},[12]={status="C"}}}
local second={name="Second",ready=true,time=100,level=16,xpMax=1000,quests={
 [10]={status="A",xp=100},[11]={status="X",xp=500},[12]={status="L"}}}
local look=HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))
assert(#look==1 and look[1].quest.id==11 and look[1].needs[1].levels==1)
assert(look[1].needs[1].steps[1].name=="Missing chain step")
second.quests[12].status="C"; second.quests[11].status="V"
look=HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))
assert(#look==1 and #look[1].needs[1].steps==0 and look[1].needs[1].levels==1)
second.level=14; assert(#HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))==0)
second.level=17; second.quests[11].status="C"
assert(#HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))==0)
print("Short chain and level-gap lookahead tests passed.")

futureCatalog[11].preQuestGroup={12,13}
futureCatalog[13]={id=13,name="Earlier link",prerequisiteOnly=true}
second.level=16; second.quests[11]={status="X",xp=500}; second.quests[12]={status="C"}; second.quests[13]={status="L"}
look=HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))
assert(#look==1 and look[1].needs[1].steps[1].name=="Earlier link")
futureCatalog[11].preQuestGroup={12,13,14}
futureCatalog[14]={id=14,name="Too much preparation",prerequisiteOnly=true}
second.quests[14]={status="L"}; second.quests[12]={status="L"}
assert(#HT.Planner.LookAhead(futureCatalog,{first,second},HT.Planner.Rank(futureCatalog,{first,second},100))==0,
    "More than two missing chain quests must not be suggested as a short gap")
print("Multiple prerequisite and short-gap limit tests passed.")

futureCatalog[11].preQuestGroup={12}
futureCatalog[12].prerequisiteOnly=nil
futureCatalog[12].start={mapID=1,x=0.12,y=0.12}
second.quests[12]={status="A",xp=80}
second.quests[11]={status="X",xp=500}; second.level=16
local rankedNow=HT.Planner.Rank(futureCatalog,{first,second},100)
look=HT.Planner.LookAhead(futureCatalog,{first,second},rankedNow)
local prep=HT.Planner.Preparation(look[1],futureCatalog,{first,second},1,0,0,rankedNow)
assert(#prep==1 and prep[1].preparation and prep[1].tasks[1].neededBy[1]=="Second")
assert(prep[1].action=="Pick up" and prep[1].quest.id==12)
futureCatalog[12].start=nil
assert(#HT.Planner.Preparation(look[1],futureCatalog,{first,second},1,0,0,rankedNow)==0,
    "Unknown coordinates never create a preparation stop")
print("Confirmed preparation stop routing tests passed.")
