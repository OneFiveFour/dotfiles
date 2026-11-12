.pragma library

// BlueZ klassifiziert Geräte anhand ihrer Bluetooth-Metadaten.
// Namen werden erst verwendet, wenn keine passende Klassifikation vorliegt.
function forDevice(device) {
    const type = String(device.icon || "").toLowerCase();
    if (/keyboard/.test(type)) return "keyboard";
    if (/mouse|trackball|touchpad/.test(type)) return "mouse";
    if (/headset|headphone/.test(type)) return "headphones";
    const name = String(device.deviceName || device.name || "").toLowerCase();
    if (/^keychron/.test(name)) return "keyboard";
    if (/^mx/.test(name)) return "mouse";
    if (/^wh/.test(name)) return "headphones";
    return "bluetooth";
}
