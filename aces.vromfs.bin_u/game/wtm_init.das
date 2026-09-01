options no_aot = true
require %game.events
require %appGame.wtm_events
require ecs
require app
require DagorSystem

[init]
def load
  var ok = true
  if is_in_aot() || (get_DAGOR_DBGLEVEL() > 0 && get_TARGET_PC() != 0 && find_index(get_command_line_arguments(), "--das-no-linter") == -1)
    ok = load_das_linter("%game/linter/linter.das") && ok
  if is_in_aot()
    assert(ok)
