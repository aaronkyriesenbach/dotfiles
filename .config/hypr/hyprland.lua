local programs = require("programs")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },

    input = {
        sensitivity = -0.7,
        numlock_by_default = true,

        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
        },
    },

    scrolling = {
        column_width = 1.0,
        direction = "down",
    },

    misc = {
        disable_hyprland_logo   = true,
    },
})

hl.device({
    name        = "asup1206:00-093a:300d-touchpad",
    sensitivity = 0,
})

require("monitors")
require("binds")
require("style")

hl.on("hyprland.start", function()
    hl.exec_cmd("pkill waybar; waybar")
    hl.exec_cmd("pkill hypridle; hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("cider",   { workspace = "1" })
    hl.exec_cmd("firefox", { workspace = "2" })
end)
