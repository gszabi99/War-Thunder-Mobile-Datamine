from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { register_command } = require("console")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")

let SEEN_UNIT = "seenUnit"
let unseenUnits = Watched({})
let maxTimeShowingUnseenMark = TIME_DAY_IN_SECONDS * 14

let availableUnitsList = Computed(@() allUnitsCfg.value
  .filter(@(u) !u?.isHidden))

let function loadUnseenUnits() {
  let res = {}
  let seenBlk = get_local_custom_settings_blk()?[SEEN_UNIT]
  foreach(unit in availableUnitsList.value){
    if(serverTime.value - unit.releaseDate <= maxTimeShowingUnseenMark &&
        (unit.name not in seenBlk))
      res[unit.name] <- true
  }
  unseenUnits(res)
}

availableUnitsList.subscribe(@(_) loadUnseenUnits())
isOnlineSettingsAvailable.subscribe(@(_) loadUnseenUnits())
loadUnseenUnits()

let function markUnitSeen(unit){
  if (unit.name not in unseenUnits.value)
    return

  if(serverTime.value - unit.releaseDate <= maxTimeShowingUnseenMark){
    let sBlk = get_local_custom_settings_blk()
    let blk = sBlk.addBlock(SEEN_UNIT)
    blk[unit.name] = true
    send("saveProfile", {})
  }
  loadUnseenUnits()
}

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SEEN_UNIT)
  send("saveProfile", {})
  loadUnseenUnits()
}, "debug.reset_seen_units")

return {
  unseenUnits
  markUnitSeen
}