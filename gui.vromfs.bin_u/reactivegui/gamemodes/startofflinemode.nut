from "%globalsDarg/darg_library.nut" import *
let logO = log_with_prefix("[OFFLINE_MISSION] ")
let { TANK, AIR, HELICOPTER } = require("%appGlobals/unitConst.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getMissionUnitsAndAddons, getCommonBots, addSupportUnits } = require("%appGlobals/updater/missionUnits.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { getDefaultBulletsForSpawn } = require("%rGui/weaponry/bulletsCalc.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitSlotsPresetNonUpdatable } = require("%rGui/unitMods/unitModsSlotsState.nut")
let { missingUnitResourcesByRank, getMissingUnitsForRank } = require("%appGlobals/updater/gameModeAddons.nut")
let { getCampaignRankAddons, getCampaignPkgsForNewbieSingle } = require("%appGlobals/updater/campaignAddons.nut")


let defTestFlight = "testFlight_destroyer_usa_tfs"
let testFlightByUnitType = {
  [AIR]             = "testFlight_plane",
  [HELICOPTER]      = "testFlight_plane",
  [TANK]            = "testFlight_ussr_tft",
}

let getBulletsForTestFlight = @(unitName, level = 1000) getDefaultBulletsForSpawn(unitName, level, campMyUnits.get()?[unitName].mods)

function startTestFlightImpl(unitName, missionNameExt, skin) {
  if (unitName == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }

  let unitType = getUnitType(unitName)
  let missionName = missionNameExt ?? testFlightByUnitType?[unitType] ?? defTestFlight
  let evtParams = {
    unitName
    skin
    missionName
    bullets = getBulletsForTestFlight(unitName)
    weaponPreset = getUnitSlotsPresetNonUpdatable(unitName, campMyUnits.get()?[unitName].mods)
      .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})
  }
  logO("openDownloadAddonsWnd startTestFlight")
  let { mRank = 1 } = serverConfigs.get()?.allUnits[unitName]
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let units = { [getTagsUnitName(unitName)] = true }.__update(misUnits)
  openDownloadAddonsWnd(getCampaignRankAddons(curCampaign.get(), 1).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startTestFlight", { paramStr1 = unitName, paramInt1 = mRank, unit = unitName },
    "startTestFlight", evtParams)
}

let getUnitSkin = @(unit) unit?.currentSkins[unit.name] ?? ""

let startTestFlightByName = @(unitName, missionName = null, skin = "")
  notAvailableForSquadMsg(@() startTestFlightImpl(unitName, missionName, skin))

let startTestFlight = @(unit, missionName = null)
  startTestFlightByName(unit.name, missionName, getUnitSkin(unit))

function startNewbieOfflineBattle(unit, missionName) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("openDownloadAddonsWnd startTraining")
  let { mRank = 1 } = serverConfigs.get()?.allUnits[unit.name]
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let units = { [getTagsUnitName(unit.name)] = true }.__update(misUnits)
  openDownloadAddonsWnd(getCampaignPkgsForNewbieSingle(curCampaign.get()).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startTraining", { paramStr1 = unit.name, paramInt1 = mRank, unit = unit.name },
    "startTraining",
    {
      unitName = unit.name
      skin = getUnitSkin(unit)
      missionName
      bullets = getBulletsForTestFlight(unit.name, unit?.level ?? 1000)
      weaponPreset = getUnitSlotsPresetNonUpdatable(unit.name, unit?.mods)
        .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})
    })
}

let mkLocalMPParams = @(unit, missionName, presetOvrMis, misBlkParams) {
  unitName = unit.name
  skin = getUnitSkin(unit)
  missionName
  bullets = getBulletsForTestFlight(unit.name)
  presetOvrMis
  misBlkParams
}

function startLocalMPBattle(unit, missionName, presetOvrMis = null, misBlkParams = {}) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("openDownloadAddonsWnd startLocalMP")
  let { mRank = 1, campaign = "" } = serverConfigs.get()?.allUnits[unit.name]
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let units = getMissingUnitsForRank(campaign, mRank, missingUnitResourcesByRank.get())
    .__merge(misUnits, getCommonBots(campaign, mRank, mRank))
  openDownloadAddonsWnd(getCampaignRankAddons(campaign, mRank).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startLocalMP", { paramStr1 = unit.name, paramInt1 = mRank, unit = unit.name },
    "startLocalMP", mkLocalMPParams(unit, missionName, presetOvrMis, misBlkParams))
}

function startLocalMPBattleWithoutGamemode(unit, missionName, presetOvrMis = null, misBlkParams = {}) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("openDownloadAddonsWnd startLocalMPWithoutGM")
  let { mRank = 1, campaign = "" } = serverConfigs.get()?.allUnits[unit.name]
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let units = getMissingUnitsForRank(campaign, mRank, missingUnitResourcesByRank.get())
    .__merge(misUnits, getCommonBots(campaign, mRank, mRank))
  openDownloadAddonsWnd(getCampaignRankAddons(campaign, mRank).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startLocalMPWithoutGM", { paramStr1 = unit.name, paramInt1 = mRank, unit = unit.name },
    "startLocalMPWithoutGM", mkLocalMPParams(unit, missionName, presetOvrMis, misBlkParams))
}

return {
  startTestFlight
  startTestFlightByName
  startNewbieOfflineBattle
  startLocalMPBattle
  startLocalMPBattleWithoutGamemode
}