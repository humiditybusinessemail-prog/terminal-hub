-- FULL EXAMPLE.CLIENT.LUA WITH EXECUTION BRIDGE
-- Based on AppleTerminalUI Framework

-- 1. Load the library
local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/humiditybusinessemail-prog/terminal-hub/main/src/AppleTerminalUI.lua"))()

-- 2. Define Global Execution Bridge
-- This handles the actual execution logic for all components below
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

-- 3. Create the Main Window
local Window = AppleTerminalUI:CreateWindow({
    Title = "Terminal Hub",
    Subtitle = "Execution Environment",
    Size = UDim2.fromOffset(920, 590),
    ConfigFolder = "AppleTerminalUI"
})

-- 4. HOME TAB: Main Execution & Quick Actions
local Home = Window:CreateTab("Home", {
    Icon = "~/",
    Description = "System Access"
})

Home:SetHero({
    Command = "$ sudo ./run_payload",
    Title = "Terminal Hub",
    Description = "Unified execution interface for Luau scripts.",
    MetaLeft = "shell: zsh",
    MetaRight = "admin"
})

local Console = Home:AddSection("Console Input")

-- TEXTBOX: Arbitrary Code Execution
Console:AddTextbox({
    Title = "Execute Raw Script",
    Flag = "raw_exec",
    Placeholder = "print('Hello World')...",
    Callback = function(text)
        ExecutePayload(text)
        Window:Notify("System", "Payload sent to compiler", 2)
    end
})

-- BUTTON: Specific Action
Console:AddButton({
    Title = "Run Debug Ping",
    Callback = function()
        ExecutePayload("print('Terminal Hub Ping: ' .. tostring(tick()))")
    end
})

-- 5. SCRIPTS TAB: Preset Library
local Scripts = Window:CreateTab("Scripts", {
    Icon = "bin",
    Description = "Payloads"
})

Scripts:SetHero({
    Command = "$ ls /usr/local/bin",
    Title = "Script Library",
    Description = "Select and run pre-configured scripts from the dropdown or toggles.",
    MetaLeft = "status: ready",
    MetaRight = "64-bit"
})

local Presets = Scripts:AddSection("Script Presets")

-- DROPDOWN: Script Selector
Presets:AddDropdown({
    Title = "Select Utility",
    Flag = "script_selector",
    Options = {"Infinite Yield", "Fly", "Full Bright"},
    Callback = function(choice)
        if choice == "Infinite Yield" then
            ExecutePayload("loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()")
        elseif choice == "Fly" then
            ExecutePayload("print('Fly script logic goes here')")
        elseif choice == "Full Bright" then
            ExecutePayload("game:GetService('Lighting').Brightness = 2; game:GetService('Lighting').ClockTime = 14")
        end
        Window:Notify("Library", choice .. " executed successfully", 2)
    end
})

-- TOGGLE: Persistent Logic
Presets:AddToggle({
    Title = "Speed Loop",
    Flag = "speed_toggle",
    Default = false,
    Callback = function(state)
        if state then
            ExecutePayload("game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100")
        else
            ExecutePayload("game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16")
        end
    end
})

-- SLIDER: Variable Injection
Presets:AddSlider({
    Title = "JumpPower Adjuster",
    Flag = "jp_slider",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(value)
        ExecutePayload("game.Players.LocalPlayer.Character.Humanoid.JumpPower = " .. value)
    end
})

-- 6. CONFIG TAB: Settings & Keybinds
local Config = Window:CreateTab("Config", {
    Icon = "cfg",
    Description = "System"
})

local Controls = Config:AddSection("Global Controls")

Controls:AddKeybind({
    Title = "Toggle UI Visibility",
    Flag = "ui_toggle_key",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Window:ToggleVisible()
    end
})

Controls:AddButton({
    Title = "Force Close Terminal",
    Callback = function()
        Window:Destroy()
    end
})

-- Notify Startup
Window:Notify("Terminal Hub", "Execution environment initialized.", 3)
