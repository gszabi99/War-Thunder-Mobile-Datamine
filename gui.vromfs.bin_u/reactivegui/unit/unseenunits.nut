from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eachParam, isDataBlock, blk2SquirrelObjNoArrays } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { campUnitsCfg, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { register_command } = require("console")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let SEEN_UNIT = "seenUnit"
let SEEN_UNIT_VERSION_KEY = "seenUnitVersion"
let ACTUAL_VERSION = 3
let seenUnits = mkWatched(persist, "seenUnits", {})
let justReceivedUnseen = mkWatched(persist, "justReceivedUnseen", {})
let maxTimeShowingUnseenMark = TIME_DAY_IN_SECONDS * 14

function applyCompatibility() {
  let sBlk = get_local_custom_settings_blk()
  if ((sBlk?[SEEN_UNIT_VERSION_KEY] ?? 0) == ACTUAL_VERSION)
    return

  sBlk[SEEN_UNIT_VERSION_KEY] = ACTUAL_VERSION
  let toRemove = {}
  let toAdd = {}
  let blk = sBlk.addBlock(SEEN_UNIT)
  eachParam(blk, function(v, name) {
    if (getTagsUnitName(name) != name) {
      toRemove[name] <- true
      if (v)
        toAdd[getTagsUnitName(name)] <- true
    }
  })
  foreach (u, _ in toRemove)
    blk.removeParam(u)
  foreach (u, _ in toAdd)
    blk[u] <- true
}

function loadUnseenUnits() {
  if (!isLoggedIn.get())
    return
  applyCompatibility()
  let seenBlk = get_local_custom_settings_blk()?[SEEN_UNIT]
  seenUnits.set(isDataBlock(seenBlk) ? blk2SquirrelObjNoArrays(seenBlk) : {})
}

isLoggedIn.subscribe(@(_) loadUnseenUnits())
loadUnseenUnits()

let availableUnitsList = Computed(function() {
  let my = campMyUnits.get()
  return campUnitsCfg.get()
    .filter(@(u) !u?.isHidden || u.name in my)
})


let unseenUnits = Computed(function() {
  let res = clone justReceivedUnseen.get()
  let time = getServerTime() 
  foreach(unit in availableUnitsList.get()) {
    if (time - unit.releaseDate <= maxTimeShowingUnseenMark
        && getTagsUnitName(unit.name) not in seenUnits.get())
      res[unit.name] <- true
  }
  return res
})

function markUnitsUnseen(list) {
  let res = {}
  foreach(unit in list)
    if (unit not in unseenUnits.get())
      res[unit] <- true
  if (res.len() > 0)
    justReceivedUnseen.modify(@(v) v.__merge(res))
}

function markUnitSeen(unitName) {
  if (unitName in justReceivedUnseen.get()) {
    justReceivedUnseen.mutate(@(v) v.$rawdelete(unitName))
    return
  }

  if (unitName not in unseenUnits.get())
    return
  let tagName = getTagsUnitName(unitName)
  seenUnits.mutate(@(v) v.$rawset(tagName, true))
  get_local_custom_settings_blk().addBlock(SEEN_UNIT)[tagName] = true
  eventbus_send("saveProfile", {})
}

function markUnitsSeen(unitsList) {
  let justReceived = justReceivedUnseen.get()
  let newJustReceived = unitsList.filter(@(_, u) u in justReceived)
  if (newJustReceived.len() > 0)
    justReceivedUnseen.mutate(@(v) newJustReceived.each(@(_, u) v.$rawdelete(u)))

  let unseen = unseenUnits.get()
  let list = unitsList.filter(@(_, u) u in unseen)
  if (list.len() == 0)
    return

  seenUnits.mutate(@(v) list.each(@(_, u) v.$rawset(getTagsUnitName(u), true)))
  let blk = get_local_custom_settings_blk().addBlock(SEEN_UNIT)
  foreach (u, _ in list)
    blk[getTagsUnitName(u)] = true
  eventbus_send("saveProfile", {})
}

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SEEN_UNIT)
  eventbus_send("saveProfile", {})
  loadUnseenUnits()
}, "debug.reset_seen_units")

return {
  unseenUnits
  markUnitSeen
  markUnitsSeen
  markUnitsUnseen
}