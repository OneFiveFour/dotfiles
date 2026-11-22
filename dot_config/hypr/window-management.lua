-- Zentrale Konfiguration fuer Monitoranordnung und Fensterbedienung.
-- Geladen durch hyprland.lua mit require("window-management").
-- HYPER = CTRL + SUPER + ALT, bei dir auf Caps Lock.
-- Fokus: HYPER + Pfeil; Verschieben: HYPER + SHIFT + Pfeil.
-- Am linken Ende der Scrolling-Reihe wechselt der Fokus zum linken Monitor.
--
-- LINKS: DP-3, Hochkant, Dwindle-Tiling.
-- RECHTS: DP-4, Hauptmonitor, horizontales Scrolling mit voller Fensterbreite.
-- Die Regeln bestimmen die Aufteilung vorhandener/neuer Fenster pro Monitor.
-- Es gibt derzeit keine feste Zuordnung einzelner Apps zu links oder rechts.

-- Feste Monitoridentitaeten, unabhaengig von DisplayPort-Nummern.
hl.monitor({
    output = "desc:LG Electronics LG IPS QHD 207NTPC4P696",
    mode = "2560x1440@59.95", position = "0x0", scale = 1,
    transform = 1, supports_hdr = -1, vrr = 0, bitdepth = 8, cm = "srgb",
})
hl.monitor({
    output = "desc:LG Electronics LG IPS QHD 207NTVS4P719",
    mode = "2560x1440@59.95", position = "1440x579", scale = 1,
    transform = 0, vrr = 0, bitdepth = 8, cm = "srgb",
})

-- Aufteilung, Abstaende und Verhalten am Monitorrand.
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
    },
    binds = {
        window_direction_monitor_fallback = true,
    },
    scrolling = {
        column_width = 1.0,
        fullscreen_on_one_column = true,
        focus_fit_method = 1,
        follow_focus = 1,
        wrap_focus = false,
    },
    dwindle = {
        preserve_split = true,
    },
})

-- Layout folgt dem Monitor: Hauptmonitor Scrolling, Hochkantmonitor Dwindle.
hl.workspace_rule({ workspace = "m[desc:LG Electronics LG IPS QHD 207NTVS4P719]", layout = "scrolling" })
hl.workspace_rule({ workspace = "m[desc:LG Electronics LG IPS QHD 207NTPC4P696]", layout = "dwindle" })

-- Terminal-Workspace verwendet auf beiden Monitoren das Master-Layout.
hl.workspace_rule({ workspace = "name:T", layout = "master" })

-- Aktives Fenster verschieben; am Monitorrand zum Nachbarmonitor wechseln.
hl.bind("CTRL + SUPER + ALT + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("CTRL + SUPER + ALT + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Richtungsfokus: durch Scrolling-Fenster, am Rand zum Nachbarmonitor.
hl.bind("CTRL + SUPER + ALT + left", hl.dsp.focus({ direction = "left" }))
hl.bind("CTRL + SUPER + ALT + right", hl.dsp.focus({ direction = "right" }))
hl.bind("CTRL + SUPER + ALT + up", hl.dsp.focus({ direction = "up" }))
hl.bind("CTRL + SUPER + ALT + down", hl.dsp.focus({ direction = "down" }))

-- Aktives Fenster schliessen: HYPER + SHIFT + Q.
hl.bind("CTRL + SUPER + ALT + SHIFT + Q", hl.dsp.window.close())
