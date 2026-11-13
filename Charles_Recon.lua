-- Charles_Recon.lua
-- Run it BEFORE you put the module into the scanner / start the egg minigame, play the minigame once
-- (win it if you can), then check workspace/DiamondHub/Recon/ for:
--   log.txt        every remote the server sends / you send (spam remotes filtered), with timestamps
--   modules/*.lua  decompiled source of FloorReplicated.Minigames.* and of the ToolClientModule of your tools
--   tree.txt       FloorReplicated + your Backpack/Character tools (children, attributes)
-- Needs: writefile, makefolder, decompile (modules/tree are skipped without decompile). Nothing is fired by this script.

if shared.CharlesRecon then return end
shared.CharlesRecon = true
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local DIR = "DiamondHub/Recon"

pcall(function()
	for _, p in ipairs({ "DiamondHub", DIR, DIR .. "/modules" }) do
		if not isfolder(p) then makefolder(p) end
	end
end)

local SPAM = {
	MotorReplication = true, FootstepRemoteThatWeNeed = true, PingRemote = true, Crouch = true,
	Roomba = true, CheckRevive = true, LiveClock = true, CamShake = true, CamShakeRelative = true,
}

local T0 = os.clock()
local buf = {}
local function ser(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "Instance" then return "<" .. v.ClassName .. " " .. v:GetFullName() .. ">" end
	if t == "string" then return string.format("%q", v) end
	if t == "table" then
		if depth > 2 then return "{...}" end
		local out, n = {}, 0
		for k, x in pairs(v) do
			n += 1
			if n > 20 then out[#out + 1] = "..." break end
			out[#out + 1] = "[" .. ser(k, depth + 1) .. "]=" .. ser(x, depth + 1)
		end
		return "{" .. table.concat(out, ", ") .. "}"
	end
	if t == "number" or t == "boolean" or t == "nil" then return tostring(v) end
	return tostring(v) .. ":" .. t
end
local function log(line)
	buf[#buf + 1] = string.format("[%7.2f] %s", os.clock() - T0, line)
end
local function pack(...)
	local a, out = table.pack(...), {}
	for i = 1, a.n do out[i] = ser(a[i]) end
	return table.concat(out, ", ")
end

local function flush()
	if #buf == 0 or not writefile then return end
	local old = ""
	pcall(function() old = readfile(DIR .. "/log.txt") end)
	pcall(writefile, DIR .. "/log.txt", old .. table.concat(buf, "\n") .. "\n")
	table.clear(buf)
end
task.spawn(function() while task.wait(2) do flush() end end)

-- outgoing remotes
if hookmetamethod and getnamecallmethod and newcclosure then
	local old
	old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local m = getnamecallmethod()
		if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" and not SPAM[self.Name] then
			log("OUT " .. self:GetFullName() .. ":" .. m .. "(" .. pack(...) .. ")")
		end
		return old(self, ...)
	end))
end

-- incoming remotes
local hooked = {}
local function watch(r)
	if hooked[r] or not r:IsA("RemoteEvent") and not r:IsA("UnreliableRemoteEvent") then return end
	hooked[r] = true
	if SPAM[r.Name] then return end
	r.OnClientEvent:Connect(function(...)
		log("IN  " .. r:GetFullName() .. "(" .. pack(...) .. ")")
	end)
end
for _, d in ipairs(RS:GetDescendants()) do watch(d) end
RS.DescendantAdded:Connect(watch)
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("RemoteEvent") then watch(d) end end
workspace.DescendantAdded:Connect(function(d) if d:IsA("RemoteEvent") then watch(d) end end)

-- module dumping
local dumped = {}
local function dump(inst, tag)
	if dumped[inst] or not decompile or not writefile then return end
	dumped[inst] = true
	local ok, src = pcall(decompile, inst)
	local name = (tag .. "." .. inst:GetFullName()):gsub("[^%w%._%-]", "_"):sub(1, 150)
	pcall(writefile, DIR .. "/modules/" .. name .. ".lua", ok and src or ("-- decompile failed: " .. tostring(src)))
	log("DUMP " .. inst:GetFullName())
end

local function dumpMinigames()
	local fr = RS:FindFirstChild("FloorReplicated")
	local mg = fr and fr:FindFirstChild("Minigames")
	if mg then
		for _, m in ipairs(mg:GetDescendants()) do
			if m:IsA("ModuleScript") then dump(m, "minigame") end
		end
	end
end
local function dumpTool(tool)
	if not tool:IsA("Tool") then return end
	log("TOOL " .. tool:GetFullName() .. " attrs=" .. ser(tool:GetAttributes()))
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("ModuleScript") or d:IsA("LocalScript") then dump(d, "tool") end
	end
end

local function tree()
	local out = {}
	local function walk(i, d)
		out[#out + 1] = string.rep("  ", d) .. i.Name .. " [" .. i.ClassName .. "] " .. ser(i:GetAttributes())
		if d < 6 then for _, c in ipairs(i:GetChildren()) do walk(c, d + 1) end end
	end
	local fr = RS:FindFirstChild("FloorReplicated")
	if fr then walk(fr, 0) end
	for _, c in ipairs(LP.Backpack:GetChildren()) do walk(c, 0) end
	if LP.Character then for _, c in ipairs(LP.Character:GetChildren()) do if c:IsA("Tool") then walk(c, 0) end end end
	pcall(writefile, DIR .. "/tree.txt", table.concat(out, "\n"))
end

local function sweep()
	dumpMinigames()
	for _, t in ipairs(LP.Backpack:GetChildren()) do dumpTool(t) end
	if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do dumpTool(t) end end
	tree()
end

LP.Backpack.ChildAdded:Connect(function(t) task.wait(0.5) dumpTool(t) tree() end)
local fr = RS:WaitForChild("FloorReplicated", 30)
if fr then
	fr.DescendantAdded:Connect(function(d)
		if d:IsA("ModuleScript") and d:FindFirstAncestor("Minigames") then task.wait(0.2) dump(d, "minigame") end
	end)
end

-- the game's own minigame handshake (EngageMinigame -> ... -> MinigameControl(token))
local rf = RS:WaitForChild("RemotesFolder", 30)
local eng = rf and rf:FindFirstChild("EngageMinigame")
if eng then
	eng.OnClientEvent:Connect(function(name, ...)
		log("MINIGAME ENGAGE name=" .. ser(name) .. " args=" .. pack(...))
		task.wait(0.5)
		sweep()
	end)
end

sweep()
log("recon ready; start the Charles / egg minigame now")
flush()
print("[CharlesRecon] ready, output in workspace/" .. DIR)
