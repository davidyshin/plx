local _, HT = ...
HT.peers, HT.queue, HT.catalog, HT.stops, HT.locations = {}, {}, {}, {}, {}
local PREFIX = "PlxTogether4"
local function name(unit)
    local n, realm = UnitFullName(unit)
    -- Forever exposes first name and surname separately through UnitName.
    if UnitName and C_PlayerInfo and C_PlayerInfo.ShouldDisplaySurname then
        local first, surname = UnitName(unit)
        if first then
            n = first
            if surname and surname ~= "" and not first:find(" ", 1, true) then n = first .. " " .. surname end
            realm = GetNormalizedRealmName()
        end
    end
    if not n then return end
    return n .. "-" .. ((realm and realm ~= "") and realm or GetNormalizedRealmName())
end
HT.UnitName = name
function HT.CreateButton(parent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.07,0.085,0.095,0.65); b:SetBackdropBorderColor(0.19,0.23,0.25,0.7)
    local text = b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    text:SetPoint("LEFT",7,0); text:SetPoint("RIGHT",-7,0)
    b:SetFontString(text)
    b:SetScript("OnEnter",function(self)
        if self:IsEnabled() then self:SetBackdropColor(0.13,0.16,0.17,0.9); self:SetBackdropBorderColor(0.43,0.48,0.45,0.8) end
    end)
    b:SetScript("OnLeave",function(self)
        self:SetBackdropColor(0.07,0.085,0.095,0.65); self:SetBackdropBorderColor(0.19,0.23,0.25,0.7)
    end)
    b:SetScript("OnUpdate",function(self) text:SetTextColor(self:IsEnabled() and 0.78 or 0.35,self:IsEnabled() and 0.82 or 0.39,self:IsEnabled() and 0.81 or 0.4) end)
    return b
end
function HT.Print(message) print("|cffff5555PlxTogether:|r " .. message) end
function HT.ModeLabel()
    if HT.demo then return "DEMO · SIMULATED" end
    return IsInGroup() and "PARTY MODE" or "SOLO MODE"
end
function HT.TaskInstruction(task)
    if task.action == "Pick up" then return "Accept this quest from the quest giver." end
    if task.action == "Turn in" then return "Hand in the completed quest." end
    return task.text or "Complete this objective; check your quest log for details."
end
function HT.MemberNames(names)
    local short = {}
    for _, name in ipairs(names or {}) do short[#short + 1] = name:match("^[^-]+") end
    return table.concat(short, ", ")
end
-- Navigation changes the target only; it never marks a quest complete.
function HT.ActiveStopIndex()
    return math.max(1, math.min(HT.selectedStop or 1, #HT.stops))
end
function HT.SelectStop(index)
    HT.selectedStop = math.max(1, math.min(index, #HT.stops))
    if HT.RenderTracker then HT.RenderTracker() end
end
local function roster()
    local result = {}
    for i = 1, 4 do
        local n = name("party" .. i)
        if n then result[n] = true end
    end
    return result
end
local function broadcast(snapshot)
    if HT.demo then HT.queue, HT.nextSnapshot = {}, nil; return end
    if not IsInGroup() or IsInRaid() then HT.queue, HT.nextSnapshot = {}, nil; return end
    if #HT.queue > 0 then HT.nextSnapshot = snapshot; return end
    HT.nextSnapshot = nil
    HT.serial = (HT.serial or 0) + 1
    HT.queue = HT.Protocol.Encode(snapshot, HT.serial)
end
function HT.Rebuild()
    if HT.demo then HT.Demo.Rebuild(); return end
    if not HT.me then HT.stops, HT.notes, HT.ranked, HT.routeKey = {}, {}, {}, nil; return end
    local members = {HT.me}
    local names = {}
    for n in pairs(roster()) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        local peer = HT.peers[n]
        if peer and peer.mapID == HT.me.mapID then members[#members + 1] = peer
        else members[#members + 1] = {name = n, ready = false} end
    end
    HT.ranked, HT.waiting = HT.Planner.Rank(HT.catalog, members, GetTime())
    HT.future = HT.waiting and {} or HT.Planner.LookAhead(HT.catalog, members, HT.ranked)
    local keys = {tostring(HT.me.mapID)}
    for _, row in ipairs(HT.ranked) do
        keys[#keys + 1] = tostring(row.quest.id)
        for _, detail in ipairs(row.details) do
            keys[#keys + 1] = detail.name .. detail.status .. tostring(detail.doneMask) .. tostring(detail.objectiveCount) .. tostring(detail.objectiveKey)
        end
        for _, objective in ipairs(row.quest.objectives or {}) do
            keys[#keys + 1] = tostring(objective.index) .. (objective.text or "")
            for _, point in ipairs(objective.points or {}) do
                keys[#keys + 1] = tostring(point.mapID) .. ":" .. point.x .. ":" .. point.y
            end
        end
        for _, point in pairs({row.quest.start, row.quest.finish}) do
            keys[#keys + 1] = tostring(point.mapID) .. ":" .. point.x .. ":" .. point.y
        end
    end
    keys[#keys + 1] = HT.waiting or ""
    for _, suggestion in ipairs(HT.future or {}) do
        keys[#keys + 1] = tostring(suggestion.quest.id)
        for _, need in ipairs(suggestion.needs) do
            keys[#keys + 1] = need.name .. ":" .. need.levels
            for _, step in ipairs(need.steps) do keys[#keys + 1] = tostring(step.id) .. ":" .. step.status end
        end
    end
    local key = table.concat(keys, "|")
    if key ~= HT.routeKey then
        local pos = C_Map.GetPlayerMapPosition(HT.me.mapID, "player")
        HT.stops, HT.notes = HT.Planner.Stops(HT.ranked, HT.me.mapID, pos and pos.x, pos and pos.y)
        local prep = HT.Planner.Preparation(HT.future[1], HT.catalog, members, HT.me.mapID,
            pos and pos.x, pos and pos.y, HT.ranked)
        for i = #prep, 1, -1 do table.insert(HT.stops, 1, prep[i]) end
        HT.routeKey = key
        HT.selectedStop = 1
    end
end
function HT.Scan()
    if HT.demo then HT.Demo.Rebuild(); return end
    if UnitFactionGroup("player") ~= "Horde" then
        HT.error = "This prototype supports Horde characters only."
        HT.me, HT.catalog, HT.stops, HT.queue, HT.nextSnapshot, HT.routeKey = nil, {}, {}, {}, nil, nil
        return
    end
    if IsInRaid() then
        HT.error = "Leave the raid group to plan party questing."
        HT.me, HT.catalog, HT.stops, HT.queue, HT.nextSnapshot, HT.routeKey = nil, {}, {}, {}, nil, nil
        return
    end
    if InCombatLockdown() then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        HT.error = "Waiting for your zone to load."
        HT.me, HT.stops, HT.routeKey = nil, {}, nil
        HT.queue, HT.nextSnapshot = {}, nil
        return
    end
    local ok, snapshot, err = pcall(HT.Provider.Scan, mapID)
    if not ok or not snapshot then
        HT.error = ok and err or "Questie adapter failed: " .. tostring(snapshot)
        HT.me, HT.catalog, HT.stops, HT.queue, HT.nextSnapshot, HT.routeKey = nil, {}, {}, {}, nil, nil
        return
    end
    HT.error = nil
    snapshot.name, snapshot.ready, snapshot.time = name("player"), true, GetTime()
    HT.me, HT.catalog = snapshot, snapshot.catalog
    broadcast(snapshot)
    HT.Rebuild()
end
local function receive(message, sender)
    if HT.demo or type(sender) ~= "string" then return end
    if not sender:find("-", 1, true) then sender = sender .. "-" .. GetNormalizedRealmName() end
    if not roster()[sender] then return end
    if message:sub(1, 2) == "P|" then
        local location = HT.Protocol.ReceiveLocation(message, GetTime())
        if location then HT.locations[sender] = location end
        return
    end
    HT.pending = HT.pending or {}
    local peer = HT.Protocol.Receive(HT.pending, message, sender, GetTime())
    if peer then
        HT.peers[sender] = peer
        HT.Rebuild()
    end
end

function HT.StatusLines()
    local lines = {}
    if HT.demo then
        for _, member in ipairs(HT.demo.members) do
            lines[#lines + 1] = member.name .. ": level " .. member.level .. " · simulated"
        end
        return lines
    end
    if HT.error then lines[#lines + 1] = HT.error end
    if HT.me then
        lines[#lines + 1] = "You: level " .. HT.me.level .. ", " .. HT.me.count .. " zone quests scanned"
    else lines[#lines + 1] = "You: waiting for quest data" end
    local names = {}
    for n in pairs(roster()) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        local peer, state = HT.peers[n], "no snapshot — addon missing, loading, or different protocol version"
        if peer then
            if GetTime() - peer.time > 90 then state = "stale data — waiting for refresh"
            elseif HT.me and peer.mapID ~= HT.me.mapID then state = "in another zone"
            else state = "ready, level " .. peer.level end
        end
        lines[#lines + 1] = n .. ": " .. state
    end
    if #names == 0 then lines[#lines + 1] = "Solo mode — invite Horde friends to plan together" end
    return lines
end
function HT.Status()
    for _, line in ipairs(HT.StatusLines()) do HT.Print(line) end
end

function HT.Report()
    HT.Rebuild()
    if HT.error then HT.Print(HT.error); return end
    if not HT.me then HT.Print("Waiting for a zone scan."); return end
    if HT.waiting then HT.Print(HT.waiting .. ". Everyone needs the addon and Questie in the same zone."); return end
    HT.Print("Shared quests in this zone (Questie XP estimates; beta rules unverified):")
    if #HT.ranked == 0 then HT.Print("No confirmed shared quests with known positive XP.") end
    for i = 1, math.min(8, #HT.ranked) do
        local row, details = HT.ranked[i], {}
        for _, d in ipairs(row.details) do
            details[#details + 1] = string.format("%s: %d XP (~%d%% level retention, %s)",
                d.name, d.xp, math.floor((d.retention or 0) * 100), d.status)
        end
        HT.Print(i .. ". " .. row.quest.name .. " — " .. table.concat(details, "; "))
    end
    HT.Print("A=available, L=in log, T=ready to turn in. Map numbers order the next route steps.")
    for i, stop in ipairs(HT.stops) do
        HT.Print(i .. ". " .. HT.Planner.Title(stop))
    end
end
SLASH_PLXTOGETHER1 = "/plx"
SLASH_PLXTOGETHER2 = "/plxtogether"
SLASH_PLXTOGETHER3 = "/ht"
SlashCmdList.PLXTOGETHER = function(input)
    input = (input or ""):lower():match("^%s*(.-)%s*$")
    if input == "demo" or input == "demo reset" then HT.Demo.Start()
    elseif input == "hud" then HT.ToggleTracker()
    elseif input == "hud show" then HT.ToggleTracker(true)
    elseif input == "hud hide" then HT.ToggleTracker(false)
    elseif input == "guide" or input == "help" then if HT.ShowGuide then HT.ShowGuide() end
    elseif input == "demo next" then HT.Demo.Next()
    elseif input == "live" or input == "solo" or input == "demo off" then HT.Demo.Stop()
    elseif input == "refresh" then HT.routeKey = nil; HT.Scan(); HT.Report()
    elseif input == "status" then HT.Status()
    elseif input == "map" then
        if HT.demo then if HT.ShowWindow then HT.ShowWindow() end
        elseif HT.me then OpenWorldMap(HT.me.mapID) end
    elseif input == "list" then HT.Report()
    elseif input ~= "" then HT.Print("/plx · /plx demo · /plx demo next · /plx live · /plx refresh")
    elseif HT.ToggleWindow then HT.ToggleWindow() else HT.Report() end
end
local frame = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "GROUP_ROSTER_UPDATE", "PLAYER_LEVEL_UP",
    "QUEST_LOG_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED", "CHAT_MSG_ADDON"}) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", function(_, event, ...)
    if HT.demo then return end
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == PREFIX and channel == "PARTY" then receive(message, sender) end
    else
        if event == "PLAYER_LOGIN" then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
            HT.Print("Ready. /plx opens your route. /plx demo previews a party while solo.")
        elseif event == "GROUP_ROSTER_UPDATE" then
            HT.queue, HT.nextSnapshot = {}, nil
            local current = roster()
            for n in pairs(HT.peers) do if not current[n] then HT.peers[n] = nil end end
            for n in pairs(HT.locations) do if not current[n] then HT.locations[n] = nil end end
            HT.Rebuild()
        end
        HT.dirty = true
    end
end)
local elapsed, scanElapsed, locationElapsed = 0, 30, 5
frame:SetScript("OnUpdate", function(_, delta)
    if HT.demo then return end
    elapsed, scanElapsed, locationElapsed = elapsed + delta, scanElapsed + delta, locationElapsed + delta
    if elapsed < 0.2 then return end
    elapsed = 0
    if #HT.queue > 0 then C_ChatInfo.SendAddonMessage(PREFIX, table.remove(HT.queue, 1), "PARTY") end
    if locationElapsed >= 5 then
        locationElapsed = 0
        if IsInGroup() and not IsInRaid() and HT.me then
            local map = C_Map.GetBestMapForUnit("player")
            local pos = map and C_Map.GetPlayerMapPosition(map, "player")
            local packet = map and pos and HT.Protocol.EncodeLocation(map, pos.x, pos.y)
            if packet then C_ChatInfo.SendAddonMessage(PREFIX, packet, "PARTY") end
        end
    end
    if #HT.queue == 0 and HT.nextSnapshot then broadcast(HT.nextSnapshot) end
    if scanElapsed >= 30 or (HT.dirty and scanElapsed >= 5) then
        scanElapsed, HT.dirty = 0, false
        HT.Scan()
    end
end)
