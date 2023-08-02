from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")

let BLINK = 0.3
let PAUSE = 0.1
let NEWBIE_BLINK = "newbieBackButtonBlink"

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

let function startAnimation() {
  anim_start("backButtonBlink")
}

let function backButtonBlink(wnd) {
  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(NEWBIE_BLINK)
  if (wnd not in blk) {
    blk[wnd] = "shown"
    send("saveProfile", {})
    setInterval(3.0, startAnimation)
  }
}

register_command(function() {
    get_local_custom_settings_blk().removeBlock(NEWBIE_BLINK)
    send("saveProfile", {})
  }, "debug.reset_back_button_blink")

return {
  blinkAnimation
  backButtonBlink
  clearBlinkInterval = @() clearTimer(startAnimation)
}