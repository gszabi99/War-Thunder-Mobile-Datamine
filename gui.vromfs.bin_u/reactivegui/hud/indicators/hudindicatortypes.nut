from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { Indicator } = require("wt.behaviors")
let { isPlayerTitleVisible } = require("playerIndicator.nut")

let INDICATOR_TYPE = {
  PLAYER_CHAT_BUBBLE = 1
}

let FADE_TIME = 1.0
let PLAYER_CHAT_BUBBLE_POS_Y = hdpx(-120)
let PLAYER_WITH_TITLE_CHAT_BUBBLE_POS_Y = hdpx(-146)

let mkHudIndicatorComp = @(id, ovr, iconOvr) {
  key = $"hudIndicator{id}"
  size = [0, 0]
  behavior = Indicator
  useTargetCenterPos = true
  transform = {}
  children = {
    key = $"hudIndicatorVis{id}"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(iconOvr)
}.__update(ovr)

let indicatorTypes = {
  [INDICATOR_TYPE.PLAYER_CHAT_BUBBLE] = {
    showSec = 5.0
    isDuplicate = @(p1, p2) p1.playerId == p2.playerId
    function ctor(data) {
      let { id, startTimeMs, endTimeMs, params } = data
      let { playerId, icon, iconScale = 1.0 } = params
      let shiftY = isPlayerTitleVisible(playerId)
        ? PLAYER_WITH_TITLE_CHAT_BUBBLE_POS_Y
        : PLAYER_CHAT_BUBBLE_POS_Y
      let startDelay = (startTimeMs - get_time_msec()) / 1000.0
      let totalTime = (endTimeMs - startTimeMs) / 1000.0
      let size = (hdpx(64) * iconScale + 0.5).tointeger()
      return mkHudIndicatorComp(id, { playerId }, {
        size = [size, size]
        pos = [0, shiftY]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{icon}:{size}:{size}:P")
        keepAspect = true
        color = 0xFFFFFFFF
        opacity = 0
        animations = [
          { prop = AnimProp.opacity, from = 0, to = 1, duration = FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay }
          { prop = AnimProp.opacity, from = 1, to = 1, duration = totalTime - (FADE_TIME * 2),
              play = true, easing = InOutQuad, delay = startDelay + FADE_TIME }
          { prop = AnimProp.opacity, from = 1, to = 0, duration = FADE_TIME,
              play = true, easing = InOutQuad, delay = startDelay + totalTime - FADE_TIME }
        ]
      })
    }
  },
}

return {
  INDICATOR_TYPE
  indicatorTypes
}
