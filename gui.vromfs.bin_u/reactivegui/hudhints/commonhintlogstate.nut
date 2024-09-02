from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { format } =  require("string")
let { register_command } = require("console")
let { HUD_MSG_EVENT } = require("hudMessages")
let { localMPlayerTeam, isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { bulletsInfo, currentBulletName } = require("%rGui/hud/bullets/hudUnitBulletsState.nut")
let { addHudElementPointer, removeHudElementPointer } = require("%rGui/tutorial/hudElementPointers.nut")
let { resetTimeout } = require("dagor.workcycle")

let state = require("%sqstd/mkEventLogState.nut")({
  persistId = "commonHintLogState"
  maxActiveEvents = 2
  defTtl = 3
  isEventsEqual = @(a, b) "id" in a ? a?.id == b?.id : a?.text == b?.text
})
let { addEvent, modifyOrAddEvent, removeEvent, clearEvents } = state
let COUNTER_SAVE_ID = "hintCounter"

isInBattle.subscribe(@(_) clearEvents())

//todo: export from native code to darg
const MP_TEAM_NEUTRAL = 0

let getTeamColor = @(team) team == MP_TEAM_NEUTRAL ? null
 : team == localMPlayerTeam.value ? teamBlueColor
 : teamRedColor

let addCommonHint = @(text, evId = "", evType = "simpleTextTiny") addEvent({ id = evId, hType = evType, text })
let addCommonHintWithTtl = @(text, ttl, evId = "") addEvent({ id = evId, hType = "simpleTextTiny", text, ttl })

eventbus_subscribe("hint:ui_message:show", function(data) {
  let { locId, param = null, paramTeamId = MP_TEAM_NEUTRAL, teamId = MP_TEAM_NEUTRAL } = data
  local text = loc(locId)
  if (param != null)
    text = format(text, colorize(getTeamColor(paramTeamId), param))
  addCommonHint(colorize(getTeamColor(teamId), text))
})

eventbus_subscribe("hint:action_not_available", function(data) {
  let { hintId, param = null, paramTeamId = MP_TEAM_NEUTRAL, teamId = MP_TEAM_NEUTRAL } = data
  local text = loc("".concat("hints/", hintId))
  if (param != null)
    text = format(text, colorize(getTeamColor(paramTeamId), param))
  addCommonHint(colorize(getTeamColor(teamId), text))
})

const ART_SUPPORT_ID = "have_art_support"
eventbus_subscribe("hint:have_art_support:show",
  @(_) addEvent({ id = ART_SUPPORT_ID, hType = "simpleTextTiny", text = loc("hints/have_art_support") }))

eventbus_subscribe("hint:have_art_support:hide",
  @(_) removeEvent({ id = ART_SUPPORT_ID }))

eventbus_subscribe("repairBlocked",
  @(p) addEvent({ id = "repair_blocked", hType = "simpleTextTiny", text = loc(p.hintId) }))

eventbus_subscribe("hint:target_deeper_than_periscope:show",
  @(_) addEvent({ hType = "simpleTextTiny", text = loc("hints/target_deeper_than_periscope") }))

eventbus_subscribe("hint:drowning:show", function(data) {
  let timeTo = data?.timeTo ?? 0
  let text = " ".concat(loc("hints/drowning_in"), secondsToTimeSimpleString(timeTo))
  addEvent({ hType = "simpleTextTiny", text, ttl = timeTo > 4 ? 0.5 : 1.0 })
})

const MISSION_HINT = "mission_hint_bottom"
eventbus_subscribe("hint:missionHint:set", @(data) data?.hintType != "bottom" ? null
  : modifyOrAddEvent(
      data.__merge({
        id = MISSION_HINT
        hType = "mission"
        zOrder = Layers.Upper
        ttl = data?.time ?? 0
        text = loc(data?.locId ?? "", { var = data?.variable_value })
      }),
      @(ev) ev?.id == MISSION_HINT && ev?.locId == data?.locId))

eventbus_subscribe("hint:missionHint:remove", @(data) data?.hintType != "bottom" ? null
  : removeEvent({ id = MISSION_HINT }))

function incHintCounter(id, showCount) {
  let sBlk = get_local_custom_settings_blk()
  let saveId = $"{COUNTER_SAVE_ID}/{id}"
  let count = getBlkValueByPath(sBlk, saveId) ?? 0
  if (count >= showCount)
    return false

  setBlkValueByPath(sBlk, saveId, count + 1)
  eventbus_send("saveProfile", {})
  return true
}

eventbus_subscribe("hint:ineffective_hit_tank:show", function(_) {
  if (incHintCounter("ineffective_hit_tank", 15))
    addCommonHint(loc("hints/ineffective_hit_tank"))
})

eventbus_subscribe("hint:shoot_when_tank_stop:show", function(_) {
  if (incHintCounter("shoot_when_tank_stop", 15))
    addCommonHint(loc("hints/shoot_when_tank_stop"))
})

eventbus_subscribe("hint:change_shell_type:show", function(_) {
  if (bulletsInfo.value == null)
    return
  let isHE = bulletsInfo.value?.fromUnitTags[currentBulletName.value ?? "default"]?.isHE ?? false
  if (isHE && incHintCounter("change_shell_type", 15))
    addCommonHint(loc("hints/change_shell_type"))
})

eventbus_subscribe("hint:miss_shot_tank:show", function(_) {
  if (incHintCounter("miss_shot_tank", 5))
    addCommonHint(loc("hints/miss_shot_tank"))
})

eventbus_subscribe("hint:kill_tank_back:show", function(_) {
  if (incHintCounter("kill_tank_back", 5))
    addCommonHint(loc("hints/kill_tank_back"))
})

eventbus_subscribe("hint:dont_hold_ctrl_to_move_tank:show", function(_) {
  if (incHintCounter("dont_hold_ctrl_to_move_tank", 3))
    addCommonHint(loc("hints/dont_hold_ctrl_to_move"))
})

eventbus_subscribe("hint:dont_hold_ctrl_to_move_ship:show", function(_) {
  if (incHintCounter("dont_hold_ctrl_to_move_ship", 3))
    addCommonHint(loc("hints/dont_hold_ctrl_to_move"))
})

eventbus_subscribe("hint:turn_types_ctrl:show", function(_) {
  if (incHintCounter("turn_types_ctrl", 3))
    addCommonHint(loc("hints/turn_types_ctrl"))
})

eventbus_subscribe("hint:need_target_for_lock", function(_) {
  addCommonHint(loc("hints/need_target_for_lock"))
})

eventbus_subscribe("hint:kill_streak_fighter_reverted", function(_) {
  addCommonHint(loc("hints/kill_streak_fighter_reverted"))
})

const GUT_OVERHEAT_WARNING = "gun_overheat_warning"
eventbus_subscribe("hint:gun_overheat_warning", function(_) {
  if (!incHintCounter(GUT_OVERHEAT_WARNING, 5))
    return
  addCommonHint(loc("hints/gun_overheat_warning"))
})

eventbus_subscribe("hint:use_gun_for_spaa:show", function(_) {
  if (incHintCounter("use_gun_for_spaa", 3)){
    addCommonHint(loc("hints/use_gun_for_spaa"))
  }
})

eventbus_subscribe("hint:holding_for_stop:show", function(_) {
  if (!incHintCounter("holding_for_stop", 5))
    return
  addCommonHint(loc("hints/holding_for_stop"))
})

eventbus_subscribe("hint:need_stop_for_fire", function(_) {
  addCommonHint(loc("hints/need_stop_for_fire"))
})

eventbus_subscribe("hint:hull_aiming_with_camera:show", function(_) {
  if (!incHintCounter("hull_aiming_with_camera", 3))
    return
  addCommonHint(loc("hints/hull_aiming_with_camera"))
})

const REPAIR_MODULE_ID = "repair_module"
eventbus_subscribe("hint:repair_module:show", function(_) {
  if (!incHintCounter(REPAIR_MODULE_ID, 15))
    return
  addCommonHintWithTtl(loc("hints/for_newbies/repair_module"), 30, REPAIR_MODULE_ID)
  addHudElementPointer("btn_repair", 30)
})
eventbus_subscribe("hint:repair_module:hide", function(_) {
  removeEvent({ id = REPAIR_MODULE_ID })
  removeHudElementPointer("btn_repair")
})

const SHIP_REPAIR_OFFER_ID = "ship_offer_repair"
eventbus_subscribe("hint:ship_offer_repair:show", function(_) {
  if (!incHintCounter(SHIP_REPAIR_OFFER_ID, 15))
    return
  addCommonHintWithTtl(loc("hints/ship_offer_repair"), 30, SHIP_REPAIR_OFFER_ID)
  addHudElementPointer("btn_repair", 30)
})
eventbus_subscribe("hint:ship_offer_repair:hide", function(_) {
  removeEvent({ id = SHIP_REPAIR_OFFER_ID })
  removeHudElementPointer("btn_repair")
})


const EXTINGUISH_FIRE_ID = "can_extinguish_fire"
eventbus_subscribe("hint:can_extinguish_fire:show", function(_) {
  if (!incHintCounter(EXTINGUISH_FIRE_ID, 15))
    return
  addCommonHintWithTtl(loc("hints/for_newbies/can_extinguish_fire"), 30, EXTINGUISH_FIRE_ID)
  addHudElementPointer("btn_extinguisher", 30)
})
eventbus_subscribe("hint:can_extinguish_fire:hide", function(_) {
  removeEvent({ id = EXTINGUISH_FIRE_ID })
  removeHudElementPointer("btn_extinguisher")
})

const WAIT_FOR_FIRE_STOP_ID = "wait_for_fire_stop"
eventbus_subscribe("hint:wait_for_fire_stop:show", function(_) {
  if (incHintCounter(WAIT_FOR_FIRE_STOP_ID, 15))
    addCommonHintWithTtl(loc("hints/for_newbies/wait_for_fire_stop"), 30, WAIT_FOR_FIRE_STOP_ID)
})
eventbus_subscribe("hint:wait_for_fire_stop:hide",
  @(_) removeEvent({ id = WAIT_FOR_FIRE_STOP_ID }))

const CAN_USE_AIR_SUPPORT_ID = "can_use_air_support"
eventbus_subscribe("hint:can_use_air_support:show", function(_) {
  if (!incHintCounter(CAN_USE_AIR_SUPPORT_ID, 15))
    return
  addCommonHintWithTtl(loc("hints/for_newbies/can_use_air_support"), 30, CAN_USE_AIR_SUPPORT_ID)
  addHudElementPointer("btn_special_unit", 30)
  addHudElementPointer("btn_special_unit2", 30)
})
eventbus_subscribe("hint:can_use_air_support:hide", function(_) {
  removeEvent({ id = CAN_USE_AIR_SUPPORT_ID })
  removeHudElementPointer("btn_special_unit")
  removeHudElementPointer("btn_special_unit2")
})

eventbus_subscribe("hint:mission_goal", function(p) {
  if (incHintCounter("mission_goal", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/mission_goal"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

eventbus_subscribe("hint:this_is_minimap", function(p) {
  if (incHintCounter("this_is_minimap", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/this_is_minimap"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

eventbus_subscribe("hint:this_is_capture_point", function(p) {
  if (incHintCounter("this_is_capture_point", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/this_is_capture_point"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

eventbus_subscribe("hint:you_are_capturing", function(p) {
  if (incHintCounter("you_are_capturing", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/you_are_capturing"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

eventbus_subscribe("hint:capture_zones", function(p) {
  if (incHintCounter("capture_zones", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/capture_zones"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

eventbus_subscribe("hint:this_is_score_board", function(p) {
  if (incHintCounter("this_is_score_board", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/this_is_score_board"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

let bailoutTimer = mkWatched(persist,"bailoutTimer", 0)
local bailoutTimerStep = 0

function updateBailoutText() {
  bailoutTimerStep = 1.0
  let time = bailoutTimer.get()
  if (time <= 0) {
    removeEvent({ id = "start_bailout" })
    return
  }
  let text = " ".concat(loc("hints/bailout_in_progress"), secondsToTimeSimpleString(time))
  addEvent({id = "start_bailout", hType = "simpleTextTiny", text, ttl = bailoutTimerStep + 1.0})
  bailoutTimer.set(time - bailoutTimerStep)
}

bailoutTimer.subscribe(@(_) resetTimeout(bailoutTimerStep, updateBailoutText))
updateBailoutText()

eventbus_subscribe("hint:bailout:startBailout", function(data) {
  bailoutTimerStep = 0
  bailoutTimer.set(data?.lifeTime ?? 0)
  addCommonHintWithTtl(loc("hints/can_leave_in_menu"), 5)
})

eventbus_subscribe("hint:bailout:notBailouts", function(_) {
  bailoutTimer.set(0)
})

eventbus_subscribe("hint:ticket_loose", function(p) {
  if (incHintCounter("ticket_loose", 3)) {
    addCommonHintWithTtl(loc("hints/mission_goals_for_newbies/ticket_loose"), p.duration)
    addHudElementPointer(p.elementId, p.duration)
  }
})

const MSG_EVENT_HINT = "MSG_EVENT_HINT"
eventbus_subscribe("HudMessage", @(data) data.type != HUD_MSG_EVENT ? null
  : modifyOrAddEvent(data.__merge({
        id = MSG_EVENT_HINT
        hType = "simpleTextTiny"
        ttl = data?.time ?? 3.0
      }),
      @(ev) ev?.id == MSG_EVENT_HINT))

eventbus_subscribe("hint:air_target_far_away", function(data) {
  let rangeText = "".concat(data?.effectiveRange ?? "", loc("measureUnits/meters_alt"))
  addCommonHintWithTtl("".concat(loc("hints/air_target_far_away"), rangeText), 10)
})

eventbus_subscribe("hint:air_critical_speed", function(_) {
  addCommonHintWithTtl(loc("hints/air_critical_speed"), 10)
})

eventbus_subscribe("hint:aim_for_lead_indicator", function(_) {
  addCommonHintWithTtl(loc("hints/aim_for_lead_indicator"), 10)
})

eventbus_subscribe("CaptureBlockerActive", function(_) {
  addCommonHintWithTtl(loc("hints/capture_blocker_active"), 5)
})

eventbus_subscribe("CaptureInterrupted", function(_) {
  addCommonHintWithTtl(loc("hints/capture_interrupted"), 5)
})

eventbus_subscribe("hint:enemy_too_far", function(_) {
  addCommonHintWithTtl(loc("hints/enemy_too_far"), 3)
})

eventbus_subscribe("hint:need_lock_target", function(_) {
  if (incHintCounter("need_lock_target", 5)) {
    addCommonHintWithTtl(loc("hints/need_lock_target"), 5)
    anim_start("hint_need_lock_target")
  }
})

const CAPTURED_BY_ENEMY = "can_use_air_support"

eventbus_subscribe("CapturedByEnemy:show",
  @(_) addCommonHintWithTtl(loc("hints/ship_is_captured_by_enemy"), -1, CAPTURED_BY_ENEMY))

eventbus_subscribe("CapturedByEnemy:hide",
  @(_) removeEvent({ id = CAPTURED_BY_ENEMY }))

register_command(function() {
    let sBlk = get_local_custom_settings_blk()
    if (COUNTER_SAVE_ID not in sBlk)
      return
    sBlk.removeBlock(COUNTER_SAVE_ID)
    eventbus_send("saveProfile", {})
  },
  "reset_hint_counters")

return state.__update({
  addCommonHint
  addCommonHintWithTtl
})