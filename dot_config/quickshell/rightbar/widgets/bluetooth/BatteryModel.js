.pragma library

function forDevice(device, reports) {
    if (!device.connected) return null;
    const address = String(device.address || "").toLowerCase();
    const deviceName = String(device.deviceName || device.name || "").trim().toLowerCase();
    const report = reports[address] || reports["name:" + deviceName];
    if (report) return report;
    if (!device.batteryAvailable) return null;
    const value = Number(device.battery) * 100;
    if (!isFinite(value) || value < 0 || value > 100) return null;
    return {bars:value < 15 ? 1 : value < 80 ? 2 : 3,
            label:Math.round(value) + " % (vom Gerät gemeldet)", coarse:false, source:"Bluetooth"};
}
