local HT = {}
assert(loadfile("addon/PlxTogether/Protocol.lua"))("PlxTogether", HT)
local snapshot = {mapID = 1, level = 15, xpMax = 10000, quests = {}}
for id = 1, 300 do
    snapshot.quests[id] = {status = "L", xp = 500, retention = 0.8, doneMask = 5, objectiveCount = 3, objectiveKey = 77}
end
local packets, pending, result = HT.Protocol.Encode(snapshot, 1), {}, nil
for i, packet in ipairs(packets) do
    assert(#packet <= 220, "Respect addon message budget")
    result = HT.Protocol.Receive(pending, packet, "Peer", 100)
    if i < #packets then assert(result == nil, "Never expose a partial snapshot") end
end
assert(result and result.count == 300 and result.quests[1].doneMask == 5 and result.quests[1].objectiveKey == 77, "Round trip objective state")
assert(result.quests[1].retention == 0.8 and result.quests[1].xp == 500)
HT.Protocol.Receive(pending, "B|2|1|15|10000|2", "Peer", 100)
HT.Protocol.Receive(pending, "D|2|1:L:500:100:0:1:77;", "Peer", 100)
assert(not HT.Protocol.Receive(pending, "E|2|", "Peer", 100), "Drop incomplete snapshot")
HT.Protocol.Receive(pending, "B|3|1|15|10000|1", "Peer", 100)
HT.Protocol.Receive(pending, "D|3|1:L:500:100:0:1:77;1:L:500:100:0:1:77;", "Peer", 100)
assert(not pending.Peer, "Drop duplicate quest IDs")
HT.Protocol.Receive(pending, "B|4|1|15|10000|1", "Peer", 100)
HT.Protocol.Receive(pending, "D|4|1:L:500:100:4:1:77;", "Peer", 100)
assert(not pending.Peer, "Reject out-of-range objective masks")
HT.Protocol.Receive(pending, "B|5|1|15|10000|1", "Peer", 100)
assert(not HT.Protocol.Receive(pending, "E|5|", "Peer", 146), "Expire abandoned snapshots")
for _, message in ipairs({"", "B|6|bad", "D|6|bad;", "E|6|bad", string.rep("X", 256)}) do
    assert(pcall(HT.Protocol.Receive, pending, message, "Peer", 100), "Malformed input must not throw")
end
local empty = {mapID = 1, level = 15, xpMax = 10000, quests = {}}
for _, packet in ipairs(HT.Protocol.Encode(empty, 7)) do result = HT.Protocol.Receive(pending, packet, "Peer", 100) end
assert(result and result.count == 0, "An empty zone snapshot is valid")
print("Party protocol tests passed.")

local pointPacket = HT.Protocol.EncodeLocation(1, 0.23456, 0.8)
local point = HT.Protocol.ReceiveLocation(pointPacket, 123)
assert(point and point.mapID == 1 and math.abs(point.x - 0.2346) < 0.00001 and point.time == 123)
for _, bad in ipairs({"P|1|10001|0", "P|1|-1|0", "P|0|0|0", "P|1|abc|0", "P|1|0|0|extra"}) do
    assert(not HT.Protocol.ReceiveLocation(bad, 123), "Reject malformed party coordinates")
end
assert(not HT.Protocol.EncodeLocation(1, 2, 0))
local done = {mapID=1,level=15,xpMax=10000,quests={[5]={status="C"},[6]={status="V",xp=500}}}
local restored
for _, packet in ipairs(HT.Protocol.Encode(done, 8)) do restored=HT.Protocol.Receive(pending,packet,"Peer",100) or restored end
assert(restored.quests[5].status=="C" and restored.quests[6].status=="V")
print("Location and unlock-state protocol tests passed.")
