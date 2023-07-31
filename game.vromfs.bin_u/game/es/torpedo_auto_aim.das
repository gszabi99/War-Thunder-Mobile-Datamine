require ecs
require math
require Unit
require Weapon
require WarShipModel
require Ballistics
require DagorMathUtils
require WTNetUnit
require %dasGameLibs.math.base
require %game.utils.utils_common
require %game.events

def torpedo_auto_aim_impl(var weapon; target; uid : int; is_unit_submarine : bool; unit_vel : float3)
  get_unit_for_edit(uid) <| $(var unit)
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
    let maxDiveDepth = shipTarget != null && target.isSubmarine ? shipTarget.periscopeDepth : weapon.prop.diveDepth;
    weapon.aimDepth = target.isSubmarine || is_unit_submarine ? clamp(-targetPos.y, weapon.prop.diveDepth, maxDiveDepth) : -1.

[es(tag=server, REQUIRE=enableTorpedoAutoAim)]
def torpedo_auto_aim(evt : EventOnStartShooting; uid : int)
  get_unit_with_target(uid) <| $(unit, target)
    var weapon = unit.weap.Weapons |> get_weapon(evt.weaponIdx)
    if weapon != null && weapon.isTorpedoGun
      weapon |> torpedo_auto_aim_impl(target, uid, unit.isSubmarine, unit.vel)

[es(tag=server)]
def torpedo_auto_aim_aircraft(evt : EventOnStartShooting;
                              aircarft__ownerId : int;
                              uid : int;
                              net_unit : ECSNetUnit;
                              weapon_controller : WeaponController)
  get_unit_target(aircarft__ownerId) <| $(target)
    var weapon = weapon_controller.Weapons |> get_weapon(evt.weaponIdx)
    if weapon != null && weapon.isTorpedoGun
      let emitterNo = weapon.emitterNo
      var shootTm : float3x4
      weapon |> weapon_calcShootTm(net_unit.tm, true, emitterNo, true, shootTm)
      weapon.startShootingPos = float3(shootTm[3].x, 0., shootTm[3].z)

      weapon |> torpedo_auto_aim_impl(target, uid, false, net_unit.phys.currentState.velocity)

[es(tag=server, REQUIRE=enableTorpedoAutoAim, no_order)]
def torpedo_guns_to_target(info : UpdateStageInfoAct;
                           uid : int;
                           var torpedo_auto_aim__targetAngles : float2&)
  get_unit_for_edit_with_target(uid) <| $(var unit; target)
    let dirToTarget    = normalize(target.unitTm[3] - unit.unitTm[3])
    let relDirToTarget = rotate(inverse(unit.unitTm), dirToTarget)

    torpedo_auto_aim__targetAngles = rad_to_deg(dir_to_angles(relDirToTarget))

[es(tag=gameClient, REQUIRE=enableTorpedoAutoAim, after=torpedo_guns_to_target)]
def torpedo_guns_to_target_client(info : UpdateStageInfoAct;
                                  uid : int;
                                  torpedo_auto_aim__targetAngles : float2)
  get_unit_for_edit(uid) <| $(var unit)
    if unit.weap != null
      foreach_torpedo_gun(unit.weap.Weapons) <| $(var weapon)
        assume turret = unit.weap.turret[weapon.turretNo]
        turret.yawLim   = torpedo_auto_aim__targetAngles.x
        turret.pitchLim = torpedo_auto_aim__targetAngles.y
        turret.yawDstWithoutLimit   = torpedo_auto_aim__targetAngles.x
        turret.pitchDstWithoutLimit = torpedo_auto_aim__targetAngles.y
