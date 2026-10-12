local _, HT = ...
local pins, elapsed = {}, 0
local updater = CreateFrame("Frame")
updater:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed < 0.25 then return end
    elapsed = 0
    for _, pin in ipairs(pins) do pin:Hide() end
    if HT.demo then return end
    if not WorldMapFrame or not WorldMapFrame:IsShown() or not HT.me then return end
    HT.Rebuild()
    if GetTime() - HT.me.time > 90 then return end
    for _, peer in pairs(HT.peers) do
        if GetTime() - peer.time > 90 then return end
    end
    local container = WorldMapFrame.ScrollContainer
    local canvas = container and container.Child
    if not canvas then return end
    for i, stop in ipairs(HT.stops) do
        if WorldMapFrame:GetMapID() == stop.point.mapID then
            local pin = pins[i]
            if not pin then
                pin = CreateFrame("Button", nil, canvas)
                pin:SetSize(24, 24)
                pin:SetFrameLevel(canvas:GetFrameLevel() + 20)
                local bg = pin:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(); bg:SetColorTexture(0.65, 0.05, 0.05, 0.95)
                pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                pin.text:SetPoint("CENTER")
                pin:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(HT.Planner.Title(self.stop))
                    for _, task in ipairs(self.stop.tasks) do
                        GameTooltip:AddLine(task.action .. ": " .. task.quest.name, 1, 0.85, 0.5, true)
                        if task.text then GameTooltip:AddLine(task.text, 1, 1, 1, true) end
                        GameTooltip:AddLine("For: " .. table.concat(task.neededBy, ", "), 0.6, 0.8, 0.75, true)
                    end
                    GameTooltip:AddLine("Approximate stop; terrain and travel paths are not modeled.", 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
                pin:SetScript("OnHide", function(self)
                    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
                end)
                pins[i] = pin
            end
            pin.stop = stop
            pin.text:SetText(i)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT",
                stop.point.x * canvas:GetWidth(), -stop.point.y * canvas:GetHeight())
            pin:Show()
        end
    end
end)
