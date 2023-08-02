from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { HUD_MSG_MULTIPLAYER_DMG, UT_Unknown, UT_Ship } = require("hudMessages")
let { GO_WIN, GO_FAIL, GO_NONE } = require("guiMission")
let { chooseRandom } = require("%sqstd/rand.nut")
let { localMPlayerId, localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { debugHudType, HT_CUTSCENE } = require("%appGlobals/clientState/hudState.nut")
let { playersCommonStats, dbgCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let hudMessagesUnitTypesMap = require("hudMessagesUnitTypesMap.nut")

//mission hints
let hintsForTest = [
  "hints/enemy_base_destroyed_no_respawn" //multiline
  "avn_ntdm_objective_02" //with blue team color
  "avg_Bttl_objective_01" //with red team color
]
register_command(
  @() send("hint:missionHint:set", { locId = chooseRandom(hintsForTest), time = 5.0 }),
  "hud.debug.missionHintSet")
register_command(
  @() send("hint:missionHint:remove", {}),
  "hud.debug.missionHintRemove")
register_command(
  @() send("hint:missionHint:set", { locId = "hints/enemy_base_destroyed_no_respawn", time = 5.0, hintType = "bottom" }),
  "hud.debug.missionBottomHintSet")
register_command(
  @() send("hint:missionHint:remove", { hintType = "bottom" }),
  "hud.debug.missionBottomHintRemove")


//mission objectives
register_command(
  @() send("HudMessage",
    {
      id = 0
      type = 0
      text = "Destroy all ships of the enemy fleet"
      show = true
    }),
  "hud.debug.objectiveHintShow")
register_command(
  @() send("HudMessage",
    {
      id = 0
      type = 0
      show = false
    }),
  "hud.debug.objectiveHintHide")


let results = [
  { id = GO_WIN, dbg = "Win" }
  { id = GO_FAIL, dbg = "Fail" }
  { id = GO_NONE, dbg = "Continue" }
]
local prevIdx = -1
register_command(
  function() {
    let { id, dbg } = results[++prevIdx % results.len()]
    if (id == GO_NONE)
      send("MissionContinue", {})
    else
      send("MissionResult", { resultNum = id })
    log(dbg)
  },
  "hud.debug.battleResultHint")


register_command(
  @() send("HudMessage", {
    type = HUD_MSG_MULTIPLAYER_DMG
    isKill = true
    action = "kill"

    playerId = localMPlayerId.value,
    team = 3 - localMPlayerTeam.value
    unitName = allUnitsCfg.value.findvalue(@(_) true)?.name ?? ""
    unitType = UT_Ship
    unitNameLoc = "Killer Unit"

    victimPlayerId = localMPlayerId.value,
    victimTeam = localMPlayerTeam.value
    victimUnitName = allUnitsCfg.value.findvalue(@(_) true)?.name ?? ""
    victimUnitType = UT_Ship
    victimUnitNameLoc = "Victim Unit"
  }),
  "hud.debug.killMessage")

register_command(
  function() {
    if (debugHudType.value == HT_CUTSCENE) {
      debugHudType(null)
      return
    }
    let unit = allUnitsCfg.value.findvalue(@(_) true)
    let unitType = hudMessagesUnitTypesMap.findindex(@(v) v == unit?.unitType) ?? UT_Unknown
    send("HudMessage", {
      type = HUD_MSG_MULTIPLAYER_DMG
      isKill = true
      action = "kill"

      playerId = localMPlayerId.value,
      team = 3 - localMPlayerTeam.value
      unitName = unit?.name ?? ""
      unitType
      unitNameLoc = "Killer Unit"

      victimPlayerId = localMPlayerId.value,
      victimTeam = localMPlayerTeam.value
      victimUnitName = unit?.name ?? ""
      victimUnitType = unitType
      victimUnitNameLoc = "Victim Unit"
    })
    if (myUserId.value != null && (playersCommonStats.value?[myUserId.value].len() ?? 0) == 0)
      dbgCommonStats.mutate(@(v) v[myUserId.value] <- { hasPremium = true, level = unit?.rank ?? 1, unit = { level = 25, isPremium = true } })
    debugHudType(HT_CUTSCENE)
  },
  "hud.debug.deathScreen")
