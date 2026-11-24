-- records every BridgeNet2 send (id + short look at the data); read it with diag/dump.lua
local g = getgenv()
local RS = game:GetService("ReplicatedStorage")
g.__sniff = g.__sniff or {log = {}, n = 0}
local S = g.__sniff
if S.installed then return "already installed, " .. S.n .. " sends so far" end
local function brief(v, d)
    local t = typeof(v)
    if t == "string" then return string.format("%q", #v > 40 and (string.sub(v, 1, 40) .. "..") or v) end
    if t == "number" then return string.format("%.4g", v) end
    if t == "boolean" or t == "nil" then return tostring(v) end
    if t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
    if t == "Instance" then return "<" .. v.ClassName .. " " .. v.Name .. ">" end
    if t == "table" then
        if d >= 2 then return "{..}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n = n + 1
            if n > 6 then parts[#parts + 1] = ".." break end
            parts[#parts + 1] = (type(k) == "number" and "" or (tostring(k) .. "=")) .. brief(x, d + 1)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return t
end
local all = getgc(true)
local found = {}
for i = 1, #all do
    local t = all[i]
    if type(t) == "table" and type(rawget(t, "addToQueue")) == "function" and type(rawget(t, "registerBridge")) == "function"
        and type(rawget(t, "connect")) == "function" then
        found[#found + 1] = t
    end
end
if #found == 0 then return "BridgeNet2 queue not found" end
S.W = S.W or setmetatable({}, {__mode = "k"})
for _, t in ipairs(found) do
    local cur = rawget(t, "addToQueue")
    local base = S.W[cur] or cur
    local function wrapper(id, data)
        S.n = S.n + 1
        if #S.log < 600 then
            local ok, b = pcall(brief, data, 0)
            S.log[#S.log + 1] = {t = os.clock(), id = id, b = ok and b or "?"}
        end
        return base(id, data)
    end
    S.W[wrapper] = base
    rawset(t, "addToQueue", wrapper)
end
S.installed = true
return "sniff installed on " .. #found .. " queue table(s)"
