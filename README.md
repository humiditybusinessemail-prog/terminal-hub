# AppleTerminalUI Revised

This version revises the main source so the library keeps a much stronger Apple Terminal identity while improving the internal page structure.

## What changed

- stronger macOS Terminal look
- dedicated sidebar home card
- clear tabs section in the sidebar
- per-page hero/header block
- cleaner page routing with independent scrolling pages
- improved section containers and control layout
- same reusable client-side executor workflow
- config save/load, notifications, keybinds, sliders, dropdowns, textboxes, and toggles

The visual identity, component design, API shape, and terminal styling are rebuilt around the Apple Terminal concept.

## Files

- `src/AppleTerminalUI.lua`
- `examples/Example.client.lua`

## Load the library

```lua
local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/humiditybusinessemail-prog/terminal-hub/main/src/AppleTerminalUI.lua"))()
```

## Basic usage

```lua
local Window = AppleTerminalUI:CreateWindow({
    Title = "Terminal Hub",
    Subtitle = "apple terminal identity",
    Size = UDim2.fromOffset(900, 580),
    ConfigFolder = "AppleTerminalUI"
})

local Tab = Window:CreateTab("Home", {
    Icon = "~/",
    Description = "overview page"
})

Tab:SetHero({
    Command = "$ ./terminal_hub",
    Title = "Terminal Hub",
    Description = "Page hero/header block"
})

local Section = Tab:AddSection("Quick Start")

Section:AddButton({
    Title = "Run Command",
    Callback = function()
        print("clicked")
    end
})

Section:AddToggle({
    Title = "Enable Feature",
    Flag = "enabled",
    Default = true,
    Callback = function(state)
        print(state)
    end
})

Section:AddTextbox({
    Title = "Username",
    Flag = "username",
    Default = "guest"
})

Section:AddSlider({
    Title = "WalkSpeed",
    Flag = "walkspeed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16
})

Section:AddDropdown({
    Title = "Mode",
    Flag = "mode",
    Options = {"Legit", "Stealth", "Debug"}
})

Section:AddKeybind({
    Title = "Toggle UI",
    Flag = "toggle_ui",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        Window:ToggleVisible()
    end
})
```

## Window API

```lua
Window:SetVisible(true)
Window:ToggleVisible()
Window:Destroy()
Window:GetFlag("enabled")
Window:SetFlag("enabled", false)
Window:GetConfig()
Window:SaveConfig("my_config")
Window:LoadConfig("my_config")
Window:Notify("Saved", "Config saved.", 3)
```

## Tab API

```lua
local Tab = Window:CreateTab("Combat", {
    Icon = ">_",
    Description = "combat related features"
})

Tab:SetHero({
    Command = "$ open combat",
    Title = "Combat",
    Description = "Hero card text"
})
```

## Notes

- `game:HttpGet(...)` should use the raw GitHub URL, not the `/blob/` page URL.
- Config files are saved with executor file APIs when available.
- If file APIs do not exist, configs fall back to in-memory session storage.
