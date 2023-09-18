from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { HUD_MSG_OBJECTIVE, HUD_MSG_MULTIPLAYER_DMG } = require("hudMessages")
let { GO_WIN, GO_FAIL, GO_EARLY, GO_WAITING_FOR_RESULT, GO_NONE, MISSION_CAPTURING_ZONE
} = require("guiMission")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { localMPlayerId, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { rqPlayerAndDo } = require("rqPlayersAndDo.nut")
let { startMissionHintSeria, captureHintSeria } = require("missionNewbiesHints.nut")
let { unitType } = require("%rGui/hudState.nut")
let { TANK } = require("%appGlobals/unitConst.nut")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "mainHintLogState"
  maxActiveEvents = 3
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})
let { addEvent, modifyOrAddEvent, removeEvent, clearEvents } = state

isInBattle.subscribe(@(_) clearEvents())

const MISSION_HINT = "mission_hint"

subscribe("hint:missionHint:set", @(data) data?.hintType == "bottom" ? null
  : modifyOrAddEvent(
      data.__merge({
        id = MISSION_HINT
        hType = "mission"
        zOrder = Layers.Upper
        ttl = data?.time
        text = loc(data?.locId ?? "", { var = data?.variable_value })
      }),
      @(ev) ev?.id == MISSION_HINT && ev?.locId == data?.locId))

subscribe("hint:missionHint:remove", @(data) data?.hintType == "bottom" ? null
  : removeEvent({ id = MISSION_HINT }))

subscribe("hint:missionHint:setById", @(data) modifyOrAddEvent(
  data.__merge({
    id = MISSION_HINT
    hType = "mission"
    zOrder = Layers.Upper
    ttl = data?.time
    text = loc(data?.hintId ?? "hints/unknown")
  }),
  @(ev) ev?.id == MISSION_HINT && ev?.hintId == data?.hintId))

let addHudMessage = {
  [HUD_MSG_OBJECTIVE] = function(data) {
    let id = $"objective_{data.id}"
    if (data?.show ?? true) {
      data.__update({key = "mission_objective"})
      if (unitType.value == TANK) {
        startMissionHintSeria()
      }
      addEvent(data.__merge({ id, ttl = 8 }))
    }
    else
      removeEvent({ id })
  },

  [HUD_MSG_MULTIPLAYER_DMG] = function(data) {
    let { isKill = false, playerId = null, victimPlayerId = null, victimUnitName = "" } = data
    if (!isKill || localMPlayerId.value != playerId)
      return

    let classIcon = getUnitClassFontIcon(allUnitsCfg.value?[victimUnitName])
    rqPlayerAndDo(victimPlayerId, @(victim) addEvent(data.__merge({
      id = $"kill_{victimPlayerId}"
      hType = "fail"
      ttl = 5
      text = loc("multiplayer/playerUnitDestroyed",
        { name = $"{getPlayerName(victim?.name ?? data?.victimUnitNameLoc, myUserRealName.value, myUserName.value)} {classIcon}" })
    })))
  },
}

subscribe("HudMessage", @(data) addHudMessage?[data.type](data))


subscribe("zoneCapturingEvent", function(data) {
  let { zoneName, isHeroAction, isMyTeam, eventId, text } = data
  let id = $"capture_event_{zoneName}"
  if (isHeroAction && unitType.value == TANK)
    captureHintSeria()
  modifyOrAddEvent(
    {
      key = "mission_hint"
      id
      hType = isMyTeam ? "mission" : "fail"
      ttl = isHeroAction && eventId == MISSION_CAPTURING_ZONE ? 1.5 : 3.0 //capturing event repeat each sec
      text
      eventId
    },
    @(ev) ev?.id == id && ev?.text == text)
})

const MISSSION_RESULT = "mission_result"
let resultLocId = {
  [GO_WIN] = "MISSION_SUCCESS",
  [GO_FAIL] = "MISSION_FAIL",
  [GO_EARLY] = "MISSION_IN_PROGRESS",
  [GO_WAITING_FOR_RESULT] = "FINALIZING",
}

subscribe("MissionResult", function(data) {
  clearEvents()
  let { resultNum = GO_NONE } = data
  if (resultNum == GO_WIN || resultNum == GO_FAIL)
    return

  addEvent({
    id = MISSSION_RESULT
    hType = resultNum == GO_WIN ? "win"
      : resultNum == GO_FAIL ? "fail"
      : ""
    text = loc(resultLocId?[resultNum] ?? "")
  })
})

subscribe("MissionContinue", @(_) removeEvent({ id = MISSSION_RESULT }))

return state