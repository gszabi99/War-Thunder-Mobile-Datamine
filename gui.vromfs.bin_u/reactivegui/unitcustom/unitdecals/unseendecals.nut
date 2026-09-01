from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
from "%sqstd/datablock.nut" import isDataBlock, eachParam
from "%appGlobals/loginState.nut" import isLoggedIn, isSettingsAvailable
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset
from "%rGui/unitCustom/unitDecals/unitDecalsState.nut" import availableDecals, userDecals


const SEEN_DECALS = "seenDecals"
const maxDayShowingUnseenMark = 14
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
