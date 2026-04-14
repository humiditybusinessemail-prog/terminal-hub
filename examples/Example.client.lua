local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/humiditybusinessemail-prog/terminal-hub/main/src/AppleTerminalUI.lua"))()

local Window = AppleTerminalUI:CreateWindow({
    Title = "Terminal Hub",
    Subtitle = "session",
    Size = UDim2.fromOffset(900, 580),
    ConfigFolder = "AppleTerminalUI"
})

local Home = Window:CreateTab("Home", {
    Icon = "~/",
    Description = "dashboard"
})

Home:SetHero({
    Command = "$ ./terminal_hub",
    Title = "Terminal Hub",
    Description = "dashboard",
    MetaLeft = "shell: zsh",
    MetaRight = "ready"
})

local Main = Home:AddSection("Main")
Main:AddButton({
    Title = "Hello",
    Callback = function()
        print("Terminal Hub")
        Window:Notify("Terminal Hub", "Ready", 2)
    end
})
Main:AddToggle({
    Title = "Enabled",
    Flag = "enabled",
    Default = true,
    Callback = function(v)
        print("Enabled:", v)
    end
})
Main:AddKeybind({
    Title = "Toggle UI",
    Flag = "toggle_ui",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Window:ToggleVisible()
    end
})

local Settings = Window:CreateTab("Settings", {
    Icon = "cfg",
    Description = "config"
})

Settings:SetHero({
    Command = "$ open settings",
    Title = "Settings",
    Description = "config",
    MetaLeft = "profile: default",
    MetaRight = "client"
})

local Config = Settings:AddSection("Config")
Config:AddTextbox({
    Title = "Profile",
    Flag = "profile_name",
    Default = "default",
    Placeholder = "profile"
})
Config:AddSlider({
    Title = "WalkSpeed",
    Flag = "walkspeed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16,
    Suffix = " ws"
})
Config:AddDropdown({
    Title = "Mode",
    Flag = "mode",
    Default = "Legit",
    Options = {"Legit", "Stealth", "Debug", "Custom"}
})

local IO = Settings:AddSection("IO")
IO:AddButton({
    Title = "Save",
    Callback = function()
        local ok, result = Window:SaveConfig("terminal_hub_example")
        Window:Notify(ok and "Saved" or "Error", ok and "Done" or tostring(result), 3)
    end
})
IO:AddButton({
    Title = "Load",
    Callback = function()
        local ok, result = Window:LoadConfig("terminal_hub_example")
        Window:Notify(ok and "Loaded" or "Error", ok and "Done" or tostring(result), 3)
    end
})
IO:AddButton({
    Title = "Print",
    Callback = function()
        local cfg = Window:GetConfig()
        for k, v in pairs(cfg) do
            print(k, v)
        end
    end
})
