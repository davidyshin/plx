local HT = {}
assert(loadfile("addon/PlxTogether/Navigation.lua"))("PlxTogether", HT)
local function near(a, b) assert(math.abs(a - b) < 0.000001, tostring(a) .. " ~= " .. tostring(b)) end
local calc = HT.Navigation.Calculate
near(calc(0.5,0.5,0.5,0.4,1000,2000,0).angle,0)
near(calc(0.5,0.5,0.6,0.5,1000,2000,0).angle,-math.pi/2)
near(calc(0.5,0.5,0.4,0.5,1000,2000,0).angle,math.pi/2)
near(calc(0.5,0.5,0.5,0.6,1000,2000,0).angle,-math.pi)
near(calc(0.5,0.5,0.6,0.5,1000,2000,3*math.pi/2).angle,0)
near(calc(0.5,0.5,0.6,0.4,1000,2000,0).distance,math.sqrt(50000))
assert(calc(0.5,0.5,0.51,0.5,1000,2000,0).nearby)
assert(not calc(0.5,0.5,0.6,0.5,0,2000,0))
assert(not calc(0.5,0.5,0.6,0.5,1000,2000,nil))
assert(not calc(0.5,0.5,0.6,0.5,1000,2000,0/0))
assert(not calc(0.5,0.5,1.1,0.5,1000,2000,0))
HT.me = {time=100}; HT.stops = {{point={mapID=1,x=0.6,y=0.5}}}
GetTime = function() return 100 end
GetPlayerFacing = function() return 0 end
C_Map = {GetBestMapForUnit=function() return 1 end, GetPlayerMapPosition=function() return {x=0.5,y=0.5} end,
    GetMapWorldSize=function() return 1000,2000 end}
assert(HT.Navigation.State())
HT.me.time = 0; assert(not HT.Navigation.State()); HT.me.time=100
C_Map.GetBestMapForUnit=function() return 2 end; assert(not HT.Navigation.State())
HT.demo={x=0.5,y=0.5}; assert(HT.Navigation.State(), "Demo navigation must use simulated coordinates")
HT.demo=nil; C_Map.GetBestMapForUnit=function() return 1 end
GetPlayerFacing=function() return nil end; assert(not HT.Navigation.State())
C_Map.GetMapWorldSize=nil
LibStub={GetLibrary=function() return {GetZoneSize=function() return 1200,800 end} end}
local w,h=HT.Navigation.Dimensions(1); assert(w==1200 and h==800)
LibStub=nil
print("Navigation tests passed: cardinal directions, facing, map scale, arrival, stale/off-zone/missing positions, demo isolation.")

local seconds, pace=HT.Navigation.TravelTime(700, 0)
assert(seconds==100 and pace=="walking")
seconds, pace=HT.Navigation.TravelTime(700, 14)
assert(seconds==50 and pace=="current speed")
GetUnitSpeed=function() return 14 end
C_Map.GetMapWorldSize=function() return 1000,2000 end
GetPlayerFacing=function() return 0 end
assert(HT.Navigation.State().seconds==8, "Live ETA uses current speed")
print("Travel time estimates passed.")
