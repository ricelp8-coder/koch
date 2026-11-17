-- Diamond UI (the original custom menu), loaded by Cameraman_TD, Sorcerer_TD and Doors.
-- Called as loadstring(src)(UIX, runKey); returns the library table.
local UIX, RUN = ...
    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local pg = lp:WaitForChild("PlayerGui")
    local genv = (getgenv and getgenv()) or _G

    for _, g in ipairs(pg:GetChildren()) do
        if g.Name:sub(1, 10) == "DiamondUI_" or g.Name == "cm_menu" then g:Destroy() end
    end
    if genv.dui_conns then
        for _, c in ipairs(genv.dui_conns) do
            pcall(function() c:Disconnect() end)
        end
    end
    genv.dui_conns = {}
    local function keep(c)
        table.insert(genv.dui_conns, c)
        return c
    end

    local Lib = {Version = "1.0.0", Windows = {}, _order = 1000, _toasts = {}, _toastList = {}, Name = "Diamond UI"}
    local Window = {}
    Window.__index = Window
    local Tab = {}
    Tab.__index = Tab
    local Container = {}
    Container.__index = Container

    local THEMES = {
        Dark = {
            Background = Color3.fromRGB(15, 15, 19), Topbar = Color3.fromRGB(21, 21, 27),
            Sidebar = Color3.fromRGB(19, 19, 24), Surface = Color3.fromRGB(25, 25, 32),
            Element = Color3.fromRGB(34, 34, 43), ElementHover = Color3.fromRGB(44, 44, 56),
            Stroke = Color3.fromRGB(50, 50, 64), Text = Color3.fromRGB(238, 238, 245),
            SubText = Color3.fromRGB(148, 150, 168), Accent = Color3.fromRGB(86, 138, 255),
            Success = Color3.fromRGB(64, 208, 128), Warning = Color3.fromRGB(255, 188, 66),
            Danger = Color3.fromRGB(240, 82, 94),
        },
        Light = {
            Background = Color3.fromRGB(240, 241, 246), Topbar = Color3.fromRGB(250, 250, 253),
            Sidebar = Color3.fromRGB(245, 246, 250), Surface = Color3.fromRGB(255, 255, 255),
            Element = Color3.fromRGB(236, 238, 245), ElementHover = Color3.fromRGB(224, 227, 237),
            Stroke = Color3.fromRGB(214, 217, 228), Text = Color3.fromRGB(30, 32, 44),
            SubText = Color3.fromRGB(104, 108, 128), Accent = Color3.fromRGB(56, 112, 245),
            Success = Color3.fromRGB(34, 170, 98), Warning = Color3.fromRGB(230, 150, 20),
            Danger = Color3.fromRGB(220, 60, 72),
        },
        Midnight = {
            Background = Color3.fromRGB(12, 10, 22), Topbar = Color3.fromRGB(18, 15, 32),
            Sidebar = Color3.fromRGB(16, 13, 28), Surface = Color3.fromRGB(22, 18, 40),
            Element = Color3.fromRGB(32, 27, 56), ElementHover = Color3.fromRGB(42, 36, 72),
            Stroke = Color3.fromRGB(52, 45, 88), Text = Color3.fromRGB(240, 236, 255),
            SubText = Color3.fromRGB(150, 142, 190), Accent = Color3.fromRGB(150, 100, 255),
            Success = Color3.fromRGB(80, 220, 150), Warning = Color3.fromRGB(255, 196, 80),
            Danger = Color3.fromRGB(255, 90, 110),
        },
        Ocean = {
            Background = Color3.fromRGB(10, 18, 24), Topbar = Color3.fromRGB(14, 26, 34),
            Sidebar = Color3.fromRGB(12, 22, 30), Surface = Color3.fromRGB(17, 31, 41),
            Element = Color3.fromRGB(24, 44, 58), ElementHover = Color3.fromRGB(32, 58, 76),
            Stroke = Color3.fromRGB(40, 72, 92), Text = Color3.fromRGB(232, 246, 250),
            SubText = Color3.fromRGB(130, 170, 186), Accent = Color3.fromRGB(36, 196, 200),
            Success = Color3.fromRGB(70, 220, 140), Warning = Color3.fromRGB(255, 190, 80),
            Danger = Color3.fromRGB(245, 90, 100),
        },
    }
    Lib.Themes = THEMES

    local function copy(t)
        local r = {}
        for k, v in pairs(t) do r[k] = v end
        return r
    end

    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props or {}) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end

    local function round(o, r)
        return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o)
    end

    local function padding(o, l, t, r, b)
        return new("UIPadding", {
            PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
            PaddingRight = UDim.new(0, r or l), PaddingBottom = UDim.new(0, b or t),
        }, o)
    end

    local TI = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function tween(o, props, info)
        local t = TweenService:Create(o, info or TI, props)
        t:Play()
        return t
    end

    local function safe(cb, ...)
        if type(cb) ~= "function" then return end
        local ok, err = pcall(cb, ...)
        if not ok then warn("[DiamondUI] callback error: " .. tostring(err)) end
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
        pcall(function() if Lib.AEToggle then Lib.AEToggle:Set(v and true or false, true) end end)
        Lib.AESilent = false
    end
    function Lib.IsOwnGui(g)
        if not g then return false end
        return g.Name:sub(1, 10) == "DiamondUI_"
    end
    function Lib.Unload()
        if Lib.Unloaded then return end
        Lib.Unloaded = true
        local lib = Lib.Library
        if lib then
            lib.Unloaded = true
            while #lib._unload > 0 do
                local fn = table.remove(lib._unload, 1)
                pcall(fn)
            end
        end
        local list = {}
        for _, w in ipairs(Lib.Windows) do list[#list + 1] = w end
        for _, w in ipairs(list) do pcall(function() w:Destroy() end) end
        pcall(function() if Lib._nGui then Lib._nGui:Destroy() end end)
        for _, c in ipairs(genv.dui_conns or {}) do pcall(function() c:Disconnect() end) end
        genv.dui_conns = {}
        genv[RUN .. "_run"] = nil
        if genv[RUN .. "_privDestroy"] then pcall(genv[RUN .. "_privDestroy"]) end
    end

    function Lib.Rich(text, color)
        return string.format('<font color="rgb(%d,%d,%d)">%s</font>',
            math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5), tostring(text))
    end

    local function trackDrag(input, onMove, onEnd)
        local conns, done = {}, false
        local function finish()
            if done then return end
            done = true
            for _, c in ipairs(conns) do c:Disconnect() end
            if onEnd then onEnd() end
        end
        table.insert(conns, UIS.InputChanged:Connect(function(i)
            if i == input or (input.UserInputType == Enum.UserInputType.MouseButton1
                and i.UserInputType == Enum.UserInputType.MouseMovement) then
                onMove(i.Position)
            end
        end))
        table.insert(conns, UIS.InputEnded:Connect(function(i)
            if i == input then finish() end
        end))
        table.insert(conns, input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then finish() end
        end))
    end

    local function isPointer(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
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

    local function ensureNotify()
        if Lib._nList and Lib._nList.Parent then return end
        local g = new("ScreenGui", {
            Name = "DiamondUI_Notify", ResetOnSpawn = false, IgnoreGuiInset = false,
            DisplayOrder = 100000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        g.Parent = pg
        local list = new("Frame", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 104),
            Size = UDim2.new(0, 250, 1, -112), BackgroundTransparency = 1,
        }, g)
        new("UIListLayout", {
            Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top,
        }, list)
        Lib._nGui, Lib._nList = g, list
    end

    function Lib:Notify(a, b, c)
        local o = type(a) == "table" and a or {Title = a, Content = b, Duration = c}
        if Lib.Tr then
            local copy = {}
            for k, v in pairs(o) do copy[k] = v end
            if type(copy.Title) == "string" then copy.Title = Lib.Tr(copy.Title) end
            if type(copy.Content) == "string" then copy.Content = Lib.Tr(copy.Content) end
            o = copy
        end
        local ok, err = pcall(function()
            ensureNotify()
            local win1 = Lib.Windows[1]
            local th = (win1 and win1.Theme) or THEMES.Dark
            local dur = o.Duration or 3
            local key = tostring(o.Title) .. "|" .. tostring(o.Content)
            local ex = Lib._toasts[key]
            if ex and ex.alive then
                ex.expire = os.clock() + dur
                return
            end

            local alive = {}
            for _, t in ipairs(Lib._toastList) do
                if t.alive then table.insert(alive, t) end
            end
            Lib._toastList = alive
            while #Lib._toastList >= 4 do
                local oldest = table.remove(Lib._toastList, 1)
                oldest.expire = 0
            end

            local kind = o.Type or "Info"
            local col = th.Accent
            if kind == "Success" then col = th.Success
            elseif kind == "Warning" then col = th.Warning
            elseif kind == "Error" then col = th.Danger end

            Lib._seq = (Lib._seq or 0) + 1
            local card = new("CanvasGroup", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = th.Surface, BorderSizePixel = 0, GroupTransparency = 1, LayoutOrder = Lib._seq,
            }, Lib._nList)
            round(card, 8)
            new("UIStroke", {Color = th.Stroke, Thickness = 1}, card)
            new("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0}, card)
            local inner = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            }, card)
            padding(inner, 14, 8, 10, 8)
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, inner)
            if o.Title and tostring(o.Title) ~= "" then
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                    Text = tostring(o.Title), RichText = true, TextWrapped = true, Font = Enum.Font.GothamBold,
                    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = th.Text, LayoutOrder = 1,
                }, inner)
            end
            if o.Content and tostring(o.Content) ~= "" then
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                    Text = tostring(o.Content), RichText = true, TextWrapped = true, Font = Enum.Font.Gotham,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = th.SubText, LayoutOrder = 2,
                }, inner)
            end
            local click = new("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5,
            }, card)

            local t = {alive = true, expire = os.clock() + dur}
            Lib._toasts[key] = t
            table.insert(Lib._toastList, t)
            click.Activated:Connect(function() t.expire = 0 end)
            tween(card, {GroupTransparency = 0}, TI)
            task.spawn(function()
                while t.alive and os.clock() < t.expire do task.wait(0.1) end
                pcall(function() tween(card, {GroupTransparency = 1}, TI) end)
                task.wait(0.25)
                t.alive = false
                if Lib._toasts[key] == t then Lib._toasts[key] = nil end
                pcall(function() card:Destroy() end)
            end)
        end)
        if not ok then warn("[DiamondUI] notify failed: " .. tostring(err)) end
    end

    keep(UIS.InputBegan:Connect(function(input, gp)
        if Lib._listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local fn = Lib._listening
                Lib._listening = nil
                fn(input.KeyCode)
            end
            return
        end
        if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        for _, win in ipairs(Lib.Windows) do
            for _, kb in ipairs(win._keybinds) do
                if kb.down then kb.down(input.KeyCode) end
            end
        end
    end))
    keep(UIS.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        for _, win in ipairs(Lib.Windows) do
            for _, kb in ipairs(win._keybinds) do
                if kb.up then kb.up(input.KeyCode) end
            end
        end
    end))

    function Lib:_nextOrder()
        Lib._order = Lib._order + 1
        return Lib._order
    end

    function Lib:_front(win)
        if win.Gui and win.Gui.DisplayOrder ~= Lib._order then
            win.Gui.DisplayOrder = Lib:_nextOrder()
        end
    end

    function Window:_bind(obj, prop, key)
        obj[prop] = self.Theme[key]
        table.insert(self._bound, {obj, prop, key})
    end

    function Window:_onTheme(fn)
        table.insert(self._hooks, fn)
    end

    function Window:_reg(flag, comp)
        if flag then self.Flags[flag] = comp end
    end

    local function resolveTheme(v)
        if type(v) == "table" then
            local t = copy(THEMES.Dark)
            for k, c in pairs(v) do t[k] = c end
            return "Custom", t
        end
        if THEMES[v] then return v, copy(THEMES[v]) end
        return "Dark", copy(THEMES.Dark)
    end

    function Window:SetTheme(v)
        if type(v) == "table" then self._customTbl = v end
        local name, t = resolveTheme(v)
        self.ThemeName = name
        self._baseAccent = t.Accent
        if self._accent then t.Accent = self._accent end
        self.Theme = t
        local aliveList = {}
        for _, e in ipairs(self._bound) do
            local obj = e[1]
            if obj.Parent ~= nil then
                table.insert(aliveList, e)
                tween(obj, {[e[2]] = t[e[3]]}, TI)
            end
        end
        self._bound = aliveList
        for _, fn in ipairs(self._hooks) do pcall(fn) end
        if self._accentPicker and not self._accent then self._accentPicker:Set(t.Accent, true) end
    end

    function Window:SetAccent(c)
        if c ~= nil and self._baseAccent then
            local b = self._baseAccent
            if math.abs(c.R - b.R) + math.abs(c.G - b.G) + math.abs(c.B - b.B) < 0.01 then c = nil end
        end
        self._accent = c
        local col = c or self._baseAccent
        self.Theme.Accent = col
        for _, e in ipairs(self._bound) do
            if e[3] == "Accent" and e[1].Parent ~= nil then e[1][e[2]] = col end
        end
        for _, fn in ipairs(self._hooks) do pcall(fn) end
    end

    function Window:SetScale(s)
        s = math.clamp(tonumber(s) or 1, 0.6, 1.3)
        self.Scale = s
        self.UIScale.Scale = s
        self.Holder.Size = UDim2.fromScale(1 / s, 1 / s)
    end

    function Window:SetTransparency(t)
        t = math.clamp(tonumber(t) or 0, 0, 0.7)
        self.Transparency = t
        for _, fr in ipairs(self._transFrames) do fr.BackgroundTransparency = t end
    end

    function Window:SetLocked(v) self.Locked = v and true or false end

    function Window:SetStatus(text)
        if self._status then self._status.Text = tostring(text) end
    end

    function Window:Notify(a, b, c) Lib:Notify(a, b, c) end

    function Window:ResetPosition()
        self.Main.Position = UDim2.fromScale(0.5, 0.5)
        self.Main.Size = UDim2.fromOffset(self._defSize.X, self._defSize.Y)
    end

    function Window:Toggle(v)
        if v == nil then v = not self.Main.Visible end
        self.Main.Visible = v
        if not v then self:_closePopup() end
        if v then Lib:_front(self) end
    end

    function Window:Minimize(v)
        if v == nil then v = not self._min end
        self._min = v
        self._side.Visible = not v
        self._contentF.Visible = not v
        self._sep.Visible = not v
        self._grip.Visible = not v
        self:_closePopup()
        if v then
            self._fullSize = self.Main.Size
            tween(self.Main, {Size = UDim2.fromOffset(self.Main.Size.X.Offset, 40)}, TI)
        else
            tween(self.Main, {Size = self._fullSize or UDim2.fromOffset(self._defSize.X, self._defSize.Y)}, TI)
        end
    end

    function Window:Destroy()
        for i, w in ipairs(Lib.Windows) do
            if w == self then
                table.remove(Lib.Windows, i)
                break
            end
        end
        if self.Gui then self.Gui:Destroy() end
    end

    function Window:_openPopup(frame)
        if self._popup and self._popup ~= frame then self._popup.Visible = false end
        self._popup = frame
        self.Catcher.Visible = true
        frame.Visible = true
    end

    function Window:_closePopup()
        if self._popup then self._popup.Visible = false end
        self._popup = nil
        if self.Catcher then self.Catcher.Visible = false end
    end

    function Window:_place(frame, anchor, w, h)
        local s = self.Scale
        local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
        local sw, sh = self.Gui.AbsoluteSize.X / s, self.Gui.AbsoluteSize.Y / s
        local x = ap.X / s
        local y = (ap.Y + as.Y) / s + 3
        if y + h > sh - 6 then y = ap.Y / s - h - 3 end
        if y < 6 then y = 6 end
        x = math.clamp(x, 6, math.max(6, sw - w - 6))
        frame.Position = UDim2.fromOffset(x, y)
        frame.Size = UDim2.fromOffset(w, h)
    end

    function Window:_tip(obj, text)
        if not text or text == "" then return end
        local function show()
            self._tipLabel.Text = Lib.Tr and Lib.Tr(tostring(text)) or tostring(text)
            local s = self.Scale
            local ap, as = obj.AbsolutePosition, obj.AbsoluteSize
            local sw = self.Gui.AbsoluteSize.X / s
            local x = math.clamp(ap.X / s, 6, math.max(6, sw - 236))
            local y = (ap.Y + as.Y) / s + 4
            self._tipFrame.Position = UDim2.fromOffset(x, y)
            self._tipFrame.Visible = true
        end
        local hover, holding = false, false
        obj.MouseEnter:Connect(function()
            hover = true
            task.delay(0.5, function() if hover then show() end end)
        end)
        obj.MouseLeave:Connect(function()
            hover = false
            self._tipFrame.Visible = false
        end)
        obj.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                holding = true
                task.delay(0.55, function() if holding then show() end end)
            end
        end)
        obj.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                holding = false
                task.delay(1.5, function() if not holding then self._tipFrame.Visible = false end end)
            end
        end)
    end

    function Window:SetLoadOrder(list)
        self._loadLast = type(list) == "table" and list or {}
    end

    -- Every saveable element (it has a Flag and is not NoSave) is written to <ConfigFolder>/settings.json by itself
    -- whenever its value changes, and applied again by RestoreState on the next start. No manual configs.
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
            local function applyFlag(flag, v)
                local comp = self.Flags[flag]
                if comp and not comp.NoSave and comp.Set then
                    pcall(function() comp:Set(decodeVal(v)) end)
                end
            end
            local late = {}
            for _, fl in ipairs(self._loadLast or {}) do late[fl] = true end
            -- theme first: SetAccent compares the colour with the active theme's accent
            if d.flags["ui.theme"] ~= nil then applyFlag("ui.theme", d.flags["ui.theme"]) end
            for flag, v in pairs(d.flags) do
                if not late[flag] and flag ~= "ui.theme" then applyFlag(flag, v) end
            end
            for _, fl in ipairs(self._loadLast or {}) do
                if d.flags[fl] ~= nil then applyFlag(fl, d.flags[fl]) end
            end
        end
        -- the saver starts only after the restore, otherwise the defaults would overwrite the saved state
        local _, last = self:_snapshot()
        task.spawn(function()
            while self.Gui and self.Gui.Parent do
                task.wait(0.4)
                local flags, cur = self:_snapshot()
                if cur ~= last and io.write({v = 2, flags = flags}) then last = cur end
            end
        end)
        return restored
    end

    function Window:SelectTab(tab)
        for _, t in ipairs(self.Tabs) do
            t.Page.Visible = (t == tab)
            t._active = (t == tab)
            t._paint()
        end
        self._activeTab = tab
        self:_closePopup()
    end

    function Window:AddTab(name, opts)
        local win = self
        local tab = setmetatable({Window = win, Name = tostring(name), _sections = {}, _active = false}, Tab)

        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            BorderSizePixel = 0, LayoutOrder = #win.Tabs + 1,
        }, win._tabList)
        round(btn, 8)
        local bar = new("Frame", {
            Position = UDim2.new(0, 0, 0.5, -9), Size = UDim2.fromOffset(3, 18), BorderSizePixel = 0, Visible = false,
        }, btn)
        round(bar, 2)
        win:_bind(bar, "BackgroundColor3", "Accent")
        local lbl = new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0),
            Text = tab.Name, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)

        tab._paint = function()
            local th = win.Theme
            bar.Visible = tab._active
            btn.BackgroundTransparency = tab._active and 0 or 1
            btn.BackgroundColor3 = th.Element
            lbl.TextColor3 = tab._active and th.Text or th.SubText
        end
        win:_onTheme(tab._paint)
        btn.MouseEnter:Connect(function()
            if not tab._active then lbl.TextColor3 = win.Theme.Text end
        end)
        btn.MouseLeave:Connect(function()
            if not tab._active then lbl.TextColor3 = win.Theme.SubText end
        end)
        btn.Activated:Connect(function() win:SelectTab(tab) end)

        local page = new("ScrollingFrame", {
            Name = "Page_" .. tab.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
        }, win._contentF)
        win:_bind(page, "ScrollBarImageColor3", "Accent")
        padding(page, 10, 10, 10, 10)
        new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)

        tab.Page, tab.Button = page, btn
        table.insert(win.Tabs, tab)
        tab._paint()
        if #win.Tabs == 1 then win:SelectTab(tab) end
        return tab
    end

    function Tab:AddSection(title, opts)
        opts = opts or {}
        local win = self.Window
        local card = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
            LayoutOrder = #self._sections + 1,
        }, self.Page)
        win:_bind(card, "BackgroundColor3", "Surface")
        round(card, 10)
        local cs = new("UIStroke", {Thickness = 1}, card)
        win:_bind(cs, "Color", "Stroke")
        padding(card, 10, 8, 10, 10)
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, card)

        local body = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1,
        }, card)
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, body)

        if title and title ~= "" then
            local header = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0,
            }, card)
            local hl = new("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, 0), Text = string.upper(tostring(title)),
                Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            }, header)
            win:_bind(hl, "TextColor3", "Accent")
            local chev = new("TextLabel", {
                BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.fromOffset(20, 20), Text = "v", Font = Enum.Font.GothamBold, TextSize = 12,
            }, header)
            win:_bind(chev, "TextColor3", "SubText")
            if opts.Collapsible ~= false then
                local open = opts.Collapsed ~= true
                body.Visible = open
                chev.Text = open and "v" or ">"
                header.Activated:Connect(function()
                    open = not open
                    body.Visible = open
                    chev.Text = open and "v" or ">"
                end)
            else
                chev.Visible = false
            end
        end

        local c = setmetatable({Window = win, Frame = body, Page = self.Page, Tab = self}, Container)
        table.insert(self._sections, c)
        return c
    end

    function Tab:_default()
        if not self._def then self._def = self:AddSection(nil) end
        return self._def
    end

    function Container:_order()
        self._n = (self._n or 0) + 1
        return self._n
    end

    local function hoverColor(th, key)
        if key == "Element" then return th.ElementHover end
        return th[key]:Lerp(Color3.new(1, 1, 1), 0.14)
    end

    local function elementBase(self, height, tooltip, colorKey)
        local win = self.Window
        colorKey = colorKey or "Element"
        local f = new("TextButton", {
            Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
            LayoutOrder = self:_order(),
        }, self.Frame)
        win:_bind(f, "BackgroundColor3", colorKey)
        round(f, 8)
        f.MouseEnter:Connect(function()
            tween(f, {BackgroundColor3 = hoverColor(win.Theme, colorKey)}, TI_FAST)
        end)
        f.MouseLeave:Connect(function()
            tween(f, {BackgroundColor3 = win.Theme[colorKey]}, TI_FAST)
        end)
        if tooltip then win:_tip(f, tooltip) end
        return f
    end

    local function textLabel(win, parent, props, colorKey)
        props.BackgroundTransparency = 1
        props.Font = props.Font or Enum.Font.GothamMedium
        props.TextSize = props.TextSize or 13
        props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
        local l = new("TextLabel", props, parent)
        win:_bind(l, "TextColor3", colorKey or "Text")
        return l
    end

    local function fieldStyle(win, o)
        round(o, 6)
        win:_bind(o, "BackgroundColor3", "Background")
        local s = new("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
        win:_bind(s, "Color", "Stroke")
    end

    local function finish(obj, f)
        obj.Frame = f
        function obj:SetVisible(v) f.Visible = v and true or false end
        function obj:Destroy() f:Destroy() end
        return obj
    end

    function Container:AddLabel(...)
        local o = P({"Text"}, ...)
        local win = self.Window
        local l = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Text = tostring(o.Text or ""), RichText = true, TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = self:_order(),
        }, self.Frame)
        win:_bind(l, "TextColor3", o.Color or "SubText")
        padding(l, 4, 2)
        local obj = {}
        function obj:SetText(t) l.Text = tostring(t) end
        function obj:Get() return l.Text end
        function obj:Set(t) l.Text = tostring(t) end
        return finish(obj, l)
    end

    function Container:AddParagraph(...)
        local o = P({"Title", "Content"}, ...)
        local win = self.Window
        local f = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = self:_order(),
        }, self.Frame)
        win:_bind(f, "BackgroundColor3", "Element")
        round(f, 8)
        padding(f, 10, 8, 10, 8)
        new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, f)
        local t = textLabel(win, f, {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(o.Title or ""),
            RichText = true, TextWrapped = true, Font = Enum.Font.GothamBold, TextSize = 13, LayoutOrder = 1,
        }, "Text")
        local c = textLabel(win, f, {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(o.Content or ""),
            RichText = true, TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
        }, "SubText")
        local obj = {}
        function obj:SetTitle(x) t.Text = tostring(x) end
        function obj:SetContent(x) c.Text = tostring(x) end
        return finish(obj, f)
    end

    function Container:AddDivider()
        local win = self.Window
        local d = new("Frame", {Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = self:_order()}, self.Frame)
        win:_bind(d, "BackgroundColor3", "Stroke")
        return finish({}, d)
    end

    function Container:AddButton(...)
        local o = P({"Name", "Callback"}, ...)
        local win = self.Window
        local style = o.Style or "Default"
        local key = (style == "Accent" and "Accent") or (style == "Danger" and "Danger") or "Element"
        local f = elementBase(self, 34, o.Tooltip, key)
        local txt = new("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = tostring(o.Name or "Button"), RichText = true,
            Font = Enum.Font.GothamMedium, TextSize = 13,
        }, f)
        if key == "Element" then
            win:_bind(txt, "TextColor3", "Text")
        else
            txt.TextColor3 = Color3.new(1, 1, 1)
        end
        f.Activated:Connect(function()
            local th = win.Theme
            tween(f, {BackgroundColor3 = th[key]:Lerp(Color3.new(0, 0, 0), 0.18)}, TI_FAST)
            task.delay(0.12, function()
                tween(f, {BackgroundColor3 = th[key]}, TI_FAST)
            end)
            safe(o.Callback)
        end)
        local obj = {}
        function obj:SetText(t) txt.Text = tostring(t) end
        function obj:SetCallback(cb) o.Callback = cb end
        return finish(obj, f)
    end

    function Container:AddToggle(...)
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local f = elementBase(self, 34, o.Tooltip)
        local tlabel = textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -62, 1, 0), Text = tostring(o.Name or "Toggle"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local track = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(40, 20),
            BorderSizePixel = 0,
        }, f)
        round(track, 10)
        local knob = new("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14),
            BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
        }, track)
        round(knob, 7)

        local state = o.Default == true
        local function paint(animate)
            local th = win.Theme
            local col = state and th.Accent or th.Stroke
            local pos = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            if animate then
                tween(track, {BackgroundColor3 = col}, TI)
                tween(knob, {Position = pos}, TI)
            else
                track.BackgroundColor3 = col
                knob.Position = pos
            end
        end
        paint(false)
        win:_onTheme(function() paint(false) end)

        local obj = {NoSave = o.NoSave}
        function obj:SetText(t) tlabel.Text = tostring(t) end
        function obj:Get() return state end
        function obj:Set(v, silent)
            v = v and true or false
            if v == state then return end
            state = v
            paint(true)
            if not silent then safe(o.Callback, state) end
        end
        f.Activated:Connect(function() obj:Set(not state) end)
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddSlider(...)
        local o = P({"Name", "Min", "Max", "Default", "Callback"}, ...)
        local win = self.Window
        local min, max = tonumber(o.Min) or 0, tonumber(o.Max) or 100
        if max < min then min, max = max, min end
        local step = tonumber(o.Step) or 1
        if step <= 0 then step = 1 end
        local suffix = tostring(o.Suffix or "")
        local value = math.clamp(tonumber(o.Default) or min, min, max)

        local f = elementBase(self, 48, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -90, 0, 16), Text = tostring(o.Name or "Slider"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local valL = textLabel(win, f, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(72, 16),
            TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold, TextSize = 12,
        }, "Accent")
        local hit = new("TextButton", {
            Position = UDim2.new(0, 8, 0, 26), Size = UDim2.new(1, -16, 0, 18), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false,
        }, f)
        local bar = new("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6), BorderSizePixel = 0,
        }, hit)
        win:_bind(bar, "BackgroundColor3", "Stroke")
        round(bar, 3)
        local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BorderSizePixel = 0}, bar)
        win:_bind(fill, "BackgroundColor3", "Accent")
        round(fill, 3)
        local knob = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
            BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2,
        }, bar)
        round(knob, 7)

        local function fmt(v)
            if step >= 1 then return tostring(math.floor(v + 0.5)) end
            local s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
            return s
        end

        local function setValue(v, silent)
            v = math.clamp(v, min, max)
            v = math.floor((v - min) / step + 0.5) * step + min
            v = math.clamp(v, min, max)
            value = v
            local a = (max > min) and (v - min) / (max - min) or 0
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            valL.Text = fmt(v) .. suffix
            if not silent then safe(o.Callback, v) end
        end
        setValue(value, true)

        local function fromInput(px)
            local a = math.clamp((px - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            setValue(min + a * (max - min))
        end
        hit.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            if self.Page then self.Page.ScrollingEnabled = false end
            fromInput(input.Position.X)
            trackDrag(input, function(p) fromInput(p.X) end, function()
                if self.Page then self.Page.ScrollingEnabled = true end
            end)
        end)

        local obj = {NoSave = o.NoSave}
        function obj:Get() return value end
        function obj:Set(v, silent)
            if tonumber(v) then setValue(tonumber(v), silent) end
        end
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddInput(...)
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local f = elementBase(self, 34, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -14, 1, 0), Text = tostring(o.Name or "Input"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local box = new("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.5, -6, 0, 24),
            Text = tostring(o.Default or ""), PlaceholderText = tostring(o.Placeholder or ""),
            ClearTextOnFocus = o.ClearOnFocus == true, Font = Enum.Font.Gotham, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
        }, f)
        fieldStyle(win, box)
        padding(box, 8, 0)
        win:_bind(box, "TextColor3", "Text")
        win:_bind(box, "PlaceholderColor3", "SubText")

        local value = box.Text
        box.FocusLost:Connect(function(enter)
            if o.Numeric then
                local n = tonumber(box.Text)
                if n then box.Text = tostring(n) else box.Text = value end
            end
            value = box.Text
            safe(o.Callback, value, enter)
        end)

        local obj = {NoSave = o.NoSave}
        function obj:Get() return box.Text end
        function obj:Set(v, silent)
            box.Text = tostring(v or "")
            value = box.Text
            if not silent then safe(o.Callback, value, false) end
        end
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddDropdown(...)
        local o = P({"Name", "Options", "Default", "Callback"}, ...)
        local win = self.Window
        local options = type(o.Options) == "table" and o.Options or {}
        local searchable = o.Searchable ~= false

        local f = elementBase(self, 34, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -14, 1, 0), Text = tostring(o.Name or "Dropdown"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local btn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.5, -6, 0, 24),
            Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        }, f)
        fieldStyle(win, btn)
        local val = textLabel(win, btn, {
            Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamMedium,
            TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Text = "None",
        }, "Text")
        textLabel(win, btn, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 0), Size = UDim2.fromOffset(20, 24),
            Text = "v", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center,
        }, "SubText")

        local value
        local popup, search, listFrame
        local rows = {}
        local obj = {NoSave = o.NoSave}

        local function paintRows()
            local th = win.Theme
            for _, r in ipairs(rows) do
                local sel = (value ~= nil) and (r.opt == value or tostring(r.opt) == tostring(value))
                r.btn.TextColor3 = sel and th.Accent or th.Text
                r.btn.Font = sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
                r.btn.BackgroundColor3 = th.Element
                r.btn.BackgroundTransparency = sel and 0 or 1
            end
        end

        local function rebuildRows()
            if not listFrame then return end
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            rows = {}
            for i, opt in ipairs(options) do
                local b = new("TextButton", {
                    Size = UDim2.new(1, -4, 0, 26), BackgroundTransparency = 1, AutoButtonColor = false,
                    Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 12, BorderSizePixel = 0, LayoutOrder = i,
                }, listFrame)
                round(b, 6)
                rows[i] = {btn = b, opt = opt}
                b.Activated:Connect(function()
                    obj:Set(opt)
                    win:_closePopup()
                end)
            end
            paintRows()
        end
        win:_onTheme(paintRows)

        local function build()
            popup = new("Frame", {Visible = false, BorderSizePixel = 0, ZIndex = 3}, win.Overlay)
            win:_bind(popup, "BackgroundColor3", "Surface")
            round(popup, 8)
            local ps = new("UIStroke", {Thickness = 1}, popup)
            win:_bind(ps, "Color", "Stroke")
            local topOff = 0
            if searchable then
                search = new("TextBox", {
                    Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 24), Text = "",
                    PlaceholderText = "Search...", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
                }, popup)
                fieldStyle(win, search)
                padding(search, 8, 0)
                win:_bind(search, "TextColor3", "Text")
                win:_bind(search, "PlaceholderColor3", "SubText")
                topOff = 34
                search:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = search.Text:lower()
                    for _, r in ipairs(rows) do
                        r.btn.Visible = (q == "" or tostring(r.opt):lower():find(q, 1, true) ~= nil)
                    end
                end)
            end
            listFrame = new("ScrollingFrame", {
                Position = UDim2.fromOffset(4, topOff + 4), Size = UDim2.new(1, -8, 1, -(topOff + 8)),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
            }, popup)
            win:_bind(listFrame, "ScrollBarImageColor3", "Accent")
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)
            rebuildRows()
        end

        btn.Activated:Connect(function()
            if not popup then build() end
            if search then search.Text = "" end
            for _, r in ipairs(rows) do r.btn.Visible = true end
            local h = math.min(math.max(#options, 1), 6) * 28 + (searchable and 34 or 0) + 10
            win:_place(popup, btn, btn.AbsoluteSize.X / win.Scale, h)
            win:_openPopup(popup)
        end)

        function obj:Get() return value end
        function obj:Set(v, silent)
            local found
            if v ~= nil then
                for _, opt in ipairs(options) do
                    if opt == v or tostring(opt) == tostring(v) then
                        found = opt
                        break
                    end
                end
            end
            value = found
            val.Text = (found ~= nil) and tostring(found) or "None"
            paintRows()
            if not silent and found ~= nil then safe(o.Callback, found) end
        end
        function obj:SetOptions(list)
            options = type(list) == "table" and list or {}
            local keep = false
            for _, opt in ipairs(options) do
                if value ~= nil and (opt == value or tostring(opt) == tostring(value)) then keep = true end
            end
            if not keep then
                value = nil
                val.Text = "None"
            end
            rebuildRows()
        end
        obj.Refresh = obj.SetOptions

        if o.Default ~= nil then obj:Set(o.Default, true) end
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddColorPicker(...)
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local color = typeof(o.Default) == "Color3" and o.Default or Color3.fromRGB(255, 255, 255)
        local h, s, v = Color3.toHSV(color)

        local f = elementBase(self, 34, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -70, 1, 0), Text = tostring(o.Name or "Color"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local sw = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(44, 20),
            Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = color,
        }, f)
        round(sw, 6)
        local sws = new("UIStroke", {Thickness = 1}, sw)
        win:_bind(sws, "Color", "Stroke")

        local popup, svBox, svCursor, hueBar, hueCursor, hexBox, preview
        local obj = {NoSave = o.NoSave}

        local function hex(c)
            return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
        end

        local function refreshPopup()
            if not popup then return end
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
            hueCursor.Position = UDim2.new(0.5, 0, h, 0)
            preview.BackgroundColor3 = color
            hexBox.Text = hex(color)
        end

        local function apply(silent)
            color = Color3.fromHSV(h, s, v)
            sw.BackgroundColor3 = color
            refreshPopup()
            if not silent then safe(o.Callback, color) end
        end

        local function build()
            popup = new("Frame", {Visible = false, BorderSizePixel = 0, ZIndex = 3}, win.Overlay)
            win:_bind(popup, "BackgroundColor3", "Surface")
            round(popup, 8)
            local ps = new("UIStroke", {Thickness = 1}, popup)
            win:_bind(ps, "Color", "Stroke")

            svBox = new("TextButton", {
                Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(150, 100), Text = "", AutoButtonColor = false,
                BorderSizePixel = 0, BackgroundColor3 = Color3.fromHSV(h, 1, 1),
            }, popup)
            round(svBox, 6)
            local white = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, svBox)
            round(white, 6)
            new("UIGradient", {
                Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
            }, white)
            local black = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0}, svBox)
            round(black, 6)
            new("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
            }, black)
            svCursor = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 4,
            }, svBox)
            round(svCursor, 6)
            new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1)}, svCursor)

            hueBar = new("TextButton", {
                Position = UDim2.fromOffset(166, 8), Size = UDim2.fromOffset(18, 100), Text = "", AutoButtonColor = false,
                BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
            }, popup)
            round(hueBar, 6)
            local seq = {}
            for i = 0, 6 do
                table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 >= 1 and 0.999 or i / 6, 1, 1)))
            end
            new("UIGradient", {Rotation = 90, Color = ColorSequence.new(seq)}, hueBar)
            hueCursor = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 5), BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, ZIndex = 4,
            }, hueBar)
            round(hueCursor, 2)
            new("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0)}, hueCursor)

            hexBox = new("TextBox", {
                Position = UDim2.fromOffset(8, 116), Size = UDim2.fromOffset(112, 26), Text = hex(color), ClearTextOnFocus = false,
                Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
            }, popup)
            fieldStyle(win, hexBox)
            padding(hexBox, 8, 0)
            win:_bind(hexBox, "TextColor3", "Text")
            preview = new("Frame", {
                Position = UDim2.fromOffset(128, 116), Size = UDim2.fromOffset(56, 26), BorderSizePixel = 0, BackgroundColor3 = color,
            }, popup)
            round(preview, 6)

            local function svFrom(p)
                s = math.clamp((p.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
                v = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
                apply(false)
            end
            local function hueFrom(p)
                h = math.clamp((p.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 0.999)
                apply(false)
            end
            svBox.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                svFrom(input.Position)
                trackDrag(input, svFrom)
            end)
            hueBar.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                hueFrom(input.Position)
                trackDrag(input, hueFrom)
            end)
            hexBox.FocusLost:Connect(function()
                local txt = hexBox.Text:gsub("#", "")
                if #txt == 6 then
                    local r, g, b = tonumber(txt:sub(1, 2), 16), tonumber(txt:sub(3, 4), 16), tonumber(txt:sub(5, 6), 16)
                    if r and g and b then
                        h, s, v = Color3.toHSV(Color3.fromRGB(r, g, b))
                        apply(false)
                        return
                    end
                end
                hexBox.Text = hex(color)
            end)
            refreshPopup()
        end

        sw.Activated:Connect(function()
            if not popup then build() end
            refreshPopup()
            win:_place(popup, sw, 192, 150)
            win:_openPopup(popup)
        end)

        function obj:Get() return color end
        function obj:Set(c, silent)
            if typeof(c) ~= "Color3" then return end
            h, s, v = Color3.toHSV(c)
            apply(silent)
        end
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddKeybind(...)
        local o = P({"Name", "Default", "Callback"}, ...)
        local win = self.Window
        local mode = o.Mode or "Press"

        local function toKey(x)
            if typeof(x) == "EnumItem" then return x end
            if type(x) == "string" and x ~= "" and x ~= "None" then
                local ok, kc = pcall(function() return Enum.KeyCode[x] end)
                if ok then return kc end
            end
            return nil
        end
        local key = toKey(o.Default)

        local f = elementBase(self, 34, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -116, 1, 0), Text = tostring(o.Name or "Keybind"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local btn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(96, 24),
            Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        }, f)
        fieldStyle(win, btn)
        local txt = textLabel(win, btn, {
            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold,
            TextSize = 11, Text = "None",
        }, "Text")

        local listening, state = false, false
        local function paint() txt.Text = listening and "..." or (key and key.Name or "None") end
        paint()

        local obj = {NoSave = o.NoSave}
        function obj:SetMode(m) mode = m end
        function obj:SetState(b) state = b and true or false end
        function obj:Get() return key and key.Name or "None" end
        function obj:Set(x, silent)
            key = toKey(x)
            paint()
            if not silent then safe(o.Changed, key) end
        end
        btn.Activated:Connect(function()
            if listening then return end
            listening = true
            paint()
            Lib._listening = function(code)
                listening = false
                if code == Enum.KeyCode.Escape then key = nil else key = code end
                paint()
                safe(o.Changed, key)
            end
        end)
        table.insert(win._keybinds, {
            down = function(code)
                if not key or code ~= key then return end
                if mode == "Toggle" then
                    state = not state
                    safe(o.Callback, state)
                elseif mode == "Hold" then
                    safe(o.Callback, true)
                else
                    safe(o.Callback, key)
                end
            end,
            up = function(code)
                if mode == "Hold" and key and code == key then safe(o.Callback, false) end
            end,
        })
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    function Container:AddGrid(...)
        local o = P({"Columns", "CellHeight"}, ...)
        local cols = math.max(1, math.floor(tonumber(o.Columns) or 2))
        local pad = tonumber(o.Padding) or 6
        local g = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = self:_order(),
        }, self.Frame)
        new("UIGridLayout", {
            CellPadding = UDim2.fromOffset(pad, pad),
            CellSize = UDim2.new(1 / cols, -math.ceil(pad * (cols - 1) / cols), 0, tonumber(o.CellHeight) or 34),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, g)
        return setmetatable({Window = self.Window, Frame = g, Page = self.Page, Tab = self.Tab}, Container)
    end

    for _, name in ipairs({"AddLabel", "AddParagraph", "AddDivider", "AddButton", "AddToggle", "AddSlider", "AddInput",
        "AddDropdown", "AddColorPicker", "AddKeybind", "AddGrid"}) do
        Tab[name] = function(self, ...)
            return Container[name](self:_default(), ...)
        end
    end

    function Window:AddSettingsTab(name)
        local win = self
        local tab = self:AddTab(name or "Settings")

        local ap = tab:AddSection("Appearance")
        ap:AddDropdown({
            Name = "Theme", Flag = "ui.theme", Options = {"Dark", "Light", "Midnight", "Ocean"},
            Default = win.ThemeName, Searchable = false,
            Callback = function(v) win:SetTheme(v) end,
        })
        win._accentPicker = ap:AddColorPicker({
            Name = "Accent Color", Flag = "ui.accent", Default = win.Theme.Accent,
            Callback = function(c) win:SetAccent(c) end,
        })
        ap:AddSlider({
            Name = "Transparency", Flag = "ui.transparency", Min = 0, Max = 0.6, Step = 0.05, Default = win.Transparency,
            Callback = function(v) win:SetTransparency(v) end,
        })
        ap:AddSlider({
            Name = "UI Scale", Flag = "ui.scale", Min = 0.7, Max = 1.2, Step = 0.05, Default = win.Scale,
            Callback = function(v) win:SetScale(v) end,
        })

        local ct = tab:AddSection("Controls")
        ct:AddToggle({
            Name = "Lock UI", Flag = "ui.lock", Default = false,
            Tooltip = "Disables dragging and resizing the window",
            Callback = function(v) win:SetLocked(v) end,
        })
        ct:AddKeybind({
            Name = "Toggle UI Key", Flag = "ui.key", Default = win.ToggleKey, Mode = "Press",
            Changed = function(k) win.ToggleKey = k or Enum.KeyCode.RightShift end,
        })
        ct:AddButton({Name = "Reset Window Position", Callback = function() win:ResetPosition() end})

        local sc = tab:AddSection("Script")
        Lib.AEToggle = sc:AddToggle({
            Name = "Auto Execute", Default = false, NoSave = true,
            Tooltip = "Reruns the script after every teleport",
            Callback = function(v)
                if Lib.AESilent then return end
                if Lib.OnAutoExecute then Lib.OnAutoExecute(v) end
            end,
        })
        sc:AddButton({Name = "Unload", Style = "Danger", Callback = function() Lib.Unload() end})
        sc:AddDropdown({
            Name = "UI Library", Options = UIX.names, Default = UIX.active, NoSave = true, Searchable = false,
            Tooltip = "Obsidian UI is the default. Diamond UI is the older custom menu. Changing it reloads the script",
            Callback = function(v)
                if v ~= UIX.active then UIX.switch(v, function() Lib.Unload() end) end
            end,
        })
        return tab
    end

    -- Multi-select dropdown (the Obsidian API Doors is written against has one; the old menu did not)
    function Container:AddMultiDropdown(...)
        local o = P({"Name", "Options", "Default", "Callback"}, ...)
        local win = self.Window
        local options = type(o.Options) == "table" and o.Options or {}
        local f = elementBase(self, 34, o.Tooltip)
        textLabel(win, f, {
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -14, 1, 0), Text = tostring(o.Name or "Dropdown"),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "Text")
        local btn = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.5, -6, 0, 24),
            Text = "", AutoButtonColor = false, BorderSizePixel = 0,
        }, f)
        fieldStyle(win, btn)
        local val = textLabel(win, btn, {
            Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -26, 1, 0), Font = Enum.Font.GothamMedium,
            TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Text = "None",
        }, "Text")
        textLabel(win, btn, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 0), Size = UDim2.fromOffset(20, 24),
            Text = "v", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center,
        }, "SubText")
        local value = {}
        local popup, search, listFrame
        local rows = {}
        local obj = {NoSave = o.NoSave}
        local function exists(x)
            for _, opt in ipairs(options) do
                if opt == x then return true end
            end
            return false
        end
        local function normalize(v)
            local set = {}
            if type(v) == "string" then
                if exists(v) then set[v] = true end
            elseif type(v) == "table" then
                for k, a in pairs(v) do
                    if type(k) == "number" and type(a) == "string" then
                        if exists(a) then set[a] = true end
                    elseif a == true and exists(k) then
                        set[k] = true
                    end
                end
            end
            return set
        end
        local function copySet()
            local c = {}
            for k, a in pairs(value) do c[k] = a end
            return c
        end
        local function summary()
            local names = {}
            for _, opt in ipairs(options) do
                if value[opt] then names[#names + 1] = tostring(opt) end
            end
            if #names == 0 then val.Text = "None"
            elseif #names <= 2 then val.Text = table.concat(names, ", ")
            else val.Text = #names .. " selected" end
        end
        local function paintRows()
            local th = win.Theme
            for _, r in ipairs(rows) do
                local sel = value[r.opt] == true
                r.btn.Text = (sel and "[x]  " or "[  ]  ") .. tostring(r.opt)
                r.btn.TextColor3 = sel and th.Accent or th.Text
                r.btn.Font = sel and Enum.Font.GothamBold or Enum.Font.GothamMedium
                r.btn.BackgroundColor3 = th.Element
                r.btn.BackgroundTransparency = sel and 0 or 1
            end
        end
        local function rebuildRows()
            if not listFrame then return end
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            rows = {}
            for i, opt in ipairs(options) do
                local b = new("TextButton", {
                    Size = UDim2.new(1, -4, 0, 26), BackgroundTransparency = 1, AutoButtonColor = false,
                    Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 12, BorderSizePixel = 0, LayoutOrder = i,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, listFrame)
                round(b, 6)
                padding(b, 8, 0)
                rows[i] = {btn = b, opt = opt}
                b.Activated:Connect(function()
                    if value[opt] then value[opt] = nil else value[opt] = true end
                    summary()
                    paintRows()
                    safe(o.Callback, copySet())
                end)
            end
            paintRows()
        end
        win:_onTheme(paintRows)
        local searchable = #options > 8
        local function build()
            popup = new("Frame", {Visible = false, BorderSizePixel = 0, ZIndex = 3}, win.Overlay)
            win:_bind(popup, "BackgroundColor3", "Surface")
            round(popup, 8)
            local ps = new("UIStroke", {Thickness = 1}, popup)
            win:_bind(ps, "Color", "Stroke")
            local topOff = 0
            if searchable then
                search = new("TextBox", {
                    Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 24), Text = "",
                    PlaceholderText = "Search...", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
                }, popup)
                fieldStyle(win, search)
                padding(search, 8, 0)
                win:_bind(search, "TextColor3", "Text")
                win:_bind(search, "PlaceholderColor3", "SubText")
                topOff = 34
                search:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = search.Text:lower()
                    for _, r in ipairs(rows) do
                        r.btn.Visible = (q == "" or tostring(r.opt):lower():find(q, 1, true) ~= nil)
                    end
                end)
            end
            listFrame = new("ScrollingFrame", {
                Position = UDim2.fromOffset(4, topOff + 4), Size = UDim2.new(1, -8, 1, -(topOff + 8)),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
            }, popup)
            win:_bind(listFrame, "ScrollBarImageColor3", "Accent")
            new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)
            rebuildRows()
        end
        btn.Activated:Connect(function()
            if not popup then build() end
            if search then search.Text = "" end
            for _, r in ipairs(rows) do r.btn.Visible = true end
            local h = math.min(math.max(#options, 1), 7) * 28 + (searchable and 34 or 0) + 10
            win:_place(popup, btn, btn.AbsoluteSize.X / win.Scale, h)
            win:_openPopup(popup)
        end)
        function obj:Get() return copySet() end
        function obj:Set(v, silent)
            value = normalize(v)
            summary()
            paintRows()
            if not silent then safe(o.Callback, copySet()) end
        end
        function obj:SetOptions(list)
            options = type(list) == "table" and list or {}
            value = normalize(value)
            summary()
            rebuildRows()
        end
        obj.Refresh = obj.SetOptions
        value = normalize(o.Default)
        summary()
        win:_reg(o.Flag, obj)
        return finish(obj, f)
    end

    -- Obsidian-style Library and window API on top of the old menu (Doors builds its menu through them)
    local Library = {Toggles = {}, Options = {}, Registry = {}, _unload = {}, Unloaded = false}
    Library.IsMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) and true or false
    Library.Scheme = setmetatable({}, {
        __index = function(_, k)
            local w = Lib.Windows[1]
            local th = (w and w.Theme) or THEMES.Dark
            if k == "AccentColor" then return th.Accent end
            if k == "BackgroundColor" then return th.Background end
            if k == "MainColor" then return th.Surface end
            if k == "OutlineColor" then return th.Stroke end
            if k == "FontColor" then return th.Text end
            return nil
        end,
    })
    function Library:OnUnload(fn) table.insert(Library._unload, fn) end
    function Library:Unload() Lib.Unload() end
    function Library:SafeCallback(fn, ...) safe(fn, ...) end
    function Library:AddToRegistry(inst, props) Library.Registry[inst] = {Properties = props} end
    function Library:Notify(a, b, c)
        local o = type(a) == "table" and a or {Title = a, Description = b, Time = c}
        Lib:Notify({Title = o.Title, Content = o.Description or o.Content, Duration = o.Time or o.Duration or 3})
    end
    Lib.Library = Library

    local function obsRun(el)
        if el.Disabled then return end
        safe(el._info.Callback, el.Value)
        if el.Changed then safe(el.Changed, el.Value) end
    end
    local function obsPlace(section, el, frame)
        local anchor = el._tail or el.Frame
        if not (anchor and frame) then return end
        local base = anchor.LayoutOrder
        for _, c in ipairs(section.Frame:GetChildren()) do
            if c:IsA("GuiObject") and c ~= frame and c.LayoutOrder > base then c.LayoutOrder = c.LayoutOrder + 1 end
        end
        frame.LayoutOrder = base + 1
        section._n = (section._n or 0) + 1
        el._tail = frame
    end
    local function obsTip(info)
        if info.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return info.Tooltip
    end
    local function obsKeyPicker(section, parent, idx, info)
        info = type(info) == "table" and info or {}
        local el = {Type = "KeyPicker", Idx = idx, Text = info.Text, _info = info, _state = false}
        el.Value = (info.Default ~= nil and tostring(info.Default) ~= "") and tostring(info.Default) or "None"
        el.Mode = info.Mode or "Toggle"
        local function dmode(m) return (m == "Hold" or m == "Toggle") and m or "Press" end
        local d = section:AddKeybind({
            Name = tostring(info.Text or idx), Default = (el.Value ~= "None") and el.Value or nil, Mode = dmode(el.Mode), NoSave = true,
            Callback = function(st)
                if el.Mode ~= "Hold" and el.Mode ~= "Toggle" then return end
                el._state = st == true
                if info.SyncToggleState and parent and parent.SetValue then parent:SetValue(el._state) end
                safe(info.Callback, el._state)
                if el.Clicked then safe(el.Clicked, el._state) end
            end,
            Changed = function(k)
                el.Value = k and k.Name or "None"
                if el.Changed then safe(el.Changed, el.Value) end
            end,
        })
        el._d = d
        function el:GetState()
            if el.Mode == "Always" then return true end
            return el._state
        end
        function el:SetValue(v)
            if type(v) ~= "table" then return end
            local key, mode = v[1], v[2]
            d:Set((key ~= nil and key ~= "None") and key or nil, true)
            el.Value = (key ~= nil and key ~= "") and tostring(key) or "None"
            if mode then
                el.Mode = mode
                if d.SetMode then d:SetMode(dmode(mode)) end
            end
        end
        function el:OnChanged(fn) el.Changed = fn end
        function el:OnClick(fn) el.Clicked = fn end
        function el:SetVisible(v) d:SetVisible(v) end
        el.Frame = d.Frame
        if parent then
            parent._pickers = parent._pickers or {}
            table.insert(parent._pickers, el)
            obsPlace(section, parent, d.Frame)
        end
        if idx ~= nil then Library.Options[idx] = el end
        return el
    end
    local function obsColor(section, parent, idx, info)
        info = type(info) == "table" and info or {}
        local el = {Type = "ColorPicker", Idx = idx, Text = info.Text, _info = info, Transparency = info.Transparency}
        el.Value = typeof(info.Default) == "Color3" and info.Default or Color3.new(1, 1, 1)
        local d = section:AddColorPicker({
            Name = tostring(info.Text or idx), Default = el.Value, NoSave = true, Tooltip = info.Tooltip,
            Callback = function(c)
                el.Value = c
                safe(info.Callback, c)
                if el.Changed then safe(el.Changed, c) end
            end,
        })
        function el:SetValueRGB(c)
            if typeof(c) ~= "Color3" then return end
            el.Value = c
            d:Set(c, true)
            safe(info.Callback, c)
            if el.Changed then safe(el.Changed, c) end
        end
        function el:SetValue(hsv)
            if type(hsv) ~= "table" then return end
            if hsv[4] ~= nil then el.Transparency = hsv[4] end
            el:SetValueRGB(Color3.fromHSV(hsv[1] or 0, hsv[2] or 0, hsv[3] or 0))
        end
        function el:OnChanged(fn) el.Changed = fn end
        function el:SetVisible(v) d:SetVisible(v) end
        el.Frame = d.Frame
        if parent then obsPlace(section, parent, d.Frame) end
        if idx ~= nil then Library.Options[idx] = el end
        return el
    end
    local function obsChain(section, el)
        function el:AddKeyPicker(idx, info) return obsKeyPicker(section, el, idx, info) end
        function el:AddColorPicker(idx, info) return obsColor(section, el, idx, info) end
    end
    local function obsBox(section)
        local Box = {Section = section}
        local function register(el)
            if type(el.Idx) == "string" then
                if el.Type == "Toggle" then Library.Toggles[el.Idx] = el else Library.Options[el.Idx] = el end
            end
            return el
        end
        function Box:AddToggle(idx, info)
            info = type(info) == "table" and info or {}
            local el = {Type = "Toggle", Idx = idx, Text = info.Text, Disabled = info.Disabled == true, _info = info}
            el.Value = info.Default == true
            local d
            d = section:AddToggle({
                Name = info.Text, Default = el.Value, Tooltip = obsTip(info), NoSave = true,
                Callback = function(v)
                    if el.Disabled then d:Set(el.Value, true) return end
                    el.Value = v
                    for _, p in ipairs(el._pickers or {}) do
                        if p._info.SyncToggleState and p.Mode == "Toggle" then
                            p._state = v
                            if p._d.SetState then p._d:SetState(v) end
                        end
                    end
                    obsRun(el)
                end,
            })
            el._d, el.Frame = d, d.Frame
            function el:SetValue(v)
                v = v and true or false
                if v == el.Value then return end
                el.Value = v
                d:Set(v, true)
                for _, p in ipairs(el._pickers or {}) do
                    if p._info.SyncToggleState and p.Mode == "Toggle" then
                        p._state = v
                        if p._d.SetState then p._d:SetState(v) end
                    end
                end
                obsRun(el)
            end
            function el:OnChanged(fn) el.Changed = fn end
            function el:SetText(t) el.Text = t if d.SetText then d:SetText(t) end end
            function el:SetVisible(v) d:SetVisible(v) end
            function el:SetDisabled(b) el.Disabled = b and true or false end
            obsChain(section, el)
            return register(el)
        end
        Box.AddCheckbox = Box.AddToggle
        function Box:AddSlider(idx, info)
            info = type(info) == "table" and info or {}
            local el = {Type = "Slider", Idx = idx, Text = info.Text, Disabled = info.Disabled == true, _info = info}
            el.Min, el.Max = tonumber(info.Min) or 0, tonumber(info.Max) or 100
            el.Value = math.clamp(tonumber(info.Default) or el.Min, el.Min, el.Max)
            local rounding = tonumber(info.Rounding) or 0
            local step = rounding > 0 and (10 ^ -rounding) or 1
            local d
            d = section:AddSlider({
                Name = info.Text, Min = el.Min, Max = el.Max, Default = el.Value, Step = step, Suffix = info.Suffix,
                Tooltip = obsTip(info), NoSave = true,
                Callback = function(v)
                    if el.Disabled then d:Set(el.Value, true) return end
                    el.Value = v
                    obsRun(el)
                end,
            })
            el._d, el.Frame = d, d.Frame
            function el:SetValue(v)
                v = tonumber(v)
                if not v then return end
                v = math.clamp(v, el.Min, el.Max)
                if v == el.Value then return end
                el.Value = v
                d:Set(v, true)
                obsRun(el)
            end
            function el:OnChanged(fn) el.Changed = fn end
            function el:SetVisible(v) d:SetVisible(v) end
            function el:SetDisabled(b) el.Disabled = b and true or false end
            return register(el)
        end
        function Box:AddInput(idx, info)
            info = type(info) == "table" and info or {}
            local el = {Type = "Input", Idx = idx, Text = info.Text, _info = info, Value = tostring(info.Default or "")}
            local d = section:AddInput({
                Name = info.Text, Default = el.Value, Placeholder = info.Placeholder, Tooltip = obsTip(info), NoSave = true,
                Numeric = info.Numeric, Callback = function(v) el.Value = v obsRun(el) end,
            })
            el._d, el.Frame = d, d.Frame
            function el:SetValue(v) el.Value = tostring(v or "") d:Set(el.Value, true) obsRun(el) end
            function el:OnChanged(fn) el.Changed = fn end
            function el:SetVisible(v) d:SetVisible(v) end
            return register(el)
        end
        function Box:AddDropdown(idx, info)
            info = type(info) == "table" and info or {}
            local values = type(info.Values) == "table" and info.Values or {}
            local el = {Type = "Dropdown", Idx = idx, Text = info.Text, Disabled = info.Disabled == true, _info = info, Values = values}
            local multi = info.Multi == true
            local d
            local function cb(v)
                if el.Disabled then
                    d:Set(el.Value, true)
                    return
                end
                el.Value = v
                obsRun(el)
            end
            if multi then
                d = section:AddMultiDropdown({
                    Name = info.Text, Options = values, Default = info.Default, Tooltip = obsTip(info), NoSave = true, Callback = cb,
                })
                el.Value = d:Get()
            else
                local def = info.Default
                if type(def) == "number" then def = values[def] end
                d = section:AddDropdown({
                    Name = info.Text, Options = values, Default = def, Tooltip = obsTip(info), NoSave = true,
                    Searchable = #values > 8, Callback = cb,
                })
                el.Value = d:Get()
            end
            el._d, el.Frame = d, d.Frame
            function el:SetValue(v)
                if not multi and type(v) == "number" then v = el.Values[v] end
                d:Set(v, true)
                el.Value = d:Get()
                obsRun(el)
            end
            function el:SetValues(list)
                el.Values = type(list) == "table" and list or {}
                d:SetOptions(el.Values)
                el.Value = d:Get()
            end
            function el:OnChanged(fn) el.Changed = fn end
            function el:SetVisible(v) d:SetVisible(v) end
            function el:SetDisabled(b) el.Disabled = b and true or false end
            return register(el)
        end
        function Box:AddButton(a, b)
            local info = type(a) == "table" and a or {Text = a, Func = b}
            local el = {Type = "Button", Text = info.Text, Disabled = info.Disabled == true, _info = info}
            local confirm, token = false, 0
            local d
            d = section:AddButton({
                Name = info.Text, Tooltip = obsTip(info),
                Callback = function()
                    if el.Disabled then return end
                    if info.DoubleClick then
                        if not confirm then
                            confirm = true
                            token = token + 1
                            local mine = token
                            d:SetText("Click again to confirm")
                            task.delay(2.5, function()
                                if token == mine and confirm then
                                    confirm = false
                                    d:SetText(tostring(el.Text))
                                end
                            end)
                            return
                        end
                        confirm = false
                        token = token + 1
                        d:SetText(tostring(el.Text))
                    end
                    safe(info.Func or info.Callback)
                end,
            })
            el._d, el.Frame = d, d.Frame
            function el:SetText(t) el.Text = t if not confirm then d:SetText(tostring(t)) end end
            function el:SetVisible(v) d:SetVisible(v) end
            function el:SetDisabled(x) el.Disabled = x and true or false end
            function el:AddButton(...) return Box:AddButton(...) end
            return el
        end
        function Box:AddLabel(a, b)
            local idx, info, text
            if type(a) == "string" and type(b) == "table" then
                idx, info, text = a, b, b.Text
            elseif type(a) == "table" then
                info, text = a, a.Text
            else
                text = a
            end
            local d = section:AddLabel({Text = tostring(text or "")})
            local el = {Type = "Label", Idx = idx, Text = text, Frame = d.Frame, _info = info or {}}
            function el:SetText(t) el.Text = t d:SetText(t) end
            function el:SetVisible(v) d:SetVisible(v) end
            obsChain(section, el)
            return el
        end
        function Box:AddDivider() section:AddDivider() end
        return Box
    end
    local function obsTabbox(dtab, title)
        local TB = {}
        function TB:AddTab(name)
            local t = tostring(name)
            if title and title ~= "" then t = tostring(title) .. " - " .. t end
            return obsBox(dtab:AddSection(t))
        end
        return TB
    end
    function Lib.MakeObs(win)
        local Obs = {}
        function Obs:AddTab(name, icon)
            local dtab = win:AddTab(tostring(name), {Icon = icon})
            local T = {_tab = dtab}
            function T:AddLeftGroupbox(n) return obsBox(dtab:AddSection(tostring(n))) end
            T.AddRightGroupbox = T.AddLeftGroupbox
            function T:AddLeftTabbox(n) return obsTabbox(dtab, n) end
            T.AddRightTabbox = T.AddLeftTabbox
            function T:UpdateWarningBox() end
            return T
        end
        return Obs
    end

    function Lib:CreateWindow(a, b)
        local o = type(a) == "table" and a or {Title = a, Subtitle = b}
        local self = setmetatable({}, Window)
        self.Title = tostring(o.Title or "Window")
        self.Subtitle = tostring(o.Subtitle or "")
        self.Scale = 1
        self.Locked = false
        self.Flags = {}
        self.Tabs = {}
        self._bound, self._hooks, self._keybinds, self._transFrames = {}, {}, {}, {}
        self.Transparency = 0
        self._defSize = (typeof(o.Size) == "Vector2") and o.Size or Vector2.new(540, 310)
        self.MinSize = (typeof(o.MinSize) == "Vector2") and o.MinSize or Vector2.new(430, 250)
        self.MaxSize = (typeof(o.MaxSize) == "Vector2") and o.MaxSize or Vector2.new(720, 440)
        self.ToggleKey = (typeof(o.ToggleKey) == "EnumItem") and o.ToggleKey or Enum.KeyCode.RightShift
        self.ConfigFolder = tostring(o.ConfigFolder or "DiamondUI")
        self._stateIO = stateIO(self.ConfigFolder)

        if type(o.Theme) == "table" then self._customTbl = o.Theme end
        local tn, tt = resolveTheme(o.Theme or "Dark")
        self.ThemeName, self.Theme, self._baseAccent = tn, tt, tt.Accent

        local safeName = (self.Title:gsub("%W", ""))
        local gui = new("ScreenGui", {
            Name = "DiamondUI_" .. safeName, ResetOnSpawn = false, IgnoreGuiInset = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = Lib:_nextOrder(),
        })
        gui.Parent = pg
        self.Gui = gui

        local holder = new("Frame", {Name = "Holder", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
        local uiscale = new("UIScale", {Scale = 1}, holder)
        self.Holder, self.UIScale = holder, uiscale

        local main = new("Frame", {
            Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(self._defSize.X, self._defSize.Y), BorderSizePixel = 0,
        }, holder)
        self:_bind(main, "BackgroundColor3", "Background")
        round(main, 12)
        local mst = new("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, main)
        self:_bind(mst, "Color", "Stroke")
        self.Main = main
        table.insert(self._transFrames, main)
        main.InputBegan:Connect(function(input)
            if isPointer(input) then Lib:_front(self) end
        end)

        local top = new("Frame", {Name = "Topbar", Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0}, main)
        self:_bind(top, "BackgroundColor3", "Topbar")
        round(top, 12)
        local topFill = new("Frame", {
            Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BorderSizePixel = 0,
        }, top)
        self:_bind(topFill, "BackgroundColor3", "Topbar")
        table.insert(self._transFrames, top)
        table.insert(self._transFrames, topFill)
        local topLine = new("Frame", {
            Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
        }, top)
        self:_bind(topLine, "BackgroundColor3", "Stroke")

        local logo = new("Frame", {
            Position = UDim2.fromOffset(17, 15), Size = UDim2.fromOffset(10, 10), Rotation = 45, BorderSizePixel = 0,
        }, top)
        round(logo, 2)
        self:_bind(logo, "BackgroundColor3", "Accent")
        local tl = new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(38, 3), Size = UDim2.new(1, -120, 0, 19),
            Text = self.Title, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, top)
        self:_bind(tl, "TextColor3", "Text")
        local sl = new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(38, 21), Size = UDim2.new(1, -120, 0, 14),
            Text = self.Subtitle, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, top)
        self:_bind(sl, "TextColor3", "SubText")

        local function topBtn(text, xOff, cb)
            local btn = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(26, 26),
                BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false,
                BorderSizePixel = 0,
            }, top)
            round(btn, 6)
            self:_bind(btn, "TextColor3", "SubText")
            btn.MouseEnter:Connect(function()
                btn.BackgroundTransparency = 0
                btn.BackgroundColor3 = self.Theme.Element
            end)
            btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1 end)
            btn.Activated:Connect(cb)
            return btn
        end
        topBtn("x", -10, function() self:Toggle(false) end)
        topBtn("-", -40, function() self:Minimize() end)

        top.InputBegan:Connect(function(input)
            if self.Locked or not isPointer(input) then return end
            Lib:_front(self)
            local sp, si = main.Position, input.Position
            trackDrag(input, function(p)
                local d = (p - si) / self.Scale
                main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end)
        end)

        local side = new("Frame", {
            Name = "Sidebar", Position = UDim2.fromOffset(0, 41), Size = UDim2.new(0, 118, 1, -41), BorderSizePixel = 0,
        }, main)
        self:_bind(side, "BackgroundColor3", "Sidebar")
        round(side, 12)
        local sf1 = new("Frame", {Size = UDim2.new(1, 0, 0, 12), BorderSizePixel = 0}, side)
        self:_bind(sf1, "BackgroundColor3", "Sidebar")
        local sf2 = new("Frame", {Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0), BorderSizePixel = 0}, side)
        self:_bind(sf2, "BackgroundColor3", "Sidebar")
        table.insert(self._transFrames, side)
        table.insert(self._transFrames, sf1)
        table.insert(self._transFrames, sf2)
        self._side = side

        local tabList = new("ScrollingFrame", {
            Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, side)
        padding(tabList, 8, 2, 8, 2)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, tabList)
        self._tabList = tabList

        local status = new("TextLabel", {
            Position = UDim2.new(0, 10, 1, -56), Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 1,
            Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom, RichText = true,
        }, side)
        self:_bind(status, "TextColor3", "SubText")
        self._status = status

        local sep = new("Frame", {
            Position = UDim2.fromOffset(118, 41), Size = UDim2.new(0, 1, 1, -41), BorderSizePixel = 0,
        }, main)
        self:_bind(sep, "BackgroundColor3", "Stroke")
        self._sep = sep

        local content = new("Frame", {
            Name = "Content", Position = UDim2.fromOffset(119, 41), Size = UDim2.new(1, -119, 1, -41),
            BackgroundTransparency = 1, ClipsDescendants = true,
        }, main)
        self._contentF = content

        local grip = new("TextButton", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 6,
        }, main)
        for _, pt in ipairs({{17, 17}, {17, 10}, {10, 17}}) do
            local dot = new("Frame", {
                Position = UDim2.fromOffset(pt[1], pt[2]), Size = UDim2.fromOffset(3, 3), BorderSizePixel = 0, ZIndex = 6,
            }, grip)
            round(dot, 2)
            self:_bind(dot, "BackgroundColor3", "SubText")
        end
        self._grip = grip
        grip.InputBegan:Connect(function(input)
            if self.Locked or self._min or not isPointer(input) then return end
            local s = self.Scale
            local sz, ps, si = main.Size, main.Position, input.Position
            local maxW = math.min(self.MaxSize.X, self.Gui.AbsoluteSize.X / s - 16)
            local maxH = math.min(self.MaxSize.Y, self.Gui.AbsoluteSize.Y / s - 16)
            trackDrag(input, function(p)
                local d = (p - si) / s
                local w = math.clamp(sz.X.Offset + d.X, self.MinSize.X, math.max(self.MinSize.X, maxW))
                local h = math.clamp(sz.Y.Offset + d.Y, self.MinSize.Y, math.max(self.MinSize.Y, maxH))
                main.Size = UDim2.fromOffset(w, h)
                main.Position = UDim2.new(ps.X.Scale, ps.X.Offset + (w - sz.X.Offset) / 2,
                    ps.Y.Scale, ps.Y.Offset + (h - sz.Y.Offset) / 2)
            end)
        end)

        local overlay = new("Frame", {
            Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 100,
        }, holder)
        self.Overlay = overlay
        local catcher = new("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Visible = false, ZIndex = 1,
        }, overlay)
        catcher.Activated:Connect(function() self:_closePopup() end)
        self.Catcher = catcher

        local tip = new("Frame", {
            Visible = false, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BorderSizePixel = 0, ZIndex = 10,
        }, overlay)
        self:_bind(tip, "BackgroundColor3", "Surface")
        round(tip, 6)
        local tipStroke = new("UIStroke", {Thickness = 1}, tip)
        self:_bind(tipStroke, "Color", "Stroke")
        padding(tip, 8, 6, 8, 6)
        local tipLabel = new("TextLabel", {
            Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Text = "",
            RichText = true, TextWrapped = true, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        }, tip)
        new("UISizeConstraint", {MaxSize = Vector2.new(220, 400)}, tipLabel)
        self:_bind(tipLabel, "TextColor3", "Text")
        self._tipFrame, self._tipLabel = tip, tipLabel

        if o.ToggleButton ~= false then
            local tb = new("TextButton", {
                Name = "ToggleBtn", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 56),
                Size = UDim2.fromOffset(40, 40), Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2,
            }, holder)
            self:_bind(tb, "BackgroundColor3", "Topbar")
            round(tb, 20)
            local tbs = new("UIStroke", {Thickness = 1.5}, tb)
            self:_bind(tbs, "Color", "Accent")
            local dia = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(13, 13),
                Rotation = 45, BorderSizePixel = 0,
            }, tb)
            round(dia, 3)
            self:_bind(dia, "BackgroundColor3", "Accent")
            tb.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                local sp, si, moved = tb.Position, input.Position, false
                trackDrag(input, function(p)
                    local d = p - si
                    if d.Magnitude > 8 then moved = true end
                    if moved then
                        local dd = d / self.Scale
                        tb.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dd.X, sp.Y.Scale, sp.Y.Offset + dd.Y)
                    end
                end, function()
                    if not moved then self:Toggle() end
                end)
            end)
            self._toggleBtn = tb
        end

        table.insert(self._keybinds, {
            down = function(code)
                if code == self.ToggleKey then self:Toggle() end
            end,
        })

        if o.Scale then self:SetScale(o.Scale) end
        if Lib.MakeObs then
            self.Obs = Lib.MakeObs(self)
            if Lib.Library then Lib.Library.ScreenGui = self.Gui end
        end
        table.insert(Lib.Windows, self)
        return self
    end

    return Lib
