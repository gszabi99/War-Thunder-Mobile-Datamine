from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { ceil } = require("%sqstd/math.nut")
let { TANK, AIR, HELICOPTER } = require("%appGlobals/unitConst.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { getUnitPkgs, getAddonPostfix, getCampaignPkgsForOnlineBattle } = require("%appGlobals/updater/campaignAddons.nut")
let { soloNewbieByCampaign } = require("%appGlobals/updater/addons.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let notAvailableForSquadMsg = require("%rGui/squad/notAvailableForSquadMsg.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitSlotsPresetNonUpdatable } = require("%rGui/unitMods/unitModsSlotsState.nut")


let MAX_SLOTS = 2

let testFlightExtPacks = { //for bots
  ground = getCampaignPkgsForOnlineBattle("tanks", 1) //t_34_1942
  naval = getCampaignPkgsForOnlineBattle("ships", 1) //cruiser_admiral_hipper
}

let defTestFlight = "testFlight_destroyer_usa_tfs"
let testFlightByUnitType = {
  [AIR]             = "testFlight_plane",
  [HELICOPTER]      = "testFlight_plane",
  [TANK]            = "testFlight_ussr_tft",
}

function getBulletsForTestFlight(unitName) {
  let { primary = null, secondary = null } = loadUnitBulletsChoice(unitName)?.commonWeapons
  if (primary == null)
    return [{ name = "", count = 10000 }]
  let { bulletsOrder, total, catridge, guns } = primary
  let allowed = clone bulletsOrder
  let maxSlots = secondary == null ? MAX_SLOTS : MAX_SLOTS - 1
  if (allowed.len() > maxSlots)
    allowed.resize(maxSlots)
  let stepSize = guns
  local leftSteps = ceil(total.tofloat() / stepSize / catridge) //need send catriges count for spawn instead of bullets count
  let res = allowed.map(function(name, idx) {
    let steps = ceil(leftSteps / (allowed.len() - idx)).tointeger()
    leftSteps -= steps
    return { name, count = steps * stepSize }
  })

  if (secondary != null)
    res.append({ name = secondary.bulletsOrder[0], count = secondary.total })

  return res
}

function donloadUnitPacksAndSend(unitName, extAddons, eventId, params) {
  let pkgs = getUnitPkgs(unitName, serverConfigs.value?.allUnits[unitName].mRank ?? 1)
    .extend(extAddons)
    .filter(@(v) !hasAddons.value?[v])
  if (pkgs.len() == 0)
    eventbus_send(eventId, params)
  else
    openDownloadAddonsWnd(pkgs, eventId, params)
}

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
    weaponPreset = getUnitSlotsPresetNonUpdatable(unitName, myUnits.get()?[unitName].mods)
  }
  donloadUnitPacksAndSend(unitName, testFlightExtPacks?[getAddonPostfix(unitName)] ?? [],
    "startTestFlight", params)
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
  donloadUnitPacksAndSend(unit.name, soloNewbieByCampaign?[curCampaign.get()] ?? [], "startTraining",
    {
      unitName = unit.name
      skin = getUnitSkin(unit)
      missionName
      bullets = getBulletsForTestFlight(unit.name)
      weaponPreset = getUnitSlotsPresetNonUpdatable(unit.name, unit?.mods)
    })
}

function startLocalMPBattle(unit, missionName) {
  if (unit == null) {
    openMsgBox({ text = loc("No selected unit") })
    return
  }
  donloadUnitPacksAndSend(unit.name, [], "startLocalMP",
    {
      unitName = unit.name
      skin = getUnitSkin(unit)
      missionName
      bullets = getBulletsForTestFlight(unit.name)
    })
}

return {
  startTestFlight
  startTestFlightByName
  startOfflineBattle
  startLocalMPBattle
}