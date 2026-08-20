---@module 'hl'

-- local.conf is a per-machine configuration file for monitors and input devices.
require("local")

-- make 1–8 persistent so they always exist (optional)

hl.workspace_rule({
    workspace = 1,
    layout = "master",
})

hl.workspace_rule({
    workspace = 2,
    layout = "master",
})

hl.workspace_rule({
    workspace = 3,
    layout = "master",
})

hl.workspace_rule({
    workspace = 4,
})

hl.workspace_rule({
    workspace = 5,
})

hl.workspace_rule({
    workspace = 6,
})

hl.workspace_rule({
    workspace = 7,
})

hl.workspace_rule({
    workspace = 8,
})

local w1 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/catpucc.png"

local w2 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/arch-black-4k.png"

local w3 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/grafanimals2.jpg"

local w4 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/wp11135492-commodore-amiga-wallpapers.jpg"

local w5 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/pexels-sebastiaan9977-1480690.jpg"

local w6 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/wallhaven-arch.png"

local w7 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/grafanimals.jpg"

local w8 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/pexels-pixabay-162389.jpg"

local w9 = "hyprctl hyprpaper wallpaper ,~/Sync/Wiki/wallpapers/pexels-sebastiaan9977-1480693.jpg"

--##################

--## MY PROGRAMS ###

--##################

-- See https://wiki.hypr.land/Configuring/Keywords/

-- Set programs that you use

local terminal = "ghostty"

local fileManager = "cosmic-files"

local menu = "wofi --show drun"

--################

--## AUTOSTART ###

--################

-- Autostart necessary processes (like notifications daemons, status bars, etc.)

-- Or execute your favorite apps at launch like this:

-- exec-once = $terminal

-- exec-once = nm-applet &

-- exec-once = waybar & hyprpaper & firefox



-- exec-once = systemctl --user import-environment PATH XDG_CURRENT_DESKTOP XDG_SESSION_TYPE ENVIRONMENTD_LOADED GNUPGHOME EDITOR PASSWORD_STORE_DIR WEBRTC_PIPEWIRE_FORCE_COPY

-- exec-once = systemctl --user start hyprpolkitagent

-- exec-once = hypridle

-- exec-once = dunst -config ~/.config/dunst/dunstrc




--############################

--## ENVIRONMENTVARIABLES ###

--############################

-- See https://wiki.hypr.land/Configuring/Environment-variables/

hl.env("XCURSOR_SIZE", 24)

hl.env("HYPRCURSOR_SIZE", 24)

-- need to find a better  way for doing this, like UWSM

hl.env("GNUPGHOME", "/home/chrisq/.config/gnupg")

hl.env("EDITOR", "nvim")

hl.env("PAGER", "bat")

hl.env("PASSWORD_STORE_DIR", "/home/chrisq/Sync/Password-Store")

-- gtk input is broken in recent versions, use ghostty-ibus

hl.env("GTK_IM_MODULE", "ibus")

hl.env("XMODIFIERS", "@im=ibus")

--##################

--## PERMISSIONS ###

--##################

-- See https://wiki.hypr.land/Configuring/Permissions/

-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly

-- for security reasons

-- ecosystem {

--   enforce_permissions = 1

-- }

-- permission = /usr/(bin|local/bin)/grim, screencopy, allow

-- permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow

-- permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

--####################

--## LOOK AND FEEL ###

--####################

-- Refer to https://wiki.hypr.land/Configuring/Variables/

-- https://wiki.hypr.land/Configuring/Variables/#general

hl.config({
    general = {
        -- gap between screen edge and applications
        -- gaps_in = 3
        -- some other gap thing
        gaps_out = 0,
        border_size = 1,
        -- https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
        -- col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
        -- col.inactive_border = rgba(595959aa)
        -- caatppuccin macchiato-like
        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,
        -- Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(cba6f7ee)", "rgba(b7bdf8ee)" }, angle = 45 },
            inactive_border = "rgba(494d64aa)",
        },
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#decoration

hl.config({
    decoration = {
        rounding = 10,
        rounding_power = 2,
        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 0.85,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        -- https://wiki.hypr.land/Configuring/Variables/#blur
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#animations

hl.config({
    animations = {
        enabled = true,
        -- Default curves, see https://wiki.hypr.land/Configuring/Animations/#curves
        --        NAME,           X0,   Y0,   X1,   Y1
        -- Default animations, see https://wiki.hypr.land/Configuring/Animations/
        --           NAME,          ONOFF, SPEED, CURVE,        [STYLE]
    },
})

-- Ref https://wiki.hypr.land/Configuring/Workspace-Rules/

-- "Smart gaps" / "No gaps when only"

-- uncomment all if you wish to use that.

-- workspace = w[tv1], gapsout:0, gapsin:0

-- workspace = f[1], gapsout:0, gapsin:0

-- windowrule = bordersize 0, floating:0, onworkspace:w[tv1]

-- windowrule = rounding 0, floating:0, onworkspace:w[tv1]

-- windowrule = bordersize 0, floating:0, onworkspace:f[1]

-- windowrule = rounding 0, floating:0, onworkspace:f[1]

-- See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more

hl.config({
    dwindle = {
        preserve_split = true,
        -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Master-Layout/ for more

hl.config({
    master = {
        new_status = "slave",
    },
})

-- https://wiki.hypr.land/Configuring/Variables/#misc

hl.config({
    misc = {
        force_default_wallpaper = -1,
        -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true,
        -- If true disables the random hyprland logo / anime girl background. :(
    },
})

--############

--## INPUT ###

--############

-- https://wiki.hypr.land/Configuring/Variables/#input

hl.config({
    input = {
        kb_layout = "no,us",
        kb_variant = "nodeadkeys,",
        kb_options = "grp:shifts_toggle,compose:rctrl",
        follow_mouse = 1,
        sensitivity = 0,
        -- -1.0 - 1.0, 0 means no modification.
        touchpad = {
            natural_scroll = true,
        },
    },
})

--##################

--## KEYBINDINGS ###

--##################

-- See https://wiki.hypr.land/Configuring/Keywords/

local mainMod = "SUPER"

-- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more

--# application-related keybinds

hl.bind(mainMod .. " + " .. "return", hl.dsp.exec_cmd("ghostty"))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "C", hl.dsp.window.close())

-- bind = $mainMod, M, exit,

-- bind = $mainMod, space, exec, rofi -combi-modi drun,window,run -show combi -modi combi -matching fuzzy -display-combi ''

hl.bind(mainMod .. " + " .. "space", hl.dsp.exec_cmd("fuzzel"))

-- bind = $mainMod, P, pseudo, # dwindle

-- bind = $mainMod, M, workspace, setlayout, master

-- Copy password to clipboard

hl.bind(mainMod .. " + " .. "P", hl.dsp.exec_cmd("zsh -c 'cq_pass-clip'"))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "P", hl.dsp.exec_cmd("zsh -c 'cq_pass-auto --type'"))

-- Cycle workspaces on the current monitor

hl.bind(mainMod .. " + " .. "Tab", hl.dsp.exec_cmd("~/.local/bin/cq_hypr_next-on-output"))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "Tab", hl.dsp.exec_cmd("~/.local/bin/cq_hypr_prev-on-output"))

--# Windows and workspace management keybinds

local move_window = {
    left  = "l",
    right = "r",
    up    = "u",
    down  = "d",
    h     = "l",
    j     = "d",
    k     = "u",
    l     = "r",
}

for key, direction in pairs(move_window) do
    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ direction = direction })
    )
end

-- Move focus with mainMod + arrow keys
--
-- hl.bind(mainMod .. " + " .. "left", hl.dsp.focus({ direction = "left" }))
--
-- hl.bind(mainMod .. " + " .. "right", hl.dsp.focus({ direction = "right" }))
--
-- hl.bind(mainMod .. " + " .. "up", hl.dsp.focus({ direction = "up" }))
--
-- hl.bind(mainMod .. " + " .. "down", hl.dsp.focus({ direction = "down" }))
--
-- -- alternative vim-style keys
--
-- -- bind = $mainMod, h, movefocus, l
--
-- -- bind = $mainMod, j, movefocus, d
--
-- -- bind = $mainMod, k, movefocus, u
--
-- -- bind = $mainMod, l, movefocus, r
--
-- -- Move focused window with $mainMod+Shift+Arrows
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "left", { direction = "l" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "right", { direction = "r" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "up", { direction = "u" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "down", { direction = "d" })
--
-- -- also with vim-style keys
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "h", { direction = "l" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "j", { direction = "d" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "k", { direction = "u" })
--
-- hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "l", { direction = "r" })
--
-- Switch workspaces with mainMod + [0-9]

hl.bind(mainMod .. " + " .. 1, hl.dsp.focus({ workspace = 1 }))

--## If you want to switch wallpapers with workspaces, see line below. Var defined at top. 

-- bind= $mainmod, 1, exec, $w1     #mainmod + 1 switches to wallpaper $w1 on monitor as defined in the variable

hl.bind(mainMod .. " + " .. 2, hl.dsp.focus({ workspace = 2 }))

hl.bind(mainMod .. " + " .. 3, hl.dsp.focus({ workspace = 3 }))

hl.bind(mainMod .. " + " .. 4, hl.dsp.focus({ workspace = 4 }))

hl.bind(mainMod .. " + " .. 5, hl.dsp.focus({ workspace = 5 }))

hl.bind(mainMod .. " + " .. 6, hl.dsp.focus({ workspace = 6 }))

hl.bind(mainMod .. " + " .. 7, hl.dsp.focus({ workspace = 7 }))

hl.bind(mainMod .. " + " .. 8, hl.dsp.focus({ workspace = 8 }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 1, hl.dsp.window.move({ workspace = 1 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 2, hl.dsp.window.move({ workspace = 2 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 3, hl.dsp.window.move({ workspace = 3 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 4, hl.dsp.window.move({ workspace = 4 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 5, hl.dsp.window.move({ workspace = 5 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 6, hl.dsp.window.move({ workspace = 6 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 7, hl.dsp.window.move({ workspace = 7 }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 8, hl.dsp.window.move({ workspace = 8 }))

-- Toggle special workspaces "scratch1/2/3"

hl.bind(mainMod .. " + " .. "code:61", hl.dsp.workspace.toggle_special("scratch1"))

hl.bind(mainMod .. " + " .. "code:60", hl.dsp.workspace.toggle_special("scratch2"))

hl.bind(mainMod .. " + " .. "code:59", hl.dsp.workspace.toggle_special("scratch3"))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "code:61", hl.dsp.window.move({ workspace = "special:scratch1" }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "code:60", hl.dsp.window.move({ workspace = "special:scratch2" }))

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "code:59", hl.dsp.window.move({ workspace = "special:scratch3" }))

-- Scroll through existing workspaces with mainMod + scroll

hl.bind(mainMod .. " + " .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))

hl.bind(mainMod .. " + " .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging

hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

--# Layout keybinds

-- Top row: immediate visual changes

hl.bind(mainMod .. " + " .. "Q", hl.dsp.window.fullscreen())

-- toggle fullscreen

hl.bind(mainMod .. " + " .. "W", hl.dsp.window.float())

-- float / tile

hl.bind(mainMod .. " + " .. "E", hl.dsp.layout("togglesplit"))

-- split vs stacked/alt layout

-- Middle row: tiling layout refinements (master/dwindle)

hl.bind(mainMod .. " + " .. "A", hl.dsp.layout("addmaster"))

hl.bind(mainMod .. " + " .. "S", hl.dsp.layout("swapwithmaster"))

-- master workspace: promote focused window

hl.bind(mainMod .. " + " .. "D", hl.dsp.layout("removemaster"))

-- Bottom row: rarely used layout tricks / cosmetics

hl.bind(mainMod .. " + " .. "Z", hl.dsp.window.pseudo())

-- tiled, but keep natural window size

hl.bind(mainMod .. " + " .. "X", hl.dsp.group.toggle())

-- group/tab windows into one tile

-- bind = $mainMod, X, togglegroup               # group/tab windows into one tile

-- switch between different windows in a group created with mainMod + D

hl.bind(mainMod .. " + " .. "H", hl.dsp.group.next({ forward = false }))

hl.bind(mainMod .. " + " .. "L", hl.dsp.group.next())

--# Misc submaps

hl.bind(mainMod .. " + " .. "r", hl.dsp.submap("resize"))


hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.define_submap("resize", function()
    local opts = { repeating = true }

    hl.bind("left",  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), opts)
    hl.bind("down",  hl.dsp.window.resize({ x = 0, y = 50, relative = true }), opts)
    hl.bind("up",    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), opts)
    hl.bind("right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), opts)

    hl.bind("h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), opts)
    hl.bind("j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), opts)
    hl.bind("k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), opts)
    hl.bind("l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), opts)

    hl.bind("return", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + " .. 9, hl.dsp.submap("wmutils"))

hl.define_submap("wmutils", function()
    -- TODO: Random new wallpaper
    hl.bind("E", hl.dsp.exec_cmd(
        [[bash -lc 'f=$(mktemp); env | sort > "$f"; zenity --text-info --title="Hyprland environment" --filename="$f" --width=900 --height=700; rm -f "$f"']]
    ))
    hl.bind("R", hl.dsp.exec_cmd("hyprctl reload"))
    hl.bind("K", hl.dsp.exec_cmd("hyprctl kill"))
    hl.bind("N", hl.dsp.exec_cmd(
        [[ghostty -e nvim ~/.config/hypr/hyprland.lua]]
    ))
    hl.bind("H", hl.dsp.exec_cmd(
        [[cliphist list | rofi -dmenu | cliphist decode | wl-copy]]
    ))
    hl.bind("P", hl.dsp.exec_cmd("hyprshot -m region"))
    hl.bind("return", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.submap("reset"))
end)


hl.bind(mainMod .. " + " .. 0, hl.dsp.submap("system"))

-- bind = $mainMod, 0, exec, bash -lc 'notify-send "System mode" "S  Suspend\nR  Reboot\nL  Lock screen\nEnter/Esc  Exit" hyprctl dispatch submap system'

hl.define_submap("system", function()
    -- TODO: Random new wallpaper
    -- TODO: visualize in waybar
    -- TODO: add a "environment debug" command that shows env vars in a notification (like in my i3)
    hl.bind("S", hl.dsp.exec_cmd("bash -lc 'systemctl suspend; hyprctl dispatch submap reset'"))
    hl.bind("R", hl.dsp.exec_cmd("systemctl reboot"))
    hl.bind("E", hl.dsp.exec_cmd("bash -lc 'hyprctl dispatch exit'"))
    -- exit Hyprland
    hl.bind("L", hl.dsp.exec_cmd("bash -lc 'hyprlock & disown; hyprctl dispatch submap reset'"))
    hl.bind("return", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.submap("reset"))
end)


--# Multimedia keybinds

-- bind = $mainMod, P, exec, ~/.scripts/colorpicker.sh

-- bindel = ,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+

-- bindel = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

-- bindel = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

-- bindel = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))

-- Requires playerctl

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl --all-players play-pause"), { locked = true })

hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Debug Hyprland environment variables

hl.bind(mainMod .. " + " .. "O", hl.dsp.exec_cmd("sh -lc 'FH=$(mktemp); tr \"\\0\" \"\\n\" </proc/$(pidof -s Hyprland)/environ| sort > \"$FH\" ; zenity --text-info --title=\"Hyprland ENV\" --filename=\"$FH\" '"))

--#############################

--## WINDOWS AND WORKSPACES ###

--#############################

-- See https://wiki.hypr.land/Configuring/Window-Rules/ for more

-- See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules

-- Example windowrule

-- windowrule = float,class:^(kitty)$,title:^(kitty)$

-- zen

hl.window_rule({
    name  = "zen-no-border",
    match = {
        class = "zen",
    },
    border_size = 0,
})

-- steam

-- Catch all Steam games

hl.window_rule({
    name  = "tile",
    match = {
        class = "^(steam_app_)",
    },
    tile = true,
})

hl.window_rule({
    name  = "fullscreen",
    match = {
        class = "^(steam_app_)",
    },
    fullscreen = true,
})

hl.window_rule({
    name  = "noborder",
    match = {
        class = "^(steam_app_)",
    },
    border_size = false,
})

hl.window_rule({
    name  = "bordersize_0",
    match = {
        class = "^(steam_app_)",
    },
    -- TODO: review rule: "bordersize 0"
})

hl.window_rule({
    name  = "rounding_0",
    match = {
        class = "^(steam_app_)",
    },
    rounding = 0,
})

-- (Some Proton titles only expose the class at map time)

hl.window_rule({
    name  = "tile",
    match = {
        initial_class = "^(steam_app_)",
    },
    tile = true,
})

hl.window_rule({
    name  = "fullscreen",
    match = {
        initial_class = "^(steam_app_)",
    },
    fullscreen = true,
})

hl.window_rule({
    name  = "bordersize_0",
    match = {
        initial_class = "^(steam_app_)",
    },
    border_size = 0,
})

hl.window_rule({
    name  = "rounding_0",
    match = {
        initial_class = "^(steam_app_)",
    },
    rounding = 0,
})

-- Ignore maximize requests from apps. You'll probably like this.

hl.window_rule({
    name  = "suppressevent_maximi",
    match = {
        class = "(.*)",
    },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland

hl.window_rule({
    name  = "nofocus",
    match = {
        class = "^$",
        title = "^$",
        xwayland = 1,
        float = 1,
        fullscreen = 0,
        pin = 0,
    },
    no_focus = true,
})

hl.config({
    debug = {
        suppress_errors = true,
    },
})

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_TYPE=wayland ENVIRONMENTD_LOADED GNUPGHOME EDITOR PASSWORD_STORE_DIR WEBRTC_PIPEWIRE_FORCE_COPY HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("mako")
    hl.exec_cmd("waybar")
end)
