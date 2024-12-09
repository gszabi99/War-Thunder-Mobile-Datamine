from "%globalsDarg/darg_library.nut" import *
let DataBlock = require("DataBlock")
let { AIR, HELICOPTER, TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")

let DEF_TITLE_SHOW_DIST = 1000.0
let COMMON = "common"

let cfgNameToCfgType = {
  indicatorsForPlanes = AIR,
  indicatorsForTanks = TANK,
  indicatorsForShips = SHIP,
  indicatorsCommon = COMMON,
}

local isInited = false
let cfgTypeToTitleDist = {}

function initOnce() {
  let blk = DataBlock()
  if (!blk.tryLoad("config/hud.blk"))
    return

  isInited = true
  foreach (cfgName, cfgType in cfgNameToCfgType)
    cfgTypeToTitleDist[cfgType] <- blk?.indicators[cfgName].distanceShowTitle ?? DEF_TITLE_SHOW_DIST
}

function getTitleShowDist(hudUnitType, ut) {
  if (!isInited)
    initOnce()
  // See in hudIndicators.cpp, const IndicatorsInfo &info
  let isHudTank = hudUnitType == TANK
  let cfgType = isHudTank && ut == TANK ? TANK
    : isHudTank && [SHIP, BOAT, SUBMARINE].contains(ut) ? SHIP
    : [AIR, HELICOPTER].contains(ut) ? AIR
    : COMMON
  return cfgTypeToTitleDist?[cfgType] ?? DEF_TITLE_SHOW_DIST
}

return {
  getTitleShowDist
}
