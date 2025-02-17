from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")
let { getStrategyState, NODE_ORDER_RETURN } = require("guiStrategyMode")
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

let optDebugDraw = Watched(true)
let optMoveCameraByDrag = Watched(false)

let strategyDataCur = Watched(null)
let strategyDataRest = Watched(null)
let strategyDataShip = Watched(null)

let curGroupIndex = Watched(0)
let curAirGroupType = Computed(@() getAirGroupType(strategyDataCur.value?.behaviour ?? "unknown"))
let curAirGroupCanAttackAir = Computed(@() strategyDataCur.value?.canAttackAir ?? false)
let curAirGroupCanAttackGround = Computed(@() strategyDataCur.value?.canAttackGround ?? false)
let curAirGroupCanDefend = Computed(@() strategyDataCur.value?.canDefend ?? false)
let curAirGroupCanHunt = Computed(@() strategyDataCur.value?.canHunt ?? false)
let curAirGroupPathLength = Computed(@() strategyDataCur.value?.nodes.len() ?? 0)
let curAirGroupIsLaunched = Computed(@() strategyDataCur.value?.isLaunched ?? false)
let curAirGroupIsReturning = Computed(@() strategyDataCur.value &&
  strategyDataCur.value.nodes.len() == 2 && strategyDataCur.value.nodes[1].type == NODE_ORDER_RETURN)

function updateStrategyDataCur() {
  let data = getStrategyState(curGroupIndex.get())
  if (data?.groupNotDead) {
    strategyDataCur(data)
  }
  else {
    curGroupIndex.set(-1)
    let shipData = getStrategyState(-1)
    strategyDataCur(shipData)
  }
}

function updateStrategyDataShip() {
  let data = getStrategyState(-1)
  strategyDataShip(data)
}

function udpateStrategyDataRest() {
  let data = {}
  foreach(airGroupIndex in [0, 1, 2]) {
    let airGroupData = getStrategyState(airGroupIndex)
    data.rawset(airGroupIndex, airGroupData)
  }
  strategyDataRest(data)
}

function strategyStateUpdateStart() {
  updateStrategyDataCur()
  udpateStrategyDataRest()
  updateStrategyDataShip()
  setInterval(0.1, updateStrategyDataCur)
  setInterval(1.0, udpateStrategyDataRest)
  setInterval(1.0, updateStrategyDataShip)
}

function strategyStateUpdateStop() {
  clearTimer(updateStrategyDataCur)
  clearTimer(udpateStrategyDataRest)
  clearTimer(updateStrategyDataShip)
}

register_command(@(v) optDebugDraw(v), "strategymode.debugDraw")
register_command(@(v) optMoveCameraByDrag(v), "strategymode.moveCameraByDrag")

return {
  curGroupIndex
  curAirGroupType
  curAirGroupCanAttackAir
  curAirGroupCanAttackGround
  curAirGroupCanDefend
  curAirGroupCanHunt
  curAirGroupPathLength
  curAirGroupIsLaunched
  curAirGroupIsReturning

  strategyDataCur
  strategyDataRest
  strategyDataShip

  strategyStateUpdateStart
  strategyStateUpdateStop

  updateStrategyDataCur
  udpateStrategyDataRest

  optDebugDraw
  optMoveCameraByDrag
}
