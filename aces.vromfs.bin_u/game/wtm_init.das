options no_aot = true//since this is merely loader
require %game.events
require %appGame.wtm_events
require ecs
require app
require DagorSystem

def is_pc()
  let platformId = get_platform_string_id()
  return platformId == "win32" || platformId == "win64" || platformId == "linux32" || platformId == "linux64" || platformId == "macosx"

[init]
def load
  var ok = true
  if app::get_game_name() == "aot" || (get_DAGOR_DBGLEVEL() > 0 && is_pc() && find_index(get_command_line_arguments(), "--das-no-linter") == -1)
    ok = load_das_linter("%game/linter/linter.das") && ok
  if app::get_game_name() == "aot"
    assert(ok)
