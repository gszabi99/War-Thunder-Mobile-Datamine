from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { calcVisibleBullets, mkVisibleBulletsList } = require("%rGui/bullets/calcBullets.nut")
let { BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS } = require("%rGui/bullets/bulletsConst.nut")


const SEEN_SHELLS = "SeenShells"
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

function fillUnseenBullets(res, bInfo, unitName, unit, mods, seen, slotFrom, slotTo) {
  if (bInfo == null)
    return

  let visibleBullets = calcVisibleBullets(bInfo, mods)
  for (local slot = slotFrom; slot < slotTo; slot++) {
    let { bulletsOrder, fromUnitTags } = bInfo
    let visibleBulletsList = mkVisibleBulletsList(bulletsOrder, fromUnitTags, visibleBullets, slot)
      .map(@(name) { name, fromUnitTags = fromUnitTags?[name] })
    foreach (b in visibleBulletsList)
      if (b.name != ""
          && (b.fromUnitTags?.reqLevel ?? 0) != 0
          && (unit?.level ?? 0) >= (b.fromUnitTags?.reqLevel ?? 0)
          && !(seen?[unitName][b.name] ?? false))
        res[b.name] <- true
  }
}

function getUnseenUnitBullets(unitNameRaw, myUnits, seen) {
  let primaryRes = {}
  let secondaryRes = {}
  let res = { primary = primaryRes, secondary = secondaryRes}
  let unit = myUnits?[unitNameRaw]
  if (unit == null)
    return res
  let uName = getTagsUnitName(unitNameRaw)
  let { primary = null, secondary = null, special = null } = loadUnitBulletsChoice(uName)?.commonWeapons
  let mods = (unit?.mods ?? {}).reduce(@(modsRes, val, mod) val ? modsRes.$rawset(mod, 1) : modsRes, {})
  fillUnseenBullets(primaryRes, primary, uName, unit, mods, seen, 0, BULLETS_PRIM_SLOTS)
  fillUnseenBullets(secondaryRes, secondary ?? special, uName, unit, mods, seen,
    BULLETS_PRIM_SLOTS, BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS)
  return res
}
let getUnseenUnitBulletsNonUpdatable = @(unitNameRaw)
  getUnseenUnitBullets(unitNameRaw, campMyUnits.get(), seenShells.get())
let mkUnseenUnitBullets = @(unitNameRaw)
  Computed(@() getUnseenUnitBullets(unitNameRaw.get(), campMyUnits.get(), seenShells.get()))

function markShellsSeen(unitNameRaw, idsExt) {
  let { primary, secondary } = getUnseenUnitBulletsNonUpdatable(unitNameRaw)
  let ids = idsExt.filter(@(v) v in primary || v in secondary)
  if (ids.len() == 0)
    return
  let unitName = getTagsUnitName(unitNameRaw)
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