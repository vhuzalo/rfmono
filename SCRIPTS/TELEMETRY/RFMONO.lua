local config = assert(loadScript("/SCRIPTS/TELEMETRY/lib/config.lua"))()
local sensorsFactory = assert(loadScript("/SCRIPTS/TELEMETRY/lib/sensors.lua"))()
local layoutFactory = assert(loadScript("/SCRIPTS/TELEMETRY/lib/layout.lua"))()
local sensors = sensorsFactory(config)
local layout = layoutFactory(config)

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
  layout.draw(state, event)

  return 0
end

return {
  init = init,
  run = run
}
