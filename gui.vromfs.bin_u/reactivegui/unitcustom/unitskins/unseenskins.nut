from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { register_command } = require("console")
let { blk2SquirrelObjNoArrays, isDataBlock } = require("%sqstd/datablock.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let SEEN_SKINS = "seenSkins"
let seenSkins = mkWatched(persist, "seenSkins", {})

let mySkins = Computed(@() servProfile.get()?.skins ?? {})

let mySkinsToMark = Computed(function() {
  let res = {}
  let allMySkins = mySkins.get()
  if (allMySkins.len() == 0)
    return res
  foreach(name, unit in campMyUnits.get()) {
    let { skins = null } = unit
    let resSkins = allMySkins?[name].filter(@(_, s) s in skins && !skins[s] && s != "upgraded")
    if (resSkins != null && resSkins.len() != 0)
      res[name] <- resSkins
  }
  return res
})

let unseenSkins = Computed(function() {
  let seen = seenSkins.get()
  return mySkinsToMark.get()
    .map(@(list, unitName) list.filter(@(_, skinName) skinName not in seen?[unitName]))
    .filter(@(v) v.len() != 0)
})

function loadSeenSkins() {
  if (!isLoggedIn.get())
    return
  let seenBlk = get_local_custom_settings_blk()?[SEEN_SKINS]
  seenSkins(isDataBlock(seenBlk) ? blk2SquirrelObjNoArrays(seenBlk) : {})
}

isLoggedIn.subscribe(@(_) loadSeenSkins())
if (seenSkins.get().len() == 0)
  loadSeenSkins()

function markSkinsSeen(unitName, skinsList) {
  let unitUnseen = unseenSkins.get()?[unitName]
  let skins = skinsList.filter(@(s) s in unitUnseen)
  if (skins.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_SKINS).addBlock(unitName)
  foreach(s in skins)
    blk[s] = true
  eventbus_send("saveProfile", {})

  seenSkins.mutate(function(v) {
    v[unitName] <- (v?[unitName] ?? {}).__merge(skins.reduce(@(res, s) res.$rawset(s, true), {}))
  })
}

let markAllUnitSkinsSeen = @(unitName) unitName not in unseenSkins.get() ? null
  : markSkinsSeen(unitName, unseenSkins.get()[unitName].keys())

let markSkinSeen = @(unitName, skin) markSkinsSeen(unitName, [skin])

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SEEN_SKINS)
  eventbus_send("saveProfile", {})
  loadSeenSkins()
}, "debug.reset_seen_skins")

return {
  unseenSkins
  markAllUnitSkinsSeen
  markSkinSeen
}