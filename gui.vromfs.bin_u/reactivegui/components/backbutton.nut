from "%globalsDarg/darg_library.nut" import *
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { blinkAnimation, clearBlinkInterval } = require("backButtonBlink.nut")

let height = hdpx(60)
let width  = (78.0 / 59.0 * height).tointeger()
let image  = Picture($"ui/gameuiskin#back_icon.svg:{width}:{height}")

return function backButton(onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    key = "backButton"
    onElemState = @(sf) stateFlags(sf)
    behavior = Behaviors.Button
    rendObj = ROBJ_IMAGE
    size = [width, height]
    color  = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
    image
    clickableInfo = loc("mainmenu/btnBack")
    hotkeys = [[btnBEscUp, loc("mainmenu/btnBack")]]
    onClick
    sound = { click  = "click" }
    transform = {}
    animations = blinkAnimation
    onDetach = clearBlinkInterval
  }.__update(override)
}
