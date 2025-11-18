from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { rnd_int } = require("dagor.random")
let { register_command } = require("console")
let { HUD_MSG_MULTIPLAYER_DMG, HUD_MSG_STREAK_EX, UT_Unknown, UT_Ship } = require("hudMessages")
let { GO_WIN, GO_FAIL, GO_NONE } = require("guiMission")
let { chooseRandom } = require("%sqstd/rand.nut")
let { localMPlayerId, localMPlayerTeam } = require("%appGlobals/clientState/clientState.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { debugHudType, HT_CUTSCENE } = require("%appGlobals/clientState/hudState.nut")
let { areHintsHidden } = require("%rGui/hudState.nut")
let { playersCommonStats, dbgCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let hudMessagesUnitTypesMap = require("%rGui/hudHints/hudMessagesUnitTypesMap.nut")
let { get_unlocks_blk} = require("blkGetters")


let hintsForTest = [
  "hints/enemy_base_destroyed_no_respawn" 
  "avn_ntdm_objective_02" 
  "avg_Bttl_objective_01" 
]
register_command(
  @() eventbus_send("hint:missionHint:set", { locId = chooseRandom(hintsForTest), time = 5.0 }),
  "hud.debug.missionHintSet")
register_command(
  @() eventbus_send("hint:missionHint:remove", {}),
  "hud.debug.missionHintRemove")
register_command(
  @() eventbus_send("hint:missionHint:set", { locId = "hints/enemy_base_destroyed_no_respawn", time = 5.0, hintType = "bottom" }),
  "hud.debug.missionBottomHintSet")
register_command(
  @() eventbus_send("hint:missionHint:remove", { hintType = "bottom" }),
  "hud.debug.missionBottomHintRemove")



register_command(
  @() eventbus_send("HudMessage",
    {
      id = 0
      type = 0
      text = "Destroy all ships of the enemy fleet"
      show = true
    }),
  "hud.debug.objectiveHintShow")
register_command(
  @() eventbus_send("HudMessage",
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
      eventbus_send("MissionContinue", {})
    else
      eventbus_send("MissionResult", { resultNum = id })
    log(dbg)
  },
  "hud.debug.battleResultHint")


register_command(
  @() eventbus_send("HudMessage", {
    type = HUD_MSG_MULTIPLAYER_DMG
    isKill = true
    action = "kill"

    playerId = rnd_int(0, 1) ? localMPlayerId.get()
      : localMPlayerId.get() == 0 ? 1
      : 0,
    team = localMPlayerTeam.get()
    unitName = campUnitsCfg.get().findvalue(@(_) true)?.name ?? ""
    unitType = UT_Ship
    unitNameLoc = "Killer Unit"

    victimPlayerId = localMPlayerId.get() == 0 ? 1 : 0,
    victimTeam = 3- localMPlayerTeam.get()
    victimUnitName = campUnitsCfg.get().findvalue(@(_) true)?.name ?? ""
    victimUnitType = UT_Ship
    victimUnitNameLoc = "Victim Unit"
  }),
  "hud.debug.killMessage")

register_command(
  function() {
    let { id = "" } = chooseRandom((get_unlocks_blk() % "unlockable")?.filter(@(blk) blk?.type == "streak") ?? [])
    if (id == "") {
      console_print("Unable to show hud streak, because of no unlockable streaks in blk") 
      return
    }
    eventbus_send("HudMessage", {
      type = HUD_MSG_STREAK_EX
      playerId = localMPlayerId.get()
      unlockId = id
      stage = rnd_int(1, 3)
      wp = 100
    })
  },
  "hud.debug.streak")

register_command(
  function() {
    if (debugHudType.get() == HT_CUTSCENE) {
      debugHudType.set(null)
      return
    }
    let unit = campUnitsCfg.get().findvalue(@(_) true)
    let unitType = hudMessagesUnitTypesMap.findindex(@(v) v == unit?.unitType) ?? UT_Unknown
    eventbus_send("HudMessage", {
      type = HUD_MSG_MULTIPLAYER_DMG
      isKill = true
      action = "kill"

      playerId = localMPlayerId.get(),
      team = 3 - localMPlayerTeam.get()
      unitName = unit?.name ?? ""
      unitType
      unitNameLoc = "Killer Unit"

      victimPlayerId = localMPlayerId.get(),
      victimTeam = localMPlayerTeam.get()
      victimUnitName = unit?.name ?? ""
      victimUnitType = unitType
      victimUnitNameLoc = "Victim Unit"
    })
    if (myUserId.get() != null && (playersCommonStats.get()?[myUserId.get()].len() ?? 0) == 0)
      dbgCommonStats.mutate(@(v) v[myUserId.get()] <- {
        hasPremium = true
        hasVip = true
        hasPrem = true
        level = unit?.rank ?? 1
        mainUnitName = unit?.name ?? ""
        units = {
          [unit?.name ?? ""] = { level = 25, mRank = unit?.mRank, isUpgraded = true }
        }
      })
    debugHudType.set(HT_CUTSCENE)
  },
  "hud.debug.deathScreen")

register_command(
  function() {
    areHintsHidden.set(!areHintsHidden.get())
    console_print($"Current state - {areHintsHidden.get()}") 
  },
  "hud.debug.hideHints")