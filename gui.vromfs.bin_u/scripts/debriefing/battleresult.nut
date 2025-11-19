from "%scripts/dagui_library.nut" import *
from "%globalScripts/ecs.nut" import *
let logBD = log_with_prefix("[BATTLE_RESULT] ")
let { object_to_json_string } = require("json")
let io = require("io")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { sendNetEvent, CmdApplyMyBattleResultOnExit } = require("dasevents")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isEqual } = require("%sqstd/underscore.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { EventBattleResult, EventResultMPlayers } = require("%appGlobals/sqevents.nut")
let { register_command } = require("console")
let { myUserId, myUserName } = require("%appGlobals/profileStates.nut")
let { battleData } = require("%scripts/battleData/battleData.nut")
let { singleMissionResult } = require("singleMissionResult.nut")
let { lastBattles, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle, battleSessionId, isOnline } = require("%appGlobals/clientState/clientState.nut")
let { get_mp_session_id_int, destroy_session, set_quit_to_debriefing_allowed } = require("multiplayer")
let { getPlatoonUnitCfgNonUpdatable } = require("%appGlobals/pServer/allMainUnitsByPlatoon.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { compatibilityConvertCommonStats } = require("%appGlobals/commonStatsUtils.nut")
let { get_mp_local_team, get_mplayers_list, GET_MPLAYERS_LIST } = require("mission")
let { get_mp_tbl_teams } = require("guiMission")
let mkCommonExtras = require("mkCommonExtras.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { lastRoom } = require("%scripts/matchingRooms/sessionLobby.nut")
let { squadLabels } = require("%appGlobals/squadLabelState.nut")


const destroySessionTimeout = 2.0
const SAVE_FILE = "battleResult.json"
let exportRoomParams = [ "game_mode_id", "game_mode_name", "mission" ].reduce(@(res, v) res.$rawset(v, true), {})

let debugBattleResult = mkWatched(persist, "debugBattleResult", null)
let baseBattleResult = mkWatched(persist, "battleResult", null)
let resultPlayers = mkWatched(persist, "resultPlayers", null)
let playersCommonStats = mkWatched(persist, "playersCommonStats", {})
let connectFailedData = mkWatched(persist, "connectFailedData", null)
let questProgressDiff = mkWatched(persist, "questProgressDiff", null)
let unitWeaponry = mkWatched(persist, "unitWeaponry", null)
let completedTutorials = mkWatched(persist, "completedTutorials", {})
let roomInfo = Computed(@() lastRoom.get()?.public.filter(@(_, key) key in exportRoomParams))
let hasVip = Computed(@() subscriptions.get()?.vip.isActive ?? false )
let hasPrem = Computed(@() subscriptions.get()?.premium.isActive ?? false )
let hasPremiumSubs = Computed(@() hasPrem.get() || hasVip.get())

function realNameToName(unit) {
  let res = clone unit
  res.name = unit.realName
  res.$rawdelete("realName")
  return res
}

let battleResult = Computed(function() {
  if (debugBattleResult.get())
    return debugBattleResult.get()
  local res
  if (battleSessionId.get() == -1)
    return singleMissionResult.get()
  else {
    res = baseBattleResult.get()?.__merge({ roomInfo = roomInfo.get() })
    if (res?.sessionId
        && lastBattles.get()?[$"{res.sessionId}"]
        && !res?.hasPrem
        && hasPremiumSubs.get()) {
      let lastBattle = lastBattles.get()[$"{res.sessionId}"]
      let premiumBonus = clone res?.premiumBonusNotApplied
      res.premiumBonus <- premiumBonus
      res.hasPrem <- true
      res.$rawdelete("premiumBonusNotApplied")
      res.reward.playerWp.premWp = lastBattle.wp - res.reward.playerWp.totalWp
      res.reward.playerWp.totalWp = lastBattle.wp
      res.reward.playerExp.premExp = lastBattle.playerExp - res.reward.playerExp.totalExp
      res.reward.playerExp.totalExp = lastBattle.playerExp
      res.reward.units = res.reward.units.map(function(u) {
        let totalExpWithPrem = u.exp.totalExp * (res.premiumBonus?.expMul ?? 1.0)
        let totalGoldWithPrem = u.gold.totalGold * (res.premiumBonus?.goldMul ?? 1.0)
        u.exp.premExp <- totalExpWithPrem - u.exp.totalExp
        u.gold.premGold <- totalGoldWithPrem - u.gold.totalGold
        u.exp.totalExp <- totalExpWithPrem
        u.gold.totalGold <- totalGoldWithPrem
        return u
      })
    }
    if ("realName" in res?.unit) 
      res.unit = realNameToName(res.unit)
    if (type(res?.unit.platoonUnits) == "array")
      res.unit = res.unit.__merge({ platoonUnits = res.unit.platoonUnits.map(@(u) (u?.realName ?? u.name) == u.name ? u : realNameToName(u))})
    if (res?.sessionId != battleSessionId.get())
      return connectFailedData.get()?.sessionId != battleSessionId.get() ? null
        : connectFailedData.get().__merge({ isDisconnected = true }, { roomInfo = roomInfo.get() })
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
  let { unit = null, isSeparateSlots = false } = v
  if (unit == null)
    return
  let { realName = null, name = "", platoonUnits = [] } = unit
  let units = isSeparateSlots
    ? [ realName ?? name ].extend(platoonUnits.map(@(pu) pu.name))
    : [ realName ?? name ]
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
      res[c.server_player__userId.tostring()] <- compatibilityConvertCommonStats(c.commonStats.getAll())
  })
  let defLevel = res.findvalue(@(_) true)?.level ?? 1
  foreach (player in players) {
    if (!player.isBot)
      continue
    let { userId, name, aircraftName = "" } = player
    let unitCfg = getPlatoonUnitCfgNonUpdatable(aircraftName) ?? {}
    res[userId.tostring()] <- genBotCommonStats(name, aircraftName, unitCfg, defLevel)
  }
  return res
}
resultPlayers.subscribe(@(v) playersCommonStats.set(getPlayersCommonStats(v?.players ?? {})))
isInBattle.subscribe(@(v) v ? playersCommonStats.set({}) : null)

function requestEarlyExitRewards() {
  logBD("Request early exit rewards")
  sendNetEvent(find_local_player_eid(), CmdApplyMyBattleResultOnExit())
  if (isOnline.get())
    eventbus_send("matchingApiNotify", { name = "match.remove_from_session" }) 
}

eventbus_subscribe("onBattleConnectionFailed", @(p) connectFailedData.set(p.__merge({ sessionId = battleSessionId.get() })))

register_command(requestEarlyExitRewards, "debriefing.request_early_exit_rewards")
register_command(function() {
  if (battleResult.get() == null)
    return console_print("Current battle result is empty")

  let file = io.file(SAVE_FILE, "wt+")
  file.writestring(object_to_json_string(battleResult.get(), true))
  file.close()
  return console_print($"Saved to {SAVE_FILE}")
}, "debriefing.save_current_battle_result")

return {
  battleResult
  debugBattleResult
  requestEarlyExitRewards
}
