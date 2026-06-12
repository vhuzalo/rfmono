return function(config)
  local M = {}

  local function clipText(text, maxLen)
    if text == nil or text == "" then
      return "MODEL"
    end

    if string.len(text) <= maxLen then
      return text
    end

    return string.sub(text, 1, maxLen)
  end

  local function formatTimer(seconds)
    if seconds == nil then
      return "--:--"
    end

    local total = math.floor(seconds)
    local minutes = math.floor(total / 60)
    local remain = total % 60

    if minutes > 99 then
      minutes = 99
    end

    return string.format("%02d:%02d", minutes, remain)
  end

  local function formatNumber(value, digits, suffix)
    if value == nil then
      return "--"
    end

    local pattern = "%." .. digits .. "f"
    local text = string.format(pattern, value)

    if suffix and suffix ~= "" then
      return text .. suffix
    end

    return text
  end

  local function formatInteger(value, suffix)
    if value == nil then
      return "--"
    end

    local text = tostring(math.floor(value + 0.5))
    if suffix and suffix ~= "" then
      return text .. suffix
    end

    return text
  end

  local function drawFrame()
    lcd.drawRectangle(0, 10, LCD_W, 44)
    lcd.drawLine(62, 10, 62, 53, SOLID, 0)
    lcd.drawLine(63, 10, 63, 53, SOLID, 0)
    lcd.drawLine(64, 31, LCD_W - 1, 31, SOLID, 0)
  end

  local function drawTopBar(state)
    lcd.drawFilledRectangle(0, 0, LCD_W, 9)
    lcd.drawText(1, 1, clipText(state.modelName, 8), INVERS)
    lcd.drawText(LCD_W - 1, 1, formatTimer(state.timer), INVERS + RIGHT)
  end

  local function drawFuelBlock(state)
    lcd.drawText(4, 13, "FUEL", 0)
    lcd.drawText(6, 23, formatInteger(state.fuel, "%"), DBLSIZE)
  end

  local function drawBatteryBlock(state)
    lcd.drawText(68, 13, "PACK", 0)
    lcd.drawText(LCD_W - 3, 13, formatNumber(state.battery, 1, "V"), RIGHT)

    lcd.drawText(68, 22, "CELL", 0)
    lcd.drawText(LCD_W - 3, 22, formatNumber(state.cell, 2, "V"), RIGHT)
  end

  local function drawRpmBlock(state)
    lcd.drawText(68, 35, "RPM", 0)
    lcd.drawText(LCD_W - 3, 42, formatInteger(state.rpm, ""), RIGHT)
  end

  local function drawStatusBar(state)
    local linkLabel = "RSSI"
    local linkValue = state.rssi

    if state.link ~= nil then
      linkLabel = "LQ"
      linkValue = state.link
    end

    lcd.drawFilledRectangle(0, 55, LCD_W, 9)
    lcd.drawText(1, 56, "T:" .. formatInteger(state.temp, "C"), INVERS + SMLSIZE)
    lcd.drawText(35, 56, linkLabel .. ":" .. formatInteger(linkValue, ""), INVERS + SMLSIZE)

    if state.warnings ~= "" then
      lcd.drawText(LCD_W - 1, 56, state.warnings, INVERS + SMLSIZE + RIGHT)
    end
  end

  function M.draw(state)
    lcd.clear()
    drawTopBar(state)
    drawFrame()
    drawFuelBlock(state)
    drawBatteryBlock(state)
    drawRpmBlock(state)
    drawStatusBar(state)
  end

  return M
end
