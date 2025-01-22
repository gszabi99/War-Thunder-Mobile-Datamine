from "%globalScripts/logs.nut" import *
let { get_unittags_blk } = require("blkGetters")
let { abs } = require("%sqstd/math.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


function calcCountryByUnitTags(tags, defValue) {
  local country = defValue
  if (isDataBlock(tags))
    eachParam(tags, function(_, id) {
      if (id.startswith("country_"))
        country = id
    })
  return country
}

function calcUnitClassByUnitTags(tags, defValue) {
  local res = ""
  if (isDataBlock(tags))
    eachParam(tags, function(_, id) {
      if (res == "" && id.startswith("type_"))
        res = id.slice(5)
    })
  return res == "" ? defValue : res
}

function genBotDecorators(name) {
  let playerHash = name.hash()
  let avatars = serverConfigs.get()?.allDecorators.filter(@(dec) dec.dType == "avatar" && !(dec?.isHiddenForBot ?? false))
  return {
    avatar = avatars?.keys()[(playerHash) % (avatars?.len() ?? 1)]
  }
}

function genBotCommonStats(name, unitName, unitCfg, defLevel) {
  let playerHash = name.hash()
  let unitHash = unitName.hash()
  let { tags = null, mRank = unitCfg?.mRank, isPremium = unitCfg?.isPremium ?? false } = get_unittags_blk()?[unitName]
  return {
    level = unitCfg?.rank ?? defLevel
    mainUnitName = unitName
    units = {
      [unitName] = {
        level = abs((playerHash + unitHash) % 25) + 1
        unitClass = calcUnitClassByUnitTags(tags, unitCfg?.unitClass ?? "")
        country = calcCountryByUnitTags(tags, unitCfg?.country ?? "")
        mRank
        isCollectible = unitCfg?.isCollectible ?? false
        isPremium
      }
    }
    decorators = genBotDecorators(name)
  }
}

return {
  genBotCommonStats
  genBotDecorators
}
