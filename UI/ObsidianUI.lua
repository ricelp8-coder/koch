-- Obsidian UI wrapper (Diamond Hub API on top of the Obsidian library), loaded by Cameraman_TD, Sorcerer_TD and Doors.
-- Called as loadstring(src)(UIX, runKey); returns the library table.
local UIX, RUN = ...
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local genv = (getgenv and getgenv()) or _G
    local REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

    if genv.__obsidian_lib then
        pcall(function() genv.__obsidian_lib:Unload() end)
        genv.__obsidian_lib = nil
    end
    pcall(function()
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetChildren()) do
            if g.Name:sub(1, 10) == "DiamondUI_" or g.Name == "cm_menu" then g:Destroy() end
        end
    end)

    local function fetch(file)
        local ok, res = pcall(function() return loadstring(game:HttpGet(REPO .. file))() end)
        if not ok or res == nil then
            error("Obsidian: failed to load " .. file .. ": " .. tostring(res), 0)
        end
        return res
    end
    local Library = fetch("Library.lua")
    local ThemeManager = fetch("addons/ThemeManager.lua")
    genv.__obsidian_lib = Library

    Library:OnUnload(function()
        if genv.__obsidian_lib ~= Library then return end
        genv.__obsidian_lib = nil
        genv[RUN .. "_run"] = nil
        if genv[RUN .. "_privDestroy"] then pcall(genv[RUN .. "_privDestroy"]) end
    end)

    local Lib = {Version = "2.0.0", Windows = {}, Library = Library}
    local Window = {}
    Window.__index = Window
    local Tab = {}
    Tab.__index = Tab
    local Section = {}
    Section.__index = Section

    local function safe(cb, ...)
        if type(cb) ~= "function" then return end
        local ok, err = pcall(cb, ...)
        if not ok then warn("[DiamondHub] callback error: " .. tostring(err)) end
    end
    local function sanitize(s)
        s = tostring(s or ""):gsub("[^%w _%-#]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        return s:sub(1, 24)
    end
    Lib.Sanitize = sanitize
    local function P(keys, ...)
        local first = ...
        if type(first) == "table" then return first end
        local args = {...}
        local o = {}
        for i, k in ipairs(keys) do o[k] = args[i] end
        return o
    end
    function Lib.SetAutoExecuteToggle(v)
        Lib.AESilent = true
        pcall(function() Library.Toggles.DiamondAutoExecute:SetValue(v and true or false) end)
        Lib.AESilent = false
    end

    function Lib.Rich(text, color)
        return string.format('<font color="rgb(%d,%d,%d)">%s</font>',
            math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5), tostring(text))
    end

    function Lib.MakeStore(folder, memKey)
        local hasFS = type(writefile) == "function" and type(readfile) == "function"
            and type(listfiles) == "function" and type(delfile) == "function"
            and type(isfolder) == "function" and type(makefolder) == "function"
        local mem = genv[memKey] or {items = {}, auto = nil}
        genv[memKey] = mem
        if hasFS then
            pcall(function()
                local root = folder:match("^([^/]+)")
                if root and not isfolder(root) then makefolder(root) end
                if not isfolder(folder) then makefolder(folder) end
            end)
        end
        local S = {hasFS = hasFS}
        local function path(n) return folder .. "/" .. n .. ".json" end
        function S.list()
            local names = {}
            if hasFS then
                local ok, files = pcall(listfiles, folder)
                if ok and type(files) == "table" then
                    for _, f in ipairs(files) do
                        local n = tostring(f):match("([^/\\]+)%.json$")
                        if n then table.insert(names, n) end
                    end
                end
            else
                for n in pairs(mem.items) do table.insert(names, n) end
            end
            table.sort(names)
            return names
        end
        function S.exists(n)
            for _, x in ipairs(S.list()) do
                if x == n then return true end
            end
            return false
        end
        function S.read(n)
            if not hasFS then return mem.items[n] end
            local ok, raw = pcall(readfile, path(n))
            if not ok or type(raw) ~= "string" then return nil end
            local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(d) == "table" then return d end
            return nil
        end
        function S.write(n, t)
            if not hasFS then
                mem.items[n] = t
                return true
            end
            return (pcall(function() writefile(path(n), HttpService:JSONEncode(t)) end))
        end
        function S.delete(n)
            if not hasFS then
                mem.items[n] = nil
                return true
            end
            return (pcall(delfile, path(n)))
        end
        function S.getAuto()
            if not hasFS then return mem.auto end
            local ok, raw = pcall(readfile, folder .. "/_autoload.txt")
            if ok and type(raw) == "string" then
                local n = raw:match("^%s*(.-)%s*$")
                if n and n ~= "" then return n end
            end
            return nil
        end
        function S.setAuto(n)
            if not hasFS then
                mem.auto = n
                return
            end
            pcall(writefile, folder .. "/_autoload.txt", n or "")
        end
        return S
    end

    local function stateIO(folder)
        local hasFS = type(writefile) == "function" and type(readfile) == "function"
            and type(isfolder) == "function" and type(makefolder) == "function"
        local memKey = "dui_state_" .. folder
        local path = folder .. "/settings.json"
        if hasFS then
            pcall(function()
                local root = folder:match("^([^/]+)")
                if root and not isfolder(root) then makefolder(root) end
                if not isfolder(folder) then makefolder(folder) end
            end)
        end
        local io = {hasFS = hasFS}
        function io.read()
            if not hasFS then return genv[memKey] end
            local ok, raw = pcall(readfile, path)
            if not ok or type(raw) ~= "string" then return nil end
            local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(d) == "table" then return d end
            return nil
        end
        function io.write(t)
            if not hasFS then
                genv[memKey] = t
                return true
            end
            return (pcall(function() writefile(path, HttpService:JSONEncode(t)) end))
        end
        return io
    end
    local function encodeVal(v)
        if typeof(v) == "Color3" then return {__c3 = {v.R, v.G, v.B}} end
        return v
    end
    local function decodeVal(v)
        if type(v) == "table" and type(v.__c3) == "table" then
            return Color3.new(v.__c3[1] or 0, v.__c3[2] or 0, v.__c3[3] or 0)
        end
        return v
    end

    local recent = {}
    function Lib:Notify(a, b, c)
        local o = type(a) == "table" and a or {Title = a, Content = b, Duration = c}
        local title = tostring(o.Title or "")
        local content = tostring(o.Content or o.Description or "")
        local dur = o.Duration or o.Time or 3
        local key = title .. "|" .. content
        local now = os.clock()
        if recent[key] and recent[key] > now then return end
        recent[key] = now + math.min(dur, 1.5)
        if o.Type == "Warning" then
            title = title .. " - Warning"
        elseif o.Type == "Error" then
            title = title .. " - Error"
        end
        local ok, err = pcall(function()
            Library:Notify({Title = title, Description = content, Time = dur})
        end)
        if not ok then warn("[DiamondHub] notify failed: " .. tostring(err)) end
    end

    function Lib.IsOwnGui(g)
        if not g then return false end
        if g == Library.ScreenGui then return true end
        local n = g.Name
        return n:sub(1, 10) == "DiamondUI_" or n:sub(1, 8) == "Obsidian"
    end

    local function finish(obj, el)
        obj.Element = el
        function obj:SetVisible(v)
            v = v and true or false
            local ok = el and pcall(function() el:SetVisible(v) end)
            if not ok and el and el.Holder then pcall(function() el.Holder.Visible = v end) end
        end
        function obj:SetDisabled(v)
            if el then pcall(function() el:SetDisabled(v and true or false) end) end
        end
        function obj:Destroy()
            if el then pcall(function() el:Destroy() end) end
        end
        return obj
    end

    local function fitToggleLabel(el)
        pcall(function()
            local holder = el.Holder
            if not holder then return end
            for _, d in ipairs(holder:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    d.TextTruncate = Enum.TextTruncate.AtEnd
                    d.TextWrapped = false
                    if d.Size.X.Scale >= 0.99 then
                        d.Size = UDim2.new(d.Size.X.Scale, d.Size.X.Offset - 40, d.Size.Y.Scale, d.Size.Y.Offset)
                    end
                    break
                end
            end
        end)
    end

    local function drive(ctl, silent, setter)
        ctl.fired = false
        if silent then ctl.muted = ctl.muted + 1 end
        pcall(setter)
        if silent then ctl.muted = ctl.muted - 1 end
        return ctl.fired
    end

    function Section:_break()
        if self._grid then self._grid.pending = nil end
    end
    function Section:_reg(flag, obj)
        if flag then self.Window.Flags[flag] = obj end
    end

    function Section:AddLabel(...)
        self:_break()
        local o = P({"Text"}, ...)
        local text = tostring(o.Text or "")
        local el = self.Box:AddLabel({Text = text, DoesWrap = true})
        pcall(function() el.TextLabel.RichText = true end)
        local obj = {}
        function obj:SetText(t)
            text = tostring(t)
            pcall(function() el:SetText(text) end)
        end
        function obj:Get() return text end
        function obj:Set(t) obj:SetText(t) end
        return finish(obj, el)
    end

    function Section:AddParagraph(...)
        self:_break()
        local o = P({"Title", "Content"}, ...)
        local title, content = tostring(o.Title or ""), tostring(o.Content or "")
        local function compose()
            if title == "" then return content end
            if content == "" then return "<b>" .. title .. "</b>" end
            return "<b>" .. title .. "</b>\n" .. content
        end
        local el = self.Box:AddLabel({Text = compose(), DoesWrap = true})
        pcall(function() el.TextLabel.RichText = true end)
        local obj = {}
        function obj:SetTitle(x)
            title = tostring(x)
            pcall(function() el:SetText(compose()) end)
        end
        function obj:SetContent(x)
            content = tostring(x)
            pcall(function() el:SetText(compose()) end)
        end
        return finish(obj, el)
    end

    function Section:AddDivider()
        self:_break()
        local el = self.Box:AddDivider()
        return finish({}, el)
    end

    function Section:AddButton(...)
        local o = P({"Name", "Callback"}, ...)
        local info = {
            Text = tostring(o.Name or "Button"),
            Func = function() safe(o.Callback) end,
            Tooltip = o.Tooltip,
            Risky = o.Style == "Danger",
        }
        local grid = self._grid
        local el
        if grid and grid.cols >= 2 and grid.pending then
            el = grid.pending:AddButton(info)
            grid.pending = nil
        else
            el = self.Box:AddButton(info)
            if grid and grid.cols >= 2 then grid.pending = el end
        end
        local obj = {}
        function obj:SetText(t)
            pcall(function() el:SetText(tostring(t)) end)
        end
        function obj:SetCallback(cb) o.Callback = cb end
        return finish(obj, el)
    end

    function Section:AddToggle(...)
        self:_break()
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local state = o.Default == true
        local ctl = {muted = 0, fired = false}
        local name = tostring(o.Name or "Toggle")
        local el = self.Box:AddToggle(win:_index(o.Flag), {
            Text = name, Tooltip = o.Tooltip or (#name > 26 and name or nil), Default = state,
            Callback = function(v)
                state = v and true or false
                ctl.fired = true
                if ctl.muted == 0 then safe(o.Callback, state) end
            end,
        })
        fitToggleLabel(el)
        local obj = {NoSave = o.NoSave}
        function obj:Get() return state end
        function obj:Set(v, silent)
            v = v and true or false
            if v == state then return end
            drive(ctl, silent, function() el:SetValue(v) end)
            state = v
            if not silent and not ctl.fired then safe(o.Callback, state) end
        end
        self:_reg(o.Flag, obj)
        return finish(obj, el)
    end

    function Section:AddSlider(...)
        self:_break()
        local o = P({"Name", "Min", "Max", "Default", "Callback"}, ...)
        local win = self.Window
        local min, max = tonumber(o.Min) or 0, tonumber(o.Max) or 100
        if max < min then min, max = max, min end
        local step = tonumber(o.Step) or 1
        local rounding = step >= 1 and 0 or (step >= 0.1 and 1 or 2)
        local value = math.clamp(tonumber(o.Default) or min, min, max)
        local ctl = {muted = 0, fired = false}
        local el = self.Box:AddSlider(win:_index(o.Flag), {
            Text = tostring(o.Name or "Slider"), Default = value, Min = min, Max = max, Rounding = rounding,
            Suffix = o.Suffix and tostring(o.Suffix) or nil, Tooltip = o.Tooltip,
            Callback = function(v)
                value = v
                ctl.fired = true
                if ctl.muted == 0 then safe(o.Callback, v) end
            end,
        })
        local obj = {NoSave = o.NoSave}
        function obj:Get() return value end
        function obj:Set(v, silent)
            local n = tonumber(v)
            if not n then return end
            n = math.clamp(n, min, max)
            drive(ctl, silent, function() el:SetValue(n) end)
            value = n
            if not silent and not ctl.fired then safe(o.Callback, n) end
        end
        self:_reg(o.Flag, obj)
        return finish(obj, el)
    end

    function Section:AddInput(...)
        self:_break()
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local value = tostring(o.Default or "")
        local ctl = {muted = 0, fired = false}
        local el = self.Box:AddInput(win:_index(o.Flag), {
            Text = tostring(o.Name or "Input"), Default = value, Numeric = o.Numeric == true, Finished = true,
            ClearTextOnFocus = o.ClearOnFocus == true, Placeholder = o.Placeholder and tostring(o.Placeholder) or nil,
            Tooltip = o.Tooltip,
            Callback = function(v)
                value = tostring(v or "")
                ctl.fired = true
                if ctl.muted == 0 then safe(o.Callback, value, true) end
            end,
        })
        local obj = {NoSave = o.NoSave}
  local box
  pcall(function()
  local holder = el.Holder or el.Textbox
  for _, d in ipairs(holder:GetDescendants()) do
  if d:IsA("TextBox") then box = d break end
  end
  if not box and holder:IsA("TextBox") then box = holder end
  end)
  function obj:Get()
  if box and box.Parent then
  value = tostring(box.Text or "")
  end
  return value
  end
  function obj:Set(v, silent)
  local s = tostring(v or "")
  drive(ctl, silent, function() el:SetValue(s) end)
            value = s
            if not silent and not ctl.fired then safe(o.Callback, s, false) end
        end
        self:_reg(o.Flag, obj)
        return finish(obj, el)
    end

    function Section:AddKeybind(...)
        self:_break()
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local name = tostring(o.Name or "Keybind")
        local lbl = self.Box:AddLabel(name)
        local el = lbl:AddKeyPicker(win:_index(o.Flag), {
            Default = o.Default or "None", Mode = o.Mode or "Press", Text = name, NoUI = false,
            Callback = function() safe(o.Callback) end,
        })
        local obj = {NoSave = o.NoSave}
        function obj:Get() return el.Value end
        function obj:Set(v)
            pcall(function() el:SetValue({tostring(v or "None"), el.Mode}) end)
        end
        self:_reg(o.Flag, obj)
        return finish(obj, lbl)
    end

    function Section:AddDropdown(...)
        self:_break()
        local o = P({"Name", "Options", "Default", "Callback"}, ...)
        local win = self.Window
        local map, strs = {}, {}
        local function rebuild(list)
            map, strs = {}, {}
            for i, v in ipairs(type(list) == "table" and list or {}) do
                local s = tostring(v)
                strs[i] = s
                map[s] = v
            end
        end
        rebuild(o.Options)
        local searchable = o.Searchable
        if searchable == nil then searchable = #strs > 8 end
        local value
        local defStr
        if o.Default ~= nil and map[tostring(o.Default)] ~= nil then
            defStr = tostring(o.Default)
            value = map[defStr]
        end
        local ctl = {muted = 0, fired = false}
        local el = self.Box:AddDropdown(win:_index(o.Flag), {
            Text = tostring(o.Name or "Dropdown"), Values = strs, Default = defStr, Multi = false,
            Searchable = searchable == true, Tooltip = o.Tooltip,
            Callback = function(s)
                value = s ~= nil and map[tostring(s)] or nil
                ctl.fired = true
                if ctl.muted == 0 and value ~= nil then safe(o.Callback, value) end
            end,
        })
        local obj = {NoSave = o.NoSave}
        function obj:Get() return value end
        function obj:Set(v, silent)
            local s = v ~= nil and tostring(v) or nil
            if s ~= nil and map[s] == nil then s = nil end
            if s == nil then
                value = nil
                drive(ctl, true, function() el:SetValue(nil) end)
                return
            end
            drive(ctl, silent, function() el:SetValue(s) end)
            value = map[s]
            if not silent and not ctl.fired then safe(o.Callback, value) end
        end
        function obj:SetOptions(list)
            rebuild(list)
            local keep = value ~= nil and map[tostring(value)] ~= nil
            pcall(function() el:SetValues(strs) end)
            if keep then
                drive(ctl, true, function() el:SetValue(tostring(value)) end)
            else
                value = nil
                drive(ctl, true, function() el:SetValue(nil) end)
            end
        end
        obj.Refresh = obj.SetOptions
        self:_reg(o.Flag, obj)
        return finish(obj, el)
    end

    function Section:AddGrid(...)
        local o = P({"Columns", "CellHeight"}, ...)
        local cols = math.max(1, math.floor(tonumber(o.Columns) or 2))
        return setmetatable({
            Window = self.Window, Box = self.Box, Tab = self.Tab, _grid = {cols = cols},
        }, Section)
    end

    function Tab:AddSection(title, opts)
        opts = opts or {}
        self._count = self._count + 1
        local info = {
            Side = self._side or ((self._count % 2 == 1) and "Left" or "Right"),
            Name = (title and title ~= "") and tostring(title) or self.Name,
        }
        if opts.Collapsed == true then info.Collapsed = true end
        local box = self.Obs:AddGroupbox(info)
        return setmetatable({Window = self.Window, Box = box, Tab = self}, Section)
    end
    function Tab:_default()
        if not self._def then self._def = self:AddSection(nil) end
        return self._def
    end
    for _, name in ipairs({"AddLabel", "AddParagraph", "AddDivider", "AddButton", "AddToggle", "AddSlider",
        "AddInput", "AddDropdown", "AddGrid", "AddKeybind"}) do
        Tab[name] = function(self, ...)
            return Section[name](self:_default(), ...)
        end
    end

    function Window:_index(flag)
        self._uid = (self._uid or 0) + 1
        if flag and not Library.Options[flag] and not Library.Toggles[flag] then return flag end
        return (flag or "el") .. "_" .. self._uid
    end

    function Window:AddTab(name, opts)
        opts = type(opts) == "table" and opts or {}
        local tab = setmetatable({
            Window = self, Name = tostring(name), _count = 0,
            Obs = self.Obs:AddTab(tostring(name), opts.Icon),
        }, Tab)
        table.insert(self.Tabs, tab)
        return tab
    end

    function Window:AddSettingsTab(name)
        local win = self
        local tab = self:AddTab(name or "Settings", {Icon = "settings"})
        local menu = tab.Obs:AddGroupbox({Side = "Left", Name = "Menu", IconName = "wrench"})
        pcall(function()
            menu:AddToggle("ObsKeybindMenu", {
                Text = "Open Keybind Menu", Default = Library.KeybindFrame.Visible,
                Callback = function(v) Library.KeybindFrame.Visible = v end,
            })
        end)
        pcall(function()
            menu:AddToggle("ObsCustomCursor", {
                Text = "Custom Cursor", Default = Library.ShowCustomCursor,
                Callback = function(v) Library.ShowCustomCursor = v end,
            })
        end)
        pcall(function()
            menu:AddDropdown("ObsNotifySide", {
                Values = {"Left", "Right"}, Default = "Right", Text = "Notification Side",
                Callback = function(v) Library:SetNotifySide(v) end,
            })
        end)
        pcall(function()
            menu:AddDropdown("ObsDPI", {
                Values = {"75%", "100%", "125%", "150%", "175%"}, Default = "100%", Text = "DPI Scale",
                Callback = function(v) Library:SetDPIScale(tonumber((tostring(v):gsub("%%", "")))) end,
            })
        end)
        pcall(function()
            menu:AddDivider()
            menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
                Default = "RightShift", NoUI = true, Text = "Menu keybind",
            })
            Library.ToggleKeybind = Library.Options.MenuKeybind
        end)
        pcall(function()
            local scriptBox = tab.Obs:AddGroupbox({Side = "Right", Name = "Script", IconName = "power"})
            Lib.AEToggle = scriptBox:AddToggle("DiamondAutoExecute", {
                Text = "Auto Execute", Default = false,
                Tooltip = "Reruns the script after every teleport",
                Callback = function(v)
                    if Lib.AESilent then return end
                    if Lib.OnAutoExecute then Lib.OnAutoExecute(v) end
                end,
            })
            scriptBox:AddButton("Unload", function() Library:Unload() end)
            scriptBox:AddDropdown("DiamondUIChoice", {
                Values = UIX.names, Default = UIX.active, Text = "UI Library",
                Tooltip = "Obsidian UI is the default. Diamond UI is the older custom menu. Changing it reloads the script",
                Callback = function(v)
                    if v ~= UIX.active then UIX.switch(v, function() Library:Unload() end) end
                end,
            })
        end)
        local ok, err = pcall(function()
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder(win.ConfigFolder)
            ThemeManager:ApplyToTab(tab.Obs)
        end)
        if not ok then warn("[DiamondHub] theme manager unavailable: " .. tostring(err)) end
        tab._side = "Right"
        return tab
    end

    function Window:SetLoadOrder(list)
        self._loadLast = type(list) == "table" and list or {}
    end

    function Window:_snapshot()
        local flags, keys = {}, {}
        for flag, comp in pairs(self.Flags) do
            if not comp.NoSave and comp.Get then
                local ok, v = pcall(function() return comp:Get() end)
                if ok and v ~= nil then
                    local ev = encodeVal(v)
                    if pcall(function() return HttpService:JSONEncode({ev}) end) then
                        flags[flag] = ev
                        keys[#keys + 1] = flag
                    end
                end
            end
        end
        table.sort(keys)
        local sig = {}
        for i, k in ipairs(keys) do sig[i] = k .. "=" .. HttpService:JSONEncode({flags[k]}) end
        return flags, table.concat(sig, "\n")
    end

    function Window:RestoreState()
        local io = self._stateIO
        local d = io.read()
        local restored = false
        if type(d) == "table" and type(d.flags) == "table" then
            restored = true
            local late = {}
            for _, fl in ipairs(self._loadLast or {}) do late[fl] = true end
            local function applyFlag(flag, v)
                local comp = self.Flags[flag]
                if comp and not comp.NoSave and comp.Set then
                    pcall(function() comp:Set(decodeVal(v)) end)
                end
            end
            for flag, v in pairs(d.flags) do
                if not late[flag] then applyFlag(flag, v) end
            end
            for _, fl in ipairs(self._loadLast or {}) do
                if d.flags[fl] ~= nil then applyFlag(fl, d.flags[fl]) end
            end
        end
        local _, last = self:_snapshot()
        task.spawn(function()
            while not Library.Unloaded do
                task.wait(0.4)
                local flags, cur = self:_snapshot()
                if cur ~= last and io.write({v = 2, flags = flags}) then last = cur end
            end
        end)
        return restored
    end

    function Window:Notify(a, b, c) Lib:Notify(a, b, c) end
    function Window:Toggle(v) pcall(function() Library:Toggle(v) end) end
    function Window:Destroy() pcall(function() Library:Unload() end) end

    function Lib:CreateWindow(a, b)
        local o = type(a) == "table" and a or {Title = a, Subtitle = b}
        local self = setmetatable({}, Window)
        self.Title = tostring(o.Title or "Window")
        self.Subtitle = tostring(o.Subtitle or "")
        self.ConfigFolder = tostring(o.ConfigFolder or "DiamondHub")
        self.Flags, self.Tabs = {}, {}
        self._stateIO = stateIO(self.ConfigFolder)
        local PALETTE = {
            BackgroundColor = "070a16", MainColor = "0d1228", AccentColor = "3d6bff",
            OutlineColor = "1b2554", FontColor = "eef2ff",
        }
        pcall(function()
            for k, hex in pairs(PALETTE) do Library.Scheme[k] = Color3.fromHex(hex) end
            local def = ThemeManager.BuiltInThemes and ThemeManager.BuiltInThemes["Default"]
            if def and type(def[2]) == "table" then
                for k, hex in pairs(PALETTE) do def[2][k] = hex end
            end
        end)
        self.Obs = Library:CreateWindow({
            Title = self.Title, Footer = self.Subtitle, NotifySide = "Right", ShowCustomCursor = false,
            Size = UDim2.fromOffset(740, 500), Center = true, AutoShow = true,
        })
        self.Gui = Library.ScreenGui
        pcall(function()
            for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text == self.Title then
                    d.TextXAlignment = Enum.TextXAlignment.Left
                    local parent = d.Parent
                    local layout = parent and parent:FindFirstChildWhichIsA("UIListLayout")
                    if layout then
                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                        local pad = parent:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", parent)
                        pad.PaddingLeft = UDim.new(0, 8)
                    else
                        d.AnchorPoint = Vector2.new(0, d.AnchorPoint.Y)
                        d.Position = UDim2.new(0, 10, d.Position.Y.Scale, d.Position.Y.Offset)
                    end
                    break
                end
            end
        end)
        table.insert(Lib.Windows, self)
        return self
    end

    return Lib

