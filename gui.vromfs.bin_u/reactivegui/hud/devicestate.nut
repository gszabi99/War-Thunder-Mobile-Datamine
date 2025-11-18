from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { eventbus_subscribe, eventbus_unsubscribe } = require("eventbus")
let { register_command } = require("console")
let { get_battery, is_charging } = require("sysinfo")
let { DBGLEVEL } = require("dagor.system")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { is_pc } = require("%appGlobals/clientState/platform.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { hudWhiteColor, hudCoralRedColor } = require("%rGui/style/hudColors.nut")

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
let textsFontMono = fontMonoTinyAccentedShaded
let defaultColor = hudWhiteColor
let badQualityColor = hudCoralRedColor

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

let fps = Computed(@() min(maxFpsVal, deviceState.get()?.fps.tointeger() ?? -1))
let ping = Computed(@() min(maxPingVal, deviceState.get()?.ping.tointeger() ?? -1))
let pl = Computed(@() min(maxPlVal, deviceState.get()?.pl.tointeger() ?? -1))

let updateDeviceState = @(state) deviceState.set(state)
function enableDeviceState(isEnable) {
  if (isEnable)
    eventbus_subscribe(UPDATE_STATUS_STRING_EVENT_ID, updateDeviceState)
  else {
    eventbus_unsubscribe(UPDATE_STATUS_STRING_EVENT_ID, updateDeviceState)
    deviceState.set(null)
  }
}
isInBattle.subscribe(enableDeviceState)
if (isInBattle.get())
  enableDeviceState(true)

let getTextMonoWidthPx = @(text) calc_comp_size({ rendObj = ROBJ_TEXT, text }.__update(textsFontMono))[0]
let numberW = getTextMonoWidthPx("000")
let percentW = getTextMonoWidthPx("100%")

let fpsComp = @() fps.get() < 0 ? { watch = fps } : {
  watch = fps
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = textFps
      color = (DBGLEVEL <= 0 || fps.get() >= FPS_LEVEL_ACCEPTABLE) ? defaultColor : badQualityColor
    }.__update(textsFont)
    {
      size = [ numberW, SIZE_TO_CONTENT ]
      rendObj = ROBJ_TEXT
      text = fps.get()
      color = (DBGLEVEL <= 0 || fps.get() >= FPS_LEVEL_ACCEPTABLE) ? defaultColor : badQualityColor
    }.__update(textsFontMono)
  ]
}

let pingComp = @() ping.get() < 0 ? { watch = ping } : {
  watch = ping
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = textPing
      color = ping.get() < PING_LEVEL_SLOW ? defaultColor : badQualityColor
    }.__update(textsFont)
    {
      size = [ numberW, SIZE_TO_CONTENT ]
      rendObj = ROBJ_TEXT
      text = ping.get()
      color = ping.get() < PING_LEVEL_SLOW ? defaultColor : badQualityColor
    }.__update(textsFontMono)
  ]
}

let plComp = @() pl.get() < 0 ? { watch = pl } : {
  watch = pl
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = textPackagesLoss
      color = pl.get() <= PL_LEVEL_ACCEPTABLE ? defaultColor : badQualityColor
    }.__update(textsFont)
    {
      size = [ percentW, SIZE_TO_CONTENT ]
      rendObj = ROBJ_TEXT
      text = $"{pl.get()}{pl.get() > 0 ? "%" : ""}"
      color = pl.get() <= PL_LEVEL_ACCEPTABLE ? defaultColor : badQualityColor
    }.__update(textsFontMono)
  ]
}

let pingIconFn = Computed(@() ping.get() < 0 ? ""
  : ping.get() < PING_LEVEL_MEDIUM ? "icon_wifi_high"
  : ping.get() < PING_LEVEL_SLOW ? "icon_wifi_med"
  : "icon_wifi_low"
)
let pingIconComp = @() pingIconFn.get() == "" ? { watch = pingIconFn } : {
  watch = pingIconFn
  size = pingIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{pingIconFn.get()}.svg:{pingIconSize[0]}:{pingIconSize[1]}:P")
  color = pingIconFn.get() != "icon_wifi_low" ? defaultColor : badQualityColor
  keepAspect = true
}

function updateBatteryState() {
  batteryCharge.set(getBattery())
  isCharging.set(is_charging())
}

let batteryIconFn = Computed(@() batteryCharge.get() < 0 ? BATTERY_BG_NONE
  : isCharging.get() > 0 ? BATTERY_BG_CHARGING
  : BATTERY_BG_NORMAL
)

let batteryColor = Computed(
  @() batteryCharge.get() < 0 || batteryCharge.get() >= BATTERY_LEVEL_ACCEPTABLE ? defaultColor : badQualityColor)

let batteryFillWidth = Computed(@() round(clamp(batteryCharge.get(), 0.0, 1.0) * batteryFillMaxW))

function batteryComp() {
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
  gap = hdpx(10)
  children = [
    fpsComp
    pingComp
    plComp
    pingIconComp
    batteryComp
  ]
}

register_command(@() log($"Device state: battery={get_battery()}, charging={is_charging()}, params:",
  deviceState.get()), "ui.debug.dump_device_state")

return deviceStateArea