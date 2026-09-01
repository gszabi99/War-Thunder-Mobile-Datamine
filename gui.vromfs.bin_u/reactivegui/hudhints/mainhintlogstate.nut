from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "warpoints" import *
from "dagor.workcycle" import setTimeout, clearTimer
from "dasevents" import EventZoneDamageMessage
from "guiMission" import GO_WIN, GO_FAIL, GO_EARLY, GO_WAITING_FOR_RESULT, GO_NONE, MISSION_CAPTURING_ZONE
from "hudMessages" import HUD_MSG_OBJECTIVE, HUD_MSG_MULTIPLAYER_DMG, HUD_MSG_STREAK_EX
from "mission" import get_mplayer_by_id
from "%appGlobals/clientState/clientState.nut" import localMPlayerId, isInBattle
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%appGlobals/unitConst.nut" import TANK, AIR
from "%appGlobals/unitPresentation.nut" import getUnitClassFontIcon
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hudHints/missionNewbiesHints.nut" import startMissionHintSeria, captureHintSeria
from "%rGui/hudState.nut" import unitType
from "%rGui/style/teamColors.nut" import teamRedColor


const TIME_TO_RESET_SCORE = 1.0

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "mainHintLogState"
  maxActiveEvents = 3
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})
let { addEvent, modifyOrAddEvent, removeEvent, clearEvents } = state

local scoreAccumulated = mkWatched(persist, "scoreAccumulated", 0.0)
local scoreShowed = mkWatched(persist, "scoreShowed", 0.0)
local scoreToShow = mkWatched(persist, "scoreToShow", 0.0)

isInBattle.subscribe(function(_) {
  clearEvents()
  scoreAccumulated.set(0.0)
  scoreShowed.set(0.0)
  scoreToShow.set(0.0)
})

const MISSION_HINT = "mission_hint"
const SCORE_HINT = "score_hint"
const EXP_HINT = "exp_hint"

subscribeHudEvent("hint:missionHint:set", @(data) data?.hintType == "bottom" ? null
  : modifyOrAddEvent(
      data.__merge({
        id = MISSION_HINT
        hType = "mission"
        zOrder = Layers.Upper
        ttl = data?.time
        text = loc(data?.locId ?? "", { var = data?.variable_value })
      }),
      @(ev) ev?.id == MISSION_HINT && ev?.locId == data?.locId))

subscribeHudEvent("hint:missionHint:remove", @(data) data?.hintType == "bottom" ? null
  : removeEvent({ id = MISSION_HINT }))

subscribeHudEvent("hint:missionHint:setById", @(data) modifyOrAddEvent(
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
      if (unitType.get() == TANK) {
        startMissionHintSeria()
      }
      addEvent(data.__merge({ id, ttl = 8 }))
    }
    else
      removeEvent({ id })
  },

  [HUD_MSG_MULTIPLAYER_DMG] = function(data) {
    let { isKill = false, playerId = null, victimPlayerId = null, victimUnitName = "" } = data
    if (!isKill || localMPlayerId.get() != playerId)
      return

    let classIcon = getUnitClassFontIcon(campUnitsCfg.get()?[victimUnitName])
    let victim = get_mplayer_by_id(victimPlayerId)
    addEvent(data.__merge({
      id = $"kill_{victimPlayerId}"
      hType = "expHint"
      ttl = 5
      text = loc("multiplayer/playerUnitDestroyed",
        { name = " ".join([ colorize(teamRedColor, victim?.name ?? data?.victimUnitNameLoc), classIcon ], true) })
    }))
  },

  [HUD_MSG_STREAK_EX] = function(data) {
    let { unlockId = "" } = data
    addEvent(data.__merge({
      id = $"streak_{unlockId}"
      hType = "streak"
      ttl = 5
    }))
  }
}

subscribeHudEvent("HudMessage", @(data) addHudMessage?[data.type](data))


subscribeHudEvent("zoneCapturingEvent", function(data) {
  let { zoneName, isHeroAction, isMyTeam, eventId, text } = data
  let id = $"capture_event_{zoneName}"
  if (isHeroAction && unitType.get() == TANK)
    captureHintSeria()
  modifyOrAddEvent(
    {
      key = "mission_hint"
      id
      hType = isMyTeam ? "mission" : "fail"
      ttl = isHeroAction && eventId == MISSION_CAPTURING_ZONE ? 1.5 : 3.0 
      text
      eventId
    },
    @(ev) ev?.id == id && ev?.text == text)
})

function resetScore() {
  scoreShowed.set(scoreShowed.get() + scoreToShow.get())
  scoreToShow.set(0.0)
}

function showScore(score, isAirfield) {
  clearTimer(resetScore)
  scoreAccumulated.set(scoreAccumulated.get() + score)
  scoreToShow.set((scoreAccumulated.get() - scoreShowed.get()).tointeger())
  if (scoreToShow.get() >= 1.0) {
    modifyOrAddEvent({
      id = SCORE_HINT
      zOrder = Layers.Upper
      hType = "simpleTextWithIcon"
      text = loc(isAirfield ? "exp_reasons/damage_airfield" : "exp_reasons/damage_zone", {score = scoreToShow.get()}),
      icon = $"ui/gameuiskin#score_icon.svg"
      ttl = 3
    }, @(ev) ev?.id == SCORE_HINT)
    setTimeout(TIME_TO_RESET_SCORE, resetScore)
  }
}

register_es("on_zone_damage_message",
  { [EventZoneDamageMessage] = @(evt, _eid, _comp) showScore(evt.score, evt.isAirfield) },
  { comps_rq = [["server_player__userId", TYPE_UINT64]] })


const MISSSION_RESULT = "mission_result"
let resultLocId = {
  [GO_WIN] = "MISSION_SUCCESS",
  [GO_FAIL] = "MISSION_FAIL",
  [GO_EARLY] = "MISSION_IN_PROGRESS",
  [GO_WAITING_FOR_RESULT] = "FINALIZING",
}

subscribeHudEvent("MissionResult", function(data) {
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

subscribeHudEvent("MissionContinue", @(_) removeEvent({ id = MISSSION_RESULT }))

let expEventType = {
  [EXP_EVENT_CRITICAL_HIT]  = "exp_reasons/critical_hit",
  [EXP_EVENT_SEVERE_DAMAGE] = "exp_reasons/severe_damage",
  [EXP_EVENT_ASSIST]        = "exp_reasons/assist",
}

subscribeHudEvent("ExpEvent", function(evt) {
  let msg = expEventType?[evt.messageCode];
  if ((unitType.get() == AIR || evt.messageCode == EXP_EVENT_ASSIST) && msg) {
    modifyOrAddEvent({
      id = EXP_HINT
      zOrder = Layers.Upper
      hType = "expHint"
      text = " ".concat(loc(msg), colorize(teamRedColor, evt.victim))
      ttl = 3
    }, @(ev) ev?.id == EXP_HINT)
  }
})

return state