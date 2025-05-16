from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { register_command } = require("console")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let SEEN_UNIT = "seenUnit"
let unseenUnits = Watched({})
let maxTimeShowingUnseenMark = TIME_DAY_IN_SECONDS * 14

let availableUnitsList = Computed(@() campUnitsCfg.get()
  .filter(@(u) !u?.isHidden))

function loadUnseenUnits() {
  if (!isLoggedIn.get())
    return
  let res = {}
  let seenBlk = get_local_custom_settings_blk()?[SEEN_UNIT]
  foreach(unit in availableUnitsList.get()) {
    if (serverTime.get() - unit.releaseDate <= maxTimeShowingUnseenMark &&
        (unit.name not in seenBlk))
      res[unit.name] <- true
  }
  unseenUnits(res)
}

availableUnitsList.subscribe(@(_) loadUnseenUnits())
isLoggedIn.subscribe(@(_) loadUnseenUnits())
loadUnseenUnits()

function markUnitsUnseen(list) {
  let res = {}
  foreach(unit in list)
    res[unit] <- true
  unseenUnits.set(
      unseenUnits.get().__merge(res)
    )
}

function markUnitSeen(unit) {
  if (unit.name not in unseenUnits.get())
    return

  if (serverTime.get() - unit.releaseDate <= maxTimeShowingUnseenMark) {
    let sBlk = get_local_custom_settings_blk()
    let blk = sBlk.addBlock(SEEN_UNIT)
    blk[unit.name] = true
    eventbus_send("saveProfile", {})
  }
  loadUnseenUnits()
}

function markUnitsSeen(unitsList) {
  if (!unitsList || unitsList.len() == 0)
    return

  let sBlk = get_local_custom_settings_blk()
  let blk = sBlk.addBlock(SEEN_UNIT)

  foreach(unitName, _ in unitsList)
    blk[unitName] = true

  eventbus_send("saveProfile", {})
  loadUnseenUnits()
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