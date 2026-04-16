
Check our website: terminalhub.netlify.app

# AppleTerminalUI

AppleTerminalUI is a LuaU client-side UI library for Roblox with a strong macOS Terminal look.

## Included

- draggable window
- macOS traffic-light controls
- sidebar home card
- sidebar tabs list
- hero header per page
- sections
- buttons
- toggles
- textboxes
- sliders
- dropdowns
- keybinds
- notifications
- config save and load

## Load the library

```lua
local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/humiditybusinessemail-prog/terminal-hub/main/src/AppleTerminalUI.lua"))()
```

## Create a window

```lua
local Window = AppleTerminalUI:CreateWindow({
    Title = "Terminal Hub",
    Subtitle = "Control panel",
    Size = UDim2.fromOffset(920, 590),
    ConfigFolder = "AppleTerminalUI"
})
```

## Create a tab

```lua
local Tab = Window:CreateTab("Configuration", {
    Icon = "cfg",
    Description = "Controls"
})
```

## Set the page header

```lua
Tab:SetHero({
    Command = "$ open configuration",
    Title = "Configuration",
    Description = "Adjust the profile, speed, mode, and save your current setup.",
    MetaLeft = "profile: default",
    MetaRight = "editable"
})
```

## Create a section

```lua
local Section = Tab:AddSection("Profile")
```

## Add controls

```lua
Section:AddButton({
    Title = "Save Config",
    Callback = function()
        print("saved")
    end
})

Section:AddToggle({
    Title = "UI Enabled",
    Flag = "ui_enabled",
    Default = true,
    Callback = function(state)
        print(state)
    end
})

Section:AddTextbox({
    Title = "Profile Name",
    Flag = "profile_name",
    Default = "default",
    Placeholder = "Enter a profile name..."
})

Section:AddSlider({
    Title = "WalkSpeed",
    Flag = "walk_speed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16,
    Suffix = " ws"
})

Section:AddDropdown({
    Title = "Mode",
    Flag = "mode",
    Default = "Legit",
    Options = {"Legit", "Stealth", "Debug", "Custom"}
})

Section:AddKeybind({
    Title = "Hide / Show Window",
    Flag = "toggle_window_key",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Window:ToggleVisible()
    end
})
```

## Window methods

```lua
Window:SetVisible(true)
Window:ToggleVisible()
Window:Destroy()
Window:Notify("Saved", "Your config was written.", 3)
Window:GetFlag("walk_speed")
Window:SetFlag("walk_speed", 24)
Window:GetConfig()
Window:SaveConfig("my_config")
Window:LoadConfig("my_config")
```

## Notes

- Use the raw GitHub URL with `game:HttpGet(...)`.
- Config files use executor file APIs when they are available.
- If file APIs are unavailable, configs stay in memory for the current session.
- A full working example is in `examples/Example.client.lua`.
