from "%rGui/controls/shortcutConsts.nut" import *

let axisHotkey = {
  [JOY_XBOX_REAL_AXIS_L_THUMB_H] = "J:LS",
  [JOY_XBOX_REAL_AXIS_L_THUMB_V] = "J:LS",
  [JOY_XBOX_REAL_AXIS_R_THUMB_H] = "J:RS",
  [JOY_XBOX_REAL_AXIS_R_THUMB_V] = "J:RS",
  [JOY_XBOX_REAL_AXIS_L_TRIGGER] = "J:LT",
  [JOY_XBOX_REAL_AXIS_R_TRIGGER] = "J:RT",
  [JOY_XBOX_REAL_AXIS_LR_TRIGGER] = "J:LT | J:RT",
}

let axisHotkeyMin = {
  [JOY_XBOX_REAL_AXIS_L_THUMB_H] = "J:LS.Left",
  [JOY_XBOX_REAL_AXIS_L_THUMB_V] = "J:LS.Up",
  [JOY_XBOX_REAL_AXIS_R_THUMB_H] = "J:RS.Left",
  [JOY_XBOX_REAL_AXIS_R_THUMB_V] = "J:RS.Up",
  [JOY_XBOX_REAL_AXIS_LR_TRIGGER] = "J:LT",
}

let axisHotkeyMax = {
  [JOY_XBOX_REAL_AXIS_L_THUMB_H] = "J:LS.Right",
  [JOY_XBOX_REAL_AXIS_L_THUMB_V] = "J:LS.Down",
  [JOY_XBOX_REAL_AXIS_R_THUMB_H] = "J:RS.Right",
  [JOY_XBOX_REAL_AXIS_R_THUMB_V] = "J:RS.Down",
  [JOY_XBOX_REAL_AXIS_LR_TRIGGER] = "J:RT",
}

return {
  
  axisToHotkey = @(a) axisHotkey?[a]
  axisMinToHotkey = @(a) axisHotkeyMin?[a] ?? axisHotkey?[a]
  axisMaxToHotkey = @(a) axisHotkeyMax?[a] ?? axisHotkey?[a]
}