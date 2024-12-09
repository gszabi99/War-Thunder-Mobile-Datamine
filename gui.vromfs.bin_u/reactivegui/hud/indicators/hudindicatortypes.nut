from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")

let INDICATOR_TYPE = {
  PLAYER_CHAT_BUBBLE = 1
  PLAYER_MISSION_ICON = 2
}

let INDICATOR_ICON_SIZE = hdpxi(64)
let INDICATOR_FADE_TIME = 1.0

let mkHudIndicatorIcon = @(id, icon, size, ovr) {
  key = $"HudIndicator{id}"
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{size}:{size}:P")
  keepAspect = true
  color = 0xFFFFFFFF
}.__update(ovr)

let isDuplicate_OnePerPlayer = @(p1, p2) p1.playerId == p2.playerId

let indicatorTypes = {
  [INDICATOR_TYPE.PLAYER_CHAT_BUBBLE] = {
    showSec = 5.0
    isDuplicate = isDuplicate_OnePerPlayer
    function ctor(data) {
      let { id, startTimeMs, endTimeMs, params } = data
      let { icon, iconScale = 1.0 } = params
      let startDelay = (startTimeMs - get_time_msec()) / 1000.0
      let totalTime = (endTimeMs - startTimeMs) / 1000.0
      let size = (INDICATOR_ICON_SIZE * iconScale + 0.5).tointeger()
      return mkHudIndicatorIcon(id, icon, size, {
        opacity = 0
        animations = [
          { prop = AnimProp.opacity, from = 0, to = 1, duration = INDICATOR_FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay }
          { prop = AnimProp.opacity, from = 1, to = 1, duration = totalTime - (INDICATOR_FADE_TIME * 2),
              play = true, easing = InOutQuad, delay = startDelay + INDICATOR_FADE_TIME }
          { prop = AnimProp.opacity, from = 1, to = 0, duration = INDICATOR_FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay + totalTime - INDICATOR_FADE_TIME }
        ]
      })
    }
  },
  [INDICATOR_TYPE.PLAYER_MISSION_ICON] = {
    showSec = 0.0
    isDuplicate = isDuplicate_OnePerPlayer
    function ctor(data) {
      let { id, params } = data
      let { icon, iconColor, iconScale = 1.0 } = params
      let size = (INDICATOR_ICON_SIZE * iconScale + 0.5).tointeger()
      return mkHudIndicatorIcon(id, icon, size, {
        color = iconColor
      })
    }
  },
}

return {
  INDICATOR_TYPE
  indicatorTypes
}
