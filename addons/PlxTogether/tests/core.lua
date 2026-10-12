local HT, clock, partyName, raid = {}, 100, "Friend", false
assert(loadfile("addon/PlxTogether/Planner.lua"))("PlxTogether", HT)
assert(loadfile("addon/PlxTogether/Protocol.lua"))("PlxTogether", HT)
local quest = {id = 1, name = "Hunt"}
HT.Provider = {Scan = function() return {mapID = 1, level = 15, xpMax = 1000, count = 1,
    catalog = {[1] = quest}, quests = {[1] = {status = "L", xp = 100, retention = 1}}} end}
local frame = {scripts = {}, RegisterEvent = function() end}
function frame:SetScript(key, callback) self.scripts[key] = callback end
CreateFrame = function() return frame end
UnitFullName = function(unit)
    if unit == "player" then return "Me", "Realm" end
    if unit == "party1" then return partyName, "Realm" end
end
GetNormalizedRealmName = function() return "Realm" end
UnitFactionGroup = function() return "Horde" end
GetTime = function() return clock end
IsInGroup = function() return partyName ~= nil end
IsInRaid = function() return raid end
InCombatLockdown = function() return false end
C_Map = {GetBestMapForUnit = function() return 1 end,
    GetPlayerMapPosition = function() return {x = 0, y = 0} end}
C_ChatInfo = {RegisterAddonMessagePrefix = function() end, SendAddonMessage = function() end}
SlashCmdList = {}
assert(loadfile("addon/PlxTogether/Core.lua"))("PlxTogether", HT)
HT.Scan()
assert(#HT.ranked == 0 and HT.waiting, "A missing peer blocks shared routes")
local serial = HT.serial
HT.Scan()
assert(HT.serial == serial and HT.nextSnapshot, "An active snapshot must finish before sending the latest update")
local peer = {mapID = 1, level = 18, xpMax = 2000,
    quests = {[1] = {status = "L", xp = 100, retention = 1}}}
local function receive(sender)
    for _, packet in ipairs(HT.Protocol.Encode(peer, 42)) do
        frame.scripts.OnEvent(frame, "CHAT_MSG_ADDON", "PlxTogether3", packet, "PARTY", sender)
    end
end
receive("Stranger")
assert(not HT.peers["Stranger-Realm"], "Ignore non-party senders")
receive("Friend")
assert(#HT.ranked == 1, "Normalize same-realm sender names")
local stable = HT.stops
HT.Rebuild()
assert(HT.stops == stable, "Unchanged state must preserve route order between UI refreshes")
clock = 191
HT.Rebuild()
assert(#HT.ranked == 0 and HT.waiting, "Expire stale party data")
partyName, clock = nil, 200
frame.scripts.OnEvent(frame, "GROUP_ROSTER_UPDATE")
HT.Scan()
assert(#HT.ranked == 1 and not HT.peers["Friend-Realm"], "Cleanly recover solo after a party member leaves")
raid = true
HT.Scan()
assert(HT.error and not HT.me and #HT.stops == 0, "Disable quest plans in raids")
print("Core integration tests passed.")
