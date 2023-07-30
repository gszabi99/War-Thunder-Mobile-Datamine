from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { register_command } = require("console")
let { send } = require("eventbus")
let json = require("json")
let io = require("io")
let { get_common_local_settings_blk } = require("blkGetters")
let { get_blk_value_by_path, set_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { isDataBlock, eachParam } = require("%sqstd/datablock.nut")
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { generate_full_offline_profile } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { units } = require("%appGlobals/pServer/campaign.nut")


const WTM_DATA_PATH = "../../skyquake/prog/scripts/wtm/globals/data/"
const CONFIGS = "offlineConfigs.nut"
const PROFILE = "offlineProfile.nut"
const CAMPAIGN_SAVE_ID = "offlineMenu/campaign"
const UNITS_SAVE_ID = "offlineMenu/units"

let function initOfflineMenuProfile() {
  log("Init offline menu profile")
  send("profile_srv.response",
    { id = -2, data = { result = { configs = require($"%appGlobals/data/{CONFIGS}") } } })

  let profile = clone require($"%appGlobals/data/{PROFILE}")
  let saveBlk = get_common_local_settings_blk()

  let campaign = get_blk_value_by_path(saveBlk, CAMPAIGN_SAVE_ID)
  if (campaign in profile.levelInfo)
    profile.levelInfo = profile.levelInfo.__merge({
      [campaign] = profile.levelInfo[campaign].__merge({ isCurrent = true })
    })
  let unitsBlk = get_blk_value_by_path(saveBlk, UNITS_SAVE_ID)
  if (isDataBlock(unitsBlk)) {
    let unitsUpd = {}
    eachParam(unitsBlk, function(unitName, _) {
      if (unitName in profile.units)
        unitsUpd[unitName] <- profile.units[unitName].__merge({ isCurrent = true })
    })
    if (unitsUpd.len() > 0)
      profile.units = profile.units.__merge(unitsUpd)
  }

  send("profile_srv.response",
    { id = -1, data = { result = profile } })
}

if (isOfflineMenu) {
  if (serverConfigs.value.len() == 0 && !isInLoadingScreen.value)
    initOfflineMenuProfile()
  isInLoadingScreen.subscribe(@(v) v || serverConfigs.value.len() != 0 ? null : initOfflineMenuProfile())
}

let function saveResult(res, fileName) {
  let fullName = $"{WTM_DATA_PATH}{fileName}"
  let file = io.file(fullName, "wt+")
  file.writestring("return ");
  file.writestring(json.to_string(res, true))
  file.close()
  console_print($"Saved json to {fullName}")
}

let function onFullProfileGenerated(res) {
  if (res?.error != null) {
    console_print("Failed to generate profile. See profile server error for details")
    return
  }
  let profile = clone res
  if ("isCustom" in profile)
    delete profile.isCustom
  saveResult(profile, PROFILE)
  saveResult(serverConfigs.value.__merge({
    adsCfg = {}
    allGoods = {}
    clientMissionRewards = {}
    playerLevelRewards = {}
    playerLevels = {}
    schRewards = {}
  }), CONFIGS)
}

register_command(@() generate_full_offline_profile(onFullProfileGenerated),
  $"debug.generate_offline_profile")


let offlineActions = {
  check_new_offer = @(_) {}
  get_battle_data_jwt = @(_) {}
  send_to_bq = @(_) {}

  function set_current_campaign(p) {
    let saveBlk = get_common_local_settings_blk()
    set_blk_value_by_path(saveBlk, CAMPAIGN_SAVE_ID, p.campaign)
    send("saveProfile", {})
  }

  function set_current_unit(p) {
    let newUnit = units.value?[p?.unitName]
    if (newUnit == null)
      return { error = $"Not found unit {p?.unitName}" }

    let res = { units = {} }
    let selUnit = units.value.findvalue(@(u) u?.isCurrent ?? false)
    if (selUnit != null)
      res.units[selUnit.name] <- selUnit.__merge({ isCurrent = false })
    res.units[newUnit.name] <- newUnit.__merge({ isCurrent = true })

    let saveBlk = get_common_local_settings_blk()
    let campaign = serverConfigs.value?.allUnits[newUnit.name].campaign ?? ""
    set_blk_value_by_path(saveBlk, $"{UNITS_SAVE_ID}/{campaign}", newUnit.name)
    send("saveProfile", {})

    return res
  }
}

return {
  offlineActions
}