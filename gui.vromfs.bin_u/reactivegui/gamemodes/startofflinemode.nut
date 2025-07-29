from "%globalsDarg/darg_library.nut" import *
let logO = log_with_prefix("[OFFLINE_MISSION] ")
let { eventbus_send } = require("eventbus")
let { TANK, AIR, HELICOPTER } = require("%appGlobals/unitConst.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { getDefaultBulletsForSpawn } = require("%rGui/weaponry/bulletsCalc.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { soloNewbieByCampaign } = require("%appGlobals/updater/addons.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitSlotsPresetNonUpdatable } = require("%rGui/unitMods/unitModsSlotsState.nut")


let defTestFlight = "testFlight_destroyer_usa_tfs"
let testFlightByUnitType = {
  [AIR]             = "testFlight_plane",
  [HELICOPTER]      = "testFlight_plane",
  [TANK]            = "testFlight_ussr_tft",
}

function downloadUnitPacksAndSend(unitName, extAddons, eventId, params) {
  let { mRank = 1 } = serverConfigs.get()?.allUnits[unitName]
  let pkgs = getUnitPkgs(unitName, mRank)
    .extend(extAddons)
    .filter(@(v) !hasAddons.get()?[v])
  if (pkgs.len() == 0)
    eventbus_send(eventId, params)
  else
    openDownloadAddonsWnd(pkgs, eventId, { paramStr1 = unitName, paramInt1 = mRank, unit = unitName },
      eventId, params)
}

let getBulletsForTestFlight = @(unitName) getDefaultBulletsForSpawn(unitName, 1000, campMyUnits.get()?[unitName].mods)

function startTestFlightImpl(unitName, missionName, skin) {
  if (unitName == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }

  let unitType = getUnitType(unitName)
  let params = {
    unitName
    skin
    missionName = missionName ?? testFlightByUnitType?[unitType] ?? defTestFlight
    bullets = getBulletsForTestFlight(unitName)
    weaponPreset = getUnitSlotsPresetNonUpdatable(unitName, campMyUnits.get()?[unitName].mods)
      .reduce(@(res, v, k) res.$rawset(k.tostring(), v), {})
  }
  logO("downloadUnitPacksAndSend startTestFlight")
  downloadUnitPacksAndSend(unitName, [], "startTestFlight", params)
}

let getUnitSkin = @(unit) unit?.currentSkins[unit.name] ?? ""

let startTestFlightByName = @(unitName, missionName = null, skin = "")
  notAvailableForSquadMsg(@() startTestFlightImpl(unitName, missionName, skin))

let startTestFlight = @(unit, missionName = null)
  startTestFlightByName(unit.name, missionName, getUnitSkin(unit))

function startOfflineBattle(unit, missionName) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("downloadUnitPacksAndSend startTraining")
  downloadUnitPacksAndSend(unit.name, soloNewbieByCampaign?[curCampaign.get()] ?? [], "startTraining",
    {
      unitName = unit.name
      skin = getUnitSkin(unit)
      missionName
      bullets = getBulletsForTestFlight(unit.name)
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
  logO("downloadUnitPacksAndSend startLocalMP")
  downloadUnitPacksAndSend(unit.name, [], "startLocalMP", mkLocalMPParams(unit, missionName, presetOvrMis, misBlkParams))
}

function startLocalMPBattleWithoutGamemode(unit, missionName, presetOvrMis = null, misBlkParams = {}) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  logO("downloadUnitPacksAndSend startLocalMPWithoutGM")
  downloadUnitPacksAndSend(unit.name, [], "startLocalMPWithoutGM", mkLocalMPParams(unit, missionName, presetOvrMis, misBlkParams))
}

return {
  startTestFlight
  startTestFlightByName
  startOfflineBattle
  startLocalMPBattle
  startLocalMPBattleWithoutGamemode
}