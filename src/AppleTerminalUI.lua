local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library
Library._memoryConfigs = {}

Library.Theme = {
    Window = Color3.fromRGB(16, 17, 20),
    WindowEdge = Color3.fromRGB(33, 35, 40),
    Sidebar = Color3.fromRGB(20, 22, 26),
    SidebarCard = Color3.fromRGB(24, 26, 31),
    Panel = Color3.fromRGB(22, 24, 29),
    PanelSoft = Color3.fromRGB(27, 30, 36),
    PanelMuted = Color3.fromRGB(18, 20, 24),
    Stroke = Color3.fromRGB(56, 60, 68),
    StrokeSoft = Color3.fromRGB(41, 44, 51),
    Text = Color3.fromRGB(232, 235, 239),
    SubText = Color3.fromRGB(145, 153, 166),
    Accent = Color3.fromRGB(95, 255, 162),
    AccentSoft = Color3.fromRGB(44, 110, 80),
    AccentMuted = Color3.fromRGB(22, 49, 36),
    Red = Color3.fromRGB(255, 95, 86),
    Yellow = Color3.fromRGB(255, 189, 46),
    Green = Color3.fromRGB(39, 201, 63),
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function new(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    return object
end

local function addCorner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
    return c
end

local function addStroke(instance, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = instance
    return s
end

local function addPadding(instance, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = instance
    return p
end

local function addList(instance, padding)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, padding or 0)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment = Enum.VerticalAlignment.Top
    l.Parent = instance
    return l
end

local function tween(object, info, props)
    return TweenService:Create(object, info, props)
end

local function clamp(v, minv, maxv)
    return math.max(minv, math.min(maxv, v))
end

local function roundTo(v, step)
    step = step or 1
    if step <= 0 then
        return v
    end
    return math.floor((v / step) + 0.5) * step
end

local function sanitize(name)
    name = tostring(name or "default")
    name = name:gsub("[^%w%-%._ ]", "_")
    if name == "" then
        name = "default"
    end
    return name
end

local function bindCanvas(scroller, layout, extra)
    local function update()
        scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    update()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function bindFrameHeight(frame, layout, extra)
    local function update()
        frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    update()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    local ok, result = pcall(function()
        return CoreGui
    end)
    if ok and result then
        return result
    end

    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            return playerGui
        end
    end
end

local function protectGui(gui)
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    elseif typeof(protectgui) == "function" then
        pcall(protectgui, gui)
    end
end

local function hasFileApi()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function ensureFolder(path)
    if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
        if not isfolder(path) then
            pcall(makefolder, path)
        end
    end
end

local function keyName(key)
    if typeof(key) == "EnumItem" then
        return key.Name
    end
    return tostring(key)
end

local function hover(button, normal, over)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = over
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normal
        }):Play()
    end)
end

local function terminalLabel(parent, text, size, color, alignX)
    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, size + 6),
        Font = Enum.Font.Code,
        Text = text or "",
        TextColor3 = color,
        TextSize = size,
        TextXAlignment = alignX or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent
    })
    return label
end

function Library:CreateWindow(options)
    options = options or {}
    local theme = Library.Theme

    local self = setmetatable({}, Window)
    self.Title = options.Title or "AppleTerminalUI"
    self.Subtitle = options.Subtitle or "terminal session"
    self.ConfigFolder = options.ConfigFolder or "AppleTerminalUI"
    self.Flags = {}
    self.FlagObjects = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.Visible = true
    self.Minimized = false
    self.WindowSize = options.Size or UDim2.fromOffset(860, 560)
    self.StoredPosition = options.Position or UDim2.new(0.5, 0, 0.5, 0)
    self.StoredSize = self.WindowSize

    local parent = getGuiParent()
    assert(parent, "AppleTerminalUI: no valid GUI parent")

    local gui = new("ScreenGui", {
        Name = options.GuiName or ("AppleTerminalUI_" .. HttpService:GenerateGUID(false)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true
    })
    protectGui(gui)
    gui.Parent = parent
    self.ScreenGui = gui

    local shadow = new("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self.StoredPosition,
        Size = self.WindowSize + UDim2.fromOffset(60, 60),
        Image = "rbxassetid://6014261993",
        ImageTransparency = 0.42,
        ImageColor3 = Color3.new(0, 0, 0),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = gui
    })
    self.Shadow = shadow

    local main = new("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self.StoredPosition,
        Size = self.WindowSize,
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        Parent = gui
    })
    addCorner(main, 14)
    addStroke(main, theme.WindowEdge, 1, 0.05)
    self.Main = main

    local topBar = new("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Color3.fromRGB(25, 27, 31),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = main
    })
    addCorner(topBar, 14)

    new("Frame", {
        BackgroundColor3 = Color3.fromRGB(25, 27, 31),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -16),
        Size = UDim2.new(1, 0, 0, 16),
        Parent = topBar
    })

    local traffic = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 72, 1, 0),
        Parent = topBar
    })
    local trafficLayout = addList(traffic, 8)
    trafficLayout.FillDirection = Enum.FillDirection.Horizontal
    trafficLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local closeBtn = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = theme.Red,
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        Parent = traffic
    })
    addCorner(closeBtn, 999)

    local miniBtn = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = theme.Yellow,
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        Parent = traffic
    })
    addCorner(miniBtn, 999)

    local maxBtn = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = theme.Green,
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        Parent = traffic
    })
    addCorner(maxBtn, 999)

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -180, 0, 0),
        Size = UDim2.new(0, 360, 1, 0),
        Font = Enum.Font.Code,
        Text = self.Title .. " — zsh",
        TextColor3 = theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = topBar
    })

    local divider = new("Frame", {
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = main
    })

    local body = new("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 39),
        Size = UDim2.new(1, 0, 1, -39),
        Parent = main
    })
    self.Body = body

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 1, 0),
        Parent = body
    })
    self.Sidebar = sidebar

    local sidebarDivider = new("Frame", {
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar
    })

    local contentWrap = new("Frame", {
        Name = "ContentWrap",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 220, 0, 0),
        Size = UDim2.new(1, -220, 1, 0),
        Parent = body
    })
    self.ContentWrap = contentWrap

    local sidebarInner = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 1, -24),
        Parent = sidebar
    })
    local sidebarLayout = addList(sidebarInner, 10)
    bindFrameHeight(sidebarInner, sidebarLayout, 0)

    local homeCard = new("Frame", {
        BackgroundColor3 = theme.SidebarCard,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 118),
        Parent = sidebarInner
    })
    addCorner(homeCard, 12)
    addStroke(homeCard, theme.StrokeSoft, 1, 0.2)
    addPadding(homeCard, 12, 12, 12, 12)

    local homeList = addList(homeCard, 4)
    terminalLabel(homeCard, "$ login", 13, theme.Accent, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, self.Title, 18, theme.Text, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, self.Subtitle, 12, theme.SubText, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, "tty: /dev/console", 12, theme.Accent, Enum.TextXAlignment.Left)

    local tabsLabel = terminalLabel(sidebarInner, "TABS", 11, theme.SubText, Enum.TextXAlignment.Left)
    tabsLabel.Size = UDim2.new(1, 0, 0, 16)

    local tabScroll = new("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -170),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = sidebarInner
    })
    local tabList = addList(tabScroll, 8)
    bindCanvas(tabScroll, tabList, 12)
    self.TabButtonHolder = tabScroll

    local pageHolder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 16),
        Size = UDim2.new(1, -32, 1, -32),
        Parent = contentWrap
    })
    self.PageHolder = pageHolder

    local dragging = false
    local dragStart
    local startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            main.Position = newPos
            shadow.Position = newPos
            self.StoredPosition = newPos
        end
    end)

    function self:SetVisible(state)
        self.Visible = state == true
        self.ScreenGui.Enabled = self.Visible
    end

    function self:ToggleVisible()
        self:SetVisible(not self.Visible)
    end

    function self:Destroy()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end

    function self:_setMainSize(newSize, newPosition)
        tween(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = newSize,
            Position = newPosition or main.Position
        }):Play()

        tween(shadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = newSize + UDim2.fromOffset(60, 60),
            Position = newPosition or shadow.Position
        }):Play()
    end

    function self:_registerFlag(flag, getter, setter)
        if not flag or flag == "" then
            return
        end
        self.FlagObjects[flag] = {
            Get = getter,
            Set = setter
        }
        self.Flags[flag] = getter()
    end

    function self:GetFlag(flag)
        local entry = self.FlagObjects[flag]
        if entry and entry.Get then
            return entry.Get()
        end
    end

    function self:SetFlag(flag, value)
        local entry = self.FlagObjects[flag]
        if entry and entry.Set then
            entry.Set(value, true)
        end
    end

    function self:GetConfig()
        local out = {}
        for flag, entry in pairs(self.FlagObjects) do
            local ok, value = pcall(entry.Get)
            if ok then
                out[flag] = value
            end
        end
        return out
    end

    function self:ApplyConfig(config)
        if type(config) ~= "table" then
            return
        end
        for flag, value in pairs(config) do
            local entry = self.FlagObjects[flag]
            if entry and entry.Set then
                pcall(function()
                    entry.Set(value, true)
                end)
            end
        end
    end

    function self:SaveConfig(name)
        local clean = sanitize(name or self.Title)
        local json = HttpService:JSONEncode(self:GetConfig())

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local path = self.ConfigFolder .. "/" .. clean .. ".json"
            writefile(path, json)
            return true, path
        else
            Library._memoryConfigs[clean] = json
            return true, clean
        end
    end

    function self:LoadConfig(name)
        local clean = sanitize(name or self.Title)
        local json

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local path = self.ConfigFolder .. "/" .. clean .. ".json"
            if not isfile(path) then
                return false, "Config not found: " .. path
            end
            json = readfile(path)
        else
            json = Library._memoryConfigs[clean]
            if not json then
                return false, "In-memory config not found"
            end
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if not ok then
            return false, "Failed to decode config"
        end

        self:ApplyConfig(data)
        return true, data
    end

    function self:Notify(title, bodyText, duration)
        duration = duration or 3

        local note = new("Frame", {
            BackgroundColor3 = theme.Panel,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, 120),
            Size = UDim2.fromOffset(290, 84),
            Parent = gui
        })
        addCorner(note, 12)
        addStroke(note, theme.StrokeSoft, 1, 0.15)
        addPadding(note, 12, 12, 12, 12)

        local noteList = addList(note, 4)
        terminalLabel(note, "$ echo \"" .. tostring(title or "Notice") .. "\"", 12, theme.Accent, Enum.TextXAlignment.Left)
        terminalLabel(note, tostring(bodyText or ""), 12, theme.Text, Enum.TextXAlignment.Left)
        bindFrameHeight(note, noteList, 20)

        tween(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -16, 1, -16)
        }):Play()

        task.delay(duration, function()
            if note and note.Parent then
                local t = tween(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, -16, 1, 120),
                    BackgroundTransparency = 1
                })
                t:Play()
                t.Completed:Wait()
                if note then
                    note:Destroy()
                end
            end
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    miniBtn.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            body.Visible = false
            self:_setMainSize(UDim2.new(self.WindowSize.X.Scale, self.WindowSize.X.Offset, 0, 38), main.Position)
        else
            body.Visible = true
            self:_setMainSize(self.WindowSize, main.Position)
        end
    end)

    maxBtn.MouseButton1Click:Connect(function()
        if main.Size == self.WindowSize then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            self.StoredSize = main.Size
            self.StoredPosition = main.Position
            self:_setMainSize(UDim2.fromOffset(math.floor(viewport.X * 0.82), math.floor(viewport.Y * 0.82)), UDim2.new(0.5, 0, 0.5, 0))
        else
            self:_setMainSize(self.WindowSize, self.StoredPosition)
        end
    end)

    function self:CreateTab(name, tabOptions)
        tabOptions = tabOptions or {}
        local tab = setmetatable({}, Tab)
        tab.Window = self
        tab.Name = name or ("Tab " .. tostring(#self.Tabs + 1))
        tab.Icon = tabOptions.Icon or ">_"
        tab.Description = tabOptions.Description or "session"
        tab.Page = nil
        tab.Button = nil
        tab.Sections = {}

        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.SidebarCard,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 48),
            Text = "",
            Parent = tabScroll
        })
        addCorner(button, 10)
        addStroke(button, theme.StrokeSoft, 1, 0.2)

        local icon = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 36, 1, 0),
            Font = Enum.Font.Code,
            Text = tab.Icon,
            TextColor3 = theme.Accent,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button
        })

        local title = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 5),
            Size = UDim2.new(1, -54, 0, 18),
            Font = Enum.Font.Code,
            Text = tab.Name,
            TextColor3 = theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button
        })

        local desc = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 22),
            Size = UDim2.new(1, -54, 0, 16),
            Font = Enum.Font.Code,
            Text = tab.Description,
            TextColor3 = theme.SubText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button
        })

        local page = new("ScrollingFrame", {
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = pageHolder
        })
        local pagePadding = addPadding(page, 0, 4, 0, 0)
        local pageLayout = addList(page, 10)
        bindCanvas(page, pageLayout, 12)

        tab.Button = button
        tab.Page = page
        tab.PageLayout = pageLayout

        function tab:SetHero(heroOptions)
            heroOptions = heroOptions or {}
            if tab.Hero then
                tab.Hero:Destroy()
            end

            local hero = new("Frame", {
                Name = "Hero",
                BackgroundColor3 = theme.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 106),
                Parent = page
            })
            addCorner(hero, 12)
            addStroke(hero, theme.StrokeSoft, 1, 0.15)
            addPadding(hero, 14, 14, 14, 14)

            local heroList = addList(hero, 5)
            terminalLabel(hero, heroOptions.Command or ("$ open " .. string.lower(tab.Name:gsub("%s+", "_"))), 12, theme.Accent, Enum.TextXAlignment.Left)
            terminalLabel(hero, heroOptions.Title or tab.Name, 20, theme.Text, Enum.TextXAlignment.Left)
            terminalLabel(hero, heroOptions.Description or tab.Description, 12, theme.SubText, Enum.TextXAlignment.Left)

            local metaRow = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Parent = hero
            })
            local leftMeta = terminalLabel(metaRow, heroOptions.MetaLeft or "user@local", 11, theme.SubText, Enum.TextXAlignment.Left)
            leftMeta.Size = UDim2.new(0.5, 0, 1, 0)
            local rightMeta = terminalLabel(metaRow, heroOptions.MetaRight or "ready", 11, theme.Accent, Enum.TextXAlignment.Right)
            rightMeta.Position = UDim2.new(0.5, 0, 0, 0)
            rightMeta.Size = UDim2.new(0.5, 0, 1, 0)

            tab.Hero = hero
            return hero
        end

        function tab:Show()
            for _, existing in ipairs(self.Window.Tabs) do
                existing.Page.Visible = false
                tween(existing.Button, TweenInfo.new(0.12), {
                    BackgroundColor3 = theme.SidebarCard
                }):Play()
            end

            page.Visible = true
            tween(button, TweenInfo.new(0.12), {
                BackgroundColor3 = theme.AccentMuted
            }):Play()

            self.Window.CurrentTab = tab
        end

        function tab:AddSection(sectionName)
            local section = setmetatable({}, Section)
            section.Window = self.Window
            section.Tab = tab
            section.Name = sectionName or "Section"

            local wrap = new("Frame", {
                BackgroundColor3 = theme.PanelSoft,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 60),
                Parent = page
            })
            addCorner(wrap, 12)
            addStroke(wrap, theme.StrokeSoft, 1, 0.18)

            local header = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 12),
                Size = UDim2.new(1, -28, 0, 24),
                Parent = wrap
            })

            terminalLabel(header, "> " .. section.Name, 13, theme.Accent, Enum.TextXAlignment.Left)

            local body = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 42),
                Size = UDim2.new(1, -28, 0, 10),
                Parent = wrap
            })
            local bodyLayout = addList(body, 8)
            bindFrameHeight(body, bodyLayout, 0)

            local function updateWrap()
                wrap.Size = UDim2.new(1, -4, 0, 52 + bodyLayout.AbsoluteContentSize.Y)
            end
            updateWrap()
            bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWrap)

            section.Frame = wrap
            section.Body = body
            section.Layout = bodyLayout

            function section:AddLabel(text)
                local label = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Enum.Font.Code,
                    Text = tostring(text or ""),
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = body
                })

                return {
                    Instance = label,
                    SetText = function(_, newText)
                        label.Text = tostring(newText)
                    end
                }
            end

            function section:AddParagraph(titleText, bodyText)
                local block = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 52),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = body
                })
                addCorner(block, 10)
                addStroke(block, theme.StrokeSoft, 1, 0.25)
                addPadding(block, 10, 10, 9, 9)

                local blockLayout = addList(block, 3)
                terminalLabel(block, "$ " .. tostring(titleText or "info"), 12, theme.Accent, Enum.TextXAlignment.Left)
                local textLabel = terminalLabel(block, tostring(bodyText or ""), 12, theme.SubText, Enum.TextXAlignment.Left)
                textLabel.TextWrapped = true
                textLabel.AutomaticSize = Enum.AutomaticSize.Y
                bindFrameHeight(block, blockLayout, 18)

                return {
                    Instance = block,
                    SetBody = function(_, text)
                        textLabel.Text = tostring(text)
                    end
                }
            end

            function section:AddButton(opts)
                opts = opts or {}
                local titleText = opts.Title or "Button"

                local btn = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 38),
                    Text = "",
                    Parent = body
                })
                addCorner(btn, 10)
                addStroke(btn, theme.StrokeSoft, 1, 0.25)

                terminalLabel(btn, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 0)
                hover(btn, theme.PanelMuted, Color3.fromRGB(30, 34, 39))

                btn.MouseButton1Click:Connect(function()
                    if typeof(opts.Callback) == "function" then
                        opts.Callback()
                    end
                end)

                return {
                    Instance = btn,
                    Fire = function()
                        if typeof(opts.Callback) == "function" then
                            opts.Callback()
                        end
                    end
                }
            end

            function section:AddToggle(opts)
                opts = opts or {}
                local titleText = opts.Title or "Toggle"
                local flag = opts.Flag or titleText
                local state = opts.Default == true

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 42),
                    Parent = body
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                terminalLabel(holder, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 0)

                local switch = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.fromRGB(38, 41, 48),
                    BorderSizePixel = 0,
                    Text = "",
                    Position = UDim2.new(1, -58, 0.5, -10),
                    Size = UDim2.fromOffset(46, 20),
                    Parent = holder
                })
                addCorner(switch, 999)

                local knob = new("Frame", {
                    BackgroundColor3 = Color3.fromRGB(248, 248, 248),
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    Parent = switch
                })
                addCorner(knob, 999)

                local function setState(value, silent)
                    state = value == true
                    self.Window.Flags[flag] = state

                    if state then
                        tween(switch, TweenInfo.new(0.14), {BackgroundColor3 = theme.Accent}):Play()
                        tween(knob, TweenInfo.new(0.14), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                    else
                        tween(switch, TweenInfo.new(0.14), {BackgroundColor3 = Color3.fromRGB(38, 41, 48)}):Play()
                        tween(knob, TweenInfo.new(0.14), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                    end

                    if not silent then
                        if typeof(opts.Callback) == "function" then
                            opts.Callback(state)
                        end
                        if typeof(opts.Changed) == "function" then
                            opts.Changed(state)
                        end
                    end
                end

                switch.MouseButton1Click:Connect(function()
                    setState(not state, false)
                end)

                holder.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setState(not state, false)
                    end
                end)

                setState(state, true)
                self.Window:_registerFlag(flag, function() return state end, setState)

                return {
                    Instance = holder,
                    Set = setState,
                    Get = function() return state end
                }
            end

            function section:AddTextbox(opts)
                opts = opts or {}
                local titleText = opts.Title or "Textbox"
                local flag = opts.Flag or titleText
                local value = tostring(opts.Default or "")

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = body
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                terminalLabel(holder, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 2)

                local box = new("TextBox", {
                    BackgroundColor3 = theme.Window,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 0, 26),
                    Font = Enum.Font.Code,
                    PlaceholderText = opts.Placeholder or "type here...",
                    PlaceholderColor3 = theme.SubText,
                    Text = value,
                    TextColor3 = theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = holder
                })
                addCorner(box, 8)
                addStroke(box, theme.StrokeSoft, 1, 0.25)
                addPadding(box, 8, 8, 0, 0)

                local function setValue(newValue, silent)
                    value = tostring(newValue or "")
                    box.Text = value
                    self.Window.Flags[flag] = value

                    if not silent then
                        if typeof(opts.Callback) == "function" then
                            opts.Callback(value)
                        end
                        if typeof(opts.Changed) == "function" then
                            opts.Changed(value)
                        end
                    end
                end

                box.FocusLost:Connect(function()
                    setValue(box.Text, false)
                end)

                self.Window:_registerFlag(flag, function() return value end, setValue)

                return {
                    Instance = holder,
                    Set = setValue,
                    Get = function() return value end
                }
            end

            function section:AddSlider(opts)
                opts = opts or {}
                local titleText = opts.Title or "Slider"
                local flag = opts.Flag or titleText
                local minv = tonumber(opts.Min) or 0
                local maxv = tonumber(opts.Max) or 100
                local step = tonumber(opts.Increment) or 1
                local value = tonumber(opts.Default) or minv
                value = clamp(roundTo(value, step), minv, maxv)

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = body
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                terminalLabel(holder, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 2)

                local valueLabel = terminalLabel(holder, "", 12, theme.Accent, Enum.TextXAlignment.Right)
                valueLabel.Position = UDim2.new(0, 0, 0, 2)
                valueLabel.Size = UDim2.new(1, -12, 0, 18)

                local bar = new("Frame", {
                    BackgroundColor3 = theme.Window,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 38),
                    Size = UDim2.new(1, -24, 0, 10),
                    Parent = holder
                })
                addCorner(bar, 999)
                addStroke(bar, theme.StrokeSoft, 1, 0.25)

                local fill = new("Frame", {
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = bar
                })
                addCorner(fill, 999)

                local knob = new("Frame", {
                    BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Parent = bar
                })
                addCorner(knob, 999)

                local draggingSlider = false

                local function redraw()
                    local alpha = (value - minv) / (maxv - minv)
                    alpha = clamp(alpha, 0, 1)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    valueLabel.Text = tostring(value) .. tostring(opts.Suffix or "")
                end

                local function setValue(newValue, silent)
                    value = clamp(roundTo(tonumber(newValue) or minv, step), minv, maxv)
                    self.Window.Flags[flag] = value
                    redraw()

                    if not silent then
                        if typeof(opts.Callback) == "function" then
                            opts.Callback(value)
                        end
                        if typeof(opts.Changed) == "function" then
                            opts.Changed(value)
                        end
                    end
                end

                local function fromMouse(x)
                    local alpha = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    setValue(minv + ((maxv - minv) * alpha), false)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        fromMouse(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        fromMouse(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)

                redraw()
                self.Window:_registerFlag(flag, function() return value end, setValue)

                return {
                    Instance = holder,
                    Set = setValue,
                    Get = function() return value end
                }
            end

            function section:AddDropdown(opts)
                opts = opts or {}
                local titleText = opts.Title or "Dropdown"
                local flag = opts.Flag or titleText
                local items = opts.Options or {}
                local selected = opts.Default
                local open = false

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = body
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                terminalLabel(holder, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 2)

                local mainBtn = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Window,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 0, 26),
                    Text = "",
                    Parent = holder
                })
                addCorner(mainBtn, 8)
                addStroke(mainBtn, theme.StrokeSoft, 1, 0.25)

                local current = terminalLabel(mainBtn, selected and tostring(selected) or "[ select option ]", 12, selected and theme.Text or theme.SubText, Enum.TextXAlignment.Left)
                current.Position = UDim2.new(0, 10, 0, 0)
                current.Size = UDim2.new(1, -34, 1, 0)

                local arrow = terminalLabel(mainBtn, "v", 12, theme.Accent, Enum.TextXAlignment.Right)
                arrow.Size = UDim2.new(1, -10, 1, 0)

                local listWrap = new("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 62),
                    Size = UDim2.new(1, -24, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    Parent = holder
                })
                local listLayout = addList(listWrap, 4)

                local function setSelection(choice, silent)
                    selected = choice
                    current.Text = selected and tostring(selected) or "[ select option ]"
                    current.TextColor3 = selected and theme.Text or theme.SubText
                    self.Window.Flags[flag] = selected

                    if not silent then
                        if typeof(opts.Callback) == "function" then
                            opts.Callback(selected)
                        end
                        if typeof(opts.Changed) == "function" then
                            opts.Changed(selected)
                        end
                    end
                end

                local function resize()
                    if open then
                        holder.Size = UDim2.new(1, 0, 0, 68 + listLayout.AbsoluteContentSize.Y + 6)
                    else
                        holder.Size = UDim2.new(1, 0, 0, 68)
                    end
                end

                local function setOpen(state)
                    open = state == true
                    listWrap.Visible = open
                    arrow.Text = open and "^" or "v"
                    resize()
                end

                local function rebuild()
                    for _, child in ipairs(listWrap:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, item in ipairs(items) do
                        local option = new("TextButton", {
                            AutoButtonColor = false,
                            BackgroundColor3 = theme.Window,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = "",
                            Parent = listWrap
                        })
                        addCorner(option, 8)
                        addStroke(option, theme.StrokeSoft, 1, 0.25)
                        hover(option, theme.Window, Color3.fromRGB(26, 29, 34))

                        terminalLabel(option, tostring(item), 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 10, 0, 0)

                        option.MouseButton1Click:Connect(function()
                            setSelection(tostring(item), false)
                            setOpen(false)
                        end)
                    end

                    resize()
                end

                listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)

                mainBtn.MouseButton1Click:Connect(function()
                    setOpen(not open)
                end)

                rebuild()
                if selected ~= nil then
                    setSelection(selected, true)
                end

                self.Window:_registerFlag(flag, function() return selected end, setSelection)

                return {
                    Instance = holder,
                    Set = function(_, v) setSelection(v, false) end,
                    Get = function() return selected end,
                    Refresh = function(_, newItems, keep)
                        items = newItems or {}
                        rebuild()
                        if not keep then
                            setSelection(nil, true)
                        end
                    end
                }
            end

            function section:AddKeybind(opts)
                opts = opts or {}
                local titleText = opts.Title or "Keybind"
                local flag = opts.Flag or titleText
                local currentKey = opts.Default or Enum.KeyCode.RightShift
                local listening = false

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 42),
                    Parent = body
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                terminalLabel(holder, "$ " .. titleText, 12, theme.Text, Enum.TextXAlignment.Left).Position = UDim2.new(0, 12, 0, 0)

                local bindBtn = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Window,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -112, 0.5, -12),
                    Size = UDim2.fromOffset(98, 24),
                    Text = "",
                    Parent = holder
                })
                addCorner(bindBtn, 8)
                addStroke(bindBtn, theme.StrokeSoft, 1, 0.25)
                hover(bindBtn, theme.Window, Color3.fromRGB(26, 29, 34))

                local bindText = terminalLabel(bindBtn, "[" .. keyName(currentKey) .. "]", 12, theme.Accent, Enum.TextXAlignment.Center)
                bindText.Size = UDim2.new(1, 0, 1, 0)

                local function setKey(newKey, silent)
                    if typeof(newKey) == "string" then
                        local enum = Enum.KeyCode[newKey]
                        if enum then
                            newKey = enum
                        end
                    end

                    if typeof(newKey) ~= "EnumItem" then
                        return
                    end

                    currentKey = newKey
                    bindText.Text = "[" .. keyName(currentKey) .. "]"
                    self.Window.Flags[flag] = keyName(currentKey)

                    if not silent and typeof(opts.Changed) == "function" then
                        opts.Changed(currentKey)
                    end
                end

                bindBtn.MouseButton1Click:Connect(function()
                    listening = true
                    bindText.Text = "[ ... ]"
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then
                        return
                    end
                    if UserInputService:GetFocusedTextBox() then
                        return
                    end

                    if listening then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            listening = false
                            setKey(input.KeyCode, false)
                        end
                        return
                    end

                    if input.KeyCode == currentKey then
                        if typeof(opts.Callback) == "function" then
                            opts.Callback(currentKey)
                        end
                    end
                end)

                setKey(currentKey, true)
                self.Window:_registerFlag(flag, function() return keyName(currentKey) end, setKey)

                return {
                    Instance = holder,
                    Set = setKey,
                    Get = function() return currentKey end
                }
            end

            return section
        end

        button.MouseButton1Click:Connect(function()
            tab:Show()
        end)

        table.insert(self.Tabs, tab)

        if not tab.Hero then
            tab:SetHero({
                Title = tab.Name,
                Description = tab.Description,
                Command = "$ cd /" .. string.lower(tab.Name:gsub("%s+", "_"))
            })
        end

        if not self.CurrentTab then
            tab:Show()
        end

        return tab
    end

    return self
end

return Library
