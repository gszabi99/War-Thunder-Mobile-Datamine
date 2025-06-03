require ecs
require Unit
require MPlayer
require IGroundModel
require dm
require Mission
require WTDamageModel
require %game.events
require WarShipModel
require DagorDataBlock
require DagorConsole
require %game.unit.unit_events
require %appGame.wtm_events


[es(tag=server)]
def repair_meta_parts_on_damage_es(evt : EventOnMetaPartDamage;
                                   meta_parts_hp_repair__lostMult : float;
                                   var meta_parts_hp_repair__maxHp : float&)
  let damage = rel_hp_fixed_to_float(evt.damage)
  meta_parts_hp_repair__maxHp -= damage * meta_parts_hp_repair__lostMult


[es(tag=server)]
def repair_meta_parts_init_es(evt : CmdInitComponent;
                              var unit__ref : UnitRef;
                              var meta_parts_hp_repair__duration : float&;
                              var meta_parts_hp_repair__speed : float&;
                              var meta_parts_hp_repair__maxHp : float&)
  var unit = unit__ref.unit
  let modBlk = unit.modBlk
  let durationMul = modBlk |> datablock_getReal("durationMul", 1.)
  let repairSpeedMul = modBlk |> datablock_getReal("repairSpeedMul", 1.)
  let maxHpMul = modBlk |> datablock_getReal("maxHpMul", 1.)

  meta_parts_hp_repair__duration *= durationMul
  meta_parts_hp_repair__speed *= repairSpeedMul
  meta_parts_hp_repair__maxHp *= maxHpMul


[es(tag=server, on_event = EventRepairMetaPart)]
def start_meta_parts_repair_es(evt : Event;
                               unit__ref : UnitRef;
                               var meta_parts_hp_repair__progress : float&;
                               meta_parts_hp_repair__duration : float;
                               meta_parts_hp_repair__boost : float;
                               meta_parts_hp_repair__speed : float;
                               meta_parts_hp_repair__maxHp : float;
                               var meta_parts_hp_repair__startBoost : float&;
                               var meta_parts_hp_repair__nextAtTime : float&)
  meta_parts_hp_repair__nextAtTime = float(get_total_time())
  meta_parts_hp_repair__progress = meta_parts_hp_repair__duration / meta_parts_hp_repair__boost
  meta_parts_hp_repair__startBoost = meta_parts_hp_repair__boost
  let unit = unit__ref.unit
  let hpWillBeRepaired = int(100. * min((meta_parts_hp_repair__maxHp - unit.relativeHealth), meta_parts_hp_repair__duration * meta_parts_hp_repair__speed))
  let player = unit.myPlayer
  if player != null
    broadcastEvent(EventOnPlayerRepair(userId = player.id, hpRepaired = hpWillBeRepaired))

def repair_meta_parts(var unit : Unit?;
                      repair_speed : float;
                      max_hp : float;
                      repair_interval : float) : bool
  assume unit_dm = unit.visual
  let metaPartsSize = length(unit_dm.metaParts)
  var anyMetapartNeedRepair = false
  for i in range(0, metaPartsSize)
    assume props = unit_dm.metaPartProps[i]
    assume metaPart = unit_dm.metaParts[i]

    if rel_hp_fixed_to_float(metaPart.hp) >= max_hp
      continue
    anyMetapartNeedRepair = true

    let relHpAfterRepair = min(rel_hp_fixed_to_float(metaPart.hp) + repair_speed * repair_interval, max_hp)
    metaPart |> setHp(rel_hp_float_to_fixed_ceil(relHpAfterRepair))

    for partId in props.parts
      assume part = get_damage_part_props_for_modification(unit.dmData, partId)
      part.relHpFixed = uint16(max(int(part.relHpFixed), int(metaPart.hp)))

  return anyMetapartNeedRepair

[es(tag=server, no_order)]
def repair_meta_parts_hp_es(info : UpdateStageInfoAct;
                            var unit__ref : UnitRef;
                            eid : EntityId;
                            var meta_parts_hp_repair__nextAtTime : float&;
                            var meta_parts_hp_repair__progress : float&;
                            var meta_parts_hp_repair__boost : float&;
                            var meta_parts_hp_repair__startBoost : float&;
                            meta_parts_hp_repair__interval : float;
                            meta_parts_hp_repair__speed : float;
                            meta_parts_hp_repair__maxHp : float;
                            meta_parts_hp_repair__boostVal : float;
                            meta_parts_hp_repair__timeToBoost : float;
                            meta_parts_hp_repair__earlyExit : bool;
                            var meta_parts_hp_repair__prevProgress : float&)
  var unit = unit__ref.unit
  var ship = unit |> as_ship()
  if unit.isDelayed || unit.visual == null || ship == null
    return

  meta_parts_hp_repair__boost = (info.curTime - unit.lastDamageTime) > meta_parts_hp_repair__timeToBoost ? meta_parts_hp_repair__boostVal : 1.
  let reparing = meta_parts_hp_repair__progress > 0.
  if reparing && info.curTime >= meta_parts_hp_repair__nextAtTime
    var unitDm = unit.visual


    if meta_parts_hp_repair__boost > meta_parts_hp_repair__startBoost
      meta_parts_hp_repair__progress -= meta_parts_hp_repair__progress / meta_parts_hp_repair__boost
    meta_parts_hp_repair__startBoost = meta_parts_hp_repair__boost

    meta_parts_hp_repair__nextAtTime = info.curTime + meta_parts_hp_repair__interval
    meta_parts_hp_repair__prevProgress = ship.metapartsRepairProgress

    let anyMetapartNeedRepair =  repair_meta_parts(unit,
                      meta_parts_hp_repair__speed * meta_parts_hp_repair__boost,
                      meta_parts_hp_repair__maxHp,
                      meta_parts_hp_repair__interval)

    if !meta_parts_hp_repair__earlyExit || anyMetapartNeedRepair
      meta_parts_hp_repair__progress = max(meta_parts_hp_repair__progress - meta_parts_hp_repair__interval, 0.f)
    else
      meta_parts_hp_repair__progress = 0.

    *ship |> set_repair_progress(meta_parts_hp_repair__progress)
    if ship.metapartsRepairProgress <= 0. && meta_parts_hp_repair__prevProgress > 0.
      *ship |> set_repair_cooldown()
      if unit.moduleEffectBuffer != null
        *unit.moduleEffectBuffer |> onRepair()
        var gm = unit |> as_gm()
        if gm != null && gm.autoExtinguisherWithToolkit
          sendEvent(eid, CmdStopBurn())
  if reparing
    *unit |> cacheUnitRelativeHealth()
    sendEvent(eid, CmdUpdateRelativeUnitHealth())

[es(tag=netClient, REQUIRE=(controlledHero), no_order)]
def repair_meta_parts_hp_client_es(info : UpdateStageInfoAct;
                                   var unit__ref : UnitRef;
                                   var meta_parts_hp_repair__prevProgress : float&)
  var unit = unit__ref.unit
  var ship = unit |> as_ship()
  if unit.isDelayed || unit.visual == null || ship == null
    return

  if ship.metapartsRepairProgress <= 0. && meta_parts_hp_repair__prevProgress > 0.
    *ship |> set_repair_cooldown()
  meta_parts_hp_repair__prevProgress = ship.metapartsRepairProgress
