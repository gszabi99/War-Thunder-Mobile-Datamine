options no_aot = true//since this is merely loader
require ecs
require app
require DagorSystem
require %dasGameLibs.ecs.fs
require %game.wt_scripts_init

[init]
def load
  var ok = true

  ok = load_wt_scripts("%game") && ok
  ok = load_folder("%appGame/es") && ok

  print("Das scripts are loaded")
  if !ok
    logerr("Das scripts loading failed")