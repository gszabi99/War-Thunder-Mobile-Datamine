from "%globalsDarg/darg_library.nut" import *
let { sqrt, pow, fabs } = require("math")
let { get_local_mplayer, get_mplayer_by_id } = require("mission")
let { getPlayerMapPos, mapPosToWorldPos } = require("guiTacticalMap")
let DataBlock = require("DataBlock")
let { AIR, HELICOPTER, TANK, SHIP, BOAT, SUBMARINE } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { unitType } = require("%rGui/hudState.nut")

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

function getTitleShowDist(ut) {
  if (!isInited)
    initOnce()
  // See in hudIndicators.cpp, const IndicatorsInfo &info
  let isHudTank = unitType.get() == TANK
  let cfgType = isHudTank && ut == TANK ? TANK
    : isHudTank && [SHIP, BOAT, SUBMARINE].contains(ut) ? SHIP
    : [AIR, HELICOPTER].contains(ut) ? AIR
    : COMMON
  return cfgTypeToTitleDist?[cfgType] ?? DEF_TITLE_SHOW_DIST
}

function isPlayerTitleVisible(playerId) {
  let { title = "", aircraftName = "" } = get_mplayer_by_id(playerId)
  if (title == "" || aircraftName == "")
    return false
  let mp1 = getPlayerMapPos(get_local_mplayer().id)
  let mp2 = getPlayerMapPos(playerId)
  if (mp1 == null || mp2 == null)
    return false
  let wp1 = mapPosToWorldPos(mp1)
  let wp2 = mapPosToWorldPos(mp2)
  let wdist = sqrt(pow(fabs(wp1.x - wp2.x), 2) + pow(fabs(wp1.z - wp2.z), 2))
  let playerUnitType = getUnitType(aircraftName)
  return wdist <= getTitleShowDist(playerUnitType)
}

return {
  isPlayerTitleVisible
}
