from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "warpoints" import *

let { eventbus_subscribe } = require("eventbus")
let { get_mplayer_by_id } = require("mission")
let { HUD_MSG_OBJECTIVE, HUD_MSG_MULTIPLAYER_DMG, HUD_MSG_STREAK_EX } = require("hudMessages")
let { GO_WIN, GO_FAIL, GO_EARLY, GO_WAITING_FOR_RESULT, GO_NONE, MISSION_CAPTURING_ZONE
} = require("guiMission")
let { localMPlayerId, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { startMissionHintSeria, captureHintSeria } = require("%rGui/hudHints/missionNewbiesHints.nut")
let { unitType } = require("%rGui/hudState.nut")
let { TANK, AIR } = require("%appGlobals/unitConst.nut")
let { teamRedColor } = require("%rGui/style/teamColors.nut")
let { EventZoneDamageMessage } = require("dasevents")
let { setTimeout, clearTimer } = require("dagor.workcycle")

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
  scoreAccumulated(0.0)
  scoreShowed(0.0)
  scoreToShow(0.0)
})

const MISSION_HINT = "mission_hint"
const SCORE_HINT = "score_hint"
const EXP_HINT = "exp_hint"

eventbus_subscribe("hint:missionHint:set", @(data) data?.hintType == "bottom" ? null
  : modifyOrAddEvent(
      data.__merge({
        id = MISSION_HINT
        hType = "mission"
        zOrder = Layers.Upper
        ttl = data?.time
        text = loc(data?.locId ?? "", { var = data?.variable_value })
      }),
      @(ev) ev?.id == MISSION_HINT && ev?.locId == data?.locId))

eventbus_subscribe("hint:missionHint:remove", @(data) data?.hintType == "bottom" ? null
  : removeEvent({ id = MISSION_HINT }))

eventbus_subscribe("hint:missionHint:setById", @(data) modifyOrAddEvent(
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

eventbus_subscribe("HudMessage", @(data) addHudMessage?[data.type](data))


eventbus_subscribe("zoneCapturingEvent", function(data) {
  let { zoneName, isHeroAction, isMyTeam, eventId, text } = data
  let id = $"capture_event_{zoneName}"
  if (isHeroAction && unitType.value == TANK)
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
  scoreShowed(scoreShowed.value + scoreToShow.value)
  scoreToShow(0.0)
}

function showScore(score, isAirfield) {
  clearTimer(resetScore)
  scoreAccumulated(scoreAccumulated.value + score)
  scoreToShow((scoreAccumulated.value - scoreShowed.value).tointeger())
  if (scoreToShow.value >= 1.0) {
    modifyOrAddEvent({
      id = SCORE_HINT
      zOrder = Layers.Upper
      hType = "simpleTextWithIcon"
      text = loc(isAirfield ? "exp_reasons/damage_airfield" : "exp_reasons/damage_zone", {score = scoreToShow.value}),
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

eventbus_subscribe("MissionResult", function(data) {
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

eventbus_subscribe("MissionContinue", @(_) removeEvent({ id = MISSSION_RESULT }))

let expEventType = {
  [EXP_EVENT_CRITICAL_HIT]  = "exp_reasons/critical_hit",
  [EXP_EVENT_SEVERE_DAMAGE] = "exp_reasons/severe_damage",
  [EXP_EVENT_ASSIST]        = "exp_reasons/assist",
}

eventbus_subscribe("ExpEvent", function(evt) {
  let msg = expEventType?[evt.messageCode];
  if ((unitType.value == AIR || evt.messageCode == EXP_EVENT_ASSIST) && msg) {
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