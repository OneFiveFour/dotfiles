-- Minimale Grundkonfiguration fuer Hyprland 0.57.2.
-- HYPER entspricht CTRL + SUPER + ALT (auf Caps Lock).

-- Monitoranordnung, Fensteraufteilung und Fenster-Tastenkuerzel.
require("window-management")

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "altgr-weur",
        kb_options = "",
    },
    decoration = {
        rounding = 16,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
        },
    },
})

-- Glas-Hintergrund fuer Inseln, Popup-Karten und Benachrichtigungen.
hl.layer_rule({
    name = "rightbar-glass-blur",
    match = { namespace = "^rightbar(-popup|-toast)?$" },
    blur = true,
    ignore_alpha = 0.01,
})

-- Rofi: gleicher Glaseffekt wie die Quickshell-Rightbar.
hl.layer_rule({
    name = "rofi-glass-blur",
    match = { namespace = "^rofi$" },
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

-- Screenshot-Bereich auswaehlen, speichern und in die Zwischenablage kopieren.
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o /home/florian/Screenshots"))

-- Vorhandene Anwendung auf ihrem aktuellen Workspace fokussieren.
-- Bei mehreren Fenstern gewinnt das zuletzt benutzte Fenster.
-- Nur ohne vorhandenes Fenster auf dem Buchstaben-Workspace starten.
local function bind_app_workspace(key, command, classes)
    local workspace = "name:" .. key
    hl.bind("SUPER + " .. key, function ()
        local target
        for _, window in ipairs(hl.get_windows()) do
            if window.mapped then
                for _, class in ipairs(classes) do
                    if window.class == class or window.initial_class == class then
                        if not target or window.focus_history_id < target.focus_history_id then
                            target = window
                        end
                        break
                    end
                end
            end
        end
        if target then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
            return
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        hl.exec_cmd(command, { workspace = workspace })
    end)
end

bind_app_workspace("T", "ghostty", { "com.mitchellh.ghostty" })
bind_app_workspace("B", "flatpak run app.zen_browser.zen", { "app.zen_browser.zen", "zen" })
bind_app_workspace("F", "/home/florian/.local/bin/strata", { "io.github.lgse.Strata" })
bind_app_workspace("C", "env XCURSOR_SIZE=24 chatgpt", { "Chatgpt", "chatgpt", "ChatGPT" })
bind_app_workspace("A", "flatpak run com.google.AndroidStudio", { "jetbrains-studio", "com.google.AndroidStudio" })
-- Anwendungssuche mit einzeln gedrueckter Super-Taste oeffnen/schliessen.
hl.bind("Super_L", hl.dsp.exec_cmd("pkill -x rofi || /home/florian/.local/bin/rofi-focus-or-launch"), { release = true })
hl.bind("Super_R", hl.dsp.exec_cmd("pkill -x rofi || /home/florian/.local/bin/rofi-focus-or-launch"), { release = true })
-- Benachrichtigungszentrale oeffnen oder schliessen.
hl.bind("SUPER + N", hl.dsp.exec_cmd("quickshell ipc -c rightbar call panel toggle notifications"))
-- Manuell sperren, ohne Anmeldefrist und ohne Einblendanimation.
hl.bind("SUPER + L", hl.dsp.exec_cmd("pgrep -x hyprlock > /dev/null || hyprlock --grace 0 --no-fade-in"))
hl.bind("CTRL + SUPER + ALT + SHIFT + E", hl.dsp.exit())

-- Kurze Einblendung fuer Launcher und Layer-Oberflaechen (120 ms).
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.2, bezier = "default" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.2, bezier = "default" })

-- Tastatur-Drehknopf / Medientasten: Standardausgabe wie in der Rightbar.
-- Ein Schritt pro Encoder-Impuls, ohne automatische Tastenwiederholung.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+ && quickshell ipc -c rightbar call panel volumeInput"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- && quickshell ipc -c rightbar call panel volumeInput"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
