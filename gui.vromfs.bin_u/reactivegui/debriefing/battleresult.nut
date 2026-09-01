from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/ecs.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "dagor.time" import get_time_msec
from "dagor.workcycle" import deferOnce, resetTimeout
from "dasevents" import sendNetEvent, CmdApplyMyBattleResultOnExit
from "eventbus" import eventbus_send, eventbus_subscribe
from "guiMission" import get_mp_tbl_teams
import "io" as io
from "json" import object_to_json_string
from "matching.api" import matching_notify
from "mission" import get_mp_local_team, get_mplayers_list, GET_MPLAYERS_LIST
from "multiplayer" import get_mp_session_id_int, destroy_session, set_quit_to_debriefing_allowed
from "%sqstd/datablock.nut" import isDataBlock, eachParam
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/botUtils.nut" import genBotCommonStats
from "%appGlobals/clientState/clientState.nut" import isInBattle, battleSessionId
from "%appGlobals/clientState/missionState.nut" import battleCampaign, hudCustomRules
from "%appGlobals/loginState.nut" import isMatchingOnline
from "%appGlobals/pServer/campaign.nut" import lastBattles, subscriptions
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/unitCfgByTagName.nut" import getUnitCfgByTagName
from "%appGlobals/profileStates.nut" import myUserId, myUserName
from "%appGlobals/sqevents.nut" import EventBattleResult, EventResultMPlayers
from "%appGlobals/squadLabelState.nut" import squadLabels
from "%rGui/battleData/battleData.nut" import battleData
from "%rGui/matchingRooms/sessionLobby.nut" import lastRoom
import "mkCommonExtras.nut" as mkCommonExtras
from "singleMissionResult.nut" import singleMissionResult


let logBD = log_with_prefix("[BATTLE_RESULT] ")


const destroySessionTimeout = 2.0
const SAVE_FILE = "battleResult.json"
let exportRoomParams = [ "game_mode_id", "game_mode_name", "mission", "cluster" ]
  .reduce(@(res, v) res.$rawset(v, true), {})

let debugBattleResult = mkWatched(persist, "debugBattleResult", null)
let baseBattleResult = mkWatched(persist, "battleResult", null)
let resultPlayers = mkWatched(persist, "resultPlayers", null)
let playersCommonStats = mkWatched(persist, "playersCommonStats", {})
let connectFailedData = mkWatched(persist, "connectFailedData", null)
let questProgressDiff = mkWatched(persist, "questProgressDiff", null)
let unitWeaponry = mkWatched(persist, "unitWeaponry", null)
let completedTutorials = mkWatched(persist, "completedTutorials", {})
let roomInfoShort = Computed(@() lastRoom.get()?.public.filter(@(_, key) key in exportRoomParams))
let hasVip = Computed(@() subscriptions.get()?.vip.isActive ?? false )
let hasPrem = Computed(@() subscriptions.get()?.premium.isActive ?? false )
let hasPremiumSubs = Computed(@() hasPrem.get() || hasVip.get())

eventbus_subscribe("adsBonusToApply",function(adsBonuses) {
  if(!adsBonuses)
    return

  baseBattleResult.set(baseBattleResult.get().__merge({ adsBonuses = adsBonuses.__merge({ time = get_time_msec() }) }))
})

hasPremiumSubs.subscribe(function(hasSubs) {
  let baseResult = baseBattleResult.get()
  let sessionId = baseResult?.sessionId.tostring()
  let lastBattle = lastBattles.get()?[sessionId]
  if(!hasSubs || baseResult?.hasPrem || !lastBattle)
    return
  let { adsBonuses = {}, reward } = baseResult
  let expDif = lastBattle.playerExp - reward.playerExp.totalExp - (adsBonuses?.expDif ?? 0)
  let wpDif = lastBattle.wp - reward.playerWp.totalWp - (adsBonuses?.wpDif ?? 0)
  let unitsDif = lastBattle.unitsProgress.map(function(unit, uName) {
    let debrUnit = reward.units.findvalue(@(u) u.name == uName)
    return unit.__merge({
      expDif = unit.exp - (debrUnit?.exp.totalExp ?? 0) - (adsBonuses?.unitsDif[uName].uExpDif ?? 0)
      slotExpDif = unit.slotExp - (debrUnit?.slotExp.totalExp ?? 0) - (adsBonuses?.unitsDif[uName].slotExpDif ?? 0)
      goldDif = unit.gold - (debrUnit?.gold.totalGold ?? 0) - (adsBonuses?.unitsDif[uName].uGoldDif ?? 0)
    })})

  baseBattleResult.set(baseResult.__merge({
    subsBonuses = {
      expDif
      wpDif
      unitsDif
      time = get_time_msec()
    }}))
})


let battleResult = Computed(function() {
  if (debugBattleResult.get())
    return debugBattleResult.get()
  local res
  if (battleSessionId.get() == -1)
    return singleMissionResult.get()
  else {
    res = baseBattleResult.get()?.__merge({ roomInfo = roomInfoShort.get() })
    if (res?.sessionId != battleSessionId.get())
      return connectFailedData.get()?.sessionId != battleSessionId.get() ? null
        : connectFailedData.get().__merge({ isDisconnected = true }, { roomInfo = roomInfoShort.get() })
    if (res?.sessionId == resultPlayers.get()?.sessionId)
      res = resultPlayers.get().__merge(res)
    if (playersCommonStats.get().len() != 0)
      res = { playersCommonStats = playersCommonStats.get() }.__merge(res)
    if (questProgressDiff.get() != null)
      res = { quests = questProgressDiff.get() }.__merge(res)
  }
  if (unitWeaponry.get() != null)
    res = { unitWeaponry = unitWeaponry.get() }.__merge(res)
  res.completedTutorials <- completedTutorials.get()
  return res
})

let sendBattleResult = @() eventbus_send("BattleResult", battleResult.get())
battleResult.subscribe(@(_) resetTimeout(0.1, sendBattleResult))
eventbus_subscribe("RequestBattleResult", @(_) sendBattleResult())

function updateCompletedTutorials() {
  let blk = get_local_custom_settings_blk()?.tutorials
  let list = {}
  if (isDataBlock(blk))
    eachParam(blk, function(isCompleted, id) {
      if (isCompleted)
       list[id] <- true
    })
  completedTutorials.set(list)
}

singleMissionResult.subscribe(function(_) {
  updateCompletedTutorials()
})

isInBattle.subscribe(@(v) v ? questProgressDiff.set(null) : null)
eventbus_subscribe("BattleResultQuestProgressDiff", @(v) questProgressDiff.set(v))

local isUnitWeaponryRequested = mkWatched(persist, "isUnitWeaponryRequested", null)
isInBattle.subscribe(function(v) {
  if (!v)
    return
  unitWeaponry.set(null)
  isUnitWeaponryRequested.set(null)
})
battleResult.subscribe(function(v) {
  if (debugBattleResult.get() != null)
    return
  let { unit = null } = v
  if (unit == null)
    return
  let { name = "", platoonUnits = [] } = unit
  let units = [ name ].extend(platoonUnits.map(@(pu) pu.name))
  let params = { units }
  if (isEqual(isUnitWeaponryRequested.get(), params))
    return
  isUnitWeaponryRequested.set(params)
  eventbus_send("RequestBattleResultUnitWeaponry", params)
})
eventbus_subscribe("BattleResultUnitWeaponry", @(v) unitWeaponry.set(v))

let gotQuitToDebriefing = mkWatched(persist, "gotQuitToDebriefing", false)
isInBattle.subscribe(@(v)  v ? gotQuitToDebriefing.set(false) : null)
let needDestroySession = keepref(Computed(@() gotQuitToDebriefing.get()
  && baseBattleResult.get()?.sessionId == get_mp_session_id_int()
  && resultPlayers.get()?.sessionId == get_mp_session_id_int()))

function doDestroySession() {
  gotQuitToDebriefing.set(false)
  set_quit_to_debriefing_allowed(true)
  destroy_session("on needDestroySession by battleResult received")
}
needDestroySession.subscribe(@(v) v ? deferOnce(doDestroySession) : null)

eventbus_subscribe("onSetQuitToDebriefing", function(_) {
  resetTimeout(destroySessionTimeout, doDestroySession)
  gotQuitToDebriefing.set(true)
  set_quit_to_debriefing_allowed(false)
})

isInBattle.subscribe(@(v) v ? debugBattleResult.set(null) : null)

function onBattleResult(evt, _eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.get())
    return

  let resultWithBd = evt.data.__merge(battleData.get() ?? {})
  baseBattleResult.set(mkCommonExtras(resultWithBd, serverConfigs.get())
    .__merge(
      resultWithBd,
      {
        localTeam = get_mp_local_team()
        teams = get_mp_tbl_teams()
        userName = myUserName.get()
        hudCustomRules = hudCustomRules.get()
      }))
  updateCompletedTutorials()
}

register_es("battle_result_es",
  {
    [EventBattleResult] = onBattleResult,
  },
  {
    comps_ro = [["server_player__userId", TYPE_UINT64]]
  })

register_es("battle_result_mplayers_es",
  {
    [EventResultMPlayers] = function(evt, _eid, _comp) {
      let res = evt.data.__merge({ players = clone (evt.data?.players ?? {}) })
      let localPlayers = get_mplayers_list(GET_MPLAYERS_LIST, true)
      foreach(p in localPlayers)
        if (p.userId in res.players){
          res.players[p.userId] = p.__merge(res.players[p.userId])
          res.players[p.userId].squadLabel <- (squadLabels.get()?[p.userId] ?? -1)
        }
      resultPlayers.set(res)
    },
  }, {})

let find_local_player_query = SqQuery("find_local_player_query", { comps_rq = ["localPlayer"] })
let find_local_player_eid = @()
  find_local_player_query(@(eid, _) eid) ?? INVALID_ENTITY_ID

let playersCommonStatsQuery = SqQuery("playersCommonStatsQuery",
  {
    comps_ro = [
      ["commonStats", TYPE_OBJECT],
      ["isBattleDataReceived", TYPE_BOOL],
      ["server_player__userId", TYPE_UINT64],
    ]
  })

function getPlayersCommonStats(players) {
  let res = {}
  playersCommonStatsQuery(function(_, c) {
    if (c.isBattleDataReceived)
      res[c.server_player__userId.tostring()] <- c.commonStats.getAll()
  })
  let defLevel = res.findvalue(@(_) true)?.level ?? 1
  foreach (player in players) {
    if (!player.isBot)
      continue
    let { userId, name, aircraftName = "" } = player
    let unitCfg = getUnitCfgByTagName(aircraftName, serverConfigs.get(), battleCampaign.get()) ?? {}
    res[userId.tostring()] <- genBotCommonStats(name, aircraftName, unitCfg, defLevel)
  }
  return res
}
resultPlayers.subscribe(@(v) playersCommonStats.set(getPlayersCommonStats(v?.players ?? {})))
isInBattle.subscribe(@(v) v ? playersCommonStats.set({}) : null)

function requestEarlyExitRewards() {
  logBD("Request early exit rewards")
  sendNetEvent(find_local_player_eid(), CmdApplyMyBattleResultOnExit())
  if (isMatchingOnline.get())
    matching_notify("match.remove_from_session", null) 
}

eventbus_subscribe("onBattleConnectionFailed", @(p) connectFailedData.set(p.__merge({ sessionId = battleSessionId.get() })))

register_command(requestEarlyExitRewards, "debriefing.request_early_exit_rewards")
register_command(function() {
  if (battleResult.get() == null)
    return console_print("Current battle result is empty") 

  let file = io.file(SAVE_FILE, "wt+")
  file.writestring(object_to_json_string(battleResult.get(), true))
  file.close()
  console_print($"Saved to {SAVE_FILE}") 
}, "debriefing.save_current_battle_result")

return {
  hasPremiumSubs
  battleResult
  debugBattleResult
  requestEarlyExitRewards
}
