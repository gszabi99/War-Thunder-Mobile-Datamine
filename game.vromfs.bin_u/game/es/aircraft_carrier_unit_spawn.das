require ecs
require Unit
require %game.utils.utils_common
require %appGame.wtm_events

[es(tag=server)]
def aircarft_carrier_unit_spawn_es(evt : CmdRequestSwitchOnSupportPlane; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> switchOnSupportPlane(evt.turnOn, evt.idx, -1 /* catapult_idx */, false)


[es(tag=server)]
def aircarft_carrier_unit_change_es(evt : CmdRequestSupportPlaneChange; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> changeSupportPlane(evt.idx)

[es(tag=server)]
def aircarft_carrier_unit_group_attack_es(evt : CmdRequestSupportPlaneGroupAttack; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> supportPlaneAttackOrder(evt.idx, evt.targetId, evt.attack)

[es(tag=server)]
def aircarft_carrier_unit_return(evt : CmdReturnAircraftToShip; uid : int)
  get_unit_for_edit(uid) <| $(var unit)
    *unit |> supportPlaneReturnOrder(evt.idx, evt.rtb)