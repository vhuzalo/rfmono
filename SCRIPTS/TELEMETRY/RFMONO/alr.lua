return function(config)
  local M = {}

  local lowBatteryActive = false
  local lastLowBatteryAt = nil
  local lastArmStatus = nil
  local lastGovernorStatus = nil

  local function now()
    if getTime then
      return getTime()
    end

    return 0
  end

  local function playLowBattery()
    local audio = config.audio or {}

    if playFile and audio.lowBatteryFile then
      playFile(audio.lowBatteryFile)
    end
  end

  local function playConfigured(file)
    if playFile and file then
      playFile(file)
    end
  end

  local function getArmStatus(state)
    if state.armStatus == "ARMED" then
      return "ARMED"
    end

    return "DISARMED"
  end

  local function updateArmAudio(state)
    local audio = config.audio or {}
    local current = getArmStatus(state)

    if lastArmStatus == nil then
      lastArmStatus = current
      return
    end

    if current == lastArmStatus then
      return
    end

    lastArmStatus = current

    if current == "ARMED" then
      playConfigured(audio.armedFile)
    else
      playConfigured(audio.disarmedFile)
    end
  end

  local function updateGovernorAudio(state)
    local audio = config.audio or {}
    local current = state.governor

    if current == nil or current == "" then
      return
    end

    if lastGovernorStatus == nil then
      lastGovernorStatus = current
      return
    end

    if current == lastGovernorStatus then
      return
    end

    lastGovernorStatus = current

    if current == "OFF" then
      playConfigured(audio.governorOffFile)
    elseif current == "ACTIVE" then
      playConfigured(audio.governorActiveFile)
    end
  end

  function M.update(state)
    local audio = config.audio or {}

    if audio.eventsEnabled then
      updateArmAudio(state)
      updateGovernorAudio(state)
    end

    if not audio.lowBatteryEnabled then
      return
    end

    if type(state.fuel) ~= "number" then
      lowBatteryActive = false
      lastLowBatteryAt = nil
      return
    end

    if state.fuel <= config.lowFuelPercent then
      local currentTime = now()
      local repeatTicks = (audio.lowBatteryRepeatSeconds or 30) * 100

      if not lowBatteryActive or lastLowBatteryAt == nil or currentTime - lastLowBatteryAt >= repeatTicks then
        playLowBattery()
        lowBatteryActive = true
        lastLowBatteryAt = currentTime
      end

      return
    end

    if state.fuel >= config.lowFuelPercent + (audio.lowBatteryResetMargin or 5) then
      lowBatteryActive = false
      lastLowBatteryAt = nil
    end
  end

  return M
end
