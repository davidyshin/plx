local _, HT = ...
HT.Navigation = {}
local function number(value) return type(value) == "number" and value == value and math.abs(value) < math.huge end
local function atan2(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    if y > 0 then return math.pi / 2 end
    if y < 0 then return -math.pi / 2 end
    return 0
end
-- Map X increases east, map Y south. WoW facing increases counterclockwise from north.
function HT.Navigation.Calculate(px, py, tx, ty, width, height, facing)
    local values = {px, py, tx, ty, width, height, facing}
    for i = 1, 7 do if not number(values[i]) then return end end
    if width <= 0 or height <= 0 then return end
    if px < 0 or px > 1 or py < 0 or py > 1 or tx < 0 or tx > 1 or ty < 0 or ty > 1 then return end
    local east, north = (tx - px) * width, (py - ty) * height
    local distance = math.sqrt(east * east + north * north)
    local angle = (atan2(-east, north) - facing + math.pi) % (2 * math.pi) - math.pi
    return {angle = angle, distance = distance, nearby = distance <= 20}
end
function HT.Navigation.TravelTime(distance, speed)
    if not number(distance) or distance < 0 then return end
    if not number(speed) or speed <= 0 then speed = 7 end
    return math.ceil(distance / speed), speed <= 7 and "walking" or "current speed"
end
function HT.Navigation.Dimensions(mapID)
    if C_Map.GetMapWorldSize then
        local ok, w, h = pcall(C_Map.GetMapWorldSize, mapID)
        if ok and number(w) and number(h) and w > 0 and h > 0 then return w, h end
    end
    if LibStub and LibStub.GetLibrary then
        local ok, library = pcall(LibStub.GetLibrary, LibStub, "HereBeDragons-2.0", true)
        if ok and library and library.GetZoneSize then
            local valid, w, h = pcall(library.GetZoneSize, library, mapID)
            if valid and number(w) and number(h) and w > 0 and h > 0 then return w, h end
        end
    end
end
function HT.Navigation.State()
    if HT.error or HT.waiting or not HT.me or not HT.stops[HT.ActiveStopIndex and HT.ActiveStopIndex() or 1] then return nil, "No active stop" end
    local point = HT.stops[HT.ActiveStopIndex and HT.ActiveStopIndex() or 1].point
    if HT.demo then
        local state = HT.Navigation.Calculate(HT.demo.x, HT.demo.y, point.x, point.y, 8000, 6000, 0)
        if state then state.seconds, state.pace = HT.Navigation.TravelTime(state.distance, 7) end
        return state
    end
    if not HT.me.time or GetTime() - HT.me.time > 90 then return nil, "Waiting for fresh data" end
    if C_Map.GetBestMapForUnit("player") ~= point.mapID then return nil, "Meet in the route zone" end
    local pos = C_Map.GetPlayerMapPosition(point.mapID, "player")
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not pos or not number(facing) then return nil, "Position unavailable here" end
    local width, height = HT.Navigation.Dimensions(point.mapID)
    if not width then return nil, "Map scale unavailable here" end
    local state = HT.Navigation.Calculate(pos.x, pos.y, point.x, point.y, width, height, facing)
    if state then
        local speed
        if GetUnitSpeed then
            local ok, currentSpeed = pcall(GetUnitSpeed, "player")
            if ok then speed = currentSpeed end
        end
        local ok, seconds, pace = pcall(HT.Navigation.TravelTime, state.distance, speed)
        if not ok then seconds, pace = HT.Navigation.TravelTime(state.distance, 7) end
        state.seconds, state.pace = seconds, pace
    end
    return state
end
