require ecs
require net
require app
require dm
require math
require DagorRandom
require DagorMath
require Unit
require UnitFx
require AmmoStowage
require Weapon
require WTDamageModel
require IGroundModel
require WTHangar
require %dasGameLibs.math.base
require %game.utils.utils_common
require %game.utils.component_bundle_macro
require %game.dm.fire_system_events
require %game.unit.unit_events
require %game.unit.ammo_stowage_common
require %game.unit.ammo_stowage_events
require %game.events


[with_bundle(v)]
def ammo_stowage_restore_slots(var v : tuple<
                                 ammo_slots__state : UInt32List
                               >) : void
  // water is cleared upon repair/respawn, so it is safe to just set FLOODED to false for all slots
  for state in v.ammo_slots__state
    set_flag(state, AmmoSlotState ENABLED, true)
    set_flag(state, AmmoSlotState FLOODED, false)


[es, with_bundle(v)]
def ammo_stowage_respawn_handle(evt : EventUnitRespawn; eid : EntityId;
                                var v : tuple<
                                  ammo_slots__state : UInt32List
                                >) : void
  ammo_stowage_restore_slots() <| v
  sendEvent(eid, [[EventBulletsAmountChanged isRefill=true]])


[es, with_bundle(v)]
def ammo_stowage_repair_handle(evt : EventUnitRepair; eid : EntityId;
                               var v : tuple<
                                 ammo_slots__state : UInt32List
                               >) : void
  ammo_stowage_restore_slots() <| v
  sendEvent(eid, [[EventBulletsAmountChanged isRefill=false]])


[with_bundle(v)]
def can_replenish_to_cluster(cluster_id : int; bullets_cartridge : int; v : tuple<ammo_clusters__numAmmo : IPoint3List>) : bool
  return v.ammo_clusters__numAmmo[cluster_id].x + bullets_cartridge <= v.ammo_clusters__numAmmo[cluster_id].z

[with_bundle(v)]
def can_replenish_from_cluster(cluster_id : int; bullets_cartridge : int; v : tuple<ammo_clusters__numAmmo : IPoint3List>) : bool
  return v.ammo_clusters__numAmmo[cluster_id].x >= bullets_cartridge

[with_bundle(v)]
def ammo_stowage_is_weapon_blocked_impl(unit : Unit?;
                                        stowage_state : uint;
                                        clusters_range : int2;
                                        num_ammo_in_stage : int3[4];
                                        loaded_ammo_cnt : int;
                                        v : tuple<
                                          ammo_clusters__state : UInt32List;
                                          ammo_clusters__elevatorPartsRange : IPoint2List;
                                          ammo_stowage__elevatorPartsIds : PartIdList
                                        >) : bool
  // check if there is any ammo in first or second stage of this stowage, if there is none - weapon is blocked
  if loaded_ammo_cnt == 0 && num_ammo_in_stage[int(AmmoClusterStage FIRST_STAGE)].x <= 0 && num_ammo_in_stage[int(AmmoClusterStage SECOND_STAGE)].x <= 0
    return true

  if get_flag(stowage_state, AmmoStowageState HAS_AUTO_LOAD)
    var auto_load_empty = true;
    for cluster_id in clusters_range.x..clusters_range.y
      let is_empty = get_flag(v.ammo_clusters__state[cluster_id], AmmoClusterState EMPTY)
      let is_auto_load = get_flag(v.ammo_clusters__state[cluster_id], AmmoClusterState AUTO_LOAD)
      auto_load_empty = auto_load_empty && (!is_auto_load || is_empty)
    // if no bullets are loaded in weapon and all auto load clusters for this weapon are empty
    if loaded_ammo_cnt == 0 && auto_load_empty
      return true

  // check elevators are blocked or there are no elevators
  assume unitDm = unit.dmData;
  for cluster_id in clusters_range.x..clusters_range.y
    let elevators_range = v.ammo_clusters__elevatorPartsRange[cluster_id];
    if !get_flag(v.ammo_clusters__state[cluster_id], AmmoClusterState ELEVATOR_DESTROY_BLOCK_SHOOT) || elevators_range.x == elevators_range.y
      return false
    for i in elevators_range.x..elevators_range.y
      if get_part_hp(unitDm, v.ammo_stowage__elevatorPartsIds[i]) > 0.f
        return false
  return true

[es, with_bundle(v)]
def ammo_stowage_update_replenishment_and_state_es(info : ParallelUpdateFrameDelayed;
                                                   active : bool;
                                                   eid : EntityId;
                                                   uid : int;
                                                   v : tuple<
                                                     ammo_stowage__weaponTriggers : IntList;
                                                     ammo_stowages__state : UInt32List- const;
                                                     ammo_stowages__cachedNumAmmoFirstStage : IPoint3List- const;
                                                     ammo_stowages__replenishmentStartEnd : Point2List- const;
                                                     ammo_stowages__replenishmentTime : Point2List- const;
                                                     ammo_stowages__weaponTriggersRange : IPoint2List;
                                                     ammo_stowages__bulletsCartridge : IntList;
                                                     ammo_stowages__clustersRange : IPoint2List;
                                                     ammo_clusters__state : UInt32List;
                                                     ammo_clusters__typeAndStage : UInt16List;
                                                     ammo_clusters__numAmmo : IPoint3List- const;
                                                     ammo_clusters__elevatorPartsRange : IPoint2List;
                                                     ammo_stowage__elevatorPartsIds : PartIdList
                                                   >)
  if is_in_hangar()
    return
  var unit = get_unit(uid)
  if unit == null || unit.isDelayed || !active
    return

  v.ammo_stowages__cachedNumAmmoFirstStage |> resize(length(v.ammo_stowages__state))

  let current_time = float(get_app().usefulTotalTime)
  let weapon_controller = unit.weap
  for stowage_state, replenishment_start_end, replenishment_time, bullets_cartridge, cached_num_ammo_fs, triggers_range, clusters_range in v.ammo_stowages__state, v.ammo_stowages__replenishmentStartEnd, v.ammo_stowages__replenishmentTime, v.ammo_stowages__bulletsCartridge, v.ammo_stowages__cachedNumAmmoFirstStage, v.ammo_stowages__weaponTriggersRange, v.ammo_stowages__clustersRange
    cached_num_ammo_fs = int3(0, 0, 0)
    // gather total ammo count in each stage (for all types)
    assert(int(AmmoClusterStage NUM_STAGES) == 4)
    assert(int(AmmoClusterType NUM_TYPES) == 2)
    var num_ammo_in_stage : int3[4]
    for cluster_id in clusters_range.x..clusters_range.y
      var cluster_ammo = v.ammo_clusters__numAmmo[cluster_id];
      cluster_ammo.x = (cluster_ammo.x / bullets_cartridge) * bullets_cartridge; // round down just in case
      let cluster_stage = get_ammo_cluster_stage(cluster_id, v)
      num_ammo_in_stage[cluster_stage] += cluster_ammo

      // also update cached first stage count
      if cluster_stage <= int(AmmoClusterStage FIRST_STAGE) && get_ammo_cluster_type(cluster_id, v) == int(AmmoClusterType SHELLS)
        cached_num_ammo_fs += cluster_ammo

    // find pair of stages we can replenish to and from
    var stage_to_replenish_to = -1
    var stage_to_replenish_from = -1
    for to_stage in int(AmmoClusterStage FIRST_STAGE)..int(AmmoClusterStage NO_RELOAD)
      // for flag REPLENISH_ONLY_EMPTY: dont replenish non-empty stages, if replenishment havent started yet
      if get_flag(stowage_state, AmmoStowageState REPLENISH_ONLY_EMPTY) && replenishment_start_end.x < 0.0 && num_ammo_in_stage[to_stage].x > 0
        continue
      if num_ammo_in_stage[to_stage].x + bullets_cartridge <= num_ammo_in_stage[to_stage].z
        for from_stage in (to_stage + 1)..int(AmmoClusterStage NUM_STAGES)
          if num_ammo_in_stage[from_stage].x >= bullets_cartridge
            stage_to_replenish_from = from_stage // dont break here, we want the last available stage
        if stage_to_replenish_from != -1
          stage_to_replenish_to = to_stage
          break

    // update weapon blocked state
    var loaded_ammo_cnt = 0
    for i in triggers_range.x..triggers_range.y
      for weapon in weapon_controller.Weapons |> get_weapons_by_trigger(v.ammo_stowage__weaponTriggers[i])
        if weapon == null
          continue
        let gun = weapon |> as_gun()
        if gun != null
          loaded_ammo_cnt += gun.currentLoadedAmmoCount
        else
          loaded_ammo_cnt++ // todo: base gun
    let is_weapon_blocked = ammo_stowage_is_weapon_blocked_impl(unit, stowage_state, clusters_range, num_ammo_in_stage, loaded_ammo_cnt) <| v
    set_flag(stowage_state, AmmoStowageState IS_WEAPON_BLOCKED, is_weapon_blocked)

    // early exist if replenishment is disabled or unit is burning
    if replenishment_time.x < VERY_SMALL_NUMBER
      continue
    if unit.isBurn
      replenishment_start_end = float2(-1.0f)
      continue

    // if there is no stages to replenish - cancel replenishment
    if stage_to_replenish_to == -1
      replenishment_start_end = float2(-1.0f)
      continue

    // reset progress if weapon is reloading, however dont do this if weapon is blocked due to empty stage
    var check_weapon_reloading = false
    if get_flag(stowage_state, AmmoStowageState HAS_AUTO_LOAD)
      check_weapon_reloading = num_ammo_in_stage[int(AmmoClusterStage FIRST_STAGE)].x > 0
    else
      check_weapon_reloading = num_ammo_in_stage[int(AmmoClusterStage SECOND_STAGE)].x > 0 || num_ammo_in_stage[int(AmmoClusterStage FIRST_STAGE)].x > 0
    if check_weapon_reloading
      var end_stowage_update = false
      for i in triggers_range.x..triggers_range.y
        if weapon_controller.Weapons |> is_weapon_reloading(v.ammo_stowage__weaponTriggers[i], current_time)
          replenishment_start_end = float2(-1.0f)
          end_stowage_update = true
          break
      if end_stowage_update
        continue

    // cancel replenishment if there is no loader available
    var can_reload = false
    for i in triggers_range.x..triggers_range.y
      if unit |> is_loading_crewman_available(v.ammo_stowage__weaponTriggers[i])
        can_reload = true
        break
    if !can_reload
      replenishment_start_end = float2(-1.0f)
      continue

    // start replenishment delay if it havent started yet
    if replenishment_start_end.x < 0.0f
      replenishment_start_end.x = current_time + /* delay */ replenishment_time.y
      continue

    // start replenishment after a delay
    if replenishment_start_end.x >= current_time && replenishment_start_end.y < 0.0f // start after delay
      replenishment_start_end.y = replenishment_start_end.x + /* time */ replenishment_time.x * unit.loaderPenalty

    // do replenishment
    if current_time > replenishment_start_end.y
      // replenish all types of clusters
      var can_continue_replenishment = false
      assert(int(AmmoClusterType NUM_TYPES) == 2)
      var is_replenished_by_type : bool[2] = [[bool false; false]]
      for to_cluster_id in clusters_range.x..clusters_range.y
        let cluster_type = get_ammo_cluster_type(to_cluster_id, v)
        if is_replenished_by_type[cluster_type] || get_ammo_cluster_stage(to_cluster_id, v) != stage_to_replenish_to
          continue
        if !can_replenish_to_cluster(to_cluster_id, bullets_cartridge, v)
          continue
        for from_cluster_id in clusters_range.x..clusters_range.y
          if cluster_type != get_ammo_cluster_type(from_cluster_id, v) || get_ammo_cluster_stage(from_cluster_id, v) != stage_to_replenish_from
            continue
          if !can_replenish_from_cluster(from_cluster_id, bullets_cartridge, v)
            continue
          is_replenished_by_type[cluster_type] = true;
          v.ammo_clusters__numAmmo[to_cluster_id].x += bullets_cartridge
          v.ammo_clusters__numAmmo[from_cluster_id].x -= bullets_cartridge
          if can_replenish_to_cluster(to_cluster_id, bullets_cartridge, v) && can_replenish_from_cluster(from_cluster_id, bullets_cartridge, v)
            can_continue_replenishment = true
          break

      // continue replenishment, if it is available
      if can_continue_replenishment
        replenishment_start_end.x = replenishment_start_end.y
        replenishment_start_end.y += /* time */ replenishment_time.x * unit.loaderPenalty

      // sync
      sendEvent(eid, [[EventAmmoStowageSetup
        netSyncIfRequired=true,
        initNum=false,
        isRefill=false
      ]])


[es(on_event=EventOnStopBurn)]
def ammo_stowage_on_stop_burn_es(evt : Event;
                                 uid : int; active : bool;
                                 var unit_fx : UnitFx;
                                 var ammo_clusters__state : UInt32List&;
                                 ammo_clusters__fireEvtId : IntList)

  let unit = get_unit(uid)
  if !active || unit == null || unit.isDelayed || !unit.isAuthority
    return

  for state, fire_event_id in ammo_clusters__state, ammo_clusters__fireEvtId
    if !get_flag(state, AmmoClusterState FIRE_FATAL)
      unit_fx |> stopFxEvent(fire_event_id)


[es]
def ammo_stowage_cancel_replenishment_es(evt : EventAmmoStowageCancelReplenishment;
                                         var ammo_stowages__replenishmentStartEnd : Point2List&)
  for start_end in ammo_stowages__replenishmentStartEnd
    start_end.x = -1.0f
    start_end.y = -1.0f

