from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitConst.nut" import TANK, AIR, HELICOPTER
from "%appGlobals/unitTags.nut" import getUnitType
from "%appGlobals/updater/campaignAddons.nut" import getCampaignRankAddons, getCampaignPkgsForNewbieSingle
from "%appGlobals/updater/missionUnits.nut" import getMissionUnitsAndAddons, getCommonBots, addSupportUnits
from "%rGui/components/msgBox.nut" import openMsgBox
import "%rGui/squad/notAvailableForSquadMsg.nut" as notAvailableForSquadMsg
from "%rGui/unitMods/unitModsSlotsState.nut" import getUnitSlotsPresetNonUpdatable
from "%rGui/updater/updaterState.nut" import openDownloadAddonsWnd
from "%rGui/weaponry/bulletsCalc.nut" import getDefaultBulletsForSpawn


let logO = log_with_prefix("[OFFLINE_MISSION] ")


const defTestFlight = "testFlight_destroyer_usa_tfs"
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
  let units = { [unitName] = true }.__update(misUnits)
  openDownloadAddonsWnd(getCampaignRankAddons(curCampaign.get(), 1).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startTestFlight", { paramStr1 = unitName, paramInt1 = mRank, unit = unitName },
    "startTestFlight", evtParams)
}

let getUnitSkin = @(unit) unit?.skin
  ?? unit?.currentSkins[unit.name] 
  ?? ""

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
  let units = { [unit.name] = true }.__update(misUnits)
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

let mkLocalMPParams = @(mGameModeId, missionName, unit, presetOvrMis = null, misBlkParams = {}) {
  mGameModeId
  unitName = unit.name
  skin = getUnitSkin(unit)
  missionName
  bullets = getBulletsForTestFlight(unit.name)
  presetOvrMis
  misBlkParams
}

function startLocalMPBattle(mGameModeId, missionName, units) {
  if (units.len() == 0) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("openDownloadAddonsWnd startLocalMP")

  let unit = serverConfigs.get()?.allUnits[units[0]] 
  let { mRank = 1, campaign = "" } = unit
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let unitsRes = units.reduce(@(res, u) res.$rawset(u, true), {})
    .__update(misUnits, getCommonBots(campaign, mRank, mRank))
  openDownloadAddonsWnd(getCampaignRankAddons(campaign, mRank).extend(misAddons.keys()),
    addSupportUnits(unitsRes).keys(),
    "startLocalMP", { paramStr1 = ",".join(units), paramInt1 = mRank, unit = units[0] },
    "startLocalMP", mkLocalMPParams(mGameModeId, missionName, unit))
}

function startLocalMPBattleWithoutGamemode(mGameModeId, missionName, unit, presetOvrMis = null, misBlkParams = {}) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("openDownloadAddonsWnd startLocalMPWithoutGM")
  let { mRank = 1, campaign = "" } = serverConfigs.get()?.allUnits[unit.name]
  let { misUnits, misAddons } = getMissionUnitsAndAddons(missionName)
  let units = { [unit.name] = true }
    .__merge(misUnits, getCommonBots(campaign, mRank, mRank))
  openDownloadAddonsWnd(getCampaignRankAddons(campaign, mRank).extend(misAddons.keys()),
    addSupportUnits(units).keys(),
    "startLocalMPWithoutGM", { paramStr1 = unit.name, paramInt1 = mRank, unit = unit.name },
    "startLocalMPWithoutGM", mkLocalMPParams(mGameModeId, missionName, unit, presetOvrMis, misBlkParams))
}

return {
  startTestFlight
  startTestFlightByName
  startNewbieOfflineBattle
  startLocalMPBattle
  startLocalMPBattleWithoutGamemode
}