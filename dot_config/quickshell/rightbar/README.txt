QUICKSHELL RIGHTBAR
==================

Aktiver Ordner: /home/florian/.config/quickshell/rightbar
Start: quickshell -d -n -c rightbar
Status: quickshell ipc -c rightbar call panel status
Popup öffnen/schließen: quickshell ipc -c rightbar call panel toggle bluetooth
Log: quickshell log -c rightbar -t 30

DATEIEN UND VERANTWORTLICHKEITEN

shell.qml                      Einstiegspunkt
shell/RightBarShell.qml        Leiste, Popup-Fläche, Systemdienste und IPC

theme/Theme.qml                Farben, Transparenz, Größen und Schrift
theme/Animations.qml           Animationsstil und Dauer
animations/PopupMotion.qml     Austauschbare Einblendanimation

components/                    Wiederverwendbare Oberfläche
  IconButton.qml               Icon-Button, optional mit Ladeanimation
  ActionButton.qml             Text-Button
  BarButton.qml                Icon-Button der vertikalen Leiste
  HoverPopupController.qml     Gemeinsame Hover-Steuerung für Power und Bluetooth
  BarIsland.qml                Translucente Leisteninsel
  BatteryIndicator.qml         Batterie mit einem, zwei oder drei Segmenten
  LoadingSpinner.qml           Drehende Ladeanimation
  StyledSlider.qml             Lautstärkeregler
  StyledSwitch.qml             An/Aus-Schalter

widgets/                       Einzelne Popup-Inhalte
  bluetooth/BluetoothPopup.qml        Kopfzeile, Suche, Schalter und Geräteliste
  bluetooth/BluetoothDeviceCard.qml   Eine Gerätekarte einschließlich Verbindung und Akku
  bluetooth/BluetoothIcons.js         Gerätetyp-/Namensmapping
  bluetooth/BatteryModel.js           Auswahl von UPower oder Bluetooth-Akkudaten
  power/PowerPopup.qml                Sperren und Abmelden
  sound/SoundPopup.qml                Ausgabe, Mikrofon und Geräteauswahl
  notifications/NotificationsPopup.qml Benachrichtigungsverlauf
  apps/AppsPopup.qml                  Laufende Anwendungen
  calendar/CalendarPopup.qml          Monatskalender

backend/                       Python-Systemanbindung
  main.py                      JSON-Nachrichten und Ablaufsteuerung
  applications.py              Erkennung von Desktop-Anwendungen
  process_actions.py           Identitätsgeprüftes Beenden von Prozessen
  bluetooth_agent.py           PIN-Eingabe und Bluetooth-Kopplungsbestätigung
  battery_status.py            Akkustufen aus UPower

assets/icons/                  Material-Icons und eigene dreistufige Akku-SVGs
tests/test_battery_status.py   Akku-Grenzwerte und grobe Akkumeldungen
tests/test_bluetooth_agent.py  Kopplungsantworten ohne echte Bluetooth-Aktionen

AKKUANZEIGE

Ein Balken rot: unter 15 %; zwei Balken: 15 bis unter 80 %;
drei Balken: ab 80 %. Bei groben UPower-Stufen gilt stattdessen:
Niedrig/Kritisch = ein Balken, Normal = zwei, Hoch/Voll = drei.
Unbekannte Akkustände werden nicht als voll dargestellt.
Die Prozent-/Stufenangabe kann beim Darüberfahren als Hinweis angezeigt werden.

BEARBEITEN

QML-Änderungen werden automatisch neu geladen.
Nach Änderungen im Python-Backend die Konfiguration neu starten.
Hyprland startet weiterhin genau dieselbe benannte Konfiguration rightbar.
Jeder QML-Unterordner hat eine qmldir-Datei zur Registrierung seiner Komponenten.

Tests: Im Konfigurationsordner python3 -m unittest discover -s tests -v
Die Bluetooth-Suche stoppt nach 20 Sekunden oder beim Schließen des Widgets.
Rofi, Hypridle, Hyprlock und Hyprpaper behalten ihre bisherigen Aufgaben.
Benachrichtigungsverlauf bleibt im Speicher der laufenden Quickshell-Instanz.

BLUETOOTH-BEDIENUNG

Hover über das Bluetooth-Icon öffnet die Geräteübersicht.
Ein Klick schaltet Bluetooth um; das durchgestrichene Icon bedeutet ausgeschaltet.
Beim Wechsel zwischen Icon und Popup gelten 300 ms Schließtoleranz.
Geräte-Icon, Name und Akku sind in einer Zeile zentriert; Verbinden sitzt rechts mittig.
