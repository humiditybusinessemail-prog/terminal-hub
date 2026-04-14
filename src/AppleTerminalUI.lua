--[[
    AppleTerminalUI
    A Roblox client-side UI library styled after the macOS Apple Terminal app.

    Features:
    - Window creation
    - Tabs
    - Sections
    - Buttons
    - Toggles
    - Textboxes
    - Sliders
    - Dropdowns
    - Keybinds
    - Labels / Paragraphs
    - Config save/load with executor file APIs when available
    - Draggable window
    - Minimize / maximize / close controls
]]

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
    Background = Color3.fromRGB(18, 18, 18),
    BackgroundSecondary = Color3.fromRGB(24, 24, 24),
    BackgroundTertiary = Color3.fromRGB(31, 31, 31),
    Border = Color3.fromRGB(55, 55, 55),
    Stroke = Color3.fromRGB(68, 68, 68),
    Accent = Color3.fromRGB(55, 255, 139),
    AccentDim = Color3.fromRGB(37, 150, 91),
    Text = Color3.fromRGB(230, 230, 230),
    SubText = Color3.fromRGB(150, 150, 150),
    Red = Color3.fromRGB(255, 95, 86),
    Yellow = Color3.fromRGB(255, 189, 46),
    Green = Color3.fromRGB(39, 201, 63),
    Black = Color3.fromRGB(0, 0, 0),
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function deepCopy(tbl)
    local out = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            out[key] = deepCopy(value)
        else
            out[key] = value
        end
    end
    return out
end

local function getExecutorGuiParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    if syn and typeof(syn.protect_gui) == "function" then
        return CoreGui
    end

    local success, result = pcall(function()
        return CoreGui
    end)

    if success and result then
        return result
    end

    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            return playerGui
        end
    end

    return nil
end

local function protectGuiIfPossible(gui)
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    elseif typeof(protectgui) == "function" then
        pcall(protectgui, gui)
    end
end

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Library.Theme.Stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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

local function addListLayout(instance, paddingPx, sortOrder)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, paddingPx or 0)
    layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = instance
    return layout
end

local function tween(instance, info, props)
    return TweenService:Create(instance, info, props)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function roundTo(value, increment)
    if increment <= 0 then
        return value
    end
    return math.floor((value / increment) + 0.5) * increment
end

local function sanitizeFileName(name)
    name = tostring(name or "default")
    name = name:gsub("[^%w%-%._ ]", "_")
    if name == "" then
        name = "default"
    end
    return name
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

local function bindCanvasToLayout(scrollingFrame, layout, extraPadding)
    local function update()
        local size = layout.AbsoluteContentSize
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, size.Y + (extraPadding or 0))
    end
    update()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function bindFrameHeightToLayout(frame, layout, extraPadding)
    local function update()
        local size = layout.AbsoluteContentSize
        frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, size.Y + (extraPadding or 0))
    end
    update()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
end

local function formatKeyCode(keyCode)
    if typeof(keyCode) == "EnumItem" then
        return keyCode.Name
    end
    return tostring(keyCode)
end

local function setButtonHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

local function createHeaderText(text, size, color, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, size + 8),
        Font = Enum.Font.Code,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 14,
        TextWrapped = false,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
end

local function normalizeOptions(options)
    options = options or {}
    return {
        Title = options.Title or options.Name or options.Text or "Untitled",
        Description = options.Description,
        Flag = options.Flag,
        Default = options.Default,
        Placeholder = options.Placeholder or "",
        Min = options.Min or 0,
        Max = options.Max or 100,
        Increment = options.Increment or 1,
        Suffix = options.Suffix or "",
        Options = options.Options or {},
        Callback = options.Callback,
        Changed = options.Changed,
        Value = options.Value,
        Multi = options.Multi,
    }
end

function Library:CreateWindow(options)
    options = options or {}
    local theme = deepCopy(Library.Theme)

    local self = setmetatable({}, Window)
    self.Title = options.Title or "AppleTerminalUI"
    self.Subtitle = options.Subtitle or "client-side ui library"
    self.Size = options.Size or UDim2.fromOffset(680, 480)
    self.Theme = theme
    self.Flags = {}
    self.FlagObjects = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.Minimized = false
    self.Maximized = false
    self.StoredSize = self.Size
    self.StoredPosition = UDim2.new(0.5, -340, 0.5, -240)
    self.ConfigFolder = options.ConfigFolder or "AppleTerminalUI"
    self.ScreenGui = nil
    self.Main = nil
    self.ContentHolder = nil
    self.TabButtonsHolder = nil
    self.TabPagesHolder = nil

    local parent = getExecutorGuiParent()
    assert(parent, "AppleTerminalUI: failed to find a valid GUI parent.")

    local guiName = options.GuiName or ("AppleTerminalUI_" .. HttpService:GenerateGUID(false))

    local screenGui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        Parent = nil,
    })

    protectGuiIfPossible(screenGui)
    screenGui.Parent = parent
    self.ScreenGui = screenGui

    local mainShadow = create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = self.Size + UDim2.fromOffset(40, 40),
        Position = self.StoredPosition,
        ZIndex = 0,
        Parent = screenGui,
    })

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Position = self.StoredPosition,
        Size = self.Size,
        ZIndex = 1,
        Parent = screenGui,
    })
    addCorner(main, 12)
    addStroke(main, theme.Border, 1, 0.1)
    self.Main = main
    self.Shadow = mainShadow

    local topBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Color3.fromRGB(21, 21, 21),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 2,
        Parent = main,
    })
    addCorner(topBar, 12)

    local topBarCover = create("Frame", {
        Name = "TopBarCover",
        BackgroundColor3 = Color3.fromRGB(21, 21, 21),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 2,
        Parent = topBar,
    })

    local circles = create("Frame", {
        Name = "Circles",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 70, 1, 0),
        ZIndex = 3,
        Parent = topBar,
    })
    addPadding(circles, 0, 0, 0, 0)
    local circlesLayout = addListLayout(circles, 8)
    circlesLayout.FillDirection = Enum.FillDirection.Horizontal
    circlesLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local closeButton = create("TextButton", {
        Name = "Close",
        BackgroundColor3 = theme.Red,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = circles,
    })
    addCorner(closeButton, 999)

    local minimizeButton = create("TextButton", {
        Name = "Minimize",
        BackgroundColor3 = theme.Yellow,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = circles,
    })
    addCorner(minimizeButton, 999)

    local maximizeButton = create("TextButton", {
        Name = "Maximize",
        BackgroundColor3 = theme.Green,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(12, 12),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = circles,
    })
    addCorner(maximizeButton, 999)

    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -150, 0, 0),
        Size = UDim2.new(0, 300, 1, 0),
        Font = Enum.Font.Code,
        Text = self.Title,
        TextColor3 = theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 3,
        Parent = topBar,
    })

    local subtitleLabel = create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -150, 1, -18),
        Size = UDim2.new(0, 300, 0, 16),
        Font = Enum.Font.Code,
        Text = self.Subtitle,
        TextColor3 = theme.SubText,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 3,
        Parent = topBar,
    })

    local divider = create("Frame", {
        Name = "Divider",
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 2,
        Parent = main,
    })

    local tabBar = create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 37),
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2,
        Parent = main,
    })
    self.TabButtonsHolder = tabBar

    local tabScroller = create("ScrollingFrame", {
        Name = "TabScroller",
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        Position = UDim2.new(0, 10, 0, 4),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 2,
        Size = UDim2.new(1, -20, 1, -8),
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = 3,
        Parent = tabBar,
    })
    local tabList = addListLayout(tabScroller, 8)
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center
    bindCanvasToLayout(tabScroller, tabList, 10)

    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 86),
        Size = UDim2.new(1, -20, 1, -96),
        ZIndex = 2,
        Parent = main,
    })
    self.ContentHolder = contentHolder

    local dragging = false
    local dragStart
    local startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            main.Position = newPosition
            mainShadow.Position = newPosition
            self.StoredPosition = newPosition
        end
    end)

    local function applyWindowSize(newSize, newPos)
        tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = newSize,
            Position = newPos or main.Position
        }):Play()

        tween(mainShadow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = newSize + UDim2.fromOffset(40, 40),
            Position = newPos or mainShadow.Position
        }):Play()
    end

    function self:SetVisible(state)
        self.ScreenGui.Enabled = state
    end

    function self:ToggleVisible()
        self.ScreenGui.Enabled = not self.ScreenGui.Enabled
    end

    function self:Destroy()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end

    function self:_registerFlag(flag, getter, setter, metadata)
        if not flag or flag == "" then
            return
        end

        self.FlagObjects[flag] = {
            Get = getter,
            Set = setter,
            Metadata = metadata or {},
        }

        self.Flags[flag] = getter()
    end

    function self:GetFlag(flag)
        local entry = self.FlagObjects[flag]
        if entry and entry.Get then
            return entry.Get()
        end
        return nil
    end

    function self:SetFlag(flag, value)
        local entry = self.FlagObjects[flag]
        if entry and entry.Set then
            entry.Set(value, true)
            self.Flags[flag] = entry.Get()
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

    function self:ApplyConfig(configTable)
        if type(configTable) ~= "table" then
            return
        end

        for flag, value in pairs(configTable) do
            local entry = self.FlagObjects[flag]
            if entry and entry.Set then
                pcall(function()
                    entry.Set(value, true)
                end)
            end
        end

        self.Flags = self:GetConfig()
    end

    function self:SaveConfig(fileName)
        local data = self:GetConfig()
        local json = HttpService:JSONEncode(data)
        local cleanName = sanitizeFileName(fileName or self.Title)

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local fullPath = self.ConfigFolder .. "/" .. cleanName .. ".json"
            writefile(fullPath, json)
            return true, fullPath
        else
            Library._memoryConfigs[cleanName] = json
            return true, cleanName
        end
    end

    function self:LoadConfig(fileName)
        local cleanName = sanitizeFileName(fileName or self.Title)
        local json

        if hasFileApi() then
            ensureFolder(self.ConfigFolder)
            local fullPath = self.ConfigFolder .. "/" .. cleanName .. ".json"
            if not isfile(fullPath) then
                return false, "Config file not found: " .. fullPath
            end
            json = readfile(fullPath)
        else
            json = Library._memoryConfigs[cleanName]
            if not json then
                return false, "In-memory config not found: " .. cleanName
            end
        end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(json)
        end)

        if not ok then
            return false, "Failed to decode config JSON."
        end

        self:ApplyConfig(decoded)
        return true, decoded
    end

    function self:CreateTab(tabName)
        local tabObject = setmetatable({}, Tab)
        tabObject.Window = self
        tabObject.Name = tabName or ("Tab " .. tostring(#self.Tabs + 1))

        local tabButton = create("TextButton", {
            Name = tabObject.Name .. "_Button",
            AutoButtonColor = false,
            BackgroundColor3 = theme.BackgroundTertiary,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(120, 28),
            Font = Enum.Font.Code,
            Text = tabObject.Name,
            TextColor3 = theme.SubText,
            TextSize = 13,
            ZIndex = 4,
            Parent = tabScroller,
        })
        addCorner(tabButton, 8)
        addStroke(tabButton, theme.Stroke, 1, 0.25)

        local page = create("ScrollingFrame", {
            Name = tabObject.Name .. "_Page",
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarImageColor3 = theme.Accent,
            ScrollBarThickness = 4,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 3,
            Parent = contentHolder,
        })
        addPadding(page, 0, 4, 0, 0)
        local pageLayout = addListLayout(page, 10)
        bindCanvasToLayout(page, pageLayout, 16)

        tabObject.Button = tabButton
        tabObject.Page = page
        tabObject.PageLayout = pageLayout

        function tabObject:AddSection(sectionName)
            local sectionObject = setmetatable({}, Section)
            sectionObject.Window = self.Window
            sectionObject.Tab = tabObject
            sectionObject.Name = sectionName or "Section"

            local sectionFrame = create("Frame", {
                Name = sectionObject.Name .. "_Section",
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 60),
                AutomaticSize = Enum.AutomaticSize.None,
                ZIndex = 4,
                Parent = page,
            })
            addCorner(sectionFrame, 10)
            addStroke(sectionFrame, theme.Border, 1, 0.2)

            local header = create("Frame", {
                Name = "Header",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -24, 0, 24),
                Position = UDim2.new(0, 12, 0, 10),
                ZIndex = 5,
                Parent = sectionFrame,
            })

            local title = create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Code,
                Text = sectionObject.Name,
                TextColor3 = theme.Accent,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = header,
            })

            local body = create("Frame", {
                Name = "Body",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0, 38),
                Size = UDim2.new(1, -24, 0, 10),
                ZIndex = 5,
                Parent = sectionFrame,
            })

            local bodyLayout = addListLayout(body, 8)
            bindFrameHeightToLayout(body, bodyLayout, 0)

            local function updateSectionHeight()
                sectionFrame.Size = UDim2.new(1, -4, 0, 48 + bodyLayout.AbsoluteContentSize.Y)
            end

            updateSectionHeight()
            bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionHeight)

            sectionObject.Frame = sectionFrame
            sectionObject.Body = body
            sectionObject.Layout = bodyLayout

            function sectionObject:AddLabel(text)
                local label = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Code,
                    Text = text or "",
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 6,
                    Parent = body,
                })
                return {
                    Instance = label,
                    SetText = function(_, newText)
                        label.Text = tostring(newText)
                    end
                }
            end

            function sectionObject:AddParagraph(titleText, bodyText)
                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 58),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.35)
                addPadding(holder, 10, 10, 8, 8)

                local inner = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 10),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = holder,
                })
                local innerLayout = addListLayout(inner, 4)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Code,
                    Text = titleText or "Paragraph",
                    TextColor3 = theme.Accent,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = inner,
                })

                local textLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.Code,
                    Text = bodyText or "",
                    TextColor3 = theme.SubText,
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = inner,
                })

                bindFrameHeightToLayout(holder, innerLayout, 16)

                return {
                    Instance = holder,
                    SetBody = function(_, newBody)
                        textLabel.Text = tostring(newBody)
                    end
                }
            end

            function sectionObject:AddButton(options)
                options = normalizeOptions(options)

                local button = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 34),
                    Font = Enum.Font.Code,
                    Text = "> " .. options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(button, 8)
                addStroke(button, theme.Stroke, 1, 0.25)

                setButtonHover(button, theme.BackgroundTertiary, Color3.fromRGB(42, 42, 42))

                button.MouseButton1Click:Connect(function()
                    if typeof(options.Callback) == "function" then
                        options.Callback()
                    end
                end)

                return {
                    Instance = button,
                    Fire = function()
                        if typeof(options.Callback) == "function" then
                            options.Callback()
                        end
                    end,
                    SetText = function(_, text)
                        button.Text = "> " .. tostring(text)
                    end,
                }
            end

            function sectionObject:AddToggle(options)
                options = normalizeOptions(options)

                local state = options.Default == true

                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.25)

                local titleLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -80, 1, 0),
                    Font = Enum.Font.Code,
                    Text = options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })

                local toggleButton = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -58, 0.5, -10),
                    Size = UDim2.fromOffset(46, 20),
                    Text = "",
                    ZIndex = 7,
                    Parent = holder,
                })
                addCorner(toggleButton, 999)

                local knob = create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(250, 250, 250),
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 8,
                    Parent = toggleButton,
                })
                addCorner(knob, 999)

                local function setToggle(value, silent)
                    state = value == true
                    if state then
                        tween(toggleButton, TweenInfo.new(0.15), {
                            BackgroundColor3 = theme.Accent
                        }):Play()

                        tween(knob, TweenInfo.new(0.15), {
                            Position = UDim2.new(1, -18, 0.5, -8)
                        }):Play()
                    else
                        tween(toggleButton, TweenInfo.new(0.15), {
                            BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                        }):Play()

                        tween(knob, TweenInfo.new(0.15), {
                            Position = UDim2.new(0, 2, 0.5, -8)
                        }):Play()
                    end

                    self.Window.Flags[options.Flag or options.Title] = state

                    if not silent then
                        if typeof(options.Callback) == "function" then
                            options.Callback(state)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(state)
                        end
                    end
                end

                toggleButton.MouseButton1Click:Connect(function()
                    setToggle(not state, false)
                end)

                holder.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setToggle(not state, false)
                    end
                end)

                setToggle(state, true)
                self.Window:_registerFlag(options.Flag or options.Title, function()
                    return state
                end, setToggle, {
                    Type = "Toggle",
                    Default = options.Default,
                })

                return {
                    Instance = holder,
                    Set = setToggle,
                    Get = function()
                        return state
                    end,
                }
            end

            function sectionObject:AddTextbox(options)
                options = normalizeOptions(options)

                local value = tostring(options.Default or "")

                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 64),
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.25)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 6),
                    Size = UDim2.new(1, -24, 0, 18),
                    Font = Enum.Font.Code,
                    Text = options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })

                local box = create("TextBox", {
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Position = UDim2.new(0, 12, 0, 30),
                    Size = UDim2.new(1, -24, 0, 24),
                    Font = Enum.Font.Code,
                    PlaceholderColor3 = theme.SubText,
                    PlaceholderText = options.Placeholder,
                    Text = value,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })
                addCorner(box, 6)
                addStroke(box, theme.Border, 1, 0.3)
                addPadding(box, 8, 8, 0, 0)

                local function setTextbox(newValue, silent)
                    value = tostring(newValue or "")
                    box.Text = value
                    self.Window.Flags[options.Flag or options.Title] = value

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
                    setTextbox(box.Text, false)
                end)

                self.Window:_registerFlag(options.Flag or options.Title, function()
                    return value
                end, setTextbox, {
                    Type = "Textbox",
                    Default = options.Default,
                })

                return {
                    Instance = holder,
                    Set = setTextbox,
                    Get = function()
                        return value
                    end,
                    SetPlaceholder = function(_, text)
                        box.PlaceholderText = tostring(text)
                    end,
                }
            end

            function sectionObject:AddSlider(options)
                options = normalizeOptions(options)

                local minValue = tonumber(options.Min) or 0
                local maxValue = tonumber(options.Max) or 100
                local increment = tonumber(options.Increment) or 1
                local current = tonumber(options.Default) or minValue
                current = clamp(roundTo(current, increment), minValue, maxValue)

                local draggingSlider = false

                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.25)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 6),
                    Size = UDim2.new(1, -120, 0, 18),
                    Font = Enum.Font.Code,
                    Text = options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })

                local valueLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -108, 0, 6),
                    Size = UDim2.new(0, 96, 0, 18),
                    Font = Enum.Font.Code,
                    Text = "",
                    TextColor3 = theme.Accent,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 7,
                    Parent = holder,
                })

                local bar = create("Frame", {
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 38),
                    Size = UDim2.new(1, -24, 0, 10),
                    ZIndex = 7,
                    Parent = holder,
                })
                addCorner(bar, 999)
                addStroke(bar, theme.Border, 1, 0.25)

                local fill = create("Frame", {
                    BackgroundColor3 = theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = 8,
                    Parent = bar,
                })
                addCorner(fill, 999)

                local knob = create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    ZIndex = 9,
                    Parent = bar,
                })
                addCorner(knob, 999)

                local function updateSliderVisuals()
                    local percentage = (current - minValue) / (maxValue - minValue)
                    percentage = clamp(percentage, 0, 1)
                    fill.Size = UDim2.new(percentage, 0, 1, 0)
                    knob.Position = UDim2.new(percentage, 0, 0.5, 0)
                    valueLabel.Text = tostring(current) .. tostring(options.Suffix or "")
                end

                local function setSlider(newValue, silent)
                    local numeric = tonumber(newValue) or minValue
                    numeric = clamp(roundTo(numeric, increment), minValue, maxValue)

                    current = numeric
                    self.Window.Flags[options.Flag or options.Title] = current
                    updateSliderVisuals()

                    if not silent then
                        if typeof(options.Callback) == "function" then
                            options.Callback(current)
                        end
                        if typeof(options.Changed) == "function" then
                            options.Changed(current)
                        end
                    end
                end

                local function setSliderFromX(mouseX)
                    local barX = bar.AbsolutePosition.X
                    local barWidth = bar.AbsoluteSize.X
                    local alpha = clamp((mouseX - barX) / barWidth, 0, 1)
                    local value = minValue + ((maxValue - minValue) * alpha)
                    setSlider(value, false)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        setSliderFromX(input.Position.X)
                    end
                end)

                knob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setSliderFromX(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)

                updateSliderVisuals()

                self.Window:_registerFlag(options.Flag or options.Title, function()
                    return current
                end, setSlider, {
                    Type = "Slider",
                    Default = options.Default,
                    Min = minValue,
                    Max = maxValue,
                    Increment = increment,
                })

                return {
                    Instance = holder,
                    Set = setSlider,
                    Get = function()
                        return current
                    end,
                }
            end

            function sectionObject:AddDropdown(options)
                options = normalizeOptions(options)

                local items = options.Options or {}
                local selected = options.Default
                local isOpen = false

                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 68),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.25)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 6),
                    Size = UDim2.new(1, -24, 0, 18),
                    Font = Enum.Font.Code,
                    Text = options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })

                local currentButton = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 30),
                    Size = UDim2.new(1, -24, 0, 26),
                    Font = Enum.Font.Code,
                    Text = selected and tostring(selected) or "[ select option ]",
                    TextColor3 = selected and theme.Text or theme.SubText,
                    TextSize = 13,
                    ZIndex = 7,
                    Parent = holder,
                })
                addCorner(currentButton, 6)
                addStroke(currentButton, theme.Border, 1, 0.3)

                local optionHolder = create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 0, 60),
                    Size = UDim2.new(1, -24, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 7,
                    Parent = holder,
                })
                local optionLayout = addListLayout(optionHolder, 4)

                local function applySelection(value, silent)
                    selected = value
                    currentButton.Text = value and tostring(value) or "[ select option ]"
                    currentButton.TextColor3 = value and theme.Text or theme.SubText
                    self.Window.Flags[options.Flag or options.Title] = selected

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
                    if isOpen then
                        holder.Size = UDim2.new(1, 0, 0, 68 + optionLayout.AbsoluteContentSize.Y + 6)
                    else
                        holder.Size = UDim2.new(1, 0, 0, 68)
                    end
                end

                local function rebuildOptions()
                    for _, child in ipairs(optionHolder:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end

                    for _, entry in ipairs(items) do
                        local text = tostring(entry)
                        local optionButton = create("TextButton", {
                            AutoButtonColor = false,
                            BackgroundColor3 = theme.Background,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 24),
                            Font = Enum.Font.Code,
                            Text = text,
                            TextColor3 = theme.Text,
                            TextSize = 12,
                            ZIndex = 8,
                            Parent = optionHolder,
                        })
                        addCorner(optionButton, 6)
                        addStroke(optionButton, theme.Border, 1, 0.35)
                        setButtonHover(optionButton, theme.Background, Color3.fromRGB(35, 35, 35))

                        optionButton.MouseButton1Click:Connect(function()
                            applySelection(text, false)
                            setOpen(false)
                        end)
                    end

                    if isOpen then
                        holder.Size = UDim2.new(1, 0, 0, 68 + optionLayout.AbsoluteContentSize.Y + 6)
                    end
                end

                optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if isOpen then
                        holder.Size = UDim2.new(1, 0, 0, 68 + optionLayout.AbsoluteContentSize.Y + 6)
                    end
                end)

                currentButton.MouseButton1Click:Connect(function()
                    setOpen(not isOpen)
                end)

                rebuildOptions()
                if selected ~= nil then
                    applySelection(selected, true)
                else
                    self.Window.Flags[options.Flag or options.Title] = nil
                end

                self.Window:_registerFlag(options.Flag or options.Title, function()
                    return selected
                end, function(newValue, silent)
                    applySelection(newValue, silent)
                end, {
                    Type = "Dropdown",
                    Default = options.Default,
                })

                return {
                    Instance = holder,
                    Set = function(_, value)
                        applySelection(value, false)
                    end,
                    Get = function()
                        return selected
                    end,
                    Refresh = function(_, newOptions, keepSelection)
                        items = newOptions or {}
                        rebuildOptions()
                        if not keepSelection then
                            applySelection(nil, true)
                        end
                    end,
                    Open = function()
                        setOpen(true)
                    end,
                    Close = function()
                        setOpen(false)
                    end,
                }
            end

            function sectionObject:AddKeybind(options)
                options = normalizeOptions(options)

                local currentKey = options.Default or Enum.KeyCode.RightShift
                local listening = false

                local holder = create("Frame", {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    ZIndex = 6,
                    Parent = body,
                })
                addCorner(holder, 8)
                addStroke(holder, theme.Stroke, 1, 0.25)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -150, 1, 0),
                    Font = Enum.Font.Code,
                    Text = options.Title,
                    TextColor3 = theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = holder,
                })

                local bindButton = create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -110, 0.5, -12),
                    Size = UDim2.fromOffset(98, 24),
                    Font = Enum.Font.Code,
                    Text = "[" .. formatKeyCode(currentKey) .. "]",
                    TextColor3 = theme.Accent,
                    TextSize = 12,
                    ZIndex = 7,
                    Parent = holder,
                })
                addCorner(bindButton, 6)
                addStroke(bindButton, theme.Border, 1, 0.35)
                setButtonHover(bindButton, theme.Background, Color3.fromRGB(35, 35, 35))

                local function setBind(newKey, silent)
                    if typeof(newKey) == "string" then
                        local keyEnum = Enum.KeyCode[newKey]
                        if keyEnum then
                            newKey = keyEnum
                        end
                    end

                    if typeof(newKey) ~= "EnumItem" then
                        return
                    end

                    currentKey = newKey
                    bindButton.Text = "[" .. formatKeyCode(currentKey) .. "]"
                    self.Window.Flags[options.Flag or options.Title] = formatKeyCode(currentKey)

                    if not silent and typeof(options.Changed) == "function" then
                        options.Changed(currentKey)
                    end
                end

                bindButton.MouseButton1Click:Connect(function()
                    listening = true
                    bindButton.Text = "[ ... ]"
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
                            setBind(input.KeyCode, false)
                        end
                        return
                    end

                    if input.KeyCode == currentKey then
                        if typeof(options.Callback) == "function" then
                            options.Callback(currentKey)
                        end
                    end
                end)

                setBind(currentKey, true)

                self.Window:_registerFlag(options.Flag or options.Title, function()
                    return formatKeyCode(currentKey)
                end, setBind, {
                    Type = "Keybind",
                    Default = formatKeyCode(currentKey),
                })

                return {
                    Instance = holder,
                    Set = setBind,
                    Get = function()
                        return currentKey
                    end,
                }
            end

            return sectionObject
        end

        function tabObject:Show()
            for _, existingTab in ipairs(self.Window.Tabs) do
                existingTab.Page.Visible = false
                tween(existingTab.Button, TweenInfo.new(0.12), {
                    BackgroundColor3 = theme.BackgroundTertiary,
                    TextColor3 = theme.SubText
                }):Play()
            end

            self.Page.Visible = true
            tween(self.Button, TweenInfo.new(0.12), {
                BackgroundColor3 = Color3.fromRGB(28, 42, 33),
                TextColor3 = theme.Accent
            }):Play()

            self.Window.CurrentTab = self
        end

        tabButton.MouseButton1Click:Connect(function()
            tabObject:Show()
        end)

        table.insert(self.Tabs, tabObject)

        if not self.CurrentTab then
            tabObject:Show()
        end

        return tabObject
    end

    function self:Notify(titleText, bodyText, duration)
        duration = duration or 3

        local notification = create("Frame", {
            BackgroundColor3 = theme.BackgroundSecondary,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, 120),
            Size = UDim2.fromOffset(260, 74),
            ZIndex = 20,
            Parent = screenGui,
        })
        addCorner(notification, 10)
        addStroke(notification, theme.Border, 1, 0.2)
        addPadding(notification, 12, 12, 10, 10)

        local layout = addListLayout(notification, 4)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Code,
            Text = titleText or "Notification",
            TextColor3 = theme.Accent,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notification,
        })

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Code,
            Text = bodyText or "",
            TextColor3 = theme.Text,
            TextWrapped = true,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notification,
        })

        bindFrameHeightToLayout(notification, layout, 20)

        tween(notification, TweenInfo.new(0.2), {
            Position = UDim2.new(1, -16, 1, -16)
        }):Play()

        task.delay(duration, function()
            if notification and notification.Parent then
                local closeTween = tween(notification, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -16, 1, 120),
                    BackgroundTransparency = 1
                })
                closeTween:Play()
                closeTween.Completed:Wait()
                notification:Destroy()
            end
        end)
    end

    closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized

        if self.Minimized then
            contentHolder.Visible = false
            tabBar.Visible = false
            applyWindowSize(UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 36), main.Position)
        else
            contentHolder.Visible = true
            tabBar.Visible = true
            applyWindowSize(self.Size, main.Position)
        end
    end)

    maximizeButton.MouseButton1Click:Connect(function()
        self.Maximized = not self.Maximized

        if self.Maximized then
            self.StoredSize = main.Size
            self.StoredPosition = main.Position
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
            local newSize = UDim2.fromOffset(math.floor(viewport.X * 0.9), math.floor(viewport.Y * 0.85))
            local newPos = UDim2.new(0.5, 0, 0.5, 0)
            applyWindowSize(newSize, newPos)
        else
            applyWindowSize(self.Size, self.StoredPosition)
        end
    end)

    return self
end

return Library
