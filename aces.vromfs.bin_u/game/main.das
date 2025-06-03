options no_aot = true
require ecs
require app
require DagorSystem
require ECSGlobalTags
require %dasGameLibs.ecs.fs
require %game.wt_scripts_init
require %danetlibs.imgui_daeditor.imgui_daeditor_init

[init]
def load
  var ok = true

  ok = load_wt_scripts("%game") && ok
  ok = load_folder("%appGame/es") && ok
  ok = load_imgui_daeditor("%danetlibs/imgui_daeditor") && ok
  if ecs_has_tag("sound") || is_in_aot()
    ok = load_folder("%game/sound") && ok
  if ecs_has_tag("input") || is_in_aot()
    ok = load_folder("%game/input") && ok
    ok = load_folder("%appGame/es/input") && ok

  print("Das scripts are loaded")
  if !ok
    logerr("Das scripts loading failed")