-- Global Execution Bridge
local function ExecutePayload(source)
    if not source or source == "" then return end
    
    local func, compileError = loadstring(source)
    
    if func then
        local success, runtimeError = pcall(func)
        if not success then
            warn("Terminal Hub Runtime Error: " .. tostring(runtimeError))
        end
    else
        warn("Terminal Hub Syntax Error: " .. tostring(compileError))
    end
end

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
    TopBar = Color3.fromRGB(25, 27, 31),
    Sidebar = Color3.fromRGB(20, 22, 26),
    SidebarCard = Color3.fromRGB(24, 26, 31),
    Panel = Color3.fromRGB(22, 24, 29),
    PanelSoft = Color3.fromRGB(27, 30, 36),
    PanelMuted = Color3.fromRGB(18, 20, 24),
    Input = Color3.fromRGB(14, 16, 19),
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

local function new(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    return object
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = instance
    return stroke
end

local function addPadding(instance, left, right, top, bottom)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.Parent = instance
    return padding
end

local function addList(instance, padding)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = instance
    return layout
end

local function tween(object, info, properties)
    return TweenService:Create(object, info, properties)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function roundTo(value, increment)
    increment = increment or 1
    if increment <= 0 then
        return value
    end
    return math.floor((value / increment) + 0.5) * increment
end

local function sanitize(text)
    text = tostring(text or "default")
    text = text:gsub("[^%w%-%._ ]", "_")
    if text == "" then
        text = "default"
    end
    return text
end

local function bindCanvas(scroller, layout, extra)
    local function update()
        scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    update()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function bindHeight(frame, layout, extra)
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

local function hover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

local function terminalLabel(parent, text, size, color, alignment)
    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, size + 6),
        Font = Enum.Font.Code,
        Text = text or "",
        TextColor3 = color,
        TextSize = size,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
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
    self.Maximized = false
    self.WindowSize = options.Size or UDim2.fromOffset(860, 560)
    self.StoredPosition = options.Position or UDim2.new(0.5, 0, 0.5, 0)
    self.StoredSize = self.WindowSize

    local parent = getGuiParent()
    assert(parent, "AppleTerminalUI: no valid GUI parent")

    local gui = new("ScreenGui", {
        Name = options.GuiName or ("AppleTerminalUI_" .. HttpService:GenerateGUID(false)),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    })
    protectGui(gui)
    gui.Parent = parent
    self.ScreenGui = gui

    local shadow = new("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self.StoredPosition,
        Size = self.WindowSize + UDim2.fromOffset(60, 60),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.42,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = gui
    })
    self.Shadow = shadow

    local main = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self.StoredPosition,
        Size = self.WindowSize,
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = gui
    })
    addCorner(main, 14)
    addStroke(main, theme.WindowEdge, 1, 0.05)
    self.Main = main

    local topBar = new("Frame", {
        BackgroundColor3 = theme.TopBar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Parent = main
    })
    addCorner(topBar, 14)

    new("Frame", {
        BackgroundColor3 = theme.TopBar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -16),
        Size = UDim2.new(1, 0, 0, 16),
        Parent = topBar
    })

    local topTitle = new("TextLabel", {
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

    local traffic = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 72, 1, 0),
        Parent = topBar
    })
    local trafficLayout = addList(traffic, 8)
    trafficLayout.FillDirection = Enum.FillDirection.Horizontal
    trafficLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local closeButton = new("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = theme.Red,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Parent = traffic
    })
    addCorner(closeButton, 999)

    local minimizeButton = new("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Parent = traffic
    })
    addCorner(minimizeButton, 999)

    local maximizeButton = new("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = theme.Green,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Parent = traffic
    })
    addCorner(maximizeButton, 999)

    new("Frame", {
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = main
    })

    local body = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 39),
        Size = UDim2.new(1, 0, 1, -39),
        Parent = main
    })
    self.Body = body

    local sidebar = new("Frame", {
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 1, 0),
        Parent = body
    })
    self.Sidebar = sidebar

    new("Frame", {
        BackgroundColor3 = theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = sidebar
    })

    local sidebarInner = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 1, -24),
        Parent = sidebar
    })

    local homeCard = new("Frame", {
        BackgroundColor3 = theme.SidebarCard,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 110),
        Parent = sidebarInner
    })
    addCorner(homeCard, 12)
    addStroke(homeCard, theme.StrokeSoft, 1, 0.2)
    addPadding(homeCard, 12, 12, 12, 12)

    local homeLayout = addList(homeCard, 3)
    terminalLabel(homeCard, "$ login", 13, theme.Accent, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, self.Title, 18, theme.Text, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, self.Subtitle, 12, theme.SubText, Enum.TextXAlignment.Left)
    terminalLabel(homeCard, "tty: /dev/console", 12, theme.Accent, Enum.TextXAlignment.Left)

    local tabsLabel = terminalLabel(sidebarInner, "SECTIONS", 11, theme.SubText, Enum.TextXAlignment.Left)
    tabsLabel.Position = UDim2.new(0, 0, 0, 122)
    tabsLabel.Size = UDim2.new(1, 0, 0, 16)

    local tabScroll = new("ScrollingFrame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 144),
        Size = UDim2.new(1, 0, 1, -144),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        Parent = sidebarInner
    })
    local tabLayout = addList(tabScroll, 8)
    bindCanvas(tabScroll, tabLayout, 10)
    self.TabButtonHolder = tabScroll

    local contentWrap = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 220, 0, 0),
        Size = UDim2.new(1, -220, 1, 0),
        Parent = body
    })
    self.ContentWrap = contentWrap

    local pageHolder = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 16),
        Size = UDim2.new(1, -32, 1, -32),
        Parent = contentWrap
    })
    self.PageHolder = pageHolder

    local dragging = false
    local dragStart
    local startPosition

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
            main.Position = newPosition
            shadow.Position = newPosition
            self.StoredPosition = newPosition
        end
    end)

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
        local output = {}
        for flag, entry in pairs(self.FlagObjects) do
            local ok, value = pcall(entry.Get)
            if ok then
                output[flag] = value
            end
        end
        return output
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
        local cleanName = sanitize(name or self.Title)
        local json = HttpService:JSONEncode(self:GetConfig())

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local path = self.ConfigFolder .. "/" .. cleanName .. ".json"
            writefile(path, json)
            return true, path
        end

        Library._memoryConfigs[cleanName] = json
        return true, cleanName
    end

    function self:LoadConfig(name)
        local cleanName = sanitize(name or self.Title)
        local json

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local path = self.ConfigFolder .. "/" .. cleanName .. ".json"
            if not isfile(path) then
                return false, "Config not found: " .. path
            end
            json = readfile(path)
        else
            json = Library._memoryConfigs[cleanName]
            if not json then
                return false, "In-memory config not found"
            end
        end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if not ok then
            return false, "Failed to decode config"
        end

        self:ApplyConfig(decoded)
        return true, decoded
    end

    function self:Notify(title, bodyText, duration)
        duration = duration or 3

        local note = new("Frame", {
            BackgroundColor3 = theme.Panel,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, 120),
            Size = UDim2.fromOffset(300, 86),
            Parent = gui
        })
        addCorner(note, 12)
        addStroke(note, theme.StrokeSoft, 1, 0.15)
        addPadding(note, 12, 12, 12, 12)

        local noteLayout = addList(note, 4)
        terminalLabel(note, tostring(title or "Notice"), 13, theme.Accent, Enum.TextXAlignment.Left)
        local bodyLabel = terminalLabel(note, tostring(bodyText or ""), 12, theme.Text, Enum.TextXAlignment.Left)
        bodyLabel.TextWrapped = true
        bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
        bindHeight(note, noteLayout, 20)

        tween(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -16, 1, -16)
        }):Play()

        task.delay(duration, function()
            if note and note.Parent then
                local hide = tween(note, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, -16, 1, 120),
                    BackgroundTransparency = 1
                })
                hide:Play()
                hide.Completed:Wait()
                if note then
                    note:Destroy()
                end
            end
        end)
    end

    closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            body.Visible = false
            self:_setMainSize(UDim2.new(self.WindowSize.X.Scale, self.WindowSize.X.Offset, 0, 38), main.Position)
        else
            body.Visible = true
            self:_setMainSize(self.WindowSize, main.Position)
        end
    end)

    maximizeButton.MouseButton1Click:Connect(function()
        self.Maximized = not self.Maximized

        if self.Maximized then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            self.StoredPosition = main.Position
            self.StoredSize = main.Size
            self:_setMainSize(
                UDim2.fromOffset(math.floor(viewport.X * 0.82), math.floor(viewport.Y * 0.82)),
                UDim2.new(0.5, 0, 0.5, 0)
            )
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
        tab.Description = tabOptions.Description or "page"

        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = theme.SidebarCard,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 50),
            Text = "",
            Parent = tabScroll
        })
        addCorner(button, 10)
        addStroke(button, theme.StrokeSoft, 1, 0.2)

        local iconLabel = new("TextLabel", {
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

        local titleLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 6),
            Size = UDim2.new(1, -54, 0, 18),
            Font = Enum.Font.Code,
            Text = tab.Name,
            TextColor3 = theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button
        })

        local descriptionLabel = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 24),
            Size = UDim2.new(1, -54, 0, 14),
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
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = theme.Accent,
            Visible = false,
            Parent = pageHolder
        })
        addPadding(page, 0, 4, 0, 0)
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
                BackgroundColor3 = theme.Panel,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 118),
                Parent = page
            })
            addCorner(hero, 12)
            addStroke(hero, theme.StrokeSoft, 1, 0.15)
            addPadding(hero, 14, 14, 14, 14)

            local heroLayout = addList(hero, 5)
            terminalLabel(hero, heroOptions.Command or ("$ open " .. string.lower(tab.Name:gsub("%s+", "_"))), 12, theme.Accent, Enum.TextXAlignment.Left)
            terminalLabel(hero, heroOptions.Title or tab.Name, 20, theme.Text, Enum.TextXAlignment.Left)

            local desc = terminalLabel(hero, heroOptions.Description or tab.Description, 12, theme.SubText, Enum.TextXAlignment.Left)
            desc.TextWrapped = true
            desc.AutomaticSize = Enum.AutomaticSize.Y

            local metaRow = new("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Parent = hero
            })

            local leftMeta = terminalLabel(metaRow, heroOptions.MetaLeft or "shell: zsh", 11, theme.SubText, Enum.TextXAlignment.Left)
            leftMeta.Size = UDim2.new(0.5, 0, 1, 0)

            local rightMeta = terminalLabel(metaRow, heroOptions.MetaRight or "ready", 11, theme.Accent, Enum.TextXAlignment.Right)
            rightMeta.Position = UDim2.new(0.5, 0, 0, 0)
            rightMeta.Size = UDim2.new(0.5, 0, 1, 0)

            bindHeight(hero, heroLayout, 20)
            tab.Hero = hero
            return hero
        end

        function tab:Show()
            for _, existingTab in ipairs(self.Window.Tabs) do
                existingTab.Page.Visible = false
                tween(existingTab.Button, TweenInfo.new(0.12), {
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
                Size = UDim2.new(1, -28, 0, 20),
                Parent = wrap
            })
            terminalLabel(header, "> " .. section.Name, 13, theme.Accent, Enum.TextXAlignment.Left)

            local bodyFrame = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 40),
                Size = UDim2.new(1, -28, 0, 0),
                Parent = wrap
            })
            local bodyLayout = addList(bodyFrame, 8)

            local function updateWrap()
                wrap.Size = UDim2.new(1, -4, 0, 52 + bodyLayout.AbsoluteContentSize.Y)
            end
            updateWrap()
            bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWrap)

            section.Frame = wrap
            section.Body = bodyFrame
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
                    Parent = bodyFrame
                })

                return {
                    Instance = label,
                    SetText = function(_, newText)
                        label.Text = tostring(newText)
                    end
                }
            end

            function section:AddParagraph(titleText, bodyText)
                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 52),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)
                addPadding(holder, 10, 10, 9, 9)

                local layout = addList(holder, 3)
                terminalLabel(holder, tostring(titleText or "Notice"), 12, theme.Accent, Enum.TextXAlignment.Left)
                local textLabel = terminalLabel(holder, tostring(bodyText or ""), 12, theme.SubText, Enum.TextXAlignment.Left)
                textLabel.TextWrapped = true
                textLabel.AutomaticSize = Enum.AutomaticSize.Y
                bindHeight(holder, layout, 18)

                return {
                    Instance = holder,
                    SetBody = function(_, text)
                        textLabel.Text = tostring(text)
                    end
                }
            end

            function section:AddButton(options)
                options = options or {}

                local holder = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    Text = "",
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)
                hover(holder, theme.PanelMuted, Color3.fromRGB(30, 34, 39))

                local title = terminalLabel(holder, tostring(options.Title or "Button"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 3)
                title.Size = UDim2.new(1, -24, 1, -6)

                holder.MouseButton1Click:Connect(function()
                    if typeof(options.Callback) == "function" then
                        options.Callback()
                    end
                end)

                return {
                    Instance = holder,
                    Fire = function()
                        if typeof(options.Callback) == "function" then
                            options.Callback()
                        end
                    end
                }
            end

            function section:AddToggle(options)
                options = options or {}
                local flag = options.Flag or options.Title or "Toggle"
                local state = options.Default == true

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 42),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                local title = terminalLabel(holder, tostring(options.Title or "Toggle"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 0)
                title.Size = UDim2.new(1, -86, 1, 0)

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
                    Position = UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.fromOffset(16, 16),
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
                        if typeof(options.Callback) == "function" then
                            options.Callback(state)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(state)
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

            function section:AddTextbox(options)
                options = options or {}
                local flag = options.Flag or options.Title or "Textbox"
                local value = tostring(options.Default or "")

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                local title = terminalLabel(holder, tostring(options.Title or "Textbox"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 2)
                title.Size = UDim2.new(1, -24, 0, 18)

                local box = new("TextBox", {
                    BackgroundColor3 = theme.Input,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 0, 26),
                    Font = Enum.Font.Code,
                    PlaceholderText = options.Placeholder or "Type here...",
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
                        if typeof(options.Callback) == "function" then
                            options.Callback(value)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(value)
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

            function section:AddSlider(options)
                options = options or {}
                local flag = options.Flag or options.Title or "Slider"
                local minValue = tonumber(options.Min) or 0
                local maxValue = tonumber(options.Max) or 100
                local increment = tonumber(options.Increment) or 1
                local value = tonumber(options.Default) or minValue
                value = clamp(roundTo(value, increment), minValue, maxValue)

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                local title = terminalLabel(holder, tostring(options.Title or "Slider"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 2)
                title.Size = UDim2.new(1, -120, 0, 18)

                local valueLabel = terminalLabel(holder, "", 12, theme.Accent, Enum.TextXAlignment.Right)
                valueLabel.Position = UDim2.new(0, 0, 0, 2)
                valueLabel.Size = UDim2.new(1, -12, 0, 18)

                local bar = new("Frame", {
                    BackgroundColor3 = theme.Input,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 40),
                    Size = UDim2.new(1, -24, 0, 8),
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
                    local denominator = maxValue - minValue
                    local alpha = denominator == 0 and 0 or ((value - minValue) / denominator)
                    alpha = clamp(alpha, 0, 1)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                    valueLabel.Text = tostring(value) .. tostring(options.Suffix or "")
                end

                local function setValue(newValue, silent)
                    value = clamp(roundTo(tonumber(newValue) or minValue, increment), minValue, maxValue)
                    self.Window.Flags[flag] = value
                    redraw()

                    if not silent then
                        if typeof(options.Callback) == "function" then
                            options.Callback(value)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(value)
                        end
                    end
                end

                local function setFromMouse(mouseX)
                    local alpha = clamp((mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    setValue(minValue + ((maxValue - minValue) * alpha), false)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        setFromMouse(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromMouse(input.Position.X)
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

            function section:AddDropdown(options)
                options = options or {}
                local flag = options.Flag or options.Title or "Dropdown"
                local selected = options.Default
                local items = options.Options or {}
                local isOpen = false

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                local title = terminalLabel(holder, tostring(options.Title or "Dropdown"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 2)
                title.Size = UDim2.new(1, -24, 0, 18)

                local mainButton = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Input,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 32),
                    Size = UDim2.new(1, -24, 0, 26),
                    Text = "",
                    Parent = holder
                })
                addCorner(mainButton, 8)
                addStroke(mainButton, theme.StrokeSoft, 1, 0.25)

                local currentLabel = terminalLabel(mainButton, selected and tostring(selected) or "Select an option", 12, selected and theme.Text or theme.SubText, Enum.TextXAlignment.Left)
                currentLabel.Position = UDim2.new(0, 10, 0, 0)
                currentLabel.Size = UDim2.new(1, -30, 1, 0)

                local arrowLabel = terminalLabel(mainButton, "v", 12, theme.Accent, Enum.TextXAlignment.Right)
                arrowLabel.Position = UDim2.new(0, 0, 0, 0)
                arrowLabel.Size = UDim2.new(1, -10, 1, 0)

                local optionHolder = new("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 62),
                    Size = UDim2.new(1, -24, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    Parent = holder
                })
                local optionLayout = addList(optionHolder, 4)

                local function resize()
                    if isOpen then
                        holder.Size = UDim2.new(1, 0, 0, 68 + optionLayout.AbsoluteContentSize.Y + 8)
                    else
                        holder.Size = UDim2.new(1, 0, 0, 68)
                    end
                end

                local function setSelection(choice, silent)
                    selected = choice
                    currentLabel.Text = selected and tostring(selected) or "Select an option"
                    currentLabel.TextColor3 = selected and theme.Text or theme.SubText
                    self.Window.Flags[flag] = selected

                    if not silent then
                        if typeof(options.Callback) == "function" then
                            options.Callback(selected)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(selected)
                        end
                    end
                end

                local function setOpen(state)
                    isOpen = state == true
                    optionHolder.Visible = isOpen
                    arrowLabel.Text = isOpen and "^" or "v"
                    resize()
                end

                local function rebuild()
                    for _, child in ipairs(optionHolder:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, item in ipairs(items) do
                        local optionButton = new("TextButton", {
                            AutoButtonColor = false,
                            BackgroundColor3 = theme.Input,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = "",
                            Parent = optionHolder
                        })
                        addCorner(optionButton, 8)
                        addStroke(optionButton, theme.StrokeSoft, 1, 0.25)
                        hover(optionButton, theme.Input, Color3.fromRGB(26, 29, 34))

                        local optionText = terminalLabel(optionButton, tostring(item), 12, theme.Text, Enum.TextXAlignment.Left)
                        optionText.Position = UDim2.new(0, 10, 0, 0)
                        optionText.Size = UDim2.new(1, -20, 1, 0)

                        optionButton.MouseButton1Click:Connect(function()
                            setSelection(tostring(item), false)
                            setOpen(false)
                        end)
                    end

                    resize()
                end

                optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)

                mainButton.MouseButton1Click:Connect(function()
                    setOpen(not isOpen)
                end)

                rebuild()
                if selected ~= nil then
                    setSelection(selected, true)
                end
                self.Window:_registerFlag(flag, function() return selected end, setSelection)

                return {
                    Instance = holder,
                    Set = function(_, value)
                        setSelection(value, false)
                    end,
                    Get = function()
                        return selected
                    end,
                    Refresh = function(_, newItems, keepSelection)
                        items = newItems or {}
                        rebuild()
                        if not keepSelection then
                            setSelection(nil, true)
                        end
                    end
                }
            end

            function section:AddKeybind(options)
                options = options or {}
                local flag = options.Flag or options.Title or "Keybind"
                local currentKey = options.Default or Enum.KeyCode.RightShift
                local listening = false

                local holder = new("Frame", {
                    BackgroundColor3 = theme.PanelMuted,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 42),
                    Parent = bodyFrame
                })
                addCorner(holder, 10)
                addStroke(holder, theme.StrokeSoft, 1, 0.25)

                local title = terminalLabel(holder, tostring(options.Title or "Keybind"), 12, theme.Text, Enum.TextXAlignment.Left)
                title.Position = UDim2.new(0, 12, 0, 0)
                title.Size = UDim2.new(1, -120, 1, 0)

                local bindButton = new("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Input,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -112, 0.5, -12),
                    Size = UDim2.fromOffset(98, 24),
                    Text = "",
                    Parent = holder
                })
                addCorner(bindButton, 8)
                addStroke(bindButton, theme.StrokeSoft, 1, 0.25)
                hover(bindButton, theme.Input, Color3.fromRGB(26, 29, 34))

                local bindText = terminalLabel(bindButton, "[" .. keyName(currentKey) .. "]", 12, theme.Accent, Enum.TextXAlignment.Center)
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

                    if not silent and typeof(options.Changed) == "function" then
                        options.Changed(currentKey)
                    end
                end

                bindButton.MouseButton1Click:Connect(function()
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
                        if typeof(options.Callback) == "function" then
                            options.Callback(currentKey)
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

        tab:SetHero({
            Command = "$ open " .. string.lower(tab.Name:gsub("%s+", "_")),
            Title = tab.Name,
            Description = tab.Description,
            MetaLeft = "shell: zsh",
            MetaRight = "ready"
        })

        if not self.CurrentTab then
            tab:Show()
        end

        return tab
    end

    return self
end

return Library
