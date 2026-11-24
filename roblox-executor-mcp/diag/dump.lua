-- what diag/sniff.lua recorded: one line per bridge id, with its position in identifierStorage
local S = getgenv().__sniff
if not S then return "run diag/sniff.lua first" end
local st = game:GetService("ReplicatedStorage"):FindFirstChild("identifierStorage")
local pos, total = {}, 0
if st then
    for i, c in ipairs(st:GetChildren()) do
        pos[c.Value] = {i = i, k = string.sub(c.Name, 1, 3), h = string.sub(c.Name, -6)}
        total = i
    end
end
local per, order = {}, {}
for _, e in ipairs(S.log) do
    local r = per[e.id]
    if not r then
        r = {n = 0, s = {}, seen = {}}
        per[e.id] = r
        order[#order + 1] = e.id
    end
    r.n = r.n + 1
    if #r.s < 3 and not r.seen[e.b] then
        r.seen[e.b] = true
        r.s[#r.s + 1] = e.b
    end
end
local out = {"sends " .. S.n .. ", ids " .. #order .. ", identifierStorage " .. total}
for _, id in ipairs(order) do
    local r, p = per[id], pos[id]
    out[#out + 1] = string.format("id %s #%s %s x%d  %s", id, p and p.i or "?", p and p.k or "?", r.n, table.concat(r.s, " | "))
end
S.log = {}
return table.concat(out, "\n")
