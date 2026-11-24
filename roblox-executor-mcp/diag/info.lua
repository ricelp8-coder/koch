local out = {}
local function p(s) out[#out + 1] = tostring(s) end
local RS = game:GetService("ReplicatedStorage")
p("place " .. game.PlaceId .. " game " .. game.GameId .. " job " .. tostring(game.JobId))
local ex1, ex2 = nil, nil
if identifyexecutor then ex1, ex2 = identifyexecutor() end
p("executor " .. tostring(ex1) .. " " .. tostring(ex2))
local caps = {}
for _, n in ipairs({"getgc", "hookfunction", "hookmetamethod", "getconnections", "firesignal", "request", "WebSocket",
    "setreadonly", "isreadonly", "getupvalues", "getconstants", "getscriptbytecode", "decompile", "readfile", "writefile",
    "checkcaller", "newcclosure", "getloadedmodules", "getrawmetatable", "setclipboard", "mouse1click"}) do
    local ok, v = pcall(function() return loadstring("return " .. n)() end)
    caps[#caps + 1] = n .. "=" .. ((ok and v ~= nil) and "y" or "n")
end
p("caps " .. table.concat(caps, " "))
local st = RS:FindFirstChild("identifierStorage")
if st then
    local ch, sig = st:GetChildren(), {}
    for i, c in ipairs(ch) do
        local k = string.sub(c.Name, 1, 3)
        sig[i] = (k == "UR_" and "U") or (k == "FR_" and "F") or "-"
    end
    p("identifierStorage " .. #ch .. " " .. table.concat(sig))
else
    p("identifierStorage: none")
end
p("dataRemoteEvent " .. tostring(RS:FindFirstChild("dataRemoteEvent")) .. ", metaRemoteEvent " .. tostring(RS:FindFirstChild("metaRemoteEvent")))
local paths = {}
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("ModuleScript") and d.Name == "ClientProcess" then paths[#paths + 1] = d:GetFullName() end
end
p("ClientProcess modules: " .. table.concat(paths, "; "))
local t0 = os.clock()
local all = getgc(true)
local found, n = {}, 0
for i = 1, #all do
    local t = all[i]
    if type(t) == "table" then
        n = n + 1
        if type(rawget(t, "addToQueue")) == "function" and type(rawget(t, "registerBridge")) == "function"
            and type(rawget(t, "connect")) == "function" then
            found[#found + 1] = t
        end
    end
end
p(string.format("gc: %d objects, %d tables, %d queue tables, %.2fs", #all, n, #found, os.clock() - t0))
for i, t in ipairs(found) do
    local keys = {}
    for k, v in pairs(t) do keys[#keys + 1] = tostring(k) .. ":" .. typeof(v) end
    table.sort(keys)
    p("queue#" .. i .. " keys " .. table.concat(keys, ","))
    local f = rawget(t, "addToQueue")
    p("addToQueue " .. tostring(debug.info(f, "s")) .. ":" .. tostring(debug.info(f, "l")))
end
local g = getgenv()
p("legacy script: run=" .. tostring(g.ld_run) .. " saved=" .. tostring(g.ld_net_saved ~= nil))
return table.concat(out, "\n")
