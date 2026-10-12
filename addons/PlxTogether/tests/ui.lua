-- Strict widget fixture: exercise the actual window and demo callbacks without WoW.
local HT, widgets, sent, opened = {}, {}, 0, 0
local methods = {}
local function widget(parent, kind, name)
    local value = {parent = parent or false, kind = kind, name = name, scripts = {}, shown = true,
        width = 100, height = 30, text = "", scroll = 0, enabled = true}
    setmetatable(value, {__index = function(_, key)
        if methods[key] then return methods[key] end
        error("Unknown UI method: " .. tostring(key))
    end})
    widgets[#widgets + 1] = value
    return value
end
function methods:SetSize(w, h) assert(type(w) == "number" and type(h) == "number"); self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetText(text) self.text = tostring(text) end
function methods:GetStringHeight()
    local text = self.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local lines = 0
    for line in (text .. "\n"):gmatch("(.-)\n") do lines = lines + math.max(1, math.ceil(#line * 6 / self.width)) end
    return lines * 14
end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:Show()
    local changed = not self.shown
    self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.shown = false end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:IsEnabled() return self.enabled ~= false end
function methods:SetPoint(...) self.point = {...} end
function methods:GetPoint() return "CENTER", UIParent, "CENTER", 10, 20 end
function methods:GetFrameLevel() return 1 end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:CreateFontString(name) return widget(self, "FontString", name) end
function methods:CreateTexture(name) return widget(self, "Texture", name) end
function methods:CreateLine(name) return widget(self, "Line", name) end
for _, method in ipairs({"SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetClampedToScreen", "SetMovable",
    "EnableMouse", "RegisterForDrag", "RegisterEvent", "StartMoving", "StopMovingOrSizing", "SetFrameStrata", "SetFrameLevel",
    "SetFontString", "SetWordWrap", "SetNonSpaceWrap", "SetJustifyH", "SetTextColor", "SetSpacing", "SetAllPoints", "SetColorTexture", "ClearAllPoints", "SetThickness",
    "SetStartPoint", "SetEndPoint", "SetScale", "SetScrollChild", "SetTexture", "SetVertexColor"}) do methods[method] = function() end end
CreateFrame = function(kind, name, parent, template)
    local value = widget(parent, kind, name)
    if template == "UIPanelCloseButton" then value.scripts.OnClick = function() parent:Hide() end end
    return value
end
UIParent = widget(nil, "Frame", "UIParent"); UIParent:SetSize(1920, 1080)
UISpecialFrames, SlashCmdList, PlxTogetherDB = {}, {}, nil
tinsert = table.insert
GetTime = function() return 100 end
UnitFullName = function(unit) if unit == "player" then return "Me", "Realm" end end
GetNormalizedRealmName = function() return "Realm" end
UnitFactionGroup = function() return "Horde" end
IsInGroup = function() return false end
IsInRaid = function() return false end
InCombatLockdown = function() return false end
C_Map = {GetBestMapForUnit = function() return 1 end, GetMapInfo = function() return {name = "Test zone"} end,
    GetPlayerMapPosition = function() return {x = 0.1, y = 0.2} end}
C_ChatInfo = {RegisterAddonMessagePrefix = function() end, SendAddonMessage = function() sent = sent + 1 end}
OpenWorldMap = function() opened = opened + 1 end
for _, file in ipairs({"Planner", "Protocol", "Demo", "Core", "Navigation", "Map", "Guide", "Window", "Tracker"}) do
    assert(loadfile("addon/PlxTogether/" .. file .. ".lua"))("PlxTogether", HT)
end
HT.Provider = {Scan = function() return nil, "Questie is not installed." end}
HT.Scan()
SlashCmdList.PLXTOGETHER("")
assert(HT.window:IsShown(), "Window opens even without Questie")
SlashCmdList.PLXTOGETHER("guide")
assert(HT.guideShown and HT.window:IsShown(), "Guide opens without Questie")
HT.buttons.guide.scripts.OnClick()
assert(not HT.guideShown, "Back to route closes the guide")
HT.buttons.demo.scripts.OnClick()
assert(HT.demo and HT.window:IsShown(), "Demo opens from the empty/error state")
assert(#HT.routeCards[1].rows == 2 and HT.routeCards[1].rows[1].number.text == "1.1" and HT.routeCards[1].rows[2].number.text == "1.2", "Shared stops have separate numbered substeps")
assert(HT.routeCards[1].rows[1].members.text:find("Needed by:",1,true))
HT.RenderTracker()
assert(HT.trackerControls.mode.text:find("DEMO · SIMULATED",1,true))
HT.window.scripts.OnUpdate(HT.window, 1)
assert(HT.buttons.nextStep:IsShown() and HT.buttons.nextStep:IsEnabled())
for _, item in ipairs(widgets) do
    if item.scripts.OnUpdate then item.scripts.OnUpdate(item, 0.25) end
end
assert(sent == 0, "All update handlers must keep demo traffic isolated")
HT.buttons.nextStep.scripts.OnClick()
HT.window.scripts.OnUpdate(HT.window, 1)
assert(HT.demo.steps == 1 and not HT.buttons.map:IsEnabled(), "Demo controls advance without touching the real map")
SlashCmdList.PLXTOGETHER("map")
assert(opened == 0 and sent == 0, "Demo must not open a fake world map or send party data")
HT.buttons.refresh.scripts.OnClick()
assert(HT.demo.steps == 0, "Reset button restores the demo")
local steps = 0
while #HT.stops > 0 and steps < 50 do HT.Demo.Next(); steps = steps + 1 end
HT.window.scripts.OnUpdate(HT.window, 1)
HT.RenderTracker()
assert(not HT.buttons.nextStep:IsEnabled(), "Next is disabled when demo is complete")
for _, item in ipairs(widgets) do
    if item.kind == "Line" then assert(not item:IsShown(), "Completed routes must clear old overview lines") end
end
HT.buttons.demo.scripts.OnClick()
HT.window.scripts.OnUpdate(HT.window, 1)
assert(not HT.demo and not HT.buttons.nextStep:IsShown(), "Exit demo returns to the live error state")
assert(HT.error == "Questie is not installed." and sent == 0)
HT.ToggleWindow()
assert(not HT.window:IsShown(), "Window closes cleanly")
SlashCmdList.PLXTOGETHER("  DEMO  ")
assert(HT.demo and HT.window:IsShown(), "Commands handle whitespace and case")
print("Window and demo interaction tests passed.")
HT.window:Hide()
HT.RenderTracker()
assert(HT.tracker:IsShown() and not HT.window:IsShown(), "Tracker remains on screen with Details closed")
HT.trackerControls.advance.scripts.OnClick()
assert(HT.demo.steps == 1, "Tracker advances the isolated demo")
SlashCmdList.PLXTOGETHER("hud hide")
assert(not HT.tracker:IsShown() and PlxTogetherDB.trackerHidden)
SlashCmdList.PLXTOGETHER("hud show")
assert(HT.tracker:IsShown() and not PlxTogetherDB.trackerHidden)
HT.Demo.Stop(); HT.RenderTracker()
assert(HT.trackerControls.mode.text:find("SOLO MODE",1,true), "Real solo play must not be labelled a preview")
assert(HT.trackerControls.tasks.text == "Questie is not installed.")
assert(not HT.trackerControls.map:IsEnabled(), "Tracker disables the map when live data is missing")
print("Persistent tracker interaction tests passed.")
local oldRebuild, oldFocus = HT.Rebuild, HT.FocusStop
HT.Rebuild = function() end
HT.me = {time=100,mapID=1}; HT.error,HT.waiting=nil,nil
local task={action="Pick up",quest={id=1,name="Test quest"},neededBy={"Me-Realm"}}
HT.stops={{point={mapID=1,x=0.2,y=0.3},tasks={task}}, {point={mapID=1,x=0.4,y=0.5},tasks={task}}}
WorldMapFrame=widget(UIParent,"Frame","WorldMap"); WorldMapFrame.mapID,WorldMapFrame.canvasScale=1,1
function methods:GetMapID() return self.mapID end
function methods:GetCanvasScale() return self.canvasScale end
function methods:SetScale(value) self.scale=value end
WorldMapFrame.ScrollContainer={Child=widget(WorldMapFrame,"Frame","Canvas")}
WorldMapFrame.ScrollContainer.Child:SetSize(1000,800)
local tooltipVisible,tooltipOwner=false,nil
GameTooltip={SetOwner=function(_,owner) tooltipOwner=owner end,SetText=function() end,AddLine=function() end,
    Show=function() tooltipVisible=true end,Hide=function() tooltipVisible=false end,IsOwned=function(_,owner) return tooltipOwner==owner end}
HT.mapUpdater.scripts.OnUpdate(HT.mapUpdater,0.2)
assert(#HT.mapPins==2 and HT.mapPins[1].badge:IsShown() and not HT.mapPins[2].badge:IsShown())
HT.mapPins[1].scripts.OnEnter(HT.mapPins[1])
HT.mapUpdater.scripts.OnUpdate(HT.mapUpdater,0.2)
assert(tooltipVisible,"Refreshing pins must not dismiss hovered tooltips")
WorldMapFrame.canvasScale=2
HT.mapUpdater.scripts.OnUpdate(HT.mapUpdater,0.2)
assert(HT.mapPins[1].scale==0.5 and HT.mapPins[1].anchor.point[4]==200,"Zoom must preserve world placement and screen marker size")
local focused
HT.FocusStop=function(index) focused=index end
HT.mapPins[2].scripts.OnClick(HT.mapPins[2]); assert(focused==2)
WorldMapFrame.mapID=2
HT.mapUpdater.scripts.OnUpdate(HT.mapUpdater,0.2)
assert(not HT.mapPins[1].anchor:IsShown(),"Pins must hide on other maps")
HT.Rebuild,HT.FocusStop=oldRebuild,oldFocus
WorldMapFrame=nil
print("Map presentation tests passed: markers, stable hover, zoom scaling, click-to-substeps, zone changes.")

HT.Demo.Start(); HT.RenderTracker()
assert(HT.MemberNames({"Two Words-Realm", "Another Name-Realm"}) == "Two Words, Another Name")
local before = HT.demo.steps
HT.upcomingButtons[1].scripts.OnClick(HT.upcomingButtons[1])
assert(HT.ActiveStopIndex() == 2 and HT.demo.steps == before, "Skipping must not complete quests")
HT.previousStop.scripts.OnClick()
assert(HT.ActiveStopIndex() == 1, "Previous restores the preceding target")
HT.ToggleArrowPopout(true); HT.ToggleTracker(false)
assert(HT.arrowPopout:IsShown(), "Detached GPS survives hiding the tracker")
HT.arrowPopout.scripts.OnDragStop()
assert(PlxTogetherDB.arrowPosition[1] == "CENTER", "Detached position persists")
HT.ToggleArrowPopout(false); HT.ToggleTracker(true)
assert(not HT.arrowPopout:IsShown() and not PlxTogetherDB.arrowPopout)
print("Navigation controls, names with spaces and detached GPS tests passed.")

HT.ToggleArrowPopout(true)
assert(HT.arrowPopout.width == 100 and HT.arrowPopout.height == 100, "Detached arrow uses a compact hit area")
for _, child in ipairs(widgets) do
    if child.parent == HT.arrowPopout then
        assert(child.kind ~= "Button", "Detached GPS must not show a close button")
        if child.kind == "FontString" and child:IsShown() then
            assert(child.text:find("yd",1,true), "Detached GPS shows distance only")
        end
    end
end
HT.ToggleArrowPopout(false)
print("Minimal detached GPS presentation tests passed.")
