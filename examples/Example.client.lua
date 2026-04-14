local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/apple-terminal-ui/main/src/AppleTerminalUI.lua"))()

local Window = AppleTerminalUI:CreateWindow({
    Title = "Apple Terminal",
    Subtitle = "example interface",
    Size = UDim2.fromOffset(720, 520),
    ConfigFolder = "AppleTerminalUI"
})

local MainTab = Window:CreateTab("Main")
local ConfigTab = Window:CreateTab("Config")

local MainSection = MainTab:AddSection("General Controls")
MainSection:AddLabel("This is an Apple Terminal styled Roblox UI library.")
MainSection:AddParagraph("Tip", "Use flags + save/load config to persist your toggle, slider, textbox, dropdown, and keybind values.")

MainSection:AddButton({
    Title = "Print Hello",
    Callback = function()
        print("Hello from AppleTerminalUI!")
        Window:Notify("Hello", "Button callback fired.", 2)
    end
})

MainSection:AddToggle({
    Title = "Enable Feature",
    Flag = "feature_enabled",
    Default = true,
    Callback = function(state)
        print("Toggle state:", state)
    end
})

MainSection:AddTextbox({
    Title = "Player Name",
    Flag = "player_name",
    Default = "Guest",
    Placeholder = "Type a name...",
    Callback = function(text)
        print("Textbox value:", text)
    end
})

MainSection:AddSlider({
    Title = "WalkSpeed",
    Flag = "walk_speed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16,
    Suffix = " ws",
    Callback = function(value)
        print("Slider value:", value)
    end
})

MainSection:AddDropdown({
    Title = "Mode",
    Flag = "selected_mode",
    Default = "Legit",
    Options = {"Legit", "Rage", "Stealth", "Custom"},
    Callback = function(selected)
        print("Dropdown selected:", selected)
    end
})

MainSection:AddKeybind({
    Title = "Toggle UI Keybind",
    Flag = "ui_key",
    Default = Enum.KeyCode.RightShift,
    Changed = function(newKey)
        print("Keybind changed to:", newKey.Name)
    end,
    Callback = function()
        Window:ToggleVisible()
    end
})

local ConfigSection = ConfigTab:AddSection("Configuration")
ConfigSection:AddButton({
    Title = "Save Config",
    Callback = function()
        local ok, result = Window:SaveConfig("example_config")
        if ok then
            Window:Notify("Config Saved", tostring(result), 3)
        else
            Window:Notify("Config Error", tostring(result), 3)
        end
    end
})

ConfigSection:AddButton({
    Title = "Load Config",
    Callback = function()
        local ok, result = Window:LoadConfig("example_config")
        if ok then
            Window:Notify("Config Loaded", "Values restored.", 3)
        else
            Window:Notify("Config Error", tostring(result), 3)
        end
    end
})

ConfigSection:AddButton({
    Title = "Show Current Flags",
    Callback = function()
        local config = Window:GetConfig()
        for flag, value in pairs(config) do
            print(flag, value)
        end
        Window:Notify("Flags Printed", "Check console output.", 2)
    end
})
