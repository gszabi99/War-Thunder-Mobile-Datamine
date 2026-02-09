let { get_unittags_blk, get_settings_blk } = require("blkGetters")
let defaultBattleData = require("defaultBattleData.nut")

function mkDefaultBattleData(unitName, userId) {
  let unitTags = get_unittags_blk()?[unitName]
  if (unitTags == null)
    return null
  let debugData = get_settings_blk()?.debug
  let debugUnitData = debugData?[unitName]
  return {
    userId
    isFake = true
    unit = {
      name = unitName
      unitType = unitTags.type
      weapons = { [$"{unitName}_default"] = true }
      country = "country_germany"
      isPremium = false
      mRank = 0
      level = 25
      isFake = true
    }
    items = {
      ship_tool_kit = 10
      ship_smoke_screen_system_mod =10
      tank_tool_kit_expendable = 1
      tank_extinguisher = 1
      spare = 10
      ircm_kit = 15
    }.__update(debugUnitData?.mods ?? {})
  }.__update(debugData?.battleData ?? {})
}

return @(unitName, userId) defaultBattleData?[unitName]
  ?? mkDefaultBattleData(unitName, userId)
  ?? defaultBattleData.def