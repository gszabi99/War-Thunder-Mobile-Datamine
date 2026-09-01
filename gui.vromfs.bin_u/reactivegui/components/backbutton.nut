from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/backButtonBlink.nut" import blinkAnimation, clearBlinkInterval
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/stdColors.nut" import hoverColor


const backButtonHeight = hdpx(60)
let backButtonWidth  = (78.0 / 59.0 * backButtonHeight).tointeger()
let image  = Picture($"ui/gameuiskin#back_icon.svg:{backButtonWidth}:{backButtonHeight}")

function backButton(onClick, override = {}) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    key = "backButton"
    onElemState = @(sf) stateFlags.set(sf)
    behavior = Behaviors.Button
    rendObj = ROBJ_IMAGE
    size = [backButtonWidth, backButtonHeight]
    color  = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
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

return {
  backButton
  backButtonWidth
  backButtonHeight
}
