require ecs
require app
require net
require dm
require DagorRandom
require DagorMath
require Unit
require WTDamageModel
require %game.utils.component_bundle_macro
require %game.dm.fire_system_events
require %game.dm.fire_system_common
require %game.unit.unit_events
require %game.unit.extinguish_system_common
require %game.events


[es(no_order)]
def fire_damage_init_es(evt : CmdInitComponent; var fire_damage__updateBurnInterval : float&)
  fire_damage__updateBurnInterval = get_game_params().updateBurnInterval


[es(tag=server, no_order), with_bundle(v)]
def fire_damage_update_es(act : UpdateStageInfoAct;
                          eid : EntityId;
                          v : tuple<
                            fire_system_require_net_sync : bool -const;
                            fire_damage__nextUpdateTime : float -const;
                            fire_damage__updateBurnInterval : float;
                            fire_damage__isBurn : bool;
                            fire_data__packedPartId : UInt32List;
                            fire_data__nodeId : IntList;
                            fire_data__fireParamsId : IntList;
                            fire_data__offset : Point3List;
                            fire_data__radius : Point2List;
                            fire_data__initiatorId : UInt32List -const;
                            fire_data__startTime : FloatList -const;
                            fire_data__underwaterTimer : FloatList -const
                            >)
  if !v.fire_damage__isBurn
    return

  let now_burning = check_is_burning(v)
  if !now_burning
    sendEventImmediate(eid, [[CmdStopBurn]])

  let at_time = float(get_app().usefulTotalTime)
  let seed = grnd()

  // update fire damage
  if v.fire_damage__nextUpdateTime < act.curTime
    v.fire_damage__nextUpdateTime = act.curTime + v.fire_damage__updateBurnInterval
    for id, start_time, fire_params_id, packed_part_id, initiator_id in iter_range(v.fire_data__startTime), v.fire_data__startTime, v.fire_data__fireParamsId, v.fire_data__packedPartId, v.fire_data__initiatorId
      if start_time <= 0.0f
        continue

      let fire_params = get_fire_params(fire_params_id)
      if fire_params != null && act.curTime > start_time + fire_params.maxFireTime.y && gfrnd() < fire_params.extinguishChance
        fire_system_stop_single_burn(eid, id, v)
        v.fire_system_require_net_sync = true
        continue

      let sph = fire_system_get_fire_sphere(id, at_time, v)
      sendEvent(eid, [[EventOnBurnDamageToPart
        fireId=id,
        packedPartId=packed_part_id,
        fireParamsId=fire_params_id,
        initiatorId=initiator_id,
        seed=seed,
        sph = float4(sph.c.x, sph.c.y, sph.c.z, sph.r),
        atTime = act.curTime
      ]])

  // update underwater (this used to update only when extinguisher was not active, but it does not seem to be reasonable)
  for id, start_time, underwater_timer, fire_params_id, node_id in iter_range(v.fire_data__startTime), v.fire_data__startTime, v.fire_data__underwaterTimer, v.fire_data__fireParamsId, v.fire_data__nodeId
    if start_time < 0.0f
      continue
    let sph = fire_system_get_fire_sphere(id, at_time) <| v
    let is_underwater = is_fire_emitter_underwater(eid, fire_params_id, node_id, sph)
    if is_underwater
      if underwater_timer <= 0.0f
        underwater_timer = get_fire_params(fire_params_id).underwaterExtinguishTime
    else
      underwater_timer = -1.0f

    if underwater_timer > 0.0f
      underwater_timer -= act.dt
      if underwater_timer <= 0.0f
        fire_system_stop_single_burn(eid, id) <| v
        v.fire_system_require_net_sync = true

[with_bundle(v)]
def fire_damage_process_start_burn_event(eid : EntityId;
                                         unit : Unit?;
                                         part_id : PartId;
                                         fire_params_id : int;
                                         fire_fx_id : int;
                                         offender : OffenderData;
                                         pos : float4;
                                         var v : tuple<
                                           fire_damage__isBurn : bool;
                                           fire_data__packedPartId : UInt32List;
                                           fire_data__nodeId : IntList;
                                           fire_data__fireParamsId : IntList;
                                           fire_data__offset : Point3List;
                                           fire_data__radius : Point2List;
                                           fire_data__initiatorId : UInt32List;
                                           fire_data__startTime : FloatList;
                                           fire_data__extinguishProgress : FloatList;
                                           fire_data__underwaterTimer : FloatList
                                           >)
  if unit.visual == null
    return
  assume dm = *unit.visual
  let geom_node_id = part_id.valid ? dm_get_geom_node_id_by_part_id(dm, int(part_id.globalId)) : INVALID_GEOM_NODE_ID
  let coll_node = dm_get_collision_node_by_part_id(dm, int(part_id.globalId))
  if coll_node == null
    return

  let fire_params = get_fire_params(fire_params_id)
  if fire_params == null || fire_params.damage <= 0.0f
    return

  let radius : tuple<radius : float; final_radius : float> = fire_system_calc_burn_radius(*fire_params, coll_node.boundingSphere, unit.collisionData.boundingSphere.r)
  var offset : float3
  if pos != float4(0.0f) && unit.collNodeTree != null && (fire_params.allowMultipleFires || fire_params.allowMultipleFx)
    offset = fire_system_calc_burn_offset(*fire_params, coll_node.boundingSphere, *unit.collNodeTree, geom_node_id, float3(pos.x, pos.y, pos.z))
  else
    offset = coll_node.boundingSphere.c

  let at_time = float(get_app().usefulTotalTime)
  let fire_id = fire_system_start_single_burn(eid, [[StartSingleBurnDesc()
    partId=part_id,
    nodeId=geom_node_id,
    fireParamsId=fire_params_id,
    fireFxId=fire_fx_id,
    offset=offset,
    centerDmgPart=coll_node.tm * coll_node.modelBBox.center,
    radius=radius.radius,
    finalRadius=radius.final_radius,
    atTime=at_time,
    initiatorId=offender |> get_bullet_uid()
  ]]) <| v

  if fire_id >= 0 && !v.fire_damage__isBurn
    v.fire_damage__isBurn = true
    let sph = fire_system_get_fire_sphere(fire_id, at_time) <| v
    sendEvent(eid, [[EventFireSystemStartBurning
      offender=offender,
      partId=part_id,
      sph = float4(sph.c.x, sph.c.y, sph.c.z, sph.r)
    ]])


[es, with_bundle(v)]
def fire_damage_start_burn_with_offender(evt : EventFireSystemStartBurnWithOffender;
                                         eid : EntityId;
                                         var unit__ref : UnitRef;
                                         var v : tuple<
                                           fire_data__packedPartId : UInt32List;
                                           fire_data__nodeId : IntList;
                                           fire_data__fireParamsId : IntList;
                                           fire_data__offset : Point3List;
                                           fire_data__radius : Point2List;
                                           fire_data__initiatorId : UInt32List;
                                           fire_data__startTime : FloatList;
                                           fire_data__extinguishProgress : FloatList;
                                           fire_data__underwaterTimer : FloatList;
                                           fire_damage__isBurn : bool;
                                           extinguish_system_last_extinguish_time : float const;
                                           fire_system_require_net_sync : bool;
                                           ammo_slots__state : UInt32List const;
                                           ammo_stowage__partIdRemap : IPoint4List const
                                           >)
  if !extinguish_system_can_reignite(v.extinguish_system_last_extinguish_time)
    return
  let unit = unit__ref.unit
  if unit.isDelayed
    return
  if !fire_system_can_part_burn(evt.partId, v)
    return
  fire_damage_process_start_burn_event(eid, unit,
                                       evt.partId, evt.fireParamsId, evt.fireFxId, evt.offender, float4(0.0f)) <| v
  v.fire_system_require_net_sync = true


[es(tag=server), with_bundle(v)]
def fire_damage_start_burn_with_offender_in_pos(evt : EventFireSystemStartBurnWithOffenderInPos;
                                                eid : EntityId;
                                                var unit__ref : UnitRef;
                                                var v : tuple<
                                                  fire_data__packedPartId : UInt32List;
                                                  fire_data__nodeId : IntList;
                                                  fire_data__fireParamsId : IntList;
                                                  fire_data__offset : Point3List;
                                                  fire_data__radius : Point2List;
                                                  fire_data__initiatorId : UInt32List;
                                                  fire_data__startTime : FloatList;
                                                  fire_data__extinguishProgress : FloatList;
                                                  fire_data__underwaterTimer : FloatList;
                                                  fire_damage__isBurn : bool;
                                                  extinguish_system_last_extinguish_time : float const;
                                                  fire_system_require_net_sync : bool;
                                                  ammo_slots__state : UInt32List const;
                                                  ammo_stowage__partIdRemap : IPoint4List const
                                                  >)
  if !extinguish_system_can_reignite(v.extinguish_system_last_extinguish_time)
    return
  let unit = unit__ref.unit
  if unit.isDelayed
    return
  if !fire_system_can_part_burn(evt.partId, v)
    return
  fire_damage_process_start_burn_event(eid, unit,
                                       evt.partId, evt.fireParamsId, evt.fireFxId, evt.offender, float4(evt.pos.x, evt.pos.y, evt.pos.z, 1.0f)
                                       ) <| v
  v.fire_system_require_net_sync = true


[es, with_bundle(v)]
def fire_damage_stop_burn_es(evt : CmdStopBurn;
                             eid : EntityId;
                             var v : tuple<
                               fire_data__packedPartId : UInt32List;
                               fire_data__nodeId : IntList;
                               fire_data__fireParamsId : IntList;
                               fire_data__offset : Point3List;
                               fire_data__radius : Point2List;
                               fire_data__initiatorId : UInt32List;
                               fire_data__startTime : FloatList;
                               fire_data__extinguishProgress : FloatList;
                               fire_data__underwaterTimer : FloatList;
                               fire_system_require_net_sync : bool;
                               fire_damage__isBurn : bool
                               >)
  sendEvent(eid, [[EventOnStopBurn wasBurning=v.fire_damage__isBurn]])
  v.fire_data__packedPartId |> clear()
  v.fire_data__nodeId |> clear()
  v.fire_data__fireParamsId |> clear()
  v.fire_data__offset |> clear()
  v.fire_data__radius |> clear()
  v.fire_data__initiatorId |> clear()
  v.fire_data__startTime |> clear()
  v.fire_data__extinguishProgress |> clear()
  v.fire_data__underwaterTimer |> clear()
  v.fire_damage__isBurn = false
  v.fire_system_require_net_sync = true


[es]
def fire_system_repair_es(evt : EventUnitRepair; eid : EntityId)
  sendEventImmediate(eid, [[CmdStopBurn]])


[es]
def fire_system_respawn_es(evt : EventUnitRespawn; eid : EntityId)
  sendEventImmediate(eid, [[CmdStopBurn]])


// -------------------------------- fire net sync --------------------------------------

[es(after=fire_damage_update_es, tag=server), with_bundle(v)]
def fire_system_net_sync_update_es(act : UpdateStageInfoAct;
                                   eid : EntityId;
                                   v : tuple<
                                     fire_data__packedPartId : UInt32List;
                                     fire_data__fireParamsId : IntList;
                                     fire_data__startTime : FloatList;
                                     fire_system_require_net_sync : bool -const;
                                     fire_damage__isBurn : bool
                                     >)
  if !v.fire_system_require_net_sync
    return
  v.fire_system_require_net_sync = false

  using() <| $(var data : IntList)
    data |> reserve(length(v.fire_data__packedPartId) * 2)
    for start_time, packed_part_id, fire_params_id in v.fire_data__startTime, v.fire_data__packedPartId, v.fire_data__fireParamsId
      let is_burning = start_time >= 0.0f
      if is_burning
        data |> push(int(packed_part_id))
        data |> push(fire_params_id)

    send_net_event(eid, [[EventFireSystemNetSync
      isBurning = v.fire_damage__isBurn,
      data=ecs_addr(data)
    ]])


[es(tag=netClient), with_bundle(v)]
def fire_system_net_sync_handle_es(evt : EventFireSystemNetSync;
                                   eid : EntityId;
                                   var v : tuple<
                                     fire_data__packedPartId : UInt32List;
                                     fire_data__nodeId : IntList;
                                     fire_data__fireParamsId : IntList;
                                     fire_data__offset : Point3List;
                                     fire_data__radius : Point2List;
                                     fire_data__initiatorId : UInt32List;
                                     fire_data__startTime : FloatList;
                                     fire_data__extinguishProgress : FloatList;
                                     fire_data__underwaterTimer : FloatList;
                                     fire_damage__isBurn : bool -const
                                     >)
  let total_time = float(get_app().usefulTotalTime)
  let was_burning = v.fire_damage__isBurn;
  v.fire_damage__isBurn = evt.isBurning;

  if !was_burning && evt.isBurning
    sendEvent(eid, [[EventFireSystemOnStartBurn offender=[[OffenderData]]]])
  elif was_burning && !evt.isBurning
    sendEvent(eid, [[CmdStopBurn]])

  var burning_parts : array<tuple<packed_part_id : uint; fire_params_id : int; already_burning : bool>>
  burning_parts |> reserve(length(*evt.data) / 2)
  for i in range(0, length(*evt.data) / 2)
    let packed_part_id = uint((*evt.data)[i * 2])
    let fire_params_id = (*evt.data)[i * 2 + 1]
    burning_parts |> push([[auto packed_part_id, fire_params_id, false]])

  for fire_id, packed_part_id in iter_range(v.fire_data__packedPartId), v.fire_data__packedPartId
    var fire_found = false
    for part in burning_parts
      if packed_part_id == part.packed_part_id
        fire_found = true
        part.already_burning = true
        break
    if !fire_found
      fire_system_stop_single_burn(eid, fire_id, v)

  for part in burning_parts
    if !part.already_burning
      fire_system_start_single_burn(eid, [[StartSingleBurnDesc()
        partId = unpack_part_id(part.packed_part_id),
        nodeId = INVALID_GEOM_NODE_ID,
        fireParamsId = part.fire_params_id,
        fireFxId = -1,
        offset = float3(0.0f),
        centerDmgPart = float3(0.0f),
        radius = 0.0f,
        finalRadius = 0.0f,
        atTime = total_time,
        initiatorId = -1u
      ]]) <| v
