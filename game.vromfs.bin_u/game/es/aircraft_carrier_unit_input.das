require ecs
require Unit
require MPlayer
require WTCamera
require Mission
require WTInput
require FlightControl
require %game.events
require %appGame.wtm_events

[es(tag=input, REQUIRE=(controlledHero, aircraftCarrier))]
def aircarft_carrier_input_spawn_requiest(evt : EventOnKeyUp;
                                          eid : EntityId;
                                          uid : int;
                                          aircraft_carrier__aircraftSpawnRequestInterval : float;
                                          var aircraft_carrier__lastAircraftSpawnRequestAtTime : FloatList)
  let aircraftIndex = evt.eventId - int(ShortcutEventId ID_WTM_LAUNCH_AIRCRAFT)
  if aircraftIndex < 0 || aircraftIndex >= SUPPORT_PLANES_MAX
    return

  let curTime = float(get_total_time())
  let spawnInterval = aircraft_carrier__aircraftSpawnRequestInterval
  if curTime - aircraft_carrier__lastAircraftSpawnRequestAtTime[aircraftIndex] < spawnInterval
    return

  let unit = get_unit(uid)
  if unit != null
    let supportId = get_support_plane_id(uid, aircraftIndex)
    if get_unit(supportId) == null
      return

  aircraft_carrier__lastAircraftSpawnRequestAtTime[aircraftIndex] = curTime

  let aimAngles = get_turret_aim_angles()
  sendEvent(eid, [[CmdRequestSwitchOnSupportPlane turnOn=true, idx=aircraftIndex, startAngles=float2(aimAngles.x, 0.f)]])


[es(tag=input, REQUIRE=(controlledHero))]
def aircarft_carrier_return_from_plane_requiest(evt : EventOnKeyUp;
                                                uid : int)
  let aircraftIndex = evt.eventId - int(ShortcutEventId ID_WTM_LAUNCH_AIRCRAFT)
  if aircraftIndex < 0 || aircraftIndex >= SUPPORT_PLANES_MAX
    return

  let unit = get_unit(uid)
  if unit.isGroundModel
    return

  let ownedUnit = get_owned_unit(uid)
  if !ownedUnit.isGroundModel
    return

  let aimAngles = get_turret_aim_angles()
  sendEvent(ownedUnit.eid, [[CmdRequestSwitchOnSupportPlane turnOn=false, idx=aircraftIndex, startAngles=float2(aimAngles.x, 0.f)]])


[es(tag=input, REQUIRE=(controlledHero))]
def aircarft_carrier_plane_change_request(evt : EventOnKeyUp;
                                          uid : int)
  if evt.eventId != int(ShortcutEventId ID_WTM_AIRCRAFT_CHANGE)
    return

  let unit = get_unit(uid)
  if unit.isGroundModel
    return

  let ownedUnit = get_owned_unit(uid)
  if !ownedUnit.isGroundModel
    return

  let supportPlaneIdx = find_support_plane_index(ownedUnit.id, uid)
  sendEvent(ownedUnit.eid, [[CmdRequestSupportPlaneChange idx=supportPlaneIdx]])

[es(tag=input, REQUIRE=(controlledHero))]
def aircarft_carrier_plane_group_attack(evt : EventOnKeyUp;
                                        uid : int)
  if evt.eventId != int(ShortcutEventId ID_WTM_AIRCRAFT_GROUP_ATTACK)
    return

  set_player_command(1)

  let unit = get_unit(uid)
  if unit.isGroundModel
    return

  let ownedUnit = get_owned_unit(uid)
  if !ownedUnit.isGroundModel
    return

  let supportPlaneIdx = find_support_plane_index(ownedUnit.id, uid)
  sendEvent(ownedUnit.eid, [[CmdRequestSupportPlaneGroupAttack idx=supportPlaneIdx, targetId=get_player_target_id(), attack=false]])

[es(tag=input, REQUIRE=(controlledHero))]
def aircarft_carrier_plane_return(evt : EventOnKeyUp;
                                  uid : int)
  if evt.eventId != int(ShortcutEventId ID_WTM_AIRCRAFT_RETURN)
    return

  set_player_command(5)

  let unit = get_unit(uid)
  if unit.isGroundModel
    return

  let ownedUnit = get_owned_unit(uid)
  if !ownedUnit.isGroundModel
    return

  let supportPlaneIdx = find_support_plane_index(ownedUnit.id, uid)
  sendEvent(ownedUnit.eid, [[CmdReturnAircraftToShip idx=supportPlaneIdx, rtb=true]])
