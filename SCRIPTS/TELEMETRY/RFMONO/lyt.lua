return function(config)
  local M = {}
  local SCREEN_W = LCD_W or 128
  local SCREEN_H = LCD_H or 64
  local TOP_H = 9
  local MAIN_Y = 10
  local STATUS_H = 9
  local STATUS_Y = SCREEN_H - STATUS_H
  local MAIN_H = STATUS_Y - MAIN_Y
  local LEFT_W = math.floor(SCREEN_W * 30 / 100)
  local CENTER_W = math.floor(SCREEN_W * 40 / 100)
  local RIGHT_W = SCREEN_W - LEFT_W - CENTER_W
  local LEFT_X = 0
  local CENTER_X = LEFT_W
  local RIGHT_X = LEFT_W + CENTER_W
  local LEFT_SPLIT = CENTER_X
  local RIGHT_SPLIT = RIGHT_X

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

  local function clamp(value, minValue, maxValue)
    if value == nil then
      return minValue
    end

    if value < minValue then
      return minValue
    end

    if value > maxValue then
      return maxValue
    end

    return value
  end

  local function formatNumber(value, digits, suffix)
    if value == nil then
      return "--"
    end

    if type(value) ~= "number" then
      return tostring(value)
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

    if type(value) ~= "number" then
      return tostring(value)
    end

    local text = tostring(math.floor(value + 0.5))
    if suffix and suffix ~= "" then
      return text .. suffix
    end

    return text
  end

  local function formatText(value, fallback)
    if value == nil or value == "" then
      return fallback or "--"
    end

    return tostring(value)
  end

  local function formatBatteryLine(state)
    return formatNumber(state.battery, 1, "V") .. " " .. formatNumber(state.cell, 2, "V")
  end

  local function drawSoftBox(x, y, w, h)
    lcd.drawLine(x + 1, y, x + w - 2, y, SOLID, 0)
    lcd.drawLine(x + 1, y + h - 1, x + w - 2, y + h - 1, SOLID, 0)
    lcd.drawLine(x, y + 1, x, y + h - 2, SOLID, 0)
    lcd.drawLine(x + w - 1, y + 1, x + w - 1, y + h - 2, SOLID, 0)
  end

  local function drawFrame()
    drawSoftBox(LEFT_X, MAIN_Y, LEFT_W, MAIN_H)
    drawSoftBox(CENTER_X, MAIN_Y, CENTER_W, MAIN_H)
    drawSoftBox(RIGHT_X, MAIN_Y, RIGHT_W, MAIN_H)
  end

  local function drawTopBar(state)
    local armAlert = state.armAlert

    if armAlert == nil or armAlert == "" then
      armAlert = "DISARMED"
    end

    armAlert = clipText(armAlert, 10)

    lcd.drawFilledRectangle(0, 0, SCREEN_W, TOP_H)
    lcd.drawText(1, 1, clipText(state.modelName, 11), INVERS + SMLSIZE)
    lcd.drawText(math.floor(SCREEN_W / 2), 1, armAlert, INVERS + SMLSIZE + CENTER)
    lcd.drawText(SCREEN_W - 1, 1, "ROTORFLIGHT", INVERS + SMLSIZE + RIGHT)
  end

  local function drawLeftBlock(state)
    local center = LEFT_X + math.floor(LEFT_W / 2)

    lcd.drawText(center, 12, "TIMER", SMLSIZE + CENTER)
    lcd.drawText(center, 24, formatTimer(state.timer), MIDSIZE + CENTER)
    lcd.drawText(center, 47, clipText(formatText(state.profile, "--"), 5), SMLSIZE + CENTER)
  end

  local function drawCenterBlock(state)
    local center = CENTER_X + math.floor(CENTER_W / 2)
    local bodyW = CENTER_W - 7
    local bodyH = 18
    local bodyX = center - math.floor(bodyW / 2) - 1
    local bodyY = 22
    local fillW = 0

    if type(state.fuel) == "number" then
      fillW = math.floor((bodyW - 4) * clamp(state.fuel, 0, 100) / 100)
    end

    lcd.drawText(center, 12, "BAT", SMLSIZE + CENTER)
    lcd.drawRectangle(bodyX, bodyY, bodyW, bodyH)
    lcd.drawFilledRectangle(bodyX + bodyW, bodyY + 5, 3, 8)

    if fillW > 0 then
      lcd.drawFilledRectangle(bodyX + 2, bodyY + 2, fillW, bodyH - 4)
    end

    lcd.drawText(center, bodyY + 5, formatInteger(state.fuel, "%"), INVERS + SMLSIZE + CENTER)
    lcd.drawText(center, 47, formatBatteryLine(state), SMLSIZE + CENTER)
  end

  local function drawRightBlock(state)
    local center = RIGHT_X + math.floor(RIGHT_W / 2)
    lcd.drawText(center, 12, "RPM", SMLSIZE + CENTER)
    lcd.drawText(center, 24, formatInteger(state.rpm, ""), MIDSIZE + CENTER)
    lcd.drawText(center, 47, "A: " .. formatNumber(state.current, 1, "") .. " T: " .. formatInteger(state.temp, ""), SMLSIZE + CENTER)
  end

  local function drawStatusBar(state)
    local linkLabel = "R"
    local linkValue = state.rssi
    local governor = "GOV " .. clipText(formatText(state.governor, "--"), 6)
    local rightText = "OK"

    if state.link ~= nil then
      linkLabel = "LQ"
      linkValue = state.link
    end

    if state.warning ~= "" then
      rightText = state.warning
    end

    lcd.drawFilledRectangle(0, STATUS_Y, SCREEN_W, STATUS_H)
    lcd.drawText(1, STATUS_Y + 1, linkLabel .. ":" .. formatInteger(linkValue, ""), INVERS + SMLSIZE)
    lcd.drawText(math.floor(SCREEN_W / 2), STATUS_Y + 1, governor, INVERS + SMLSIZE + CENTER)
    lcd.drawText(SCREEN_W - 1, STATUS_Y + 1, rightText, INVERS + SMLSIZE + RIGHT)
  end

  function M.draw(state)
    lcd.clear()
    drawTopBar(state)
    drawFrame()
    drawLeftBlock(state)
    drawCenterBlock(state)
    drawRightBlock(state)
    drawStatusBar(state)
  end

  return M
end
