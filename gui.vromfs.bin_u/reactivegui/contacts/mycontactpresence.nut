from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { fabs } = require("math")
let { isEqual } = require("%sqstd/underscore.nut")
let { GAME_ID } = require("%appGlobals/gameIdentifiers.nut")
let { myUserIdStr } = require("%appGlobals/profileStates.nut")
let { presences } = require("%rGui/contacts/contactPresence.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isMatchingConnected } = require("%appGlobals/loginState.nut")
let { mainBattleUnitName } = require("%appGlobals/clientState/missionState.nut")


let presenceDefault = {
  battleUnit = null
  gameId = GAME_ID
}

let serverPresence = Computed(@() presences.get()?[myUserIdStr.get()])
let localPresence = hardPersistWatched("myLocalPresence", presenceDefault)

function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}
let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

let presenceDiff = keepref(Computed(function(prev) {
  if (serverPresence.get() == null || !isMatchingConnected.get())
    return null
  let res = localPresence.get().filter(@(v, id) !isEqualWithFloat(serverPresence.get()?[id], v))
  return isEqualWithFloat(prev, res) ? prev : res
}))

function sendPresenceDiff() {
  if ((presenceDiff.get()?.len() ?? 0) == 0)
    return
  eventbus_send("matchingCall",
    {
      action = "mpresence.set_presence"
      params = presenceDiff.get()
    })
}
deferOnce(sendPresenceDiff)
presenceDiff.subscribe(@(_) deferOnce(sendPresenceDiff))

function setMyPresence(diff) {
  let badIndex = diff.findindex(@(_, id) id not in presenceDefault)
  if (badIndex != null)
    logerr($"Try to change presence field {badIndex}")
  else
    localPresence.set(localPresence.get().__merge(diff))
}

let setBattleUnit = @(battleUnit) setMyPresence({ battleUnit })
setBattleUnit(mainBattleUnitName.get())
mainBattleUnitName.subscribe(setBattleUnit)

eventbus_subscribe("setMyPresence", setMyPresence)

return {
  setMyPresence
}