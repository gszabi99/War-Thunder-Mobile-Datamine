from "%appGlobals/unitConst.nut" import *
from "%globalScripts/logs.nut" import *
let { get_unittags_blk } = require("blkGetters")
let { blk2SquirrelObjNoArrays, isDataBlock, eachBlock } = require("%sqstd/datablock.nut")
let { isReadyToFullLoad, isLoginRequired, isLoginStarted } = require("%appGlobals/loginState.nut")

let unitTagsCfg = {}

function calcUnitTypeFromTags(tagsCfg) {
  let { tags } = tagsCfg
  if ("submarine" in tags)
    return SUBMARINE
  if ("boat" in tags)
    return BOAT
  if ("ship" in tags)
    return SHIP
  if ("tank" in tags)
    return TANK
  if (tags?.type == "aircraft")
    return AIR
  return tags?.type ?? AIR
}

let remapBulletName = @(bName) bName == "default" ? "" : bName

function gatherUnitTagsCfg(unitName) {
  if (isLoginRequired.get() && !isReadyToFullLoad.get() && isLoginStarted.get())
    logerr("Call gatherUnitTagsCfg while not isReadyToFullLoad")

  let blk = get_unittags_blk()?[unitName]
  let res = isDataBlock(blk) ? blk2SquirrelObjNoArrays(blk) : {}
  res.tags <- (res?.tags ?? {}).filter(@(v) v)
  res.unitType <- calcUnitTypeFromTags(res)

  let blockName = "bullets"
  let bulletsBlk = blk?.bullets ?? blk?.Shop.weapons

  if (isDataBlock(bulletsBlk)) {
    res.bulletsOrder <- {}
    if (blockName not in res)
      res[blockName] <- res?.Shop.weapons ?? {}
    res.bullets = res.bullets.filter(@(v) type(v) == "table")
    foreach (id, bList in res.bullets) {
      if ("default" in bList)
        bList[""] <- bList.$rawdelete("default")
      local ordered = []
      if (id in bulletsBlk)
        eachBlock(bulletsBlk[id], @(b) ordered.append(remapBulletName(b.getBlockName())))
      else {  //we got strange logerr from production here, so this is just more logs about it.
        log($"bulletsBlk {unitName} = ", bulletsBlk)
        log($"res.bullets {unitName} = ", res.bullets)
        logerr("Failed to get bullets order from unittags")
        ordered = bList.keys()
      }
      res.bulletsOrder[id] <- ordered
    }
  }

  return res
}

function getUnitTagsCfg(unitName) {
  if (unitName not in unitTagsCfg)
    unitTagsCfg[unitName] <- gatherUnitTagsCfg(unitName)
  return unitTagsCfg[unitName]
}

return {
  getUnitTagsCfg
  getUnitTags = @(u) getUnitTagsCfg(u).tags
  getUnitType = @(u) getUnitTagsCfg(u).unitType
  getUnitTagsShop = @(u) getUnitTagsCfg(u)?.Shop
}