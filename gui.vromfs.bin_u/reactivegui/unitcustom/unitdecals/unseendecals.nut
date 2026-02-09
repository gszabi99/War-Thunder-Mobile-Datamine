from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isLoggedIn, isSettingsAvailable } = require("%appGlobals/loginState.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")
let { availableDecals, userDecals } = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")


let SEEN_DECALS = "seenDecals"
let maxDayShowingUnseenMark = 14
let seenDecals = Watched({})

let unseenDecals = Computed(function() {
  let res = {}
  if (!isLoggedIn.get())
    return res

  foreach(decalId, _ in availableDecals.get())
    if (serverTimeDay.get() - getDay((userDecals.get()?[decalId] ?? 0), dayOffset.get()) < maxDayShowingUnseenMark &&
        (decalId not in seenDecals.get()))
      res[decalId] <- true

  return res
})

function clearExpiredSeenDecals(blk) {
  if (!blk)
    return

  for (local idx = blk.paramCount() - 1; idx >= 0; idx--)
    if (serverTimeDay.get() - getDay((userDecals.get()?[blk.getParamName(idx)] ?? 0), dayOffset.get()) > maxDayShowingUnseenMark)
      blk.removeParam(blk.getParamName(idx))
}

function loadSeenDecals() {
  if (!isSettingsAvailable.get())
    return seenDecals.set({})
  let seenBlk = get_local_custom_settings_blk()?[SEEN_DECALS]
  let seen = {}
  if (isDataBlock(seenBlk))
    eachParam(seenBlk, @(isSeen, id) seen[id] <- isSeen)
  seenDecals.set(seen)
}

isSettingsAvailable.subscribe(@(_) loadSeenDecals())
loadSeenDecals()

function markDecalSeen(decalId) {
  if (decalId not in unseenDecals.get())
    return

  if (serverTimeDay.get() - getDay((userDecals.get()?[decalId] ?? 0), dayOffset.get()) < maxDayShowingUnseenMark) {
    let sBlk = get_local_custom_settings_blk()
    let blk = sBlk.addBlock(SEEN_DECALS)
    blk[decalId] = true
    eventbus_send("saveProfile", {})

    seenDecals.mutate(@(v) v[decalId] <- true)
  }
}

function markDecalsSeen(decalsList) {
  let filteredList = decalsList.filter(@(decalId) decalId in unseenDecals.get())
  if (filteredList.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_DECALS)

  foreach(decalId in filteredList)
    blk[decalId] = true

  seenDecals.set(seenDecals.get().__merge(decalsList.reduce(@(res, v) res.$rawset(v, true), {})))

  clearExpiredSeenDecals(blk)
  eventbus_send("saveProfile", {})
}

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SEEN_DECALS)
  eventbus_send("saveProfile", {})
  loadSeenDecals()
}, "debug.reset_seen_decals")

return {
  unseenDecals
  markDecalSeen
  markDecalsSeen
}
