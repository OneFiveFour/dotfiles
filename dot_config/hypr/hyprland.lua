-- Minimale Grundkonfiguration fuer Hyprland 0.57.2.
-- SUPER bezeichnet die Windows-/Super-Taste.

-- Monitoranordnung wie unter GNOME: Portrait links, Landscape rechts.
-- Positionen beziehen sich auf die gedrehte Groesse bei 100 % Skalierung.
hl.monitor({
    output = "DP-3",
    mode = "2560x1440@59.95",
    position = "0x0",
    scale = 1,
    transform = 1,
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
    dwindle = {
        preserve_split = true,
    },
})

-- Einmal beim Sitzungsstart; kein globaler Autostart unter GNOME.
hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
    -- Hintergrundbilder nur fuer diese Hyprland-Sitzung.
    hl.exec_cmd("hyprpaper")
    -- Benachrichtigungsdienst nur fuer die Hyprland-Sitzung.
    hl.exec_cmd("swaync")
    -- Statusleiste nur beim Start dieser Hyprland-Sitzung.
    hl.exec_cmd("waybar")
end)

-- Grundlegende Bedienung.
hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
-- Anwendungssuche; Rofi laeuft nur bei Bedarf.
hl.bind("SUPER + space", hl.dsp.exec_cmd("rofi -show drun"))
-- Benachrichtigungszentrale oeffnen oder schliessen.
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client --toggle-panel --skip-wait"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
