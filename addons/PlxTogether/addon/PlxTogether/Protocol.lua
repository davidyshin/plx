local _, HT = ...
HT.Protocol = {}
function HT.Protocol.Encode(snapshot, serial)
    serial = tostring(serial)
    local ids, packets = {}, {}
    for id in pairs(snapshot.quests) do ids[#ids + 1] = id end
    table.sort(ids)
    packets[1] = table.concat({"B", serial, snapshot.mapID, snapshot.level, snapshot.xpMax, #ids}, "|")
    local packet = "D|" .. serial .. "|"
    for _, id in ipairs(ids) do
        local state = snapshot.quests[id]
        local record = string.format("%d:%s:%d:%d:%d:%d:%d;", id, state.status,
            state.xp or -1, math.floor((state.retention or 0) * 100),
            state.doneMask or -1, state.objectiveCount or 0, state.objectiveKey or 0)
        if #packet + #record > 220 then
            packets[#packets + 1], packet = packet, "D|" .. serial .. "|"
        end
        packet = packet .. record
    end
    if packet:sub(-1) == ";" then packets[#packets + 1] = packet end
    packets[#packets + 1] = "E|" .. serial .. "|"
    return packets
end

-- A snapshot becomes visible only after a matching, complete end packet.
function HT.Protocol.Receive(pending, message, sender, now)
    if type(message) ~= "string" or #message > 255 then return end
    local kind, serial, body = message:match("^(%u)|(%d+)|(.*)$")
    if not serial or #serial > 12 then return end
    if kind == "B" then
        local map, level, xpMax, count = body:match("^(%d+)|(%d+)|(%d+)|(%d+)$")
        map, level, xpMax, count = tonumber(map), tonumber(level), tonumber(xpMax), tonumber(count)
        if not map or map < 1 or level < 1 or level > 100 or xpMax < 0
            or xpMax > 1000000000 or count > 300 then return end
        pending[sender] = {serial = serial, name = sender, mapID = map, level = level,
            xpMax = xpMax, expected = count, count = 0, quests = {}, time = now}
        return
    end
    local peer = pending[sender]
    if not peer or peer.serial ~= serial then return end
    if now - peer.time > 45 then pending[sender] = nil; return end
    if kind == "D" then
        local consumed = ""
        for record in body:gmatch("[^;]+;") do
            consumed = consumed .. record
            local id, status, xp, retention, mask, count, key = record:match(
                "^(%d+):([ALTX]):(%-?%d+):(%d+):(%-?%d+):(%d+):(%d+);$")
            id, xp, retention, mask, count = tonumber(id), tonumber(xp), tonumber(retention), tonumber(mask), tonumber(count)
            key = tonumber(key)
            if not id or id < 1 or id > 10000000 or xp < -1 or xp > 10000000
                or retention > 100 or count > 32 or mask < -1 or mask >= 2^count or key > 2147483647
                or peer.quests[id] or peer.count >= peer.expected then
                pending[sender] = nil
                return
            end
            peer.quests[id] = {status = status, xp = xp >= 0 and xp or nil,
                retention = retention / 100, doneMask = mask >= 0 and mask or nil,
                objectiveCount = count, objectiveKey = key > 0 and key or nil}
            peer.count = peer.count + 1
        end
        if consumed ~= body then pending[sender] = nil end
    elseif kind == "E" then
        pending[sender] = nil
        if body == "" and peer.count == peer.expected then
            peer.ready, peer.time = true, now
            return peer
        end
    end
end
