from "%globalsDarg/darg_library.nut" import *

let visibleLog = Watched({})

let function clearLog() {
  visibleLog({})
}

let dmgTypeIcons = [
  "⋗" //second_caliber
  "⋖" //main_caliber
  "▢" // bomb
  "▣" //rocket
  "⌋" //torpedo
  "⋄" //mine
]

let delayAnimTime = 0.2
let scaleAnimTime = 0.1
let showAnimTime = 0.5
let visibleAnimTime = delayAnimTime + scaleAnimTime + showAnimTime
let opacityAnimTime = 0.3
let fullAnimTime = visibleAnimTime + opacityAnimTime

::interop.hudDmgInfoUpdate <- function (dmg, dmgType) {
  gui_scene.resetTimeout(fullAnimTime, clearLog)
  let dmgLog = dmgType in visibleLog.value ? clone visibleLog.value[dmgType] : []
  if (dmgLog.len() > 0 && dmgLog.top() == dmg)  // !!!FIX ME need remove this when will the duplicate damage stop received from native code.
    return
  dmgLog.append(dmg)
  visibleLog.mutate(@(v) v[dmgType] <- dmgLog)
}

let textStyle = {
  rendObj = ROBJ_TEXT
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
}.__update(fontTiny)

let function damageLogUi() {
  let resObj = { watch = visibleLog, size = [shHud(50), hdpx(50)] }
  if (visibleLog.value.len() == 0)
    return resObj

  local damageCount = 0
  local damageTypes = ""
  foreach (dmgType, dmgCounts in visibleLog.value) {
    damageTypes = $"{damageTypes} {dmgTypeIcons?[dmgType] ?? dmgTypeIcons[0]}"
    damageCount = (dmgCounts.reduce(@(res, v) max(res, v), damageCount) + 0.5).tointeger()
  }

  if (damageCount <= 0)
    return resObj

  return resObj.__update({
    children = {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = shHud(5)
      key = $"damageLog_{visibleLog.value}"
      opacity = 0.0
      animations = [
        { prop = AnimProp.opacity, from = 1.0, to = 1.0, duration = visibleAnimTime, easing = Linear,
          play = true, onExit = "damageLog_hide"
        }
        { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = opacityAnimTime, easing = Linear,
          trigger = "damageLog_hide"
        }
      ]
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          text = damageTypes
          halign = ALIGN_RIGHT
        }.__update(textStyle)
        {
          size = [flex(), SIZE_TO_CONTENT]
          text = damageCount
          halign = ALIGN_LEFT
          animations = [
            { prop = AnimProp.scale, from = [0.93, 0.93], to = [0.93, 0.93], play = true,
              delay = delayAnimTime, duration = scaleAnimTime, easing = Linear
            }
          ]
          transform = { pivot = [0.2, 0.5] }
        }.__update(textStyle)
      ]
    }
  })
}

return damageLogUi
