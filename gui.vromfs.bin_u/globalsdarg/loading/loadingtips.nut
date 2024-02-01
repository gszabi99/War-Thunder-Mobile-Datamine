from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { rnd_int } = require("dagor.random")
let { doesLocTextExist } = require("dagor.localize")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let random_pick = require("%sqstd/random_pick.nut")


const GLOBAL_LOADING_TIP_BIT = 0x80000000
const MISSING_TIPS_IN_A_ROW_ALLOWED = 30
const TIP_LIFE_TIME_MSEC = 10000

let tipsLocId = {}
local isInited = false

let curTipInfo = mkWatched(persist, "curTipInfo", { locId = "", unitType = "", unitTypeBit = 0 })
let curUnitTypeWeights = mkWatched(persist, "curUnitTypeWeights", null)
let isUpdatesEnabled = Watched(false)
let lastTipTimeMsec = mkWatched(persist, "lastTipTimeMsec", 0)
let nextTipTimeMsec = Computed(@() isUpdatesEnabled.value ? lastTipTimeMsec.value + TIP_LIFE_TIME_MSEC : 0)

let unitTypeRemap = {
  [AIR] = "aircraft"
}

//for global tips unitType = null
function getKeyFormat(unitType, isNewbie) {
  let path = ["loading"]
  if (unitType != null)
    path.append(unitTypeRemap?[unitType] ?? unitType)
  if (isNewbie)
    path.append("newbie")
  path.append("tip{idx}") //warning disable: -forgot-subst
  return "/".join(path)
}

//for global tips unitType = null
function loadTipsKeysByUnitType(unitType) {
  let res = []

  let configs = []
  foreach (isNewbieTip in [true, false])
    configs.append({ isNewbieTip, keyFormat   = getKeyFormat(unitType, isNewbieTip) })

  local notExistInARow = 0
  for (local idx = 0; notExistInARow <= MISSING_TIPS_IN_A_ROW_ALLOWED; idx++) { // warning disable: -mismatch-loop-variable
    local locId = ""
    local isFound = false
    foreach (cfg in configs) {
      locId = cfg.keyFormat.subst({ idx })
      if (doesLocTextExist(locId)) {
        isFound = true
        break
      }
    }

    if (!isFound) {
      notExistInARow++
      continue
    }
    notExistInARow = 0
    res.append(locId)
  }
  return res
}

function loadTipsOnce() {
  if (isInited)
    return

  isInited = true
  tipsLocId.clear()
  tipsLocId[GLOBAL_LOADING_TIP_BIT] <- loadTipsKeysByUnitType(null)

  foreach (unitType in unitTypeOrder) {
    let keys = loadTipsKeysByUnitType(unitType)
    if (!keys.len())
      continue
    let bit = unitTypeToBit(unitType)
    tipsLocId[bit] <- keys
  }
}

function genNewTip(unitTypeWeights, prevTipInfo) {
  loadTipsOnce()
  let res = { locId = "", unitType = "", unitTypeBit = 0 }

  unitTypeWeights = unitTypeWeights.filter(@(_, bit) (tipsLocId?[bit].len() ?? 0) != 0)
  let prevBit = prevTipInfo.unitTypeBit
  if (unitTypeWeights.len() > 1 && (prevBit in unitTypeWeights) && tipsLocId[prevBit].len() == 1)
    unitTypeWeights.$rawdelete(prevBit)
  if (unitTypeWeights.len() == 0)
    return res

  //choose new tip
  let unitTypeBit = random_pick(unitTypeWeights)
  let tipsList = tipsLocId[unitTypeBit]
  let totalTips = tipsList.len()
  local idx = rnd_int(0, totalTips - 1)
  if (tipsList[idx] == prevTipInfo.locId)
    idx = (idx + 1 < totalTips) ? (idx + 1) : 0

  res.locId = tipsList[idx]
  res.unitType = bitToUnitType(unitTypeBit)
  res.unitTypeBit = unitTypeBit
  return res
}

function updateCurTip() {
  let tip = genNewTip(curUnitTypeWeights.value, curTipInfo.value)
  curTipInfo(tip)
  lastTipTimeMsec(get_time_msec())
}

nextTipTimeMsec.subscribe(@(v) v > 0 ? resetTimeout(max(0.01, 0.001 * (v - get_time_msec())), updateCurTip)
  : clearTimer(updateCurTip))

function enableTipsUpdate(unitTypeWeights = null) {
  loadTipsOnce()
  unitTypeWeights = unitTypeWeights ?? tipsLocId.map(@(_) 1.0)
  if (!isEqual(curUnitTypeWeights.value, unitTypeWeights) || curTipInfo.value.locId == "") {
    curUnitTypeWeights(unitTypeWeights)
    updateCurTip()
  }
  isUpdatesEnabled(true)
  if (nextTipTimeMsec.value < get_time_msec())
    updateCurTip()
}

let disableTipsUpdate = @() isUpdatesEnabled(false)

function getAllTips() {
  loadTipsOnce()
  return tipsLocId
}

return {
  GLOBAL_LOADING_TIP_BIT
  curTipInfo
  enableTipsUpdate
  disableTipsUpdate
  getAllTips
}