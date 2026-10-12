local _, HT = ...
local backdrop = {bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1}
local function panel(parent, w, h, r, g, b)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, h); f:SetBackdrop(backdrop)
    f:SetBackdropColor(r or 0.075, g or 0.085, b or 0.1, 1)
    f:SetBackdropBorderColor(0.16, 0.18, 0.21, 1)
    return f
end
local function label(parent, text, font, x, y, width)
    local t = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    t:SetPoint("TOPLEFT", x, y); t:SetJustifyH("LEFT")
    if width then t:SetWidth(width) end
    t:SetText(text)
    return t
end
local window = CreateFrame("Frame", "PlxTogetherWindow", UIParent, "BackdropTemplate")
HT.window = window
window:SetSize(820, 640); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true)
window:SetBackdrop(backdrop); window:SetBackdropColor(0.035, 0.043, 0.055, 0.98)
window:SetBackdropBorderColor(0.38, 0.29, 0.17, 1)
window:Hide(); tinsert(UISpecialFrames, "PlxTogetherWindow")
local drag = CreateFrame("Frame", nil, window)
drag:SetPoint("TOPLEFT"); drag:SetPoint("TOPRIGHT"); drag:SetHeight(76)
drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
drag:SetScript("OnDragStart", function() window:StartMoving() end)
drag:SetScript("OnDragStop", function()
    window:StopMovingOrSizing()
    if type(PlxTogetherDB) ~= "table" then PlxTogetherDB = {} end
    local point, _, relativePoint, x, y = window:GetPoint()
    PlxTogetherDB.position = {point, relativePoint, x, y}
end)
local logo = window:CreateTexture(nil, "ARTWORK")
logo:SetSize(46, 46); logo:SetPoint("TOPLEFT", 20, -14); logo:SetTexture("Interface\\AddOns\\PlxTogether\\Media\\paddington.tga")
local brand = label(window, "Plx|cffeac383Together|r", "GameFontNormalLarge", 78, -20)
local subtitle = label(window, "A better route. Together.", "GameFontHighlightSmall", 78, -47)
subtitle:SetTextColor(0.58, 0.64, 0.7)
local mode = label(window, "LIVE PARTY", "GameFontNormalSmall", 555, -25, 200)
local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -7, -7)
local routeHeading = label(window, "YOUR NEXT STOPS", "GameFontNormal", 24, -88)
local routeMeta = label(window, "", "GameFontHighlightSmall", 24, -111, 470)
routeMeta:SetTextColor(0.62, 0.67, 0.72)
local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 24, -137); scroll:SetPoint("BOTTOMRIGHT", -326, 82)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(466, 420); scroll:SetScrollChild(content)
local cards, pins, links = {}, {}, {}
local party = panel(window, 270, 150)
party:SetPoint("TOPLEFT", 526, -88)
label(party, "THE PARTY", "GameFontNormalSmall", 14, -14)
local partyText = label(party, "", "GameFontHighlightSmall", 14, -40, 242)
partyText:SetSpacing(5)
local overview = panel(window, 270, 248)
overview:SetPoint("TOPLEFT", 526, -250)
label(overview, "ROUTE OVERVIEW", "GameFontNormalSmall", 14, -14)
local plot = panel(overview, 240, 180, 0.045, 0.065, 0.075)
plot:SetPoint("TOPLEFT", 15, -38)
for i = 1, 3 do
    local grid = plot:CreateTexture(nil, "BACKGROUND")
    grid:SetColorTexture(0.12, 0.18, 0.2, 0.4); grid:SetSize(1, 180)
    grid:SetPoint("TOPLEFT", i * 60, 0)
    local horizontal = plot:CreateTexture(nil, "BACKGROUND")
    horizontal:SetColorTexture(0.12, 0.18, 0.2, 0.4); horizontal:SetSize(240, 1)
    horizontal:SetPoint("TOPLEFT", 0, -i * 45)
end
local plotCaption = label(overview, "Schematic · numbered stops, not roads", "GameFontHighlightSmall", 15, -228, 240)
plotCaption:SetTextColor(0.55, 0.64, 0.68)
local guidance = label(window, "", "GameFontHighlightSmall", 526, -514, 270)
guidance:SetTextColor(0.67, 0.72, 0.76)
local footer = label(window, "", "GameFontHighlightSmall", 24, -606, 480)
footer:SetTextColor(0.55, 0.6, 0.66)
local function button(text, x, width, callback)
    local b = HT.CreateButton(window)
    b:SetPoint("BOTTOMLEFT", x, 45); b:SetSize(width, 27)
    b:SetText(text); b:SetScript("OnClick", callback)
    return b
end
local refresh = button("Refresh route", 24, 128, function()
    HT.routeKey = nil; HT.Scan()
end)
local mapButton = button("World map", 162, 108, function()
    if HT.me and not HT.demo then OpenWorldMap(HT.me.mapID) end
end)
local demoButton = button("Try solo demo", 526, 130, function()
    if HT.demo then HT.Demo.Stop() else HT.Demo.Start() end
end)
local nextButton = button("Next step", 666, 130, function() HT.Demo.Next() end)
HT.buttons = {demo = demoButton, nextStep = nextButton, refresh = refresh, map = mapButton}
local render
local routeOffsets = {}
local guideButton = button("Guide", 280, 88, function()
    HT.guideShown = not HT.guideShown
    scroll:SetVerticalScroll(0)
    render()
end)
HT.buttons.guide = guideButton
local function paintPlot()
    for _, pin in ipairs(pins) do pin:Hide() end
    for _, link in ipairs(links) do link:Hide() end
    local previous
    for i, stop in ipairs(HT.stops or {}) do
        local pin = pins[i]
        if not pin then
            pin = CreateFrame("Frame",nil,plot); pin:SetSize(22,22)
            pin.disk=pin:CreateTexture(nil,"BACKGROUND"); pin.disk:SetAllPoints()
            pin.disk:SetTexture("Interface\\AddOns\\PlxTogether\\Media\\route-pin.tga")
            pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pin.text:SetPoint("CENTER")
            pins[i] = pin
        end
        local x, y = 10 + stop.point.x * 220, -10 - stop.point.y * 160
        pin:ClearAllPoints(); pin:SetPoint("CENTER", plot, "TOPLEFT", x, y)
        pin.disk:SetVertexColor(i==1 and 0.96 or 0.61,i==1 and 0.78 or 0.84,i==1 and 0.45 or 0.79)
        pin.text:SetText(i); pin:Show()
        if previous and plot.CreateLine then
            local line = links[i - 1]
            if not line then line = plot:CreateLine(nil, "ARTWORK"); links[i - 1] = line end
            line:SetThickness(1.5); line:SetColorTexture(0.35, 0.55, 0.57, 0.65)
            line:SetStartPoint("TOPLEFT", plot, previous[1], previous[2])
            line:SetEndPoint("TOPLEFT", plot, x, y); line:Show()
        end
        previous = {x, y}
    end
end
local function showCard(index, title, body, active, number)
    local card = cards[index]
    if not card then
        card = panel(content, 464, 90)
        card.number = label(card, "", "GameFontNormalLarge", 14, -16, 28)
        card.title = label(card, "", "GameFontNormal", 52, -14, 394)
        card.body = label(card, "", "GameFontHighlightSmall", 52, -40, 394)
        card.rows = {}
        card.meta = label(card, "", "GameFontHighlightSmall", 52, -38, 394)
        card.body:SetSpacing(3)
        cards[index] = card
    end
    card.number:SetText(number or "·")
    card:EnableMouse(false); card:SetScript("OnMouseUp", nil)
    card.body:Show()
    if card.rows then for _, row in ipairs(card.rows) do row:Hide() end end
    if card.meta then card.meta:Hide() end
    card.title:SetText(title); card.body:SetText(body)
    local titleHeight = card.title:GetStringHeight()
    card.body:ClearAllPoints(); card.body:SetPoint("TOPLEFT", 52, -22 - titleHeight)
    card:SetHeight(math.max(82, titleHeight + card.body:GetStringHeight() + 36))
    card:SetBackdropColor(active and 0.12 or 0.075, active and 0.105 or 0.085, active and 0.075 or 0.1, 1)
    card:SetBackdropBorderColor(active and 0.65 or 0.16, active and 0.48 or 0.18, active and 0.22 or 0.21, 1)
    card:Show()
    return card
end
local function showRouteCard(index, stop, number)
    local title = #stop.tasks > 1 and "Shared stop" or stop.tasks[1].quest.name
    local active = number == HT.ActiveStopIndex()
    local card = showCard(index, title, "", active, string.format("%02d", number))
    card:EnableMouse(true)
    card:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then HT.SelectStop(number) end end)
    card.body:Hide()
    if not card.meta then card.meta = label(card, "", "GameFontHighlightSmall", 52, -38, 394) end
    local offset = 22 + card.title:GetStringHeight()
    card.meta:ClearAllPoints(); card.meta:SetPoint("TOPLEFT", 52, -offset)
    card.meta:SetText(string.format("%s · %d substep%s · %.1f, %.1f", stop.preparation and "UNLOCK SHARED ROUTE" or (active and "GPS TARGET" or "CLICK TO TARGET"),
        #stop.tasks, #stop.tasks == 1 and "" or "s", stop.point.x*100, stop.point.y*100))
    card.meta:SetTextColor(0.67, 0.72, 0.75); card.meta:Show()
    offset = offset + card.meta:GetStringHeight() + 16
    card.rows = card.rows or {}
    for taskIndex, task in ipairs(stop.tasks) do
        local row = card.rows[taskIndex]
        if not row then
            row = CreateFrame("Frame", nil, card); row:SetWidth(432)
            row.divider = row:CreateTexture(nil, "ARTWORK"); row.divider:SetSize(432, 1)
            row.divider:SetPoint("TOPLEFT"); row.divider:SetColorTexture(0.23, 0.26, 0.28, 1)
            row.number = label(row, "", "GameFontNormalSmall", 0, -15, 42)
            row.action = label(row, "", "GameFontNormalSmall", 48, -14, 384)
            row.instruction = label(row, "", "GameFontHighlight", 48, -36, 384)
            row.members = label(row, "", "GameFontHighlightSmall", 48, -58, 384)
            row.members:SetTextColor(0.57, 0.76, 0.69)
            card.rows[taskIndex] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 16, -offset)
        row.number:SetText(number .. "." .. taskIndex)
        row.action:SetText((task.action == "Objective" and "COMPLETE OBJECTIVE" or task.action:upper()) .. " · " .. task.quest.name)
        local instructionOffset = 20 + row.action:GetStringHeight()
        row.instruction:ClearAllPoints(); row.instruction:SetPoint("TOPLEFT", 48, -instructionOffset)
        row.instruction:SetText(HT.TaskInstruction(task))
        local membersOffset = instructionOffset + row.instruction:GetStringHeight() + 8
        row.members:ClearAllPoints(); row.members:SetPoint("TOPLEFT", 48, -membersOffset)
        row.members:SetWordWrap(true); row.members:SetNonSpaceWrap(true); row.members:SetHeight(0)
        row.members:SetText("Needed by: " .. HT.MemberNames(task.neededBy))
        row:SetHeight(membersOffset + row.members:GetStringHeight() + 16)
        row:Show(); offset = offset + row:GetHeight()
    end
    card:SetHeight(offset + 4)
    return card
end
HT.routeCards = cards
render = function()
    HT.Rebuild()
    guideButton:SetText(HT.guideShown and "Back to route" or "Guide")
    guideButton:SetWidth(HT.guideShown and 118 or 88)
    routeHeading:SetText(HT.guideShown and "GETTING STARTED" or "YOUR NEXT STOPS")
    local demo = HT.demo ~= nil
    mode:SetText((demo and "|cffeac383" or "|cff86c9b4") .. HT.ModeLabel() .. "|r")
    demoButton:SetText(demo and "Exit demo" or "Try solo demo")
    nextButton:SetShown(demo)
    nextButton:SetEnabled(demo and #(HT.stops or {}) > 0)
    refresh:SetText(demo and "Reset demo" or "Refresh route")
    refresh:SetScript("OnClick", function()
        if HT.demo then HT.Demo.Start() else HT.routeKey = nil; HT.Scan() end
        render()
    end)
    mapButton:SetEnabled(not demo and HT.me ~= nil)
    local statuses = {}
    local members = HT.demo and HT.demo.members or (HT.me and {HT.me} or {})
    for _, member in ipairs(members) do
        local displayName = member == HT.me and "You" or member.name:match("^[^-]+")
        local state = demo and "Demo" or (GetTime() - member.time <= 90 and "Ready" or "Stale")
        local coordinates = ""
        if member == HT.me and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(member.mapID, "player")
            if pos then coordinates = string.format(" · %.1f, %.1f", pos.x * 100, pos.y * 100) end
        end
        statuses[#statuses + 1] = displayName .. " · Lv. " .. member.level .. " · " .. state .. coordinates
    end
    if not demo then
        for i = 1, 4 do
            local full = HT.UnitName("party" .. i)
            if full then
                local peer = HT.peers[full]
                local state = "Waiting"
                if peer and GetTime() - peer.time <= 90 then
                    state = HT.me and peer.mapID == HT.me.mapID and "Ready" or "Other zone"
                end
                local location = HT.locations and HT.locations[full]
                local position = location and GetTime() - location.time <= 15
                    and string.format(" · %.1f, %.1f", location.x * 100, location.y * 100) or ""
                statuses[#statuses + 1] = HT.MemberNames({full}) .. " · " .. state .. position
            end
        end
    end
    if #statuses == 0 then statuses[1] = "Waiting for your quest data" end
    partyText:SetText(table.concat(statuses, "\n"))
    local mapInfo = HT.me and C_Map.GetMapInfo and C_Map.GetMapInfo(HT.me.mapID)
    local zone = demo and "Practice zone" or (mapInfo and mapInfo.name or "Current zone")
    routeMeta:SetText(zone .. " · " .. #(HT.stops or {}) .. " stops · " .. #(HT.ranked or {}) .. " shared quests")
    footer:SetText(demo and "Sample quests and XP. Demo does not change your character or send party messages."
        or "Questie XP estimates · Approximate travel · /plx demo to practice solo")
    guidance:SetText(demo and "Advance the highlighted stop with Next step. Watch pickups become objectives, then turn-ins. Reset demo starts over."
        or "Follow the gold stop first. Each task names who needs it. Nearby tasks share one marker. Refresh to reorder from your position.")
    for _, card in ipairs(cards) do card:Hide() end
    local offset, count = 0, 0
    local function card(title, body, active, number)
        count = count + 1
        local item = showCard(count, title, body, active, number)
        item:ClearAllPoints(); item:SetPoint("TOPLEFT", 0, -offset)
        offset = offset + item:GetHeight() + 10
    end
    if HT.guideShown then
        for _, section in ipairs(HT.Guide) do card(section[1], section[2], false) end
    elseif HT.error then
        card("Quest data unavailable", HT.error .. "\nYou can still try the solo demo.", true)
    elseif not HT.me then
        card("Ready when you are", "Waiting for your quest data. Install Questie for live routes, or choose Try solo demo.", true)
    elseif HT.waiting then
        card("Waiting for your party", HT.waiting .. "\nEveryone needs PlxTogether and Questie in the same zone.", true)
    else
        for i, stop in ipairs(HT.stops or {}) do
            count = count + 1
            local item = showRouteCard(count, stop, i)
            item:ClearAllPoints(); item:SetPoint("TOPLEFT", 0, -offset)
            routeOffsets[i] = offset
            offset = offset + item:GetHeight() + 14
        end
        if #(HT.stops or {}) == 0 then
            card(demo and "Demo complete" or "No mapped shared stops",
                demo and "Your simulated party finished the route. Reset demo to try again, or Exit demo to return to live play."
                or "Some quests may be locked, completed, missing XP, or outside this zone. Check your quest log and the notes below.", true)
        end
        if #(HT.notes or {}) > 0 then card("Check your quest log", table.concat(HT.notes, "\n"), false) end
        if #(HT.future or {}) > 0 then
            local recommendation = HT.future[1]
            local lines = {"Potential shared route: " .. recommendation.quest.name}
            for _, need in ipairs(recommendation.needs) do
                local parts = {}
                if need.levels > 0 then parts[#parts + 1] = need.levels .. " level" .. (need.levels == 1 and "" or "s") end
                for _, step in ipairs(need.steps) do
                    parts[#parts + 1] = step.name .. (step.uncertain and " (check chain)" or "")
                end
                lines[#lines + 1] = HT.MemberNames({need.name}) .. ": " .. table.concat(parts, " + ")
            end
            lines[#lines + 1] = "Possible unlock; Questie and the quest giver confirm availability. Current stops remain playable."
            card("A BETTER ROUTE MAY BE CLOSE", table.concat(lines, "\n"), false)
        end
        if #(HT.ranked or {}) > 0 then
            card("XP FOR EVERYONE", "Estimated quest rewards for each player. The route gives extra weight to the lowest individual benefit.", false)
            for i = 1, math.min(8, #HT.ranked) do
                local row = HT.ranked[i]
                local body = {}
                for _, detail in ipairs(row.details) do
                    local status = ({A = "Needs pickup", L = "In progress", T = "Ready to turn in"})[detail.status] or "Unknown"
                    body[#body + 1] = string.format("%s · %d XP · %d%% retained\n%s", HT.MemberNames({detail.name}),
                        detail.xp, math.floor((detail.retention or 0) * 100), status)
                    body[#body + 1] = ""
                end
                card(row.quest.name,table.concat(body,"\n"),false)
            end
        end
    end
    content:SetHeight(math.max(400, offset))
    if scroll:GetVerticalScroll() > math.max(0, offset - scroll:GetHeight()) then scroll:SetVerticalScroll(0) end
    paintPlot()
end
local initialized, elapsed = false, 0
window:SetScript("OnShow", function()
    if not initialized then
        initialized = true
        local position = type(PlxTogetherDB) == "table" and PlxTogetherDB.position
        if type(position) == "table" and type(position[3]) == "number" and type(position[4]) == "number" then
            local anchors = {CENTER = true, TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, RIGHT = true,
                BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true}
            if anchors[position[1]] and anchors[position[2]] then
                window:ClearAllPoints(); window:SetPoint(position[1], UIParent, position[2], position[3], position[4])
            end
        end
        local scale = math.min(1, (UIParent:GetWidth() - 32) / 820, (UIParent:GetHeight() - 32) / 640)
        window:SetScale(math.max(0.45, scale))
    end
    render()
end)
window:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then elapsed = 0; render() end
end)
function HT.ResetScroll() scroll:SetVerticalScroll(0) end
function HT.ShowWindow() scroll:SetVerticalScroll(0); window:Show(); render() end
function HT.ToggleWindow() window:SetShown(not window:IsShown()) end
function HT.ShowGuide() HT.guideShown = true; HT.ShowWindow() end
function HT.FocusStop(index)
    HT.SelectStop(index)
    HT.guideShown = false; HT.ShowWindow()
    scroll:SetVerticalScroll(math.min(routeOffsets[index] or 0, math.max(0, content:GetHeight() - scroll:GetHeight())))
end
