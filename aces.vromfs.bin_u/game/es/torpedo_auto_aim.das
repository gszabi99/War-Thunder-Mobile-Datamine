require ecs
require math
require Unit
require Weapon
require WarShipModel
require WTBallistics
require DagorMathUtils
require WTNetUnit
require %dasGameLibs.math.base
require %game.utils.utils_common
require %game.events

def torpedo_auto_aim_impl(var weapon; target; unit : Unit?; is_unit_submarine : bool; unit_vel : float3)
  let targetPos = target.unitTm * unit.torpedoAimOffset
  let targetVel = target.vel

  let maxDistance = min(weapon.prop.distToLive, length(targetPos - weapon.startShootingPos))

  let impactPos = calc_torpedo_impact_with_target(weapon.startShootingPos, unit_vel, as_base_gun(weapon),
                                                  targetPos, targetVel, maxDistance)
  weapon.startShootingDir = impactPos - weapon.startShootingPos
  weapon.startShootingDir.y = 0.
  weapon.startShootingDir = normalize(weapon.startShootingDir)
  weapon.isStartShootingValid = true
  var shipTarget = target |> as_ship()
  let maxDiveDepth = shipTarget != null && target.isSubmarine ? shipTarget.periscopeDepth : weapon.prop.diveDepth
  weapon.aimDepth = target.isSubmarine || is_unit_submarine ? clamp(-targetPos.y, weapon.prop.diveDepth, maxDiveDepth) : -1.

[es(tag=server, REQUIRE=enableTorpedoAutoAim)]
def torpedo_auto_aim(evt : EventOnStartShooting; var unit__ref : UnitRef)
  let unit = unit__ref.unit
  let target = get_unit_target(unit)
  var weapon = unit.weap.Weapons |> get_weapon(evt.weaponIdx)
  if target != null && weapon != null && weapon.isTorpedoGun
    weapon |> torpedo_auto_aim_impl(target, unit, unit.isSubmarine, unit.vel)

[es(tag=server, REQUIRE=enableTorpedoAutoAim, no_order)]
def torpedo_guns_to_target(info : UpdateStageInfoAct;
                           var unit__ref : UnitRef;
                           var torpedo_auto_aim__targetAngles : float2&)
  var unit = unit__ref.unit
  var target = get_unit_target(unit)
  if target != null
    let dirToTarget    = normalize(target.unitTm[3] - unit.unitTm[3])
    let relDirToTarget = rotate(inverse(unit.unitTm), dirToTarget)
    torpedo_auto_aim__targetAngles = rad_to_deg(dir_to_angles(relDirToTarget))

[es(tag=gameClient, REQUIRE=enableTorpedoAutoAim, after=torpedo_guns_to_target)]
def torpedo_guns_to_target_client(info : UpdateStageInfoAct;
                                  var unit__ref : UnitRef;
                                  torpedo_auto_aim__targetAngles : float2)
  var unit = unit__ref.unit
  var target = get_unit_target(unit)
  if unit.weap != null && target != null
    foreach_torpedo_gun(unit.weap.Weapons) <| $(var weapon)
      assume turret = unit.weap.turret[weapon.turretNo]
      turret.yawLim   = torpedo_auto_aim__targetAngles.x
      turret.pitchLim = torpedo_auto_aim__targetAngles.y
      turret.yawDstWithoutLimit   = torpedo_auto_aim__targetAngles.x
      turret.pitchDstWithoutLimit = torpedo_auto_aim__targetAngles.y
