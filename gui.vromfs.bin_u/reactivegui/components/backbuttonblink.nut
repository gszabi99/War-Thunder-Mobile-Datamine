from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_send


const BLINK = 0.3
const PAUSE = 0.1
const NEWBIE_BLINK = "newbieBackButtonBlink"

let blinkAnimation = [
  {
    prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4],
    duration = BLINK, trigger = "backButtonBlink", easing = Blink
  }
  {
    prop = AnimProp.scale, from = [1.0, 1.0], to = [1.4, 1.4],
    delay = BLINK + PAUSE, duration = BLINK, trigger = "backButtonBlink", easing = Blink
  }
]

function startAnimation() {
  anim_start("backButtonBlink")
}

function backButtonBlink(wnd) {
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(NEWBIE_BLINK)
  if (wnd not in blk) {
    blk[wnd] = "shown"
    eventbus_send("saveProfile", {})
    setInterval(3.0, startAnimation)
  }
}

register_command(function() {
    get_local_custom_settings_blk().removeBlock(NEWBIE_BLINK)
    eventbus_send("saveProfile", {})
  }, "debug.reset_back_button_blink")

return {
  blinkAnimation
  backButtonBlink
  clearBlinkInterval = @() clearTimer(startAnimation)
}