# AppleTerminalUI

AppleTerminalUI is a Roblox client-side UI library styled after the macOS Apple Terminal application. It is designed to be simple to call from an executor, easy to extend, and ready to upload to GitHub.

## Features

- macOS Terminal-inspired interface
- Draggable window
- Close / minimize / maximize traffic-light controls
- Tabs
- Sections
- Buttons
- Labels
- Paragraphs
- Toggles
- Textboxes
- Sliders
- Dropdowns
- Keybinds
- Notifications
- Config save / load system
- Executor file API support (`writefile`, `readfile`, `isfile`, `makefolder`, `isfolder`)
- In-memory config fallback when file APIs are not available

---

## Repository layout

```text
apple-terminal-ui-lib/
├─ src/
│  └─ AppleTerminalUI.lua
├─ examples/
│  └─ Example.client.lua
├─ README.md
├─ LICENSE
└─ .gitignore
```

---

## How to call the library

### Option 1: loadstring from raw GitHub

```lua
local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/apple-terminal-ui/main/src/AppleTerminalUI.lua"))()
```

### Option 2: local file

```lua
local AppleTerminalUI = loadfile("AppleTerminalUI.lua")()
```

### Option 3: require as a module

If you convert it into a ModuleScript in Roblox Studio:

```lua
local AppleTerminalUI = require(path.to.AppleTerminalUI)
```

---

## Creating a window

```lua
local AppleTerminalUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/apple-terminal-ui/main/src/AppleTerminalUI.lua"))()

local Window = AppleTerminalUI:CreateWindow({
    Title = "Apple Terminal",
    Subtitle = "example interface",
    Size = UDim2.fromOffset(720, 520),
    ConfigFolder = "AppleTerminalUI"
})
```

### Window options

| Key | Type | Description |
|---|---|---|
| `Title` | string | Main window title |
| `Subtitle` | string | Small subtitle text under the title |
| `Size` | UDim2 | Window size |
| `ConfigFolder` | string | Folder used for saved config JSON files |
| `GuiName` | string | Optional ScreenGui name |

---

## Creating tabs

```lua
local MainTab = Window:CreateTab("Main")
local ConfigTab = Window:CreateTab("Config")
```

---

## Creating sections

```lua
local MainSection = MainTab:AddSection("General Controls")
```

Sections are containers that hold controls.

---

## Adding a label

```lua
MainSection:AddLabel("This is a simple label.")
```

---

## Adding a paragraph

```lua
MainSection:AddParagraph("Info", "This is a multi-line paragraph block.")
```

---

## Adding a button

```lua
MainSection:AddButton({
    Title = "Print Hello",
    Callback = function()
        print("Hello!")
    end
})
```

### Button fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Button text |
| `Callback` | function | Runs when the button is clicked |

---

## Adding a toggle

```lua
MainSection:AddToggle({
    Title = "Enable Feature",
    Flag = "feature_enabled",
    Default = true,
    Callback = function(state)
        print("Toggle state:", state)
    end
})
```

### Toggle fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Control label |
| `Flag` | string | Config key |
| `Default` | boolean | Starting value |
| `Callback` | function | Runs on change |
| `Changed` | function | Optional secondary change callback |

### Toggle methods

```lua
local Toggle = MainSection:AddToggle({...})
Toggle:Set(false)
print(Toggle:Get())
```

---

## Adding a textbox

```lua
MainSection:AddTextbox({
    Title = "Player Name",
    Flag = "player_name",
    Default = "Guest",
    Placeholder = "Type a name...",
    Callback = function(text)
        print(text)
    end
})
```

### Textbox fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Control label |
| `Flag` | string | Config key |
| `Default` | string | Starting text |
| `Placeholder` | string | Placeholder text |
| `Callback` | function | Runs when focus is lost |
| `Changed` | function | Optional secondary change callback |

### Textbox methods

```lua
local Box = MainSection:AddTextbox({...})
Box:Set("NewName")
print(Box:Get())
```

---

## Adding a slider

```lua
MainSection:AddSlider({
    Title = "WalkSpeed",
    Flag = "walk_speed",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 16,
    Suffix = " ws",
    Callback = function(value)
        print(value)
    end
})
```

### Slider fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Control label |
| `Flag` | string | Config key |
| `Min` | number | Minimum value |
| `Max` | number | Maximum value |
| `Increment` | number | Snap step |
| `Default` | number | Starting value |
| `Suffix` | string | Optional value suffix |
| `Callback` | function | Runs on change |
| `Changed` | function | Optional secondary change callback |

### Slider methods

```lua
local Slider = MainSection:AddSlider({...})
Slider:Set(42)
print(Slider:Get())
```

---

## Adding a dropdown

```lua
MainSection:AddDropdown({
    Title = "Mode",
    Flag = "selected_mode",
    Default = "Legit",
    Options = {"Legit", "Rage", "Stealth", "Custom"},
    Callback = function(selected)
        print(selected)
    end
})
```

### Dropdown fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Control label |
| `Flag` | string | Config key |
| `Default` | string | Starting selected value |
| `Options` | table | Array of entries |
| `Callback` | function | Runs on selection |
| `Changed` | function | Optional secondary change callback |

### Dropdown methods

```lua
local Dropdown = MainSection:AddDropdown({...})
Dropdown:Set("Custom")
print(Dropdown:Get())
Dropdown:Refresh({"A", "B", "C"}, false)
Dropdown:Open()
Dropdown:Close()
```

---

## Adding a keybind

```lua
MainSection:AddKeybind({
    Title = "Toggle UI Keybind",
    Flag = "ui_key",
    Default = Enum.KeyCode.RightShift,
    Changed = function(newKey)
        print("New key:", newKey.Name)
    end,
    Callback = function()
        Window:ToggleVisible()
    end
})
```

### Keybind fields

| Key | Type | Description |
|---|---|---|
| `Title` | string | Control label |
| `Flag` | string | Config key |
| `Default` | Enum.KeyCode | Starting bind |
| `Callback` | function | Runs when the bound key is pressed |
| `Changed` | function | Runs when the keybind is changed |

### Keybind methods

```lua
local Keybind = MainSection:AddKeybind({...})
Keybind:Set(Enum.KeyCode.LeftAlt)
print(Keybind:Get())
```

---

## Notifications

```lua
Window:Notify("Saved", "Config saved successfully.", 3)
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `titleText` | string | Notification title |
| `bodyText` | string | Notification body |
| `duration` | number | Seconds before closing |

---

## Working with flags

Any control with a `Flag` is automatically registered in the config system.

### Get one flag

```lua
print(Window:GetFlag("walk_speed"))
```

### Set one flag

```lua
Window:SetFlag("walk_speed", 32)
```

### Get full config table

```lua
local config = Window:GetConfig()
for flag, value in pairs(config) do
    print(flag, value)
end
```

---

## Saving and loading config

### Save config

```lua
local ok, result = Window:SaveConfig("my_config")
print(ok, result)
```

### Load config

```lua
local ok, result = Window:LoadConfig("my_config")
print(ok, result)
```

### Notes

- If the executor supports file APIs, configs save to:
  - `AppleTerminalUI/my_config.json`
- If file APIs are unavailable, configs are stored only in memory for that session.

---

## Window methods

```lua
Window:SetVisible(true)
Window:ToggleVisible()
Window:Destroy()
```

---

## Full example

A full working example is included in:

```text
examples/Example.client.lua
```

---

## Styling notes

The library uses:
- `Enum.Font.Code` for terminal-like typography
- dark layered backgrounds
- green accent text and controls
- macOS traffic-light window buttons

You can customize the theme in `src/AppleTerminalUI.lua` by editing `Library.Theme`.

---

## Uploading to GitHub

1. Upload the repository files.
2. Make the repo public if you want to use `game:HttpGet(...)`.
3. Use the raw GitHub link from the `src/AppleTerminalUI.lua` file.

Example raw URL pattern:

```text
https://raw.githubusercontent.com/<username>/<repository>/main/src/AppleTerminalUI.lua
```

---

## License

This project is licensed under the Apache License 2.0. See the `LICENSE` file for full text.
