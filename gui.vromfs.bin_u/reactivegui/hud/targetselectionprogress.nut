from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { getSvgImage } = require("%rGui/hud/hudTouchButtonStyle.nut")

let color = Color(200, 200, 200, 200)

let defTransform = {}
let cooldownEndTime = Watched(0.0)
let cooldownTime = Watched(0.0)

let size = (1.7 * shHud(3.5)).tointeger()
let selectionReloadImage = getSvgImage("reload_indication_in_zoom", size)

subscribe("on_delayed_target_select:show", function(data) {
  let { startTime = 0.0, endTime = 0.0 } = data
  cooldownEndTime(endTime)
  cooldownTime(endTime - startTime)
})

subscribe("on_delayed_target_select:hide", function(_) {
  cooldownEndTime(0.0)
})

let mkTargetSelectionData = function(endTime, cooldown) {
  let cdLeft = endTime - ::get_mission_time()
  if (endTime <= 0)
    return null
  return {
      size = flex()
      rendObj = ROBJ_PROGRESS_CIRCULAR
      image = selectionReloadImage
      fgColor = color
      bgColor = 0
      opacity = 1.0
      bValue = 1.0
      fValue = 1.0
      key = $"reload_sector_{endTime}_{cooldown}_{color}"
      transform = {}
      animations = [
        {
          prop = AnimProp.fValue, to = 1.0, play = true,
          from = (1 - (cdLeft / max(cooldown, 1))),
          duration = cdLeft
        }
        {
          prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
          duration = cdLeft
        }
      ]
  }
}

let targetSelectionProgress = @() {
  watch = [cooldownTime, cooldownEndTime ]
  transform = defTransform
  behavior = Behaviors.Indicator
  size = [shHud(2), shHud(2)]
  children = mkTargetSelectionData(cooldownEndTime.value, cooldownTime.value)
}

return {
  targetSelectionProgress
}