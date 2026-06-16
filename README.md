# Rotorflight BW Dashboard

Lightweight Lua telemetry dashboard for monochrome FrSky radios running OpenTX or EdgeTX.

RFMONO is inspired by the Rotorflight Suite for Ethos, but it is designed for small black-and-white screens, low memory, and older transmitters such as the Taranis X9D and QX7.

![RFMONO dashboard preview](docs/rfmono-dashboard.svg)

## Current Status

This project is still an MVP, but it is already structured for real radio testing:

- Single telemetry screen optimized for 128x64 monochrome displays
- Separate modules for configuration, sensors, layout, and alerts
- Safe fallback when telemetry sensors are missing
- Rotorflight-oriented telemetry aliases in `cfg.lua`
- ARM and ARMD status handling
- Governor state derived from throttle when no governor sensor is available
- Optional simulation data for development
- Custom audio events stored under the standard SD card `SOUNDS` tree

Not implemented yet:

- Multiple telemetry pages
- Heavy graphs or historical telemetry plots
- Advanced automatic sensor discovery
- Full coverage for every possible Rotorflight telemetry setup

## Supported Radios

The target radios are older monochrome FrSky transmitters, including:

- FrSky Taranis X9D / X9D+ / X9D 2019
- FrSky Taranis QX7 / QX7S

Other 128x64 OpenTX/EdgeTX radios may work, but the layout is primarily tuned for the models above.

## Project Layout

```text
/SCRIPTS/TELEMETRY/RFMONO.lua
/SCRIPTS/TELEMETRY/RFMONO/cfg.lua
/SCRIPTS/TELEMETRY/RFMONO/sns.lua
/SCRIPTS/TELEMETRY/RFMONO/lyt.lua
/SCRIPTS/TELEMETRY/RFMONO/alr.lua
/SOUNDS/en/RFMONO/*.wav
```

The Lua module filenames are intentionally short. Older radios can hit path length limits, so files such as `cfg.lua`, `sns.lua`, `lyt.lua`, and `alr.lua` are preferred over longer names.

Audio files are stored in `SOUNDS/en/RFMONO` to mirror the normal SD card sound structure and improve compatibility with `playFile()` on real radios.

## SD Card Installation

Copy the project files to the radio SD card using this structure:

```text
/SCRIPTS/TELEMETRY/RFMONO.lua
/SCRIPTS/TELEMETRY/RFMONO/cfg.lua
/SCRIPTS/TELEMETRY/RFMONO/sns.lua
/SCRIPTS/TELEMETRY/RFMONO/lyt.lua
/SCRIPTS/TELEMETRY/RFMONO/alr.lua
/SOUNDS/en/RFMONO/arm.wav
/SOUNDS/en/RFMONO/disarm.wav
/SOUNDS/en/RFMONO/govact.wav
/SOUNDS/en/RFMONO/govoff.wav
/SOUNDS/en/RFMONO/lowfuel.wav
```

## Selecting the Telemetry Screen

On OpenTX or EdgeTX:

1. Open the model setup.
2. Go to the telemetry screen configuration.
3. Add or edit a telemetry screen.
4. Select `Script` as the screen type.
5. Choose `RFMONO`.

The exact menu names can vary by firmware version, but the script file is `RFMONO.lua`.

## VS Code Simulator Deploy

The repository includes a VS Code task that copies the project directly to an EdgeTX simulator SD card folder.

Configure the simulator SD root in [.vscode/settings.json](.vscode/settings.json):

```json
{
  "rfmono.simulatorSdRoot": "C:\\Users\\vhuza\\Documents\\EdgeTX\\Taranis X9D 2019 SE"
}
```

Run the task from VS Code:

1. Open `Terminal > Run Task`.
2. Select `RFMONO: Deploy to EdgeTX simulator SD`.

The task deploys Lua files to:

```text
${rfmono.simulatorSdRoot}/SCRIPTS/TELEMETRY
```

It deploys audio files to:

```text
${rfmono.simulatorSdRoot}/SOUNDS/en/RFMONO
```

## Sensor Configuration

Telemetry aliases are configured in [cfg.lua](SCRIPTS/TELEMETRY/RFMONO/cfg.lua).

You can edit the sensor name lists to match the names discovered by your radio:

- `battery`
- `cell`
- `fuel`
- `rpm`
- `throttle`
- `current`
- `temp`
- `rssi`
- `link`
- `governor`
- `profile`
- `armFlags`
- `armDisableFlags`

Example: if your rotor RPM sensor appears as `RPM1`, keep or add it to the `rpm` aliases:

```lua
sensors = {
  rpm = { "Hspd", "RPM", "RPM1", "Rotor" }
}
```

RFMONO uses the first available telemetry field from each alias list. If a sensor is missing, the dashboard shows `--` instead of raising a Lua error.

## Expected Rotorflight Sensors

RFMONO is designed around these Rotorflight-related values:

- Total battery voltage
- Cell voltage
- Battery percentage, Fuel %, or SmartFuel
- Rotor RPM
- Current
- ESC or flight controller temperature
- RSSI
- Link Quality
- Profile or bank
- ARM flag
- ARMD arming-disable flags

The current default aliases include the following important Rotorflight names:

- `Bat%` for battery percentage or fuel
- `Vbat` for total battery voltage
- `Vcel` for cell voltage
- `Hspd` for rotor RPM
- `Thr` for throttle
- `ARM` for armed state
- `ARMD` for arming-disable reasons
- `RQly` for link quality

## Governor Status

If a real governor status sensor is not available, RFMONO derives the governor text from the `Thr` sensor:

- `Thr <= 0`: `OFF`
- `Thr > 50`: `ACTIVE`
- Any other positive value: `SPOOL`

If `Thr` is missing, RFMONO falls back to the configured `governor` sensor aliases.

## ARM and ARMD Status

RFMONO reads the Rotorflight `ARM` sensor as a bitmask. By default, bit `0` means the model is currently armed.

The `ARMD` sensor is treated as an arming-disable bitmask. When a disable reason is present, it has priority in the top status area over the normal armed/disarmed text.

The default ARMD labels are configured in `armDisableText` inside [cfg.lua](SCRIPTS/TELEMETRY/RFMONO/cfg.lua).

## Alerts and Audio

RFMONO can play audio for:

- Low fuel or battery percentage
- Armed
- Disarmed
- Governor off
- Governor active

The audio settings are configured in `cfg.lua`:

```lua
audio = {
  lowBatteryEnabled = true,
  lowBatteryFile = "/SOUNDS/en/RFMONO/lowfuel.wav",
  lowBatteryRepeatSeconds = 30,
  lowBatteryResetMargin = 5,
  eventsEnabled = true,
  armedFile = "/SOUNDS/en/RFMONO/arm.wav",
  disarmedFile = "/SOUNDS/en/RFMONO/disarm.wav",
  governorOffFile = "/SOUNDS/en/RFMONO/govoff.wav",
  governorActiveFile = "/SOUNDS/en/RFMONO/govact.wav"
}
```

For best compatibility with older radios, WAV files should be PCM, mono, 16-bit, 16 kHz. The simulator may play more formats than the actual radio, so avoid compressed or A-law WAV files.

## Missing Sensors

When a sensor is missing:

- The dashboard keeps running.
- The field displays `--`.
- The lower warning area may show `SENSOR?`.

Other warning examples include `LOW BAT`, `LOW FUEL`, and `NO RPM`.

## Simulation Mode

Simulation mode is useful while developing without a real telemetry link.

To enable it, edit [cfg.lua](SCRIPTS/TELEMETRY/RFMONO/cfg.lua):

```lua
simulation = true
```

When `simulation = true`, RFMONO uses `simulationData` from the config file. When `false`, it reads real telemetry fields from the radio.

## Design Goals

RFMONO prioritizes:

- Fast readability in flight
- High contrast
- Low CPU and memory usage
- Safe degradation when telemetry is incomplete
- Minimal dependencies
- Simple files that can be edited directly on the SD card if needed

## Roadmap Ideas

- Improve sensor auto-detection
- Add optional alternate layouts for other screen sizes
- Add more Rotorflight-specific status decoding
- Add language-specific audio folders
- Add screenshots to this README
