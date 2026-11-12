-- Minimale Grundkonfiguration fuer Hyprland 0.57.2.
-- HYPER entspricht CTRL + SUPER + ALT (auf Caps Lock).

-- Monitoranordnung wie unter GNOME: Portrait links, Landscape rechts.
-- Positionen beziehen sich auf die gedrehte Groesse bei 100 % Skalierung.
hl.monitor({
    output = "DP-3",
    mode = "2560x1440@59.95",
    position = "0x0",
    scale = 1,
    transform = 1,
    -- Workaround fuer NVIDIA/HDR-Anzeigefehler in Hyprland 0.57.
    supports_hdr = -1,
})

hl.monitor({
    output = "DP-4",
    mode = "2560x1440@59.95",
    position = "1440x579",
    scale = 1,
    transform = 0,
})

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "altgr-weur",
        kb_options = "",
    },
    general = {
        layout = "dwindle",
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
    },
    decoration = {
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
        },
    },
    binds = {
        window_direction_monitor_fallback = true,
    },
    dwindle = {
        preserve_split = true,
    },
})

-- Glas-Hintergrund fuer Inseln, Popup-Karten und Benachrichtigungen.
hl.layer_rule({
    name = "rightbar-glass-blur",
    match = { namespace = "^rightbar(-popup|-toast)?$" },
    blur = true,
    ignore_alpha = 0.01,
})

-- Einmal beim Sitzungsstart; kein globaler Autostart unter GNOME.
hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
    -- Automatische Sperre und Monitor-Standby in Hyprland.
    hl.exec_cmd("hypridle")
    -- Hintergrundbilder nur fuer diese Hyprland-Sitzung.
    hl.exec_cmd("hyprpaper")
    -- Rechte Leiste und einheitliche Popups fuer diese Hyprland-Sitzung.
    hl.exec_cmd("quickshell -d -n -c rightbar")
end)

-- Grundlegende Bedienung.
hl.bind("CTRL + SUPER + ALT + Return", hl.dsp.exec_cmd("ghostty"))
-- Anwendungssuche beim Loslassen einer einzeln gedrueckten Super-Taste.
hl.bind("Super_L", hl.dsp.exec_cmd("rofi -show drun"), { release = true })
hl.bind("Super_R", hl.dsp.exec_cmd("rofi -show drun"), { release = true })
-- Benachrichtigungszentrale oeffnen oder schliessen.
hl.bind("CTRL + SUPER + ALT + N", hl.dsp.exec_cmd("quickshell ipc -c rightbar call panel toggle notifications"))
-- Manuell sperren, ohne Anmeldefrist und ohne Einblendanimation.
hl.bind("CTRL + SUPER + ALT + L", hl.dsp.exec_cmd("pgrep -x hyprlock > /dev/null || hyprlock --grace 0 --no-fade-in"))
hl.bind("CTRL + SUPER + ALT + SHIFT + Q", hl.dsp.window.close())
hl.bind("CTRL + SUPER + ALT + SHIFT + E", hl.dsp.exit())

-- Aktives Fenster verschieben; am Monitorrand zum Nachbarmonitor wechseln.
hl.bind("CTRL + SUPER + ALT + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Fokus in Pfeilrichtung wechseln, auch zwischen Monitoren.
hl.bind("CTRL + SUPER + ALT + left", hl.dsp.focus({ direction = "left" }))
hl.bind("CTRL + SUPER + ALT + right", hl.dsp.focus({ direction = "right" }))
hl.bind("CTRL + SUPER + ALT + up", hl.dsp.focus({ direction = "up" }))
hl.bind("CTRL + SUPER + ALT + down", hl.dsp.focus({ direction = "down" }))
