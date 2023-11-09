from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { lerpClamped } = require("%sqstd/math.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")

let function mkAnimatedCountText(uid, value, delay, time, onCounterActive, baseComp) {
  let finalText = decimalFormat(value)
  local needReset = false
  local startTimeMs = 0
  local endTimeMs = 0
  let function reinitTime(nowMs) {
    startTimeMs = nowMs + (1000 * delay).tointeger()
    endTimeMs = startTimeMs + time
  }
  reinitTime(get_time_msec())
  return baseComp.__merge({
    key = uid
    text = 0
    behavior = Behaviors.RtPropUpdate
    function onAttach() {
      let curTime = get_time_msec()
      if (curTime >= endTimeMs) {
        reinitTime(curTime)
        needReset = true
      }
    }
    onDetach = @() onCounterActive?(uid, false)
    function update() {
      let curTime = get_time_msec()
      if (curTime < startTimeMs) {
        if (!needReset)
          return null
        needReset = false
        return { text = 0 }
      }
      let text = curTime >= endTimeMs ? finalText
        : decimalFormat(lerpClamped(startTimeMs, endTimeMs, 0, value, curTime).tointeger())
      onCounterActive?(uid, text != finalText)
      return { text }
    }
  })
}

return mkAnimatedCountText
