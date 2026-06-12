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
    if type(value) == "number" then
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
      temp = readSensor("temp"),
      rssi = readSensor("rssi"),
      link = readSensor("link"),
      missingSensors = 0
    }

    local required = { "battery", "cell", "fuel", "rpm", "temp" }
    local i
    for i = 1, #required do
      if state[required[i]] == nil then
        state.missingSensors = state.missingSensors + 1
      end
    end

    state.warnings = formatWarnings(state)
    return state
  end

  return M
end
