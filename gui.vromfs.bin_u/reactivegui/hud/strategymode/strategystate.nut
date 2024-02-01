from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { getStrategyState } = require("guiStrategyMode")
let { AIR_GROUP_TYPE } = require("%rGui/hud/strategyMode/style.nut")

let behaviourToType = {
  [""]              = AIR_GROUP_TYPE.SHIP_SELF,
  carrierFighter    = AIR_GROUP_TYPE.PLANE_FIGHTER,
  carrierBomber     = AIR_GROUP_TYPE.PLANE_BOMBER,
  carrierDiveBomber = AIR_GROUP_TYPE.PLANE_DIVE_BOMBER,
}

function getAirGroupType(behaviourName) {
  local airGroupType = behaviourToType?[behaviourName] ?? AIR_GROUP_TYPE.UNKNOWN
  return airGroupType
}

let strategyDataCur = Watched(null)
let strategyDataRest = Watched(null)

let curAirGroupIndex = Watched(0)
let curAirGroupType = Computed(@() getAirGroupType(strategyDataCur.value?.behaviour ?? "unknown"))
let curAirGroupCanAttack = Computed(@() strategyDataCur.value?.canAttack ?? false)
let curAirGroupCanDefend = Computed(@() strategyDataCur.value?.canDefend ?? false)
let curAirGroupCanHunt = Computed(@() strategyDataCur.value?.canHunt ?? false)
let curAirGroupIsLaunched = Computed(@() strategyDataCur.value?.isLaunched ?? false)
let curAirGroupPathLength = Computed(@() strategyDataCur.value?.nodes.len() ?? 0)

function updateStrategyDataCur() {
  let data = getStrategyState(curAirGroupIndex.value);
  strategyDataCur(data)
}

function udpateStateDataRest() {
  let data = {}
  foreach(airGroupIndex in [0, 1, 2]) {
    let airGroupData = getStrategyState(airGroupIndex)
    data.rawset(airGroupIndex, airGroupData)
  }
  strategyDataRest(data)
}

function strategyStateUpdateStart() {
  updateStrategyDataCur()
  udpateStateDataRest()
  setInterval(0.05, updateStrategyDataCur)
  setInterval(1.0, udpateStateDataRest)
}

function strategyStateUpdateStop() {
  clearTimer(updateStrategyDataCur)
  clearTimer(udpateStateDataRest)
}

return {
  curAirGroupIndex
  curAirGroupType
  curAirGroupCanAttack
  curAirGroupCanDefend
  curAirGroupCanHunt
  curAirGroupIsLaunched
  curAirGroupPathLength

  strategyDataCur
  strategyDataRest

  strategyStateUpdateStart
  strategyStateUpdateStop
}
