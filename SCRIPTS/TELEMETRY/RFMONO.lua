local config = assert(loadScript("/SCRIPTS/TELEMETRY/RFMONO/cfg.lua"))()
local sensorsFactory = assert(loadScript("/SCRIPTS/TELEMETRY/RFMONO/sns.lua"))()
local layoutFactory = assert(loadScript("/SCRIPTS/TELEMETRY/RFMONO/lyt.lua"))()
local alertsFactory = assert(loadScript("/SCRIPTS/TELEMETRY/RFMONO/alr.lua"))()
local sensors = sensorsFactory(config)
local layout = layoutFactory(config)
local alerts = alertsFactory(config)

local app = {
  initialized = false
}

local function init()
  sensors.init()
  app.initialized = true
end

local function run(event)
  if not app.initialized then
    init()
  end

  local state = sensors.read()
  alerts.update(state)
  layout.draw(state, event)

  return 0
end

return {
  init = init,
  run = run
}
