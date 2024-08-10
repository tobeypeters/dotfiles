#!/usr/bin/env python3

import i3ipc

# Maximum length of window names to display
MAX_NAME_LENGTH = 25

# Configuration dictionary to map application classes to preferred name type and icon (optional)
APP_CONFIG = {
    "Alacritty":        {"name_type": "title", "icon": " "},
    "code":             {"name_type": "custom", "custom_name": "Code Editor", "icon": ""},
    "spotify":          {"name_type": "custom", "custom_name": "Spotify", "icon": ""},
}

def truncate_name(name, max_length):
    return name if len(name) <= max_length else name[:max_length - 3] + "..."

def get_appropriate_name(window):
    app_class = window.window_class
    if app_class in APP_CONFIG:
        config = APP_CONFIG[app_class]
        if config["name_type"] == "title":
            return window.name
        elif config["name_type"] == "instance":
            return window.window_instance
        elif config["name_type"] == "custom":
            return config["custom_name"]
    # Default to window title if no specific configuration is found
    return window.name

def get_app_icon(window):
    app_class = window.window_class
    if app_class in APP_CONFIG and "icon" in APP_CONFIG[app_class]:
        return APP_CONFIG[app_class]["icon"]
    return ""

def get_open_windows():
    i3 = i3ipc.Connection()
    focused = i3.get_tree().find_focused()
    windows = focused.workspace().leaves()
    window_names = []

    for win in windows:
        name = truncate_name(get_appropriate_name(win), MAX_NAME_LENGTH) if win.name else "Unnamed"
        icon = get_app_icon(win)
        if win.id == focused.id:
            window_names.append(f"%{{F#FFFFFF}}{icon} {name}%{{F-}}")  # Active window (white text)
        else:
            window_names.append(f"%{{F#888888}}{icon} {name}%{{F-}}")  # Inactive window (dimmed text)

    # Cleanly exit i3ipc connection
    i3.main_quit()

    return " | ".join(window_names)

if __name__ == "__main__":
    print(get_open_windows())