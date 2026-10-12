local _, HT = ...
local tracker = CreateFrame("Frame", "PlxTogetherTracker", UIParent, "BackdropTemplate")
HT.tracker = tracker
tracker:SetSize(310, 288)
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
    text:SetPoint("TOPLEFT", 16, y); text:SetWidth(278); text:SetJustifyH("LEFT")
    return text
end
label(-15, "GameFontNormalLarge"):SetText("Plx|cffeac383Together|r")
local mode, current, tasks, upcoming = label(-40), label(-64, "GameFontNormal"), label(-101), label(-191)
tasks:SetHeight(82); upcoming:SetHeight(42)
tracker:SetScript("OnDragStart", function() tracker:StartMoving() end)
tracker:SetScript("OnDragStop", function()
    tracker:StopMovingOrSizing()
    local point, _, relative, x, y = tracker:GetPoint()
    db().trackerPosition = {point, relative, x, y}
end)
local function button(text, x, callback)
    local b = CreateFrame("Button", nil, tracker, "UIPanelButtonTemplate")
    b:SetSize(86, 25); b:SetPoint("BOTTOMLEFT", x, 13); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
button("Details", 16, function() HT.ShowWindow() end)
local map = button("Map", 112, function()
    if not HT.demo and HT.me then OpenWorldMap(HT.me.mapID) end
end)
local advance = button("Refresh", 208, function()
    if HT.demo then HT.Demo.Next() else HT.routeKey = nil; HT.Scan() end
    HT.RenderTracker()
end)
HT.trackerControls = {map = map, advance = advance, current = current, tasks = tasks}
function HT.RenderTracker()
    HT.Rebuild()
    mode:SetText(HT.demo and "SOLO PREVIEW · drag to move" or "PARTY ROUTE · drag to move")
    advance:SetText(HT.demo and "Next step" or "Refresh")
    map:SetEnabled(not HT.demo and HT.me ~= nil and not HT.error and not HT.waiting)
    advance:SetEnabled(not HT.demo or #HT.stops > 0)
    local stop = HT.stops[1]
    if HT.error or HT.waiting or not stop then
        current:SetText(HT.demo and "Preview complete" or "Waiting for a shared route")
        tasks:SetText(HT.error or HT.waiting or (HT.demo and "All simulated quests finished. Open Details to reset or exit the preview." or "No confirmed stops yet. Open Details for party status, or try /plx demo."))
        upcoming:SetText("")
        return
    end
    current:SetText("1 · " .. HT.Planner.Title(stop))
    local lines = {string.format("Map coordinates: %.1f, %.1f", stop.point.x * 100, stop.point.y * 100)}
    for i, task in ipairs(stop.tasks) do
        if i > 2 then lines[#lines + 1] = "+ " .. (#stop.tasks - 2) .. " more tasks in Details"; break end
        lines[#lines + 1] = task.text or task.quest.name
        lines[#lines + 1] = "Needed by: " .. table.concat(task.neededBy or {}, ", ")
    end
    tasks:SetText(table.concat(lines, "\n"))
    local nextStops = {}
    for i = 2, math.min(3, #HT.stops) do nextStops[#nextStops + 1] = i .. " · " .. HT.Planner.Title(HT.stops[i]) end
    upcoming:SetText(table.concat(nextStops, "\n"))
end
function HT.ToggleTracker(show)
    if show == nil then show = not tracker:IsShown() end
    db().trackerHidden = not show
    tracker:SetShown(show)
    if show then HT.RenderTracker() end
end
tracker:SetScript("OnEvent", function()
    local saved = db().trackerPosition
    if type(saved) == "table" and type(saved[1]) == "string" and type(saved[2]) == "string"
        and type(saved[3]) == "number" and type(saved[4]) == "number" then
        tracker:ClearAllPoints(); tracker:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    end
    tracker:SetShown(not db().trackerHidden)
end)
tracker:RegisterEvent("PLAYER_LOGIN")
local elapsed = 0
tracker:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.5 then elapsed = 0; HT.RenderTracker() end
end)
