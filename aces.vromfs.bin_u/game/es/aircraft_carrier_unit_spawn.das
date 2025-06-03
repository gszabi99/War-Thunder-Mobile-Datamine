require ecs
require Unit
require %game.utils.utils_common
require %appGame.wtm_events
require math.base

[es(tag=server)]
def aircarft_carrier_unit_spawn_es(evt : CmdRequestSwitchOnSupportPlane; var unit__ref : UnitRef)
  *unit__ref.unit |> switchOnSupportPlane(evt.turnOn, evt.switchOn, evt.idx, -1 , false, IDENT_TM)

[es(tag=server)]
def aircarft_carrier_unit_change_es(evt : CmdRequestSupportPlaneChange; var unit__ref : UnitRef)
  *unit__ref.unit |> changeSupportPlane(evt.idx)

[es(tag=server)]
def aircarft_carrier_unit_group_attack_es(evt : CmdRequestSupportPlaneGroupAttack; var unit__ref : UnitRef)
  let point = float3(0.0, 0.0, 0.0)
  *unit__ref.unit |> supportPlaneAddCommand(evt.idx, true, -1, -1, 1, evt.targetId, point)

[es(tag=server)]
def aircarft_carrier_unit_return(evt : CmdReturnAircraftToShip; var unit__ref : UnitRef)
  *unit__ref.unit |> supportPlaneRemoveCommand(evt.idx, -1, true)