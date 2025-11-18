from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let DataBlock = require("DataBlock")
let { isDataBlock } = require("%sqstd/datablock.nut")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { BULLETS_PRIM_SLOTS } = require("%rGui/bullets/bulletsConst.nut")


const SAVE_ID = "bullets"

let savedBullets = Watched(null)

function loadSavedBullets(realUnitName) {
  if (realUnitName == null)
    return null
  let unitName = getTagsUnitName(realUnitName)
  let sBlk = get_local_custom_settings_blk()
  let res = getBlkValueByPath(sBlk, $"{SAVE_ID}/{unitName}")
  if (!isDataBlock(res))
    return null
  let resExt = DataBlock()
  resExt.setFrom(res)
  return resExt
}
let applySavedBullets = @(name) savedBullets.set(loadSavedBullets(name))

isOnlineSettingsAvailable.subscribe(@(_) savedBullets.set(null)) 

function saveBullets(realUnitName, blk) {
  if (realUnitName == null)
    return null
  let unitName = getTagsUnitName(realUnitName)
  let sBlk = get_local_custom_settings_blk()
  setBlkValueByPath(sBlk, $"{SAVE_ID}/{unitName}", blk)
  eventbus_send("saveProfile", {})
}

function collectBlkBullet(slot, maxBullets, withExtraBullets, newName) {
  let { name, count } = slot
  let blk = DataBlock()
  blk.name = newName ?? name
  blk.count = (!withExtraBullets || count == 0) ? count : (maxBullets ?? 0)
  return blk
}

function setOrSwapUnitBullet(unitName, chosenBullets, chosenBulletsSec,
  maxBullets, maxBulletsSec, hasExtraBullets, hasExtraBulletsSec, slotIdx, bName
) {
  if (unitName == null)
    return false

  let bullets = slotIdx >= BULLETS_PRIM_SLOTS ? chosenBulletsSec : chosenBullets
  let actualBulletIdx = slotIdx % BULLETS_PRIM_SLOTS
  if (actualBulletIdx not in bullets)
    return false

  let prevIdx = bullets.findindex(@(s) s.name == bName)
  if (prevIdx == slotIdx)
    return false

  let newNames = { [slotIdx] = bName }
  if (prevIdx != null)
    newNames[prevIdx] <- bullets[actualBulletIdx].name

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets)
    blk.bullet <- collectBlkBullet(slot, maxBullets?[idx], hasExtraBullets, newNames?[idx])
  foreach (idx, slot in chosenBulletsSec)
    blk.bullet <- collectBlkBullet(slot, maxBulletsSec?[idx], hasExtraBulletsSec, newNames?[idx + BULLETS_PRIM_SLOTS])
  savedBullets.set(blk)
  saveBullets(unitName, blk)
  return true
}

function collectChangedBlkBullet(slot, hasChanged, bName, bCount) {
  let blk = DataBlock()
  blk.name = hasChanged ? bName : slot.name
  blk.count = hasChanged ? bCount : slot.count
  return blk
}

function setUnitBullets(unitName, chosenBullets, chosenBulletsSec, slotIdx, bName, bCount) {
  if (unitName == null)
    return

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets)
    blk.bullet <- collectChangedBlkBullet(slot, idx == slotIdx, bName, bCount)
  foreach (idx, slot in chosenBulletsSec)
    blk.bullet <- collectChangedBlkBullet(slot, idx + BULLETS_PRIM_SLOTS == slotIdx, bName, bCount)
  savedBullets.set(blk)
  saveBullets(unitName, blk)
}

function resetSavedBullets(unitName) {
  get_local_custom_settings_blk().removeBlock(SAVE_ID)
  if (unitName != null)
    applySavedBullets(unitName)
  eventbus_send("saveProfile", {})
}

return {
  savedBullets
  setUnitBullets
  setOrSwapUnitBullet
  applySavedBullets
  resetSavedBullets
}