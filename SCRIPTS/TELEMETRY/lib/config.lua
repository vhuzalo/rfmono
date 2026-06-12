return {
  simulation = true,
  lowBatteryCell = 3.50,
  lowFuelPercent = 20,
  noRpmThreshold = 100,
  sensors = {
    battery = { "VFAS", "RxBt", "Batt", "BAT" },
    cell = { "Cel", "Cell", "Cels", "CELL" },
    fuel = { "Fuel", "Fuel%", "SFul", "SmartFuel" },
    rpm = { "RPM", "RPM1", "Rotor" },
    temp = { "Tmp1", "Temp", "TEMP", "ESC" },
    rssi = { "RSSI" },
    link = { "RQly", "LQ", "Link" }
  },
  simulationData = {
    battery = 22.4,
    cell = 3.73,
    fuel = 68,
    rpm = 1450,
    temp = 54,
    rssi = 87,
    link = 98
  }
}
