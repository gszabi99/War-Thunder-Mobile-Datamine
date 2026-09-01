from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "math" import fabs
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/missionState.nut" import mainBattleUnitName
from "%appGlobals/gameIdentifiers.nut" import GAME_ID
from "%appGlobals/loginState.nut" import isMatchingConnected
from "%appGlobals/profileStates.nut" import myUserIdStr
from "%rGui/contacts/contactPresence.nut" import presences
from "%rGui/matching/matchingApi.nut" import matchingRpcCall


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
  if ((presenceDiff.get()?.len() ?? 0) != 0)
    matchingRpcCall("mpresence.set_presence", presenceDiff.get())
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

return {
  setMyPresence
}