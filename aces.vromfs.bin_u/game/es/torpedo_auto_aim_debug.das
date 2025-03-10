options no_aot
require ecs
require Unit
require DagorMath
require DagorDebug3D
require %game.utils.utils_common

[es(tag=gameClient, REQUIRE=enableTorpedoAutoAim)]
def torpedo_guns_to_target_debug(info : UpdateStageInfoRenderDebug; var unit__ref : UnitRef)
  var unit = unit__ref.unit
  begin_draw_cached_debug_lines(false, false, false)

  draw_cached_debug_sphere(unit.unitTm[3], 5.0, E3DCOLOR(0xFFFF0000), 24)

  foreach_torpedo_gun(unit.weap.Weapons) <| $(var weapon)
    var tm : float3x4
    weapon |> weapon_calcShootTm(unit.unitTm, tm)

    draw_cached_debug_sphere(tm[3], 1.0, E3DCOLOR(0xFF00FF00), 24)
    let to = tm[3] + 10.f * tm[0]
    draw_cached_debug_line(tm[3], to, E3DCOLOR(0xFF0000FF))

  end_draw_cached_debug_lines()
