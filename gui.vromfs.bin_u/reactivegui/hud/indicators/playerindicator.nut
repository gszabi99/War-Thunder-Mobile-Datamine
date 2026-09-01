from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "%appGlobals/unitConst.nut" import AIR, HELICOPTER, TANK, SHIP, BOAT, SUBMARINE


const DEF_TITLE_SHOW_DIST = 1000.0
const COMMON = "common"

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
