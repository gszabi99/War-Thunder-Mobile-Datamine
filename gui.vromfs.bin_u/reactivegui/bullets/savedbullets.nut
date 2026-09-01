from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import isDataBlock
from "%globalScripts/dataBlockExt.nut" import setBlkValueByPath, getBlkValueByPath
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS
from "%rGui/debugTools/debugSavedData.nut" import getDebugSavedBullets


const SAVE_ID = "bullets"

let savedBullets = Watched(null)

function loadSavedBullets(unitName) {
  if (unitName == null)
    return null
  let debugBlk = getDebugSavedBullets(unitName)
  if (debugBlk != null)
    return debugBlk

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

function saveBullets(unitName, blk) {
  if (unitName == null)
    return null
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

function emptyBullet() {
  let blk = DataBlock()
  blk.name = ""
  blk.count = 0
  return blk
}

function setOrSwapUnitBullet(unitName, chosenBullets, chosenBulletsSec, chosenBulletsSpec,
  maxBullets, maxBulletsSec, maxBulletsSpec, hasExtraBullets, hasExtraBulletsSec, hasExtraBulletsSpec,
  bInfo, bInfoSec, bInfoSpec, slotIdx, bName, secBulletsSlots = BULLETS_SEC_SLOTS
) {
  if (unitName == null)
    return false

  let isBulletsSpec = slotIdx >= BULLETS_PRIM_SLOTS + secBulletsSlots
  let isBulletsSec = slotIdx >= BULLETS_PRIM_SLOTS

  let bullets = isBulletsSpec ? chosenBulletsSpec
    : isBulletsSec ? chosenBulletsSec
    : chosenBullets
  let canHaveSameBullets = isBulletsSpec ? (bInfoSpec?.bulletSetAvailiable.len() ?? 0) > 0
    : isBulletsSec ? (bInfoSec?.bulletSetAvailiable.len() ?? 0) > 0
    : (bInfo?.bulletSetAvailiable.len() ?? 0) > 0

  let targetSlot = bullets.findvalue(@(s) s.idx == slotIdx)
  if (targetSlot == null)
    return false

  let prevSlot = bullets.findvalue(@(s) s.name == bName)
  if (prevSlot?.idx == slotIdx)
    return false

  let newNames = { [slotIdx] = bName }
  if (!canHaveSameBullets && prevSlot != null)
    newNames[prevSlot.idx] <- targetSlot.name

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets)
    blk.bullet <- collectBlkBullet(slot, maxBullets?[idx], hasExtraBullets, newNames?[slot.idx])
  for (local i = chosenBullets.len(); i < BULLETS_PRIM_SLOTS; i++)
    blk.bullet <- emptyBullet()
  foreach (idx, slot in chosenBulletsSec)
    blk.bullet <- collectBlkBullet(slot, maxBulletsSec?[idx], hasExtraBulletsSec, newNames?[slot.idx])
  foreach (idx, slot in chosenBulletsSpec)
    blk.bullet <- collectBlkBullet(slot, maxBulletsSpec?[idx], hasExtraBulletsSpec, newNames?[slot.idx])
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

function setUnitBullets(unitName, chosenBullets, chosenBulletsSec, chosenBulletsSpec, slotIdx, bName, bCount) {
  if (unitName == null)
    return

  let blk = DataBlock()
  foreach (_, slot in chosenBullets)
    blk.bullet <- collectChangedBlkBullet(slot, slot.idx == slotIdx, bName, bCount)
  for (local i = chosenBullets.len(); i < BULLETS_PRIM_SLOTS; i++)
    blk.bullet <- emptyBullet()
  foreach (_, slot in chosenBulletsSec)
    blk.bullet <- collectChangedBlkBullet(slot, slot.idx == slotIdx, bName, bCount)
  foreach (_, slot in chosenBulletsSpec)
    blk.bullet <- collectChangedBlkBullet(slot, slot.idx == slotIdx, bName, bCount)
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
  loadSavedBullets
  setUnitBullets
  setOrSwapUnitBullet
  applySavedBullets
  resetSavedBullets
}