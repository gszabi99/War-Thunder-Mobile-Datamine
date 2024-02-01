from "%globalsDarg/darg_library.nut" import *

let defHeightMul = 1.35
let commonHeightMuls = {
  BTN_A = 1
  BTN_A_PRESSED = 1
  BTN_B = 1
  BTN_B_PRESSED = 1
  BTN_X = 1
  BTN_X_PRESSED = 1
  BTN_Y = 1
  BTN_Y_PRESSED = 1
}

let xone = {
  BTN_A                    = "xone_button_a"
  BTN_A_PRESSED            = "xone_button_a_pressed"
  BTN_B                    = "xone_button_b"
  BTN_B_PRESSED            = "xone_button_b_pressed"
  BTN_X                    = "xone_button_x"
  BTN_X_PRESSED            = "xone_button_x_pressed"
  BTN_Y                    = "xone_button_y"
  BTN_Y_PRESSED            = "xone_button_y_pressed"

  BTN_DIRPAD               = "xone_dirpad"
  BTN_DIRPAD_DOWN          = "xone_dirpad_down"
  BTN_DIRPAD_LEFT          = "xone_dirpad_left"
  BTN_DIRPAD_RIGHT         = "xone_dirpad_right"
  BTN_DIRPAD_UP            = "xone_dirpad_up"

  BTN_BACK                 = "xone_button_back"
  BTN_BACK_PRESSED         = "xone_button_back_pressed"
  BTN_START                = "xone_button_start"
  BTN_START_PRESSED        = "xone_button_start_pressed"

  BTN_LB                   = "xone_l_shoulder"
  BTN_LB_PRESSED           = "xone_l_shoulder_pressed"
  BTN_RB                   = "xone_r_shoulder"
  BTN_RB_PRESSED           = "xone_r_shoulder_pressed"
  BTN_LT                   = "xone_l_trigger"
  BTN_LT_PRESSED           = "xone_l_trigger_pressed"
  BTN_RT                   = "xone_r_trigger"
  BTN_RT_PRESSED           = "xone_r_trigger_pressed"

  BTN_LS                   = "xone_l_stick"
  BTN_LS_PRESSED           = "xone_l_stick_pressed"
  BTN_LS_ANY               = "xone_l_stick_4"
  BTN_LS_UP                = "xone_l_stick_up"
  BTN_LS_DOWN              = "xone_l_stick_down"
  BTN_LS_LEFT              = "xone_l_stick_left"
  BTN_LS_RIGHT             = "xone_l_stick_right"
  BTN_LS_HOR               = "xone_l_stick_to_left_n_right"
  BTN_LS_VER               = "xone_l_stick_to_up_n_down"

  BTN_RS                   = "xone_r_stick"
  BTN_RS_PRESSED           = "xone_r_stick_pressed"
  BTN_RS_ANY               = "xone_r_stick_4"
  BTN_RS_UP                = "xone_r_stick_up"
  BTN_RS_DOWN              = "xone_r_stick_down"
  BTN_RS_LEFT              = "xone_r_stick_left"
  BTN_RS_RIGHT             = "xone_r_stick_right"
  BTN_RS_HOR               = "xone_r_stick_to_left_n_right"
  BTN_RS_VER               = "xone_r_stick_to_up_n_down"

  defHeightMul
  heightMuls = commonHeightMuls.__merge({
    BTN_LS = 1.2
    BTN_RS = 1.2
  })
}

let sony = {
  BTN_A                    = "ps_button_a"
  BTN_A_PRESSED            = "ps_button_a_pressed"
  BTN_B                    = "ps_button_b"
  BTN_B_PRESSED            = "ps_button_b_pressed"
  BTN_X                    = "ps_button_x"
  BTN_X_PRESSED            = "ps_button_x_pressed"
  BTN_Y                    = "ps_button_y"
  BTN_Y_PRESSED            = "ps_button_y_pressed"

  BTN_DIRPAD               = "ps_dirpad"
  BTN_DIRPAD_DOWN          = "ps_dirpad_down"
  BTN_DIRPAD_LEFT          = "ps_dirpad_left"
  BTN_DIRPAD_RIGHT         = "ps_dirpad_right"
  BTN_DIRPAD_UP            = "ps_dirpad_up"

  BTN_BACK                 = "ps_button_back"
  BTN_BACK_PRESSED         = "ps_button_back_pressed"
  BTN_START                = "ps_button_start"
  BTN_START_PRESSED        = "ps_button_start_pressed"

  BTN_LB                   = "ps_l_shoulder"
  BTN_LB_PRESSED           = "ps_l_shoulder_pressed"
  BTN_RB                   = "ps_r_shoulder"
  BTN_RB_PRESSED           = "ps_r_shoulder_pressed"
  BTN_LT                   = "ps_l_trigger"
  BTN_LT_PRESSED           = "ps_l_trigger_pressed"
  BTN_RT                   = "ps_r_trigger"
  BTN_RT_PRESSED           = "ps_r_trigger_pressed"

  BTN_LS                   = "ps_l_stick"
  BTN_LS_PRESSED           = "ps_l_stick_pressed"
  BTN_LS_ANY               = "ps_l_stick_4"
  BTN_LS_UP                = "ps_l_stick_up"
  BTN_LS_DOWN              = "ps_l_stick_down"
  BTN_LS_LEFT              = "ps_l_stick_left"
  BTN_LS_RIGHT             = "ps_l_stick_right"
  BTN_LS_HOR               = "ps_l_stick_to_left_n_right"
  BTN_LS_VER               = "ps_l_stick_to_up_n_down"

  BTN_RS                   = "ps_r_stick"
  BTN_RS_PRESSED           = "ps_r_stick_pressed"
  BTN_RS_ANY               = "ps_r_stick_4"
  BTN_RS_UP                = "ps_r_stick_up"
  BTN_RS_DOWN              = "ps_r_stick_down"
  BTN_RS_LEFT              = "ps_r_stick_left"
  BTN_RS_RIGHT             = "ps_r_stick_right"
  BTN_RS_HOR               = "ps_r_stick_to_left_n_right"
  BTN_RS_VER               = "ps_r_stick_to_up_n_down"

  //"ps_touchpad"
  //"ps_touchpad_pressed"

  defHeightMul
  heightMuls = commonHeightMuls.__merge({
    BTN_BACK = 1
    BTN_BACK_PRESSED = 1
    BTN_LB = 1.1
    BTN_LB_PRESSED = 1.1
    BTN_RB = 1.1
    BTN_RB_PRESSED = 1.1
    BTN_LT = 1.1
    BTN_LT_PRESSED = 1.1
    BTN_RT = 1.1
    BTN_RT_PRESSED = 1.1
  })
}

let nintendo = {
  BTN_A                    = "ns_a"
  BTN_A_PRESSED            = "ns_a_pressed"
  BTN_B                    = "ns_b"
  BTN_B_PRESSED            = "ns_b_pressed"
  BTN_X                    = "ns_x"
  BTN_X_PRESSED            = "ns_x_pressed"
  BTN_Y                    = "ns_y"
  BTN_Y_PRESSED            = "ns_y_pressed"

  BTN_DIRPAD               = "ns_dpad"
  BTN_DIRPAD_DOWN          = "ns_dpad_down"
  BTN_DIRPAD_LEFT          = "ns_dpad_left"
  BTN_DIRPAD_RIGHT         = "ns_dpad_right"
  BTN_DIRPAD_UP            = "ns_dpad_up"

  BTN_BACK                 = "ns_back"
  BTN_BACK_PRESSED         = "ns_back_pressed"
  BTN_START                = "ns_start"
  BTN_START_PRESSED        = "ns_start_pressed"

  BTN_LB                   = "ns_lshoulder"
  BTN_LB_PRESSED           = "ns_lshoulder_pressed"
  BTN_RB                   = "ns_rshoulder"
  BTN_RB_PRESSED           = "ns_rshoulder_pressed"
  BTN_LT                   = "ns_ltrigger"
  BTN_LT_PRESSED           = "ns_ltrigger_pressed"
  BTN_RT                   = "ns_rtrigger"
  BTN_RT_PRESSED           = "ns_rtrigger_pressed"

  BTN_LS                   = "ns_lstick"
  BTN_LS_PRESSED           = "ns_lstick_pressed"
  BTN_LS_ANY               = "ns_lstick_4"
  BTN_LS_UP                = "ns_lstick_up"
  BTN_LS_DOWN              = "ns_lstick_down"
  BTN_LS_LEFT              = "ns_lstick_left"
  BTN_LS_RIGHT             = "ns_lstick_right"
  BTN_LS_HOR               = "ns_lstick_x"
  BTN_LS_VER               = "ns_lstick_y"

  BTN_RS                   = "ns_rstick"
  BTN_RS_PRESSED           = "ns_rstick_pressed"
  BTN_RS_ANY               = "ns_rstick_4"
  BTN_RS_UP                = "ns_rstick_up"
  BTN_RS_DOWN              = "ns_rstick_down"
  BTN_RS_LEFT              = "ns_rstick_left"
  BTN_RS_RIGHT             = "ns_rstick_right"
  BTN_RS_HOR               = "ns_rstick_x"
  BTN_RS_VER               = "ns_rstick_y"

  //"ns_share"
  //"ns_share_pressed"
  //"ns_home"
  //"ns_home_pressed"
  //"ns_minus"
  //"ns_minus_pressed"
  //"ns_plus"
  //"ns_plus_pressed"

  defHeightMul
  heightMuls = commonHeightMuls.__merge({
    BTN_DIRPAD_UP = 1
    BTN_DIRPAD_DOWN = 1
    BTN_DIRPAD_LEFT = 1
    BTN_DIRPAD_RIGHT = 1
    BTN_BACK = 1
    BTN_BACK_PRESSED = 1
    BTN_START = 1
    BTN_START_PRESSED = 1
    BTN_LS = 1.2
    BTN_LS_PRESSED = 1.2
    BTN_RS = 1.2
    BTN_RS_PRESSED = 1.2
    BTN_LB = 1.2
    BTN_LB_PRESSED = 1.2
    BTN_RB = 1.2
    BTN_RB_PRESSED = 1.2
    BTN_LT = 1.1
    BTN_LT_PRESSED = 1.1
    BTN_RT = 1.1
    BTN_RT_PRESSED = 1.1
  })
}

function validatePresets(presets) {
  local basePreset = null
  local basePresetId = null
  foreach(pId, p in presets)
    if (basePreset == null) {
      basePreset = p
      basePresetId = pId
    }
    else {
      let missingKeys = []
      foreach(k, _ in p)
        if (k not in basePreset)
          missingKeys.append(k)

      if (missingKeys.len() != 0) {
        logerr($"Gamepad preset {pId} has missingKeys against {basePresetId}: {", ".join(missingKeys)}")
        continue
      }
      if (basePreset.len() == p.len())
        continue

      foreach(k, _ in basePreset)
        if (k not in p)
          missingKeys.append(k)
      if (missingKeys.len() != 0)
        logerr($"Gamepad preset {basePresetId} has missingKeys against {pId}: {", ".join(missingKeys)}")
    }
  return presets
}

return validatePresets({
  xone
  sony
  nintendo
})