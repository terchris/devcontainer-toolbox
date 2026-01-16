---
title: Menu System
sidebar_position: 4
---

# Menu System - Dialog Tool

The `dev-setup` menu uses **[dialog](https://invisible-island.net/dialog/)** - a tool for creating text-based user interfaces (TUI) in shell scripts.

---

## Why Dialog?

| Feature | Benefit |
|---------|---------|
| **Terminal-based** | Works in SSH, containers, any terminal |
| **Keyboard navigation** | Arrow keys, Tab, Enter for navigation |
| **No dependencies** | Part of most Linux distributions |
| **Accessible** | Works with screen readers |
| **Scriptable** | Captures user input via exit codes and stdout |

---

## Dialog Installation

Dialog is installed in the base devcontainer image (Dockerfile.base):

```dockerfile
RUN apt-get update && apt-get install -y dialog
```

---

## Dialog Widgets

### 1. Menu Widget (`--menu`)

Primary navigation - single selection from a list:

```bash
choice=$(dialog --clear \
    --title "Main Menu" \
    --menu "Choose an option:" \
    20 80 12 \           # height width menu-height
    "1" "Browse & Install Tools" \
    "2" "Manage Services" \
    "3" "Setup & Configuration" \
    2>&1 >/dev/tty)
```

### 2. Menu with Item Help (`--item-help`)

Adds context-sensitive help text at bottom of screen:

```bash
choice=$(dialog --clear \
    --item-help \
    --title "Select Tool" \
    --menu "Choose a tool:" \
    20 80 12 \
    "1" "Go Runtime" "Install Go development environment" \
    "2" "Python" "Install Python with pip and tools" \
    2>&1 >/dev/tty)
```

### 3. Checklist Widget (`--checklist`)

Multiple selection with on/off toggles:

```bash
selected=$(dialog --clear \
    --title "Auto-Start Services" \
    --checklist "Select services to auto-start:" \
    20 80 12 \
    "1" "Nginx Proxy" "on" \
    "2" "OTEL Collector" "off" \
    2>&1 >/dev/tty)
```

### 4. Input Box (`--inputbox`)

Text input for parameters:

```bash
version=$(dialog --clear \
    --title "Version" \
    --inputbox "Enter Go version:" \
    8 60 \
    2>&1 >/dev/tty)
```

### 5. Message Box (`--msgbox`)

Display information or errors:

```bash
dialog --title "Success" \
    --msgbox "Installation complete!" \
    8 50
```

### 6. Yes/No Dialog (`--yesno`)

Confirmation prompts:

```bash
if dialog --title "Confirm" --yesno "Proceed with installation?" 8 50; then
    # User said yes
fi
```

---

## Dialog Output Handling

Dialog writes selections to stderr (not stdout), so we redirect:

```bash
# Capture selection
choice=$(dialog ... 2>&1 >/dev/tty)

# Check exit code
if [[ $? -ne 0 ]]; then
    # User pressed ESC or Cancel
    return
fi
```

---

## Dialog Dimensions

Standard dimensions used in dev-setup.sh:

```bash
DIALOG_HEIGHT=20   # Total dialog height
DIALOG_WIDTH=80    # Total dialog width
MENU_HEIGHT=12     # Number of visible menu items
```

---

## Status Icons in Menus

The system uses Unicode/emoji for status display:

| Icon | Meaning |
|------|---------|
| `✅` | Installed / Configured / Running |
| `❌` | Not installed / Not configured / Stopped |
| `⏸️` | Service stopped |
| `[AI]`, `[DEV]` | Category prefixes |

---

## References

- [Dialog Manual](https://invisible-island.net/dialog/dialog.html)
- [Architecture](./) - System architecture overview
