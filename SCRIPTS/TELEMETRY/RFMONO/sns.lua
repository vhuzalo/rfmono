return function(config)
  local M = {}

  local sensorIds = {}

  local function getModelName()
    if model and model.getInfo then
      local info = model.getInfo()
      if info and info.name and info.name ~= "" then
        return info.name
      end
    end

    return "MODEL"
  end

  local function getTimerValue()
    if model and model.getTimer then
      local timer = model.getTimer(0)
      if timer and timer.value then
        return timer.value
      end
    end

    return nil
  end

  local function getFlightModeLabel()
    if getFlightMode then
      local flightMode = getFlightMode()
      if type(flightMode) == "number" then
        return "FM" .. tostring(flightMode)
      end
    end

    return nil
  end

  local function normalizeKey(value)
    local text = string.upper(tostring(value))
    text = string.gsub(text, "%s+", "")
    text = string.gsub(text, "_", "")
    text = string.gsub(text, "-", "")

    return text
  end

  local function firstSetBit(value)
    local bit = 0
    local flags = math.floor(value)

    while flags > 0 and bit <= 31 do
      if flags % 2 == 1 then
        return bit
      end

      flags = math.floor(flags / 2)
      bit = bit + 1
    end

    return nil
  end

  local function hasBit(value, bit)
    local flags = math.floor(value)
    local divisor = 2 ^ bit

    return math.floor(flags / divisor) % 2 == 1
  end

  local function toNumber(value)
    if type(value) == "number" then
      return value
    end

    if type(value) == "string" then
      return tonumber(value)
    end

    return nil
  end

  local function formatArmStatus(value)
    local code = toNumber(value)

    if value == nil then
      return ""
    end

    if code ~= nil then
      if not hasBit(code, config.armedFlagBit or 0) then
        return ""
      end

      return "ARMED"
    end

    local key = normalizeKey(value)
    if key == "0" or key == "" or key == "--" or key == "DISARMED" then
      return ""
    end

    if key == "1" or key == "ARMED" or key == "ARM" then
      return "ARMED"
    end

    return string.sub(tostring(value), 1, 10)
  end

  local function formatArmDisableAlert(value)
    local map = config.armDisableText or {}

    if value == nil then
      return ""
    end

    if type(value) == "number" then
      local code = math.floor(value + 0.5)

      if code == 0 then
        return ""
      end

      local bit = firstSetBit(code)
      if bit and map[bit] ~= nil then
        return map[bit]
      end

      return "ARMD " .. tostring(code)
    end

    local key = normalizeKey(value)
    if key == "0" or key == "" or key == "--" then
      return ""
    end

    if map[key] ~= nil then
      return map[key]
    end

    return string.sub(tostring(value), 1, 10)
  end

  local function formatGovernorFromThrottle(value)
    if type(value) ~= "number" then
      return nil
    end

    if value <= 0 then
      return "OFF"
    end

    if value > 50 then
      return "ACTIVE"
    end

    return "SPOOL"
  end

  local function formatGovernor(value)
    local map = config.governorText or {}

    if value == nil then
      return nil
    end

    if type(value) == "number" then
      local code = math.floor(value + 0.5)

      if map[code] ~= nil then
        return map[code]
      end

      return tostring(code)
    end

    local key = normalizeKey(value)
    if map[key] ~= nil then
      return map[key]
    end

    return string.sub(tostring(value), 1, 8)
  end

  local function formatWarnings(state)
    local warnings = {}

    if state.battery ~= nil and state.cell ~= nil and state.cell <= config.lowBatteryCell then
      warnings[#warnings + 1] = "LOW BAT"
    end

    if state.fuel ~= nil and state.fuel <= config.lowFuelPercent then
      warnings[#warnings + 1] = "LOW FUEL"
    end

    if state.rpm ~= nil and state.rpm <= config.noRpmThreshold then
      warnings[#warnings + 1] = "NO RPM"
    end

    if state.missingSensors > 0 then
      warnings[#warnings + 1] = "SENSOR?"
    end

    if #warnings == 0 then
      return ""
    end

    if #warnings == 1 then
      return warnings[1]
    end

    return warnings[1] .. "+"
  end

  local function formatArmAlert(state)
    if state.armDisableAlert ~= "" then
      return state.armDisableAlert
    end

    if state.armStatus ~= "" then
      return state.armStatus
    end

    return ""
  end

  local function resolveSensorId(candidates)
    if not getFieldInfo then
      return nil
    end

    local i
    for i = 1, #candidates do
      local info = getFieldInfo(candidates[i])
      if info and info.id then
        return info.id
      end
    end

    return nil
  end

  local function readById(id)
    if not id or not getValue then
      return nil
    end

    local value = getValue(id)
    if type(value) == "number" or type(value) == "string" then
      return value
    end

    return nil
  end

  local function readSensor(name)
    if config.simulation then
      return config.simulationData[name]
    end

    return readById(sensorIds[name])
  end

  function M.init()
    local key, aliases

    for key, aliases in pairs(config.sensors) do
      sensorIds[key] = resolveSensorId(aliases)
    end
  end

  function M.read()
    local state = {
      modelName = getModelName(),
      timer = getTimerValue(),
      battery = readSensor("battery"),
      cell = readSensor("cell"),
      fuel = readSensor("fuel"),
      rpm = readSensor("rpm"),
      throttle = readSensor("throttle"),
      current = readSensor("current"),
      temp = readSensor("temp"),
      rssi = readSensor("rssi"),
      link = readSensor("link"),
      governor = nil,
      profile = readSensor("profile") or getFlightModeLabel(),
      armStatus = formatArmStatus(readSensor("armFlags")),
      armDisableAlert = formatArmDisableAlert(readSensor("armDisableFlags")),
      missingSensors = 0
    }

    state.governor = formatGovernorFromThrottle(state.throttle) or formatGovernor(readSensor("governor"))

    local required = { "battery", "cell", "fuel", "rpm", "temp" }
    local i
    for i = 1, #required do
      if state[required[i]] == nil then
        state.missingSensors = state.missingSensors + 1
      end
    end

    state.warnings = formatWarnings(state)
    state.warning = state.warnings
    state.armAlert = formatArmAlert(state)
    return state
  end

  return M
end
