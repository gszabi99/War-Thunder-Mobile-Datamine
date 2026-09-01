import "DataBlock" as DataBlock
from "blkGetters" import get_settings_blk
from "%sqstd/datablock.nut" import eachParam
from "%appGlobals/clientState/initialState.nut" import shouldDisableMenu


function getDebugSavedBullets(unitName) {
  if (shouldDisableMenu)
    return null

  let debugBulletSets = get_settings_blk()?.debug?[unitName]?.bulletSets
  if (debugBulletSets == null)
    return null

  let resBlk = DataBlock()
  eachParam(debugBulletSets, function(count, name) {
    let bulletBlk = resBlk.addNewBlock("bullet")
    bulletBlk.setStr("name", name == "default" ? "" : name)
    bulletBlk.setInt("count", count)
  })

  return resBlk
}

function getDebugUserSettings(unitName) {
  if (shouldDisableMenu)
    return null

  let debugWeapons = get_settings_blk()?.debug?[unitName]?.weapons
  let debugBullets = get_settings_blk()?.debug?[unitName]?.bullets
  if (debugWeapons == null || debugBullets == null)
    return null

  local belts = {}
  local weaponPreset = []

  function addPreset(preset, slot) {
    if (slot + 1 > weaponPreset.len())
      weaponPreset.resize(slot + 1, "")
    weaponPreset[slot] = preset
  }

  eachParam(debugWeapons, function(preset, slotId) { addPreset(preset, slotId.tointeger()) })
  eachParam(debugBullets, function(bullets, weaponId) { belts[weaponId] <- bullets })

  return {belts, weaponPreset}
}

return {
  getDebugSavedBullets
  getDebugUserSettings
}