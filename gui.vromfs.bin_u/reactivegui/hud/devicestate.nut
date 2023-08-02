from "%globalsDarg/darg_library.nut" import *
let { subscribe, unsubscribe } = require("eventbus")
let { register_command } = require("console")
let { get_battery, is_charging } = require("sysinfo")
let { DBGLEVEL } = require("dagor.system")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { is_pc } = require("%appGlobals/clientState/platform.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

const BATTERY_UPDATE_TIMEOUT_SEC = 10.0
const UPDATE_STATUS_STRING_EVENT_ID = "updateStatusString"
const PING_LEVEL_MEDIUM = 100
const PING_LEVEL_SLOW = 300
const BATTERY_LEVEL_HIGH = 0.7
const BATTERY_LEVEL_MEDIUM = 0.3
const FPS_LEVEL_ACCEPTABLE = 25
const PL_LEVEL_ACCEPTABLE = 20

let maxFpsVal = 999
let maxPingVal = 999
let maxPlVal = 100
let textsFont = fontTinyAccentedShaded
let defaultColor = 0xFFFFFFFF
let badQualityColor = 0xFFFF5D5D

let pingIconSize = [ ((saBorders[1] - hdpxi(16)) / 0.9).tointeger(), (saBorders[1] - hdpxi(16)).tointeger()]
let batteryIconSize = [ hdpxi(44), hdpxi(22) ]

let textFps = "".concat(loc("options/perfMetrics_fps"), colon)
let textPing = "".concat(loc("mainmenu/ping"), colon)
let textPackagesLoss = "".concat(loc("mainmenu/packet_loss/abbr"), colon)

let getBattery = !is_pc
  ? get_battery
  : function() {
      let v = get_battery()
      return v < 0 ? 1.0 : v
    }

let deviceState = Watched(null)
let batteryCharge = Watched(getBattery())
let isCharging = Watched(is_charging())

let fps = Computed(@() min(maxFpsVal, deviceState.value?.fps.tointeger() ?? -1))
let ping = Computed(@() min(maxPingVal, deviceState.value?.ping.tointeger() ?? -1))
let pl = Computed(@() min(maxPlVal, deviceState.value?.pl.tointeger() ?? -1))

let updateDeviceState = @(state) deviceState(state)
let function enableDeviceState(isEnable) {
  if (isEnable)
    subscribe(UPDATE_STATUS_STRING_EVENT_ID, updateDeviceState)
  else {
    unsubscribe(UPDATE_STATUS_STRING_EVENT_ID, updateDeviceState)
    deviceState(null)
  }
}
isInBattle.subscribe(enableDeviceState)
if (isInBattle.value)
  enableDeviceState(true)

let getTextWidthPx = @(text) calc_comp_size({ rendObj = ROBJ_TEXT, text }.__update(textsFont))[0]
let fpsTextW = getTextWidthPx($"{textFps}000")
let pingTextW = getTextWidthPx($"{textPing}000")
let plTextW = getTextWidthPx($"{textPackagesLoss}100%")

let fpsComp = @() fps.value < 0 ? { watch = fps } : {
  watch = fps
  size = [ fpsTextW, SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXT
  text = $"{textFps}{fps.value}"
  color = (DBGLEVEL <= 0 || fps.value >= FPS_LEVEL_ACCEPTABLE) ? defaultColor : badQualityColor
}.__update(textsFont)

let pingComp = @() ping.value < 0 ? { watch = ping } : {
  watch = ping
  size = [ pingTextW, SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXT
  text = $"{textPing}{ping.value}"
  color = ping.value < PING_LEVEL_SLOW ? defaultColor : badQualityColor
}.__update(textsFont)

let plComp = @() pl.value < 0 ? { watch = pl } : {
  watch = pl
  size = [ plTextW, SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXT
  text = $"{textPackagesLoss}{pl.value}{pl.value > 0 ? "%" : ""}"
  color = pl.value <= PL_LEVEL_ACCEPTABLE ? defaultColor : badQualityColor
}.__update(textsFont)

let pingIconFn = Computed(@() ping.value < 0 ? ""
  : ping.value < PING_LEVEL_MEDIUM ? "icon_wifi_high"
  : ping.value < PING_LEVEL_SLOW ? "icon_wifi_med"
  : "icon_wifi_low"
)
let pingIconComp = @() pingIconFn.value == "" ? { watch = pingIconFn } : {
  watch = pingIconFn
  size = pingIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{pingIconFn.value}.svg:{pingIconSize[0]}:{pingIconSize[1]}:P")
  color = pingIconFn.value != "icon_wifi_low" ? defaultColor : badQualityColor
  keepAspect = true
}

let function updateBatteryState() {
  batteryCharge(getBattery())
  isCharging(is_charging())
}
let batteryIconFn = Computed(@() batteryCharge.value < 0 ? ""
  : isCharging.value > 0 ? "icon_battery_charging"
  : batteryCharge.value >= BATTERY_LEVEL_HIGH ? "icon_battery_high"
  : batteryCharge.value >= BATTERY_LEVEL_MEDIUM ? "icon_battery_med"
  : "icon_battery_low"
)
let batteryComp = @() batteryIconFn.value == "" ? { watch = batteryIconFn } : {
  watch = batteryIconFn
  size = batteryIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{batteryIconFn.value}.svg:{batteryIconSize[0]}:{batteryIconSize[1]}:P")
  color = batteryIconFn.value != "icon_battery_low" ? defaultColor : badQualityColor
  keepAspect = true
}

let deviceStateArea = {
  key = batteryCharge
  function onAttach() {
    updateBatteryState()
    setInterval(BATTERY_UPDATE_TIMEOUT_SEC, updateBatteryState)
  }
  onDetach = @() clearTimer(updateBatteryState)
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  size = [ SIZE_TO_CONTENT, saBorders[1] ]
  margin = [ 0, saBorders[0], 0, 0]
  flow = FLOW_HORIZONTAL
  gap = hdpx(30)
  children = [
    fpsComp
    pingComp
    plComp
    pingIconComp
    batteryComp
  ]
}

register_command(@() log($"Device state: battery={get_battery()}, charging={is_charging()}, params:",
  deviceState.value), "ui.debug.dump_device_state")

return deviceStateArea