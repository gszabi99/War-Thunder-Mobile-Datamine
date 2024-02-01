require ecs
require Unit
require %game.utils.utils_common
require %appGame.wtm_events

[es(tag=server)]
def aircarft_carrier_unit_spawn_es(evt : CmdRequestSwitchOnSupportPlane; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> switchOnSupportPlane(evt.turnOn, evt.switchOn, evt.idx, -1 /* catapult_idx */, false)

[es(tag=server)]
def aircarft_carrier_unit_change_es(evt : CmdRequestSupportPlaneChange; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> changeSupportPlane(evt.idx)

[es(tag=server)]
def aircarft_carrier_unit_group_attack_es(evt : CmdRequestSupportPlaneGroupAttack; uid : int)
  let point = float3(0.0, 0.0, 0.0)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> supportPlaneAddCommand(evt.idx, true, -1, -1, 1, evt.targetId, point)

[es(tag=server)]
def aircarft_carrier_unit_return(evt : CmdReturnAircraftToShip; uid : int)
  let point = float3(0.0, 0.0, 0.0)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> supportPlaneAddCommand(evt.idx, true, -1, -1, 5, -1, point)