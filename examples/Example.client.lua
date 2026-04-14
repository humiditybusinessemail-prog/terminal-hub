local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/humiditybusinessemail-prog/terminal-hub/main/src/AppleTerminalUI.lua"))()

local Window = AppleTerminalUI:CreateWindow({
    Title = "Terminal Hub",
    Subtitle = "Control panel",
    Size = UDim2.fromOffset(920, 590),
    ConfigFolder = "AppleTerminalUI"
})

local Home = Window:CreateTab("Home", {
    Icon = "~/",
    Description = "Overview"
})

Home:SetHero({
    Command = "$ ./terminal_hub",
    Title = "Terminal Hub",
    Description = "Welcome back. Pick a section on the left and adjust your settings from here.",
    MetaLeft = "shell: zsh",
    MetaRight = "connected"
})

local Welcome = Home:AddSection("Quick Actions")
Welcome:AddParagraph("Welcome", "This layout keeps the sidebar visible, the page header readable, and each section easy to scan.")
Welcome:AddButton({
    Title = "Say Hello",
    Callback = function()
        print("Terminal Hub is ready")
        Window:Notify("Terminal Hub", "Everything is loaded.", 2)
    end
})
Welcome:AddToggle({
    Title = "UI Enabled",
    Flag = "ui_enabled",
    Default = true,
    Callback = function(state)
        print("UI Enabled:", state)
    end
})
Welcome:AddKeybind({
    Title = "Hide / Show Window",
    Flag = "toggle_window_key",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Window:ToggleVisible()
    end
})

local Settings = Window:CreateTab("Configuration", {
    Icon = "cfg",
    Description = "Controls"
})

Settings:SetHero({
    Command = "$ open configuration",
    Title = "Configuration",
    Description = "Adjust the profile, speed, mode, and save your current setup.",
    MetaLeft = "profile: default",
    MetaRight = "editable"
})

local Profile = Settings:AddSection("Profile")
Profile:AddTextbox({
    Title = "Profile Name",
    Flag = "profile_name",
    Default = "default",
    Placeholder = "Enter a profile name...",
    Callback = function(text)
        print("Profile Name:", text)
    end
})
Profile:AddDropdown({
    Title = "Mode",
    Flag = "mode",
    Default = "Legit",
    Options = {"Legit", "Stealth", "Debug", "Custom"},
    Callback = function(choice)
        print("Mode:", choice)
    end
})
Profile:AddSlider({
    Title = "WalkSpeed",
    Flag = "walk_speed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16,
    Suffix = " ws",
    Callback = function(value)
        print("WalkSpeed:", value)
    end
})

local Storage = Settings:AddSection("Storage")
Storage:AddButton({
    Title = "Save Config",
    Callback = function()
        local ok, result = Window:SaveConfig("terminal_hub_example")
        if ok then
            Window:Notify("Saved", tostring(result), 3)
        else
            Window:Notify("Error", tostring(result), 3)
        end
    end
})
Storage:AddButton({
    Title = "Load Config",
    Callback = function()
        local ok, result = Window:LoadConfig("terminal_hub_example")
        if ok then
            Window:Notify("Loaded", "Your saved values were restored.", 3)
        else
            Window:Notify("Error", tostring(result), 3)
        end
    end
})
Storage:AddButton({
    Title = "Print Flags",
    Callback = function()
        for flag, value in pairs(Window:GetConfig()) do
            print(flag, value)
        end
        Window:Notify("Flags", "Current values were printed to the console.", 2)
    end
})
