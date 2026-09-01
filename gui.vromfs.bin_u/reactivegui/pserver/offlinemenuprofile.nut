from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "blkGetters" import get_common_local_settings_blk
from "console" import register_command
from "eventbus" import eventbus_send
import "io" as io
from "json" import object_to_json_string
from "%globalScripts/dataBlockExt.nut" import setBlkValueByPath, getBlkValueByPath, isDataBlock, eachParam
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen
from "%appGlobals/clientState/initialState.nut" import isOfflineMenu
from "%appGlobals/pServer/campaign.nut" import units
from "%appGlobals/pServer/pServerApi.nut" import generate_full_offline_profile, registerHandler
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs


const WTM_DATA_PATH = "../../skyquake/prog/scripts/wtm/globals/data/"
const CONFIGS = "offlineConfigs.nut"
const PROFILE = "offlineProfile.nut"
const CAMPAIGN_SAVE_ID = "offlineMenu/campaign"
const UNITS_SAVE_ID = "offlineMenu/units"

function initOfflineMenuProfile() {
  log("Init offline menu profile")
  eventbus_send("profile_srv.response",
    { id = -2, data = { result = { configs = require($"%appGlobals/data/{CONFIGS}") } } })

  let profile = clone require($"%appGlobals/data/{PROFILE}")
  let saveBlk = get_common_local_settings_blk()

  let campaign = getBlkValueByPath(saveBlk, CAMPAIGN_SAVE_ID)
  if (campaign in profile.levelInfo)
    profile.levelInfo = profile.levelInfo.__merge({
      [campaign] = profile.levelInfo[campaign].__merge({ isCurrent = true })
    })
  let unitsBlk = getBlkValueByPath(saveBlk, UNITS_SAVE_ID)
  if (isDataBlock(unitsBlk)) {
    let unitsUpd = {}
    eachParam(unitsBlk, function(unitName, _) {
      if (unitName in profile.units)
        unitsUpd[unitName] <- profile.units[unitName].__merge({ isCurrent = true })
    })
    if (unitsUpd.len() > 0)
      profile.units = profile.units.__merge(unitsUpd)
  }

  eventbus_send("profile_srv.response",
    { id = -1, data = { result = profile } })
}

if (isOfflineMenu) {
  if (serverConfigs.get().len() == 0 && !isInLoadingScreen.get())
    initOfflineMenuProfile()
  isInLoadingScreen.subscribe(@(v) (v || serverConfigs.get().len() != 0) ? null : initOfflineMenuProfile())
}

function saveResult(res, fileName) {
  let fullName = $"{WTM_DATA_PATH}{fileName}"
  let file = io.file(fullName, "wt+")
  file.writestring("return ");
  file.writestring(object_to_json_string(res, true))
  file.close()
  log($"Saved json to {fullName}")
}

registerHandler("onFullProfileGenerated",
  function(res) {
    if (res?.error != null) {
      log("Failed to generate profile. See profile server error for details")
      return
    }
    let profile = clone res
    profile?.$rawdelete("isCustom")
    saveResult(profile, PROFILE)
    saveResult(serverConfigs.get().__merge({
      adsCfg = {}
      allGoods = {}
      clientMissionRewards = {}
      playerLevelRewards = {}
      playerLevels = {}
      schRewards = {}
    }), CONFIGS)
  })

register_command(@() generate_full_offline_profile("onFullProfileGenerated"),
  $"debug.generate_offline_profile")


let offlineActions = {
  check_new_offer = @(_) {}
  get_battle_data_jwt = @(_) {}

  function set_current_campaign(p) {
    let saveBlk = get_common_local_settings_blk()
    setBlkValueByPath(saveBlk, CAMPAIGN_SAVE_ID, p.campaign)
    eventbus_send("saveProfile", {})
  }

  function set_current_unit(p) {
    let newUnit = units.get()?[p?.unitName]
    if (newUnit == null)
      return { error = $"Not found unit {p?.unitName}" }

    let res = { units = {} }
    let selUnit = units.get().findvalue(@(u) u?.isCurrent ?? false)
    if (selUnit != null)
      res.units[selUnit.name] <- selUnit.__merge({ isCurrent = false })
    res.units[newUnit.name] <- newUnit.__merge({ isCurrent = true })

    let saveBlk = get_common_local_settings_blk()
    let campaign = serverConfigs.get()?.allUnits[newUnit.name].campaign ?? ""
    setBlkValueByPath(saveBlk, $"{UNITS_SAVE_ID}/{campaign}", newUnit.name)
    eventbus_send("saveProfile", {})

    return res
  }
}

return {
  offlineActions
}
