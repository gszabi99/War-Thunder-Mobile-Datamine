from "%scripts/dagui_library.nut" import *

let DataBlock  = require("DataBlock")
let u = require("%sqStdLibs/helpers/u.nut")
let { set_blk_value_by_path, get_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let { isOnlineSettingsAvailable, getLoginStateDebugStr } = require("%appGlobals/loginState.nut")
let { shouldDisableMenu } = require("%appGlobals/clientState/initialState.nut")
let { script_net_assert_once } = require("%sqStdLibs/helpers/net_errors.nut")

//save/load settings by account. work only after local profile received from host.
::save_local_account_settings <- function save_local_account_settings(path, value) {
  if (!shouldDisableMenu && !isOnlineSettingsAvailable.value) {
    script_net_assert_once("unsafe profile settings write",
      $"save_local_account_settings at login state {getLoginStateDebugStr()}")
    return
  }

  let cdb = ::get_local_custom_settings_blk()
  if (set_blk_value_by_path(cdb, path, value))
    saveProfile()
}

::load_local_account_settings <- function load_local_account_settings(path, defValue = null) {
  if (!shouldDisableMenu && !isOnlineSettingsAvailable.value) {
    script_net_assert_once("unsafe profile settings read",
      $"load_local_account_settings at login state {getLoginStateDebugStr()}")
    return defValue
  }

  let cdb = ::get_local_custom_settings_blk()
  return get_blk_value_by_path(cdb, path, defValue)
}

//save/load setting to local profile, not depend on account, so can be usable before login.
::save_local_shared_settings <- function save_local_shared_settings(path, value) {
  let blk = ::get_common_local_settings_blk()
  if (set_blk_value_by_path(blk, path, value))
    saveProfile()
}

::load_local_shared_settings <- function load_local_shared_settings(path, defValue = null) {
  let blk = ::get_common_local_settings_blk()
  return get_blk_value_by_path(blk, path, defValue)
}

let getRootSizeText = @() "{0}x{1}".subst(::screen_width(), ::screen_height())

//save/load settings by account and by screenSize
::loadLocalByScreenSize <- function loadLocalByScreenSize(name, defValue = null) {
  if (!isOnlineSettingsAvailable.value)
    return defValue
  let rootName = getRootSizeText()
  let cdb = ::get_local_custom_settings_blk()
  if (cdb?[rootName][name])
    return cdb[rootName][name]
  return defValue
}

::saveLocalByScreenSize <- function saveLocalByScreenSize(name, value) {
  if (!isOnlineSettingsAvailable.value)
    return
  let rootName = getRootSizeText()
  let cdb = ::get_local_custom_settings_blk()
  if (cdb?[rootName] != null && type(cdb[rootName]) != "instance")
    cdb[rootName] = null
  if (cdb?[rootName] == null)
    cdb[rootName] = DataBlock()
  if (cdb?[rootName][name] == null)
    cdb[rootName][name] = value
  else if (cdb[rootName][name] == value)
    return  //no need save when no changes
  else
    cdb[rootName][name] = value
  saveProfile()
}

//remove all data by screen size from all size blocks
//also clear empty size blocks
::clear_local_by_screen_size <- function clear_local_by_screen_size(name) {
  if (!isOnlineSettingsAvailable.value)
    return
  let cdb = ::get_local_custom_settings_blk()
  local hasChanges = false
  for (local idx = cdb.blockCount() - 1; idx >= 0; idx--) {
    let blk = cdb.getBlock(idx)
    if (!(name in blk))
      continue

    hasChanges = true
    if (u.isDataBlock(blk?[name]))
      blk.removeBlock(name)
    else
      blk.removeParam(name)

    if (!blk.blockCount() && !blk.paramCount())
      cdb.removeBlockById(idx)
  }
  if (hasChanges)
    saveProfile()
}
