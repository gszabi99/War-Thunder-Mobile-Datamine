from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { obstacleIsNear, distanceToObstacle } = require("%rGui/hud/shipState.nut")
let { abs } = require("%sqstd/math.nut")
let { register_command } = require("console")
let { registerHintCreator } = require("%rGui/hudHints/hintCtors.nut")
let { addEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")


let HINT_TYPE = "obstacleWarning"
let alertDMColor = Color(221, 17, 17)

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isDebugDistance = mkWatched(persist, "debugDistance", false)
let debugDistance = Watched(null)
let needHint = keepref(Computed(@() obstacleIsNear.get() != isDebugMode.get()))
let distanceToObstacleExt = Computed(@() debugDistance.get() ?? distanceToObstacle.get())
let showCollideWarning = Computed(@() distanceToObstacleExt.get() < 0)

let textToShow = Computed(@() showCollideWarning.get() ? loc("hud_ship_collide_warning")
  : loc("hud_ship_depth_on_course_warning"))

let updateDebugDistance = @() debugDistance.set((((debugDistance.get() ?? 0) + 2) % 10) - 1)
function updateDebugDistanceTimer(isDebug) {
  clearTimer(updateDebugDistance)
  if (!isDebug) {
    debugDistance.set(null)
    return
  }
  setInterval(0.5, updateDebugDistance)
  debugDistance.set(1)
}
updateDebugDistanceTimer(isDebugDistance.get())
isDebugDistance.subscribe(updateDebugDistanceTimer)

registerHintCreator(HINT_TYPE, @(_, __) @() {
  watch = [textToShow, distanceToObstacleExt]
  key = textToShow
  size = [saSize[0] - hdpx(1100), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  fontFxColor = Color(0, 0, 0, 50)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_GLOW
  text = "".concat(textToShow.get(), colon,
    abs(distanceToObstacleExt.get()),
    loc("measureUnits/meters_alt"))
  color = alertDMColor
  halign = ALIGN_CENTER
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.7,
      easing = DoubleBlink, play = true }
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true }
  ]
}.__update(fontTiny))

needHint.subscribe(@(v) !v ? removeEvent({ id = HINT_TYPE })
  : addEvent({ id = HINT_TYPE, hType = HINT_TYPE }))

register_command(@() isDebugMode.set(!isDebugMode.get()), "hud.debug.obstacleNearHint")
register_command(@() isDebugDistance.set(!isDebugDistance.get()), "hud.debug.obstacleNearHintDistance")
