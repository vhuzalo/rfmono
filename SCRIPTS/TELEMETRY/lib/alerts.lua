return function(config)
  local M = {}

  local lowBatteryActive = false
  local lastLowBatteryAt = nil

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

  function M.update(state)
    local audio = config.audio or {}

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
