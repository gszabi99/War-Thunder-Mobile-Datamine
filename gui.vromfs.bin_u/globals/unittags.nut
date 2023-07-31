
from "%appGlobals/unitConst.nut" import *
from "%globalScripts/logs.nut" import *
let { get_unittags_blk } = require("blkGetters")
let { blk2SquirrelObjNoArrays, isDataBlock, eachBlock } = require("%sqstd/datablock.nut")

let unitTagsCfg = {}

let function calcUnitTypeFromTags(tagsCfg) {
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

let function gatherUnitTagsCfg(unitName) {
  let blk = get_unittags_blk()?[unitName]
  let res = isDataBlock(blk) ? blk2SquirrelObjNoArrays(blk) : {}
  res.tags <- (res?.tags ?? {}).filter(@(v) v)
  res.unitType <- calcUnitTypeFromTags(res)

  if (isDataBlock(blk?.bullets)) {
    res.bulletsOrder <- {}
    res.bullets = res.bullets.filter(@(v) type(v) == "table")
    foreach (id, bList in res.bullets) {
      if ("default" in bList)
        bList[""] <- delete bList["default"]
      let ordered = []
      eachBlock(blk.bullets[id], @(b) ordered.append(remapBulletName(b.getBlockName())))
      res.bulletsOrder[id] <- ordered
    }
  }

  return res
}

let function getUnitTagsCfg(unitName) {
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