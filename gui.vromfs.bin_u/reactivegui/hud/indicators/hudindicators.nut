from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { localMPlayerId } = require("%appGlobals/clientState/clientState.nut")
let { isHudIndicatorsAttached, hudIndicatorsByPlayerSorted, playerTitlesVisibility
} = require("%rGui/hud/indicators/hudIndicatorsState.nut")
let { indicatorTypes, INDICATOR_ICON_SIZE } = require("%rGui/hud/indicators/hudIndicatorTypes.nut")

let PLAYER_LOCAL_INDICATOR_SHIFT_Y = 0
let PLAYER_WITHOUT_TITLE_INDICATOR_SHIFT_Y = hdpx(-88)
let PLAYER_WITH_TITLE_INDICATOR_SHIFT_Y = hdpx(-114)
let ARROW_SIZE = hdpxi(32)
let ARROW_LAYER_SIZE = INDICATOR_ICON_SIZE + (2 * ARROW_SIZE)

let getPlayerIndicatorsShiftY = @(isLocal, isTitleVisible) isLocal ? PLAYER_LOCAL_INDICATOR_SHIFT_Y
  : isTitleVisible ? PLAYER_WITH_TITLE_INDICATOR_SHIFT_Y
  : PLAYER_WITHOUT_TITLE_INDICATOR_SHIFT_Y

let scrEdgeArrowImg = {
  size = [ARROW_SIZE, ARROW_SIZE]
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#arrow_mark.svg:{ARROW_SIZE}:{ARROW_SIZE}:P")
  keepAspect = KEEP_ASPECT_FIT
  color = 0xFFFFFFFF
}

function mkHudIndicatorsContainer(playerId, teamColor, children) {
  let posShiftY = Computed(@() getPlayerIndicatorsShiftY(playerId == localMPlayerId.get(),
    playerTitlesVisibility.get()?[playerId] ?? false))
  let isOnScrEdge = Watched(false)
  return {
    key = $"hudIndicatorBhv{playerId}"
    size = 0
    behavior = Indicator
    playerId
    useTargetCenterPos = true
    transform = {}
    children = [
      @() {
        watch = [isOnScrEdge, posShiftY]
        pos = isOnScrEdge.get() ? [0, 0] : [0, posShiftY.get()]
        hplace = ALIGN_CENTER
        vplace = isOnScrEdge.get() ? ALIGN_CENTER : ALIGN_BOTTOM
        transform = {}
        flow = FLOW_VERTICAL
        gap = hdpx(16)
        children
      }
      {
        size = [ARROW_LAYER_SIZE, ARROW_LAYER_SIZE]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        opacity = 0
        transform = {}
        onScrEdgeState = @(v) isOnScrEdge.set(v)
        children = scrEdgeArrowImg.__merge({ color = teamColor })
      }
    ]
  }
}

let mkIndicator = @(data) indicatorTypes[data.indicatorType].ctor(data)

let indicatorsKey = {}

let hudIndicators = @() {
  watch = hudIndicatorsByPlayerSorted
  key = indicatorsKey
  size = flex()
  onAttach = @() isHudIndicatorsAttached.set(true)
  onDetach = @() isHudIndicatorsAttached.set(false)
  children = hudIndicatorsByPlayerSorted.get().map(@(v) mkHudIndicatorsContainer(v.playerId, v.teamColor, v.data.map(mkIndicator)))
}

return hudIndicators
