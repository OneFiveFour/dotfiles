#!/bin/bash
set -eu
source_file=/home/florian/.config/hypr/gdm-main-monitor.xml
target=/var/lib/gdm/seat0/config/monitors.xml
[ "$(id -u)" -eq 0 ] || { echo 'Bitte mit sudo bash ausfuehren.'; exit 1; }
[ -d "$(dirname "$target")" ]
xmllint --noout "$source_file"
if [ -e "$target" ]; then
    backup="$target.before-main-monitor-$(date +%Y%m%d-%H%M%S)"
    cp -a -- "$target" "$backup"
    echo "Sicherung: $backup"
fi
install -m 644 -- "$source_file" "$target"
chown --reference="$(dirname "$target")" "$target"
echo 'GDM: Hauptmonitor aktiv, Hochkantmonitor deaktiviert. Gilt bei der naechsten Anmeldung.'
