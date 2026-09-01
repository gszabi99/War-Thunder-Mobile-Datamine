from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import isDataBlock, blk2SquirrelObjNoArrays
from "%appGlobals/loginState.nut" import isSettingsAvailable
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BS_VISIBLE, BS_UNLOCKED,
  BS_ONLY_EXTERNAL_SLOT
from "%rGui/bullets/calcBullets.nut" import calcBulletsStatus
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice


require("%rGui/onlyAfterLogin.nut")


const SEEN_SHELLS = "SeenShells"
let MASK_FOR_UNSEEN = BS_VISIBLE | BS_UNLOCKED
let seenShells = mkWatched(persist, SEEN_SHELLS, {})

function loadSeenShells() {
  if (!isSettingsAvailable.get())
    return seenShells.set({})
  let sBlk = get_local_custom_settings_blk()

  let htBlk = sBlk?[SEEN_SHELLS]
  seenShells.set(isDataBlock(htBlk) ? blk2SquirrelObjNoArrays(htBlk) : {})
}

if (seenShells.get().len() == 0)
  loadSeenShells()
isSettingsAvailable.subscribe(@(_) loadSeenShells())

function fillUnseenBullets(res, bInfo, unitName, unit, modsCfg, seen, slotTo) {
  if (bInfo == null)
    return

  let status = calcBulletsStatus(bInfo, unit?.level ?? 0, unit?.mods ?? {}, modsCfg)
  foreach (bName, s in status)
    if (bName != ""
        && (s & MASK_FOR_UNSEEN) == MASK_FOR_UNSEEN
        && (slotTo > 0 || (s & BS_ONLY_EXTERNAL_SLOT) == 0)
        && !(seen?[unitName][bName] ?? false))
      res[bName] <- true
}

function getUnseenUnitBullets(uName, myUnits, configs, seen) {
  let primaryRes = {}
  let secondaryRes = {}
  let res = { primary = primaryRes, secondary = secondaryRes}
  let unit = myUnits?[uName]
  if (unit == null)
    return res
  let modsCfg = configs?.unitModPresets[configs?.allUnits[uName].modPreset] ?? {}
  let { primary = null, secondary = null, special = null } = loadUnitBulletsChoice(uName)?.commonWeapons
  fillUnseenBullets(primaryRes, primary, uName, unit, modsCfg, seen, BULLETS_PRIM_SLOTS)
  fillUnseenBullets(secondaryRes, secondary ?? special, uName, unit, modsCfg, seen,
    BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS)
  return res
}
let getUnseenUnitBulletsNonUpdatable = @(unitName)
  getUnseenUnitBullets(unitName, campMyUnits.get(), campConfigs.get(), seenShells.get())
let mkUnseenUnitBullets = @(unitName)
  Computed(@() getUnseenUnitBullets(unitName.get(), campMyUnits.get(), campConfigs.get(), seenShells.get()))

function markShellsSeen(unitName, idsExt) {
  let { primary, secondary } = getUnseenUnitBulletsNonUpdatable(unitName)
  let ids = idsExt.filter(@(v) v in primary || v in secondary)
  if (ids.len() == 0)
    return
  seenShells.mutate(function(v) {
    let unitSeen = getSubTable(v, unitName)
    foreach (id in ids)
      unitSeen[id] <- true
  })
  let blk = get_local_custom_settings_blk()
    .addBlock(SEEN_SHELLS)
    .addBlock(unitName)
  foreach (id in ids)
    blk[id] = true
  eventbus_send("saveProfile", {})
}

register_command(function() {
  seenShells.set({})
  get_local_custom_settings_blk().removeBlock(SEEN_SHELLS)
  eventbus_send("saveProfile", {})
}, "debug.reset_seen_shells")


return {
  seenShells
  mkUnseenUnitBullets
  getUnseenUnitBulletsNonUpdatable
  markShellsSeen
  SEEN_SHELLS
}