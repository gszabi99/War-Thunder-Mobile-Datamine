//checked for explicitness
#no-root-fallback
#explicit-this


from "%scripts/dagui_library.nut" import *
from "%globalScripts/ecs.nut" import *
let logBD = log_with_prefix("[BATTLE_RESULT] ")
let json = require("json")
let io = require("io")
let { send, subscribe } = require("eventbus")
let { deferOnce, resetTimeout } = require("dagor.workcycle")
let { sendNetEvent, CmdApplyMyBattleResultOnExit } = require("dasevents")
let { EventBattleResult, EventResultMPlayers } = require("%appGlobals/sqevents.nut")
let { register_command } = require("console")
let { myUserId, myUserName } = require("%appGlobals/profileStates.nut")
let { battleData } = require("%scripts/battleData/battleData.nut")
let { singleMissionResult } = require("singleMissionResult.nut")
let { isInBattle, battleSessionId } = require("%appGlobals/clientState/clientState.nut")
let { get_mp_session_id_int, destroy_session } = require("multiplayer")
let { allUnitsCfgFlat } = require("%appGlobals/pServer/profile.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { get_local_mplayer } = require("mission")

const destroySessionTimeout = 2.0
const SAVE_FILE = "battleResult.json"
let debugBattleResult = mkWatched(persist, "debugBattleResult", null)
let baseBattleResult = mkWatched(persist, "battleResult", null)
let resultPlayers = mkWatched(persist, "resultPlayers", null)
let playersCommonStats = mkWatched(persist, "playersCommonStats", {})
let connectFailedData = mkWatched(persist, "connectFailedData", null)
let battleResult = Computed(function() {
  if (debugBattleResult.value)
    return debugBattleResult.value
  if (battleSessionId.value == -1)
    return singleMissionResult.value
  local res = baseBattleResult.value
  if (res == null)
    return connectFailedData.value?.sessionId != battleSessionId.value ? null
      : connectFailedData.value.__merge({ isDisconnected = true })
  if (res?.sessionId == resultPlayers.value?.sessionId)
    res = resultPlayers.value.__merge(res)
  if (playersCommonStats.value.len() != 0)
    res = { playersCommonStats = playersCommonStats.value }.__merge(res)
  return res
})

let sendBattleResult = @() send("BattleResult", battleResult.value)
battleResult.subscribe(@(_) resetTimeout(0.1, sendBattleResult))
subscribe("RequestBattleResult", @(_) sendBattleResult())

singleMissionResult.subscribe(@(_) debugBattleResult(null))

let gotQuitToDebriefing = mkWatched(persist, "gotQuitToDebriefing", false)
isInBattle.subscribe(@(v)  v ? gotQuitToDebriefing(false) : null)
let needDestroySession = keepref(Computed(@() gotQuitToDebriefing.value
  && baseBattleResult.value?.sessionId == get_mp_session_id_int()
  && resultPlayers.value?.sessionId == get_mp_session_id_int()))

let function doDestroySession() {
  gotQuitToDebriefing(false)
  destroy_session("on needDestroySession by battleResult received")
}
needDestroySession.subscribe(@(v) v ? deferOnce(doDestroySession) : null)

subscribe("onQuitToDebriefing", function(_) {
  resetTimeout(destroySessionTimeout, doDestroySession)
  gotQuitToDebriefing(true)
})

let function onBattleResult(evt, _eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value)
    return
  baseBattleResult(evt.data.__merge(
    battleData.value ?? {}
    {
      localTeam = get_local_mplayer()?.team
      teams = ::get_mp_tbl_teams()
      userName = myUserName.value
    }))
  debugBattleResult(null)
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
    [EventResultMPlayers] = @(evt, _eid, _comp) resultPlayers(evt.data),
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

let function getPlayersCommonStats(players) {
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
    let unitCfg = allUnitsCfgFlat.value?[aircraftName] ?? {}
    res[userId.tostring()] <- genBotCommonStats(name, aircraftName, unitCfg, defLevel)
  }
  return res
}
resultPlayers.subscribe(@(v) playersCommonStats(getPlayersCommonStats(v?.players ?? {})))
isInBattle.subscribe(@(v) v ? playersCommonStats({}) : null)

let function requestEarlyExitRewards() {
  logBD("Request early exit rewards")
  sendNetEvent(find_local_player_eid(), CmdApplyMyBattleResultOnExit())
}

subscribe("onBattleConnectionFailed", @(p) connectFailedData(p.__merge({ sessionId = battleSessionId.value })))

register_command(requestEarlyExitRewards, "debriefing.request_early_exit_rewards")
register_command(function() {
  if (battleResult.value == null)
    return console_print("Current battle result is empty")

  let file = io.file(SAVE_FILE, "wt+")
  file.writestring(json.to_string(battleResult.value, true))
  file.close()
  return console_print($"Saved to {SAVE_FILE}")
}, "debriefing.save_current_battle_result")

return {
  battleResult
  debugBattleResult
  requestEarlyExitRewards
}
