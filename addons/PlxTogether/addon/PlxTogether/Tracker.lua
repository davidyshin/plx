local _, HT = ...
local tracker = CreateFrame("Frame", "PlxTogetherTracker", UIParent, "BackdropTemplate")
HT.tracker = tracker
tracker:SetSize(330, 380)
tracker:SetPoint("RIGHT", UIParent, "RIGHT", -50, 80)
tracker:SetFrameStrata("MEDIUM")
tracker:SetClampedToScreen(true)
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:RegisterForDrag("LeftButton")
tracker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
tracker:SetBackdropColor(0.035, 0.043, 0.055, 0.94)
tracker:SetBackdropBorderColor(0.5, 0.37, 0.18, 1)
local function db()
    if type(PlxTogetherDB) ~= "table" then PlxTogetherDB = {} end
    return PlxTogetherDB
end
local function label(y, font)
    local text = tracker:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 16, y); text:SetWidth(298); text:SetJustifyH("LEFT")
    return text
end
local logo = tracker:CreateTexture(nil, "ARTWORK")
logo:SetSize(29,29); logo:SetPoint("TOPLEFT",12,-10); logo:SetTexture("Interface\\AddOns\\PlxTogether\\Media\\paddington.tga")
local brand = label(-15, "GameFontNormalLarge")
brand:ClearAllPoints(); brand:SetPoint("TOPLEFT",47,-15); brand:SetWidth(265); brand:SetText("Plx|cffeac383Together|r")
local mode, current, tasks, upcoming = label(-40), label(-151, "GameFontNormal"), label(-193), label(-280)
current:SetHeight(34); tasks:SetHeight(78); upcoming:SetHeight(42)
tasks:SetWordWrap(true); tasks:SetNonSpaceWrap(true)
local gps = CreateFrame("Frame", nil, tracker)
gps:SetSize(60, 60); gps:SetPoint("TOPLEFT", 16, -70)
local distance, direction = label(-83, "GameFontNormalLarge"), label(-109)
distance:ClearAllPoints(); distance:SetPoint("TOPLEFT", 88, -83); distance:SetWidth(226)
direction:ClearAllPoints(); direction:SetPoint("TOPLEFT", 88, -109); direction:SetWidth(226)
local arrow = {}
local taskDivider = tracker:CreateTexture(nil, "ARTWORK")
taskDivider:SetColorTexture(0.22,0.25,0.24,1); taskDivider:SetSize(298,1)
for i = 1, 3 do
    arrow[i] = gps:CreateLine(nil, "OVERLAY")
    arrow[i]:SetThickness(5); arrow[i]:SetColorTexture(0.93, 0.78, 0.51, 1)
end
for _, y in ipairs({-139}) do
    local divider = tracker:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.22, 0.25, 0.24, 1); divider:SetSize(298, 1); divider:SetPoint("TOPLEFT", 16, y)
end
local footerDivider=tracker:CreateTexture(nil,"ARTWORK")
footerDivider:SetColorTexture(0.22,0.25,0.24,1); footerDivider:SetSize(298,1); footerDivider:SetPoint("BOTTOMLEFT",16,46)
local function layout()
    current:SetHeight(0); tasks:SetHeight(0); upcoming:SetHeight(0)
    local headingHeight=math.max(28,current:GetStringHeight())
    current:SetHeight(headingHeight)
    local bodyTop=151+headingHeight+10
    tasks:ClearAllPoints(); tasks:SetPoint("TOPLEFT",16,-bodyTop)
    local bodyHeight=math.max(44,tasks:GetStringHeight()+3)
    tasks:SetHeight(bodyHeight)
    local nextTop=bodyTop+bodyHeight+18
    taskDivider:ClearAllPoints(); taskDivider:SetPoint("TOPLEFT",16,-nextTop+8)
    upcoming:ClearAllPoints(); upcoming:SetPoint("TOPLEFT",16,-nextTop)
    local upcomingHeight=math.max(14,upcoming:GetStringHeight()+3)
    upcoming:SetHeight(upcomingHeight)
    tracker:SetHeight(math.max(360,nextTop+upcomingHeight+139))
end
function HT.RenderGPS()
    local state, reason = HT.Navigation.State()
    for _, line in ipairs(arrow) do line:SetShown(state ~= nil and not state.nearby) end
    if not state then distance:SetText(db().arrowPopout and "-- yd" or "GPS paused"); direction:SetText(reason or "Position unavailable"); return end
    if state.nearby then
        distance:SetText(db().arrowPopout and (math.floor(state.distance + 0.5) .. " yd") or "At the stop")
        direction:SetText(HT.demo and "Demo · advance with Next step" or "Complete the tasks below")
        return
    end
    distance:SetText(string.format("%s%d yd", HT.demo and "~" or "", math.floor(state.distance + 0.5)))
    direction:SetText(HT.demo and "Simulated direction" or "Direct to stop · not a road route")
    local x, y = -math.sin(state.angle), math.cos(state.angle)
    local px, py = y, -x
    local segments = {{-18*x,-18*y,22*x,22*y}, {22*x,22*y,9*x+11*px,9*y+11*py}, {22*x,22*y,9*x-11*px,9*y-11*py}}
    for i, segment in ipairs(segments) do
        arrow[i]:SetStartPoint("CENTER", gps, segment[1], segment[2])
        arrow[i]:SetEndPoint("CENTER", gps, segment[3], segment[4])
    end
end
local embeddedGPS, embeddedDistance, embeddedDirection, embeddedArrow = gps, distance, direction, arrow
local popout = CreateFrame("Frame", "PlxTogetherArrow", UIParent, "BackdropTemplate")
HT.arrowPopout = popout
popout:SetSize(100,100); popout:SetPoint("CENTER",UIParent,"CENTER",0,160)
popout:SetFrameStrata("HIGH"); popout:SetClampedToScreen(true); popout:SetMovable(true)
popout:EnableMouse(true); popout:RegisterForDrag("LeftButton")
local floatingGPS = CreateFrame("Frame",nil,popout)
floatingGPS:SetSize(60,60); floatingGPS:SetPoint("TOP",0,-12)
local floatingArrow = {}
for i=1,3 do floatingArrow[i]=floatingGPS:CreateLine(nil,"OVERLAY"); floatingArrow[i]:SetThickness(5); floatingArrow[i]:SetColorTexture(0.93,0.78,0.51,1) end
local floatingDistance=popout:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
floatingDistance:SetPoint("TOP",0,-77); floatingDistance:SetWidth(100)
local floatingDirection=popout:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
floatingDirection:Hide()
popout:SetScript("OnDragStart",function() popout:StartMoving() end)
popout:SetScript("OnDragStop",function()
    popout:StopMovingOrSizing(); local p,_,relative,x,y=popout:GetPoint(); db().arrowPosition={p,relative,x,y}
end)
function HT.ToggleArrowPopout(show)
    db().arrowPopout=show; popout:SetShown(show)
    embeddedGPS:SetShown(not show); embeddedDistance:SetShown(not show); embeddedDirection:SetShown(not show)
    if show then gps,distance,direction,arrow=floatingGPS,floatingDistance,floatingDirection,floatingArrow
    else gps,distance,direction,arrow=embeddedGPS,embeddedDistance,embeddedDirection,embeddedArrow end
    HT.RenderGPS()
end
popout:Hide()
local floatingElapsed, rebuildElapsed=0,0
popout:SetScript("OnUpdate",function(_,delta)
    floatingElapsed=floatingElapsed+delta
    rebuildElapsed=rebuildElapsed+delta
    if rebuildElapsed>=0.5 then rebuildElapsed=0; HT.Rebuild() end
    if floatingElapsed>=0.05 then floatingElapsed=0; HT.RenderGPS() end
end)
tracker:SetScript("OnDragStart", function() tracker:StartMoving() end)
tracker:SetScript("OnDragStop", function()
    tracker:StopMovingOrSizing()
    local point, _, relative, x, y = tracker:GetPoint()
    db().trackerPosition = {point, relative, x, y}
end)
local function button(text, x, callback)
    local b = HT.CreateButton(tracker)
    b:SetSize(92, 25); b:SetPoint("BOTTOMLEFT", x, 13); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
button("Details", 16, function() HT.ShowWindow() end)
local map = button("Map", 119, function()
    if HT.demo then HT.Demo.Stop(); HT.RenderTracker()
    elseif HT.me then OpenWorldMap(HT.me.mapID) end
end)
local advance = button("Refresh", 222, function()
    if HT.demo then HT.Demo.Next() else HT.routeKey = nil; HT.Scan() end
    HT.RenderTracker()
end)
HT.upcomingButtons = {}
for i = 1, 2 do
    local b = HT.CreateButton(tracker)
    b:SetSize(298, 23); b:SetPoint("BOTTOMLEFT", 16, 98 - (i-1)*25)
    b:SetScript("OnClick", function(self) HT.SelectStop(self.target) end)
    HT.upcomingButtons[i] = b
end
local function navButton(text, x, callback)
    local b = HT.CreateButton(tracker)
    b:SetSize(92,23); b:SetPoint("BOTTOMLEFT",x,48); b:SetText(text); b:SetScript("OnClick",callback)
    return b
end
HT.previousStop = navButton("Previous",16,function() HT.SelectStop(HT.ActiveStopIndex()-1) end)
HT.nextStop = navButton("Skip / Next",119,function() HT.SelectStop(HT.ActiveStopIndex()+1) end)
local popoutButton = navButton("Popout GPS",222,function() HT.ToggleArrowPopout(not db().arrowPopout) end)
HT.trackerControls = {map = map, advance = advance, current = current, tasks = tasks, mode = mode, distance = distance, arrow = arrow}
function HT.RenderTracker()
    HT.Rebuild()
    mode:SetText(HT.ModeLabel() .. " · drag to move")
    popoutButton:SetText(db().arrowPopout and "Dock GPS" or "Popout GPS")
    advance:SetText(HT.demo and "Next step" or "Refresh")
    map:SetText(HT.demo and "Exit demo" or "Map")
    map:SetEnabled(HT.demo ~= nil or (HT.me ~= nil and not HT.error and not HT.waiting))
    advance:SetEnabled(not HT.demo or #HT.stops > 0)
    local index = HT.ActiveStopIndex()
    local stop = HT.stops[index]
    HT.RenderGPS()
    if HT.error or HT.waiting or not stop then
        current:SetText(HT.demo and "Demo complete" or "Waiting for a route")
        tasks:SetText(HT.error or HT.waiting or (HT.demo and "All simulated quests finished. Open Details to reset or exit the preview." or "No confirmed stops yet. Open Details for party status, or try /plx demo."))
        upcoming:SetText("")
        for _, b in ipairs(HT.upcomingButtons) do b:Hide() end
        HT.previousStop:SetEnabled(false); HT.nextStop:SetEnabled(false)
        layout()
        return
    end
    current:SetText("STOP " .. index .. " · " .. HT.Planner.Title(stop))
    local task = stop.tasks[1]
    local lines = {"|cffeac383" .. index .. ".1  " .. task.action:upper() .. "|r", HT.TaskInstruction(task),
        "|cff91b9b1Needed by: " .. HT.MemberNames(task.neededBy) .. "|r"}
    if #stop.tasks > 1 then lines[#lines + 1] = "+ " .. (#stop.tasks - 1) .. " substeps · open Details" end
    tasks:SetText(table.concat(lines, "\n"))
    local nextStops = {"|cff87939fUP NEXT - click a stop below|r"}
    for slot, b in ipairs(HT.upcomingButtons) do
        local target = index + slot
        b.target = target; b:SetShown(HT.stops[target] ~= nil)
        b:SetText(HT.stops[target] and (target .. " - " .. HT.Planner.Title(HT.stops[target])) or "")
    end
    HT.previousStop:SetEnabled(index > 1); HT.nextStop:SetEnabled(index < #HT.stops)
    upcoming:SetText(table.concat(nextStops, "\n"))
    layout()
end
function HT.ToggleTracker(show)
    if show == nil then show = not tracker:IsShown() end
    db().trackerHidden = not show
    tracker:SetShown(show)
    if show then HT.RenderTracker() end
end
tracker:SetScript("OnEvent", function()
    HT.ToggleArrowPopout(db().arrowPopout == true)
    local arrowSaved = db().arrowPosition
    if type(arrowSaved) == "table" and type(arrowSaved[1]) == "string" and type(arrowSaved[2]) == "string" and type(arrowSaved[3]) == "number" and type(arrowSaved[4]) == "number" then
        HT.arrowPopout:ClearAllPoints(); HT.arrowPopout:SetPoint(arrowSaved[1], UIParent, arrowSaved[2], arrowSaved[3], arrowSaved[4])
    end
    local saved = db().trackerPosition
    if type(saved) == "table" and type(saved[1]) == "string" and type(saved[2]) == "string"
        and type(saved[3]) == "number" and type(saved[4]) == "number" then
        tracker:ClearAllPoints(); tracker:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    end
    tracker:SetShown(not db().trackerHidden)
end)
tracker:RegisterEvent("PLAYER_LOGIN")
local elapsed, navElapsed = 0, 0
tracker:SetScript("OnUpdate", function(_, delta)
    elapsed, navElapsed = elapsed + delta, navElapsed + delta
    if navElapsed >= 0.05 then navElapsed = 0; HT.RenderGPS() end
    if elapsed >= 0.5 then elapsed = 0; HT.RenderTracker() end
end)
