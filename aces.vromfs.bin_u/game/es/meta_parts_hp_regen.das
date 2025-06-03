require ecs
require Unit
require dm
require Mission
require WTDamageModel
require %game.events

[es(tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def regen_meta_parts_hp_init_es(evt : Event;
                                meta_parts_hp_regen__limit : float;
                                var meta_parts_hp_regen__limitFixed : uint16&)
  meta_parts_hp_regen__limitFixed = rel_hp_float_to_fixed_ceil(meta_parts_hp_regen__limit)

[es(tag=server)]
def regen_meta_parts_hp_delay_es(evt : EventOnMetaPartDamage;
                                 meta_parts_hp_regen__delayAfterDamage : float;
                                 var meta_parts_hp_regen__nextAtTime : float&)
  meta_parts_hp_regen__nextAtTime = float(get_total_time()) + meta_parts_hp_regen__delayAfterDamage

[es(tag=server)]
def regen_meta_parts_hp_es(info : UpdateStageInfoAct;
                           var unit__ref : UnitRef;
                           eid : EntityId;
                           var meta_parts_hp_regen__nextAtTime : float&;
                           meta_parts_hp_regen__interval : float;
                           meta_parts_hp_regen__speed : float;
                           meta_parts_hp_regen__limitFixed : uint16)
  var unit = unit__ref.unit
  if unit.isDelayed || unit.visual == null || meta_parts_hp_regen__speed <= 0.
    return

  if info.curTime < meta_parts_hp_regen__nextAtTime
    return

  meta_parts_hp_regen__nextAtTime = info.curTime + meta_parts_hp_regen__interval

  var unitDm = unit.visual
  let metaPartsSize = length(unitDm.metaParts)

  for i in range(0, metaPartsSize)
    assume props = unitDm.metaPartProps[i]
    assume metaPart = unitDm.metaParts[i]

    if int(metaPart.hp) >= int(meta_parts_hp_regen__limitFixed)
      continue

    let relHpAfterRegen = min(rel_hp_fixed_to_float(metaPart.hp) + meta_parts_hp_regen__speed, 1.)
    metaPart |> setHp(rel_hp_float_to_fixed_ceil(relHpAfterRegen))

    for partId in props.parts
      assume part = get_damage_part_props_for_modification(unit.dmData, partId)
      part.relHpFixed = uint16(max(int(part.relHpFixed), int(metaPart.hp)))

  sendEvent(eid, CmdUpdateRelativeUnitHealth())
