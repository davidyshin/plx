local _, HT = ...
local pins, links, elapsed = {}, {}, 0
HT.mapPins = pins
local function hideAll()
    for _, pin in ipairs(pins) do pin.anchor:Hide() end
    for _, line in ipairs(links) do line:Hide() end
end
local function createPin(canvas)
    local anchor = CreateFrame("Frame", nil, canvas)
    anchor:SetSize(1,1)
    local pin = CreateFrame("Button", nil, anchor)
    pin:SetSize(32,32); pin:SetPoint("CENTER"); pin:SetFrameLevel(canvas:GetFrameLevel()+30)
    pin.anchor = anchor
    pin.disk = pin:CreateTexture(nil,"BACKGROUND"); pin.disk:SetAllPoints()
    pin.disk:SetTexture("Interface\\AddOns\\PlxTogether\\Media\\route-pin.tga")
    pin.text = pin:CreateFontString(nil,"OVERLAY","GameFontNormal"); pin.text:SetPoint("CENTER")
    pin.badge = pin:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); pin.badge:SetPoint("BOTTOM",pin,"TOP",0,1)
    pin.badge:SetText("NEXT")
    pin:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText("PlxTogether · Stop " .. self.index .. (self.index == 1 and " · NEXT" or ""))
        for i, task in ipairs(self.stop.tasks) do
            if i > 1 then GameTooltip:AddLine(" ") end
            GameTooltip:AddLine(self.index .. "." .. i .. "  " .. task.action:upper() .. " · " .. task.quest.name,1,0.82,0.5,true)
            GameTooltip:AddLine(HT.TaskInstruction(task),0.95,0.95,0.95,true)
            GameTooltip:AddLine("Needed by: " .. HT.MemberNames(task.neededBy),0.57,0.76,0.69,true)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click for substeps. Straight-line guide; terrain is not modeled.",0.65,0.7,0.72,true)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)
    pin:SetScript("OnHide",function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    pin:SetScript("OnClick",function(self) HT.FocusStop(self.index) end)
    return pin
end
local updater = CreateFrame("Frame")
HT.mapUpdater = updater
updater:SetScript("OnUpdate",function(_,delta)
    elapsed = elapsed + delta
    if elapsed < 0.15 then return end
    elapsed = 0
    if HT.demo or not WorldMapFrame or not WorldMapFrame:IsShown() or not HT.me then hideAll(); return end
    HT.Rebuild()
    if HT.error or HT.waiting or GetTime()-HT.me.time > 90 then hideAll(); return end
    local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
    if not canvas then hideAll(); return end
    local mapID, count = WorldMapFrame:GetMapID(), 0
    local scale = WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale() or 1
    scale = math.max(0.1,scale or 1)
    local previous
    for i,stop in ipairs(HT.stops) do
        if stop.point.mapID == mapID then
            count = count+1
            local pin = pins[count]
            if not pin then pin=createPin(canvas); pins[count]=pin end
            pin.stop, pin.index = stop,i
            pin.text:SetText(i); pin.badge:SetShown(i==1)
            pin.disk:SetVertexColor(i==1 and 0.96 or 0.61,i==1 and 0.78 or 0.84,i==1 and 0.45 or 0.79)
            pin:SetSize(i==1 and 38 or 30,i==1 and 38 or 30); pin:SetScale(1/scale)
            local x,y=stop.point.x*canvas:GetWidth(),-stop.point.y*canvas:GetHeight()
            pin.anchor:ClearAllPoints(); pin.anchor:SetPoint("CENTER",canvas,"TOPLEFT",x,y)
            pin.anchor:Show()
            if previous then
                local line=links[count-1]
                if not line then line=canvas:CreateLine(nil,"ARTWORK"); links[count-1]=line end
                line:SetThickness(1.5/scale); line:SetColorTexture(0.85,0.72,0.44,0.6)
                line:SetStartPoint("TOPLEFT",canvas,previous[1],previous[2]); line:SetEndPoint("TOPLEFT",canvas,x,y); line:Show()
            end
            previous={x,y}
        end
    end
    -- Keep active pins visible; repeatedly hiding them dismisses hovered tooltips.
    for i=count+1,#pins do pins[i].anchor:Hide() end
    for i=math.max(1,count),#links do links[i]:Hide() end
end)
