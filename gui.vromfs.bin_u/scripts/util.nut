from "%scripts/dagui_library.nut" import *

//ATTENTION! this file is coupling things to much! Split it!
//shouldDecreaseSize, allowedSizeIncrease = 110
let { is_mplayer_host, is_mplayer_peer, is_local_multiplayer } = require("multiplayer")
let { setBlkValueByPath, getBlkValueByPath, blkOptFromPath } = require("%globalScripts/dataBlockExt.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { is_pc, is_android, is_ios } = require("%sqstd/platform.nut")

::on_cannot_create_session <- @() openFMsgBox({ text = loc("NET_CANNOT_CREATE_SESSION") })

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
  let val = getBlkValueByPath(blk, path)
  return (val != null) ? val : defVal
}

::setSystemConfigOption <- function setSystemConfigOption(path, val) {
  let filename = ::get_config_blk_paths().write
  if (!filename)
    return
  let blk = blkOptFromPath(filename)
  if (setBlkValueByPath(blk, path, val))
    blk.saveToTextFile(filename)
}

let is_multiplayer = @() (is_mplayer_host() || is_mplayer_peer()) && !is_local_multiplayer()

let function is_user_mission(missionBlk) {
  return missionBlk?.userMission == true //can be null
}


return {
  is_multiplayer
  is_user_mission
}