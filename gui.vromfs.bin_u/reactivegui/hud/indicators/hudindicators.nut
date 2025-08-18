from "%globalsDarg/darg_library.nut" import *
let { Indicator } = require("wt.behaviors")
let { localMPlayerId } = require("%appGlobals/clientState/clientState.nut")
let { isHudIndicatorsAttached, hudIndicatorsByPlayerSorted, playerTitlesVisibility, indicatorTypes
} = require("%rGui/hud/indicators/hudIndicatorsState.nut")

let PLAYER_LOCAL_INDICATOR_SHIFT_Y = 0
let PLAYER_WITHOUT_TITLE_INDICATOR_SHIFT_Y = hdpx(-88)
let PLAYER_WITH_TITLE_INDICATOR_SHIFT_Y = hdpx(-114)

let getPlayerIndicatorsShiftY = @(isLocal, isTitleVisible) isLocal ? PLAYER_LOCAL_INDICATOR_SHIFT_Y
  : isTitleVisible ? PLAYER_WITH_TITLE_INDICATOR_SHIFT_Y
  : PLAYER_WITHOUT_TITLE_INDICATOR_SHIFT_Y

function mkHudIndicatorsContainer(playerId, children) {
  let posShiftY = Computed(@() getPlayerIndicatorsShiftY(playerId == localMPlayerId.get(),
    playerTitlesVisibility.get()?[playerId] ?? false))
  return {
    key = $"hudIndicatorBhv{playerId}"
    size = 0
    behavior = Indicator
    playerId
    useTargetCenterPos = true
    transform = {}
    children = @() {
      watch = posShiftY
      pos = [0, posShiftY.get()]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      flow = FLOW_VERTICAL
      gap = hdpx(16)
      children
    }
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
  children = hudIndicatorsByPlayerSorted.get().map(@(v) mkHudIndicatorsContainer(v.playerId, v.data.map(mkIndicator)))
}

return hudIndicators
