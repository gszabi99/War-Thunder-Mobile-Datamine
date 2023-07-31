from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

//ATTENTION! this file is coupling things to much! Split it!
//shouldDecreaseSize, allowedSizeIncrease = 110
let { is_mplayer_host, is_mplayer_peer } = require("multiplayer")
let { hangar_enable_controls } = require("hangar")
let { set_blk_value_by_path, get_blk_value_by_path, blkOptFromPath } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { is_pc, is_android, is_ios } = require("%sqstd/platform.nut")
let u = require("%sqStdLibs/helpers/u.nut")

::on_cannot_create_session <- @() openFMsgBox({ text = loc("NET_CANNOT_CREATE_SESSION") })

local is_hangar_controls_enabled = false
::enableHangarControls <- function enableHangarControls(value, save = true) {
  hangar_enable_controls(value)
  if (save)
    is_hangar_controls_enabled = value
}
::restoreHangarControls <- function restoreHangarControls() {
  hangar_enable_controls(is_hangar_controls_enabled)
}

::buildTableFromBlk <- function buildTableFromBlk(blk) {
  if (!blk)
    return {}
  let res = {}
  for (local i = 0; i < blk.paramCount(); i++)
    ::buildTableFromBlk_AddElement(res, blk.getParamName(i) || "", blk.getParamValue(i))
  for (local i = 0; i < blk.blockCount(); i++) {
    let block = blk.getBlock(i)
    let blockTable = ::buildTableFromBlk(block)
    ::buildTableFromBlk_AddElement(res, block.getBlockName() || "", blockTable)
  }
  return res
}

/**
 * Adds value to table that may already
 * have some value with the same key.
 */
::buildTableFromBlk_AddElement <- function buildTableFromBlk_AddElement(table, elementKey, elementValue) {
  if (!(elementKey in table))
    table[elementKey] <- elementValue
  else if (type(table[elementKey]) == "array")
    table[elementKey].append(elementValue)
  else
    table[elementKey] <- [table[elementKey], elementValue]
}

::isProductionCircuit <- function isProductionCircuit() {
  return ::get_cur_circuit_name().indexof("production") != null
}

::get_config_blk_paths <- function get_config_blk_paths() {
  // On PS4 path is "/app0/config.blk", but it is read-only.
  return {
    read  = (is_pc || is_android || is_ios) ? ::get_config_name() : null
    write = (is_pc) ? ::get_config_name() : null
  }
}

::getSystemConfigOption <- function getSystemConfigOption(path, defVal = null) {
  let filename = ::get_config_blk_paths().read
  if (!filename)
    return defVal
  let blk = blkOptFromPath(filename)
  let val = get_blk_value_by_path(blk, path)
  return (val != null) ? val : defVal
}

::setSystemConfigOption <- function setSystemConfigOption(path, val) {
  let filename = ::get_config_blk_paths().write
  if (!filename)
    return
  let blk = blkOptFromPath(filename)
  if (set_blk_value_by_path(blk, path, val))
    blk.saveToTextFile(filename)
}

::inherit_table <- function inherit_table(parent_table, child_table) {
  return u.extend(u.copy(parent_table), child_table)
}

let is_multiplayer = @() is_mplayer_host() || is_mplayer_peer()

let function is_user_mission(missionBlk) {
  return missionBlk?.userMission == true //can be null
}


return {
  is_multiplayer
  is_user_mission
}