from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
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
const BATTERY_LEVEL_ACCEPTABLE = 0.3
const FPS_LEVEL_ACCEPTABLE = 25
const PL_LEVEL_ACCEPTABLE = 20

let maxFpsVal = 999
let maxPingVal = 999
let maxPlVal = 100
let textsFont = fontTinyAccentedShaded
let defaultColor = 0xFFFFFFFF
let badQualityColor = 0xFFFF5D5D

let BATTERY_BG_NORMAL = "icon_battery"
let BATTERY_BG_CHARGING = "icon_battery_charging"
let BATTERY_BG_NONE = ""

let pingIconSize = [ ((saBorders[1] - hdpxi(16)) / 0.9).tointeger(), (saBorders[1] - hdpxi(16)).tointeger()]
let batteryIconW = hdpxi(44)
let batteryIconH = hdpxi(22)
let batteryFillOffset = hdpxi(6)
let batteryFillMaxW = hdpxi(28)

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

let batteryIconFn = Computed(@() batteryCharge.value < 0 ? BATTERY_BG_NONE
  : isCharging.value > 0 ? BATTERY_BG_CHARGING
  : BATTERY_BG_NORMAL
)

let batteryColor = Computed(
  @() batteryCharge.get() < 0 || batteryCharge.get() >= BATTERY_LEVEL_ACCEPTABLE ? defaultColor : badQualityColor)

let batteryFillWidth = Computed(@() round(clamp(batteryCharge.get(), 0.0, 1.0) * batteryFillMaxW))

let function batteryComp() {
  let res = { watch = [ batteryIconFn, batteryColor ] }
  return batteryIconFn.get() == BATTERY_BG_NONE ? res : res.__update({
    size = [batteryIconW, batteryIconH]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{batteryIconFn.get()}.svg:{batteryIconW}:{batteryIconH}:P")
    color = batteryColor.get()
    keepAspect = true
    children = batteryIconFn.get() != BATTERY_BG_NORMAL ? null : @() {
      watch = batteryFillWidth
      size = [batteryFillWidth.get(), batteryIconH - (2 * batteryFillOffset)]
      pos = [batteryFillOffset, batteryFillOffset]
      rendObj = ROBJ_SOLID
      color = defaultColor
    }
  })
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