options no_aot

require app
require DagorImgui
require imgui/imgui_boost
require daslib/strings_boost


[imgui_window(name="Time", group="General")]
def time_window()
  if IsWindowCollapsed()
    return
  let timeScales <- fixed_array(0.0, 0.01, 0.1, 0.25, 0.5, 1.0, 2.0, 4.0, 10.0, 20.0)
  let timeScalesCaptions <- fixed_array("0", ".01", ".1", ".25", ".5", "1", "2", "4", "10", "20")
  imgui::TextUnformatted("sync time: {get_sync_time():.2f} (x{get_timespeed():.2f})")
  imgui::Text("x:")
  for scale, caption in timeScales, timeScalesCaptions
    SameLine()
    let sF = caption
    if imgui::Button("{sF}##timeScale")
      set_timespeed(scale)
