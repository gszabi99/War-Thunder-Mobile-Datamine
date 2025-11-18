from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "hangar" import DM_VIEWER_NONE, DM_VIEWER_PROTECTION
from "hangarEventCommand" import set_protection_checker_params, protection_examination_shot,
  hangar_protection_map_update, get_protection_map_progress, dm_viewer_reset,
  set_dm_viewer_pointer_screenpos
from "dagor.workcycle" import resetTimeout, clearTimer
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/permissions.nut" import allow_protection_analysis
from "%appGlobals/config/countryPresentation.nut" import sortCountries
import "%appGlobals/getTagsUnitName.nut" as getTagsUnitName
from "%rGui/unit/unitsWndState.nut" import visibleUnitsList
from "%rGui/unit/unitUtils.nut" import sortUnits
from "%rGui/unit/unitNameSearch.nut" import isUnitNameMatchSearchStr
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice
from "%rGui/weaponry/dmgModel.nut" import getArmorPiercingByDistance
from "%rGui/dmViewer/dmViewerState.nut" import dmViewerMode
from "%rGui/dmViewer/dmViewerPkg.nut" import hitProbMinorColor

let FIRE_DISTANCE_DEFAULT = 500
let FIRE_DISTANCE_MAX = 2000
let PROTECTION_MAP_PROGRESS_UPDATE_INTERVAL = 0.3
let DM_MODE_SWITCHING_DELAY = 0.1

let inspectedUnit = mkWatched(persist, "inspectedUnit", null)
let inspectedBaseUnit = mkWatched(persist, "inspectedBaseUnit", null)
let isSimulationMode = mkWatched(persist, "isSimulationMode", false)

let isProtectionAnalysisAvailable = allow_protection_analysis
let isProtectionAnalysisActive = Computed(@() inspectedUnit.get() != null)

let threatUnitSearchString = mkWatched(persist, "threatUnitSearchString", "")
let threatCountry = mkWatched(persist, "threatCountry", "")
let threatMRank = mkWatched(persist, "threatMRank", 0)
let threatUnit = mkWatched(persist, "threatUnit", null)
let threatBulletData = mkWatched(persist, "threatBulletData", null)
let fireDistance = mkWatched(persist, "fireDistance", FIRE_DISTANCE_DEFAULT)

let isHintVisible = Watched(false)
let probabilityColor = Watched(hitProbMinorColor)

let protectionMapUpdProgress = Watched(0)
let isProtectionMapUpdating = Computed(@() ![0, 100].contains(protectionMapUpdProgress.get()))

let initialTargetPosX = sw(50)
let initialTargetPosY = sh(50)
let screenMaxX = sw(100) - 1
let screenMaxY = sh(100) - 1
let targetScreenX = Watched(initialTargetPosX)
let targetScreenY = Watched(initialTargetPosY)
let onPointerScreenCoordsChange = @(_) set_dm_viewer_pointer_screenpos(
  clamp(targetScreenX.get(), 0, screenMaxX),
  clamp(targetScreenY.get(), 0, screenMaxY))
targetScreenX.subscribe(onPointerScreenCoordsChange)
targetScreenY.subscribe(onPointerScreenCoordsChange)

inspectedUnit.subscribe(function(v) {
  if (v != null)
    resetTimeout(DM_MODE_SWITCHING_DELAY, @() dmViewerMode.set(DM_VIEWER_PROTECTION))
  else {
    dmViewerMode.set(DM_VIEWER_NONE)
    dm_viewer_reset()
    set_protection_checker_params("", "", "", 0, 0, 0)
    inspectedBaseUnit.set(null)
    threatUnitSearchString.set("")
  }
})

function openProtectionAnalysis(unit, baseUnit) {
  inspectedUnit.set(unit)
  inspectedBaseUnit.set(baseUnit)
}

function applyProtAnalysisOptions() {
  let unitName = getTagsUnitName(threatUnit.get()?.name ?? "")
  let { weaponBlkName = "", bulletNames = [] } = threatBulletData.get()?.bSet
  let bulletName = bulletNames?[0] ?? ""
  if (unitName != "" && weaponBlkName != "" && bulletName != "")
    set_protection_checker_params(weaponBlkName, bulletName, unitName, fireDistance.get(), 0, 0)
}

isSimulationMode.subscribe(function(v) {
  if (v)
    applyProtAnalysisOptions()
  targetScreenX.set(v ? initialTargetPosX : 0)
  targetScreenY.set(v ? initialTargetPosY : 0)
})

function doFire() {
  if (isHintVisible.get())
    protection_examination_shot()
}

function onProtectionMapUpdProgress() {
  let func = callee()
  let progress = get_protection_map_progress()
  protectionMapUpdProgress.set(progress)
  if (progress < 100)
    resetTimeout(PROTECTION_MAP_PROGRESS_UPDATE_INTERVAL, func)
  else
    clearTimer(func)
}

dmViewerMode.subscribe(function(_) {
  if (!isProtectionMapUpdating.get())
    return
  clearTimer(onProtectionMapUpdProgress)
  protectionMapUpdProgress.set(0)
})

function protectionMapUpdate() {
  applyProtAnalysisOptions()
  resetTimeout(0.1, function() {
    hangar_protection_map_update()
    onProtectionMapUpdProgress()
  })
}

function selectThreatUnit(u) {
  threatCountry.set(u?.country ?? "")
  threatMRank.set(u?.mRank ?? 0)
  threatUnit.set(u)
}

inspectedUnit.subscribe(selectThreatUnit)

let collectUnits = @(u) [ u ].extend(u.platoonUnits.map(@(pu) u.__merge(pu)))

let searchableUnitsList = Computed(function() {
  if (!isProtectionAnalysisActive.get())
    return []
  let list = visibleUnitsList.get().reduce(@(res, v) res.extend(collectUnits(v)), [])
  let inspectedUnitName = inspectedUnit.get()?.name ?? ""
  if (inspectedUnitName != "" && list.findvalue(@(u) u.name == inspectedUnitName) == null)
    list.extend(collectUnits(inspectedBaseUnit.get()))
  return list.sort(sortUnits)
})

let threatCountriesList = Computed(@() !isProtectionAnalysisActive.get() ? []
  : searchableUnitsList.get().reduce(@(res, v) res.$rawset(v.country, true), {}).keys().sort(sortCountries))
threatCountriesList.subscribe(@(v) v.contains(threatCountry.get()) ? null : threatCountry.set(v?[0] ?? ""))

let threatMRanksList = Computed(function() {
  if (!isProtectionAnalysisActive.get())
    return []
  let country = threatCountry.get()
  return searchableUnitsList.get().reduce(@(res, v) v.country == country ? res.$rawset(v.mRank, true) : res, {}).keys().sort()
})
threatMRanksList.subscribe(@(v) v.contains(threatMRank.get()) ? null
  : v.contains(inspectedUnit.get()?.mRank) ? threatMRank.set(inspectedUnit.get().mRank)
  : threatMRank.set(v?[0] ?? 0))

let threatUnitsList = Computed(function() {
  if (!isProtectionAnalysisActive.get())
    return []
  let country = threatCountry.get()
  let mRank = threatMRank.get()
  return searchableUnitsList.get().filter(@(v) v.country == country && v.mRank == mRank)
})
function updateSelUnit(threatUnitsListVal) {
  let threatUnitName = threatUnit.get()?.name ?? ""
  let inspectedUnitName = inspectedUnit.get()?.name ?? ""
  let preferredVal = threatUnitsListVal.findvalue(@(u) u.name == threatUnitName)
    ?? threatUnitsListVal.findvalue(@(u) u.name == inspectedUnitName)
  threatUnit.set(preferredVal ?? threatUnitsListVal?[0])
}
threatUnitsList.subscribe(updateSelUnit)
updateSelUnit(threatUnitsList.get())

let threatBulletDataList = Computed(function() {
  let res = []
  if (!isProtectionAnalysisActive.get())
    return res
  let unitName = getTagsUnitName(threatUnit.get()?.name ?? "")
  let bInfo = loadUnitBulletsChoice(unitName)
  foreach (set in bInfo)
    foreach (triggerType, weapon in set)
      if ([ "primary", "secondary", "special" ].contains(triggerType)) {
        let { bulletsOrder, bulletSets, fromUnitTags } = weapon
        res.extend(bulletsOrder.map(@(id) ((id not in bulletSets) || (id not in fromUnitTags)) ? null : {
          bSet = bulletSets[id]
          tags = fromUnitTags[id]
        }).filter(@(v) v != null && v.bSet?.smokeTime == null))
      }
  return res
})
function updateSelBullet(threatBulletDataListVal) {
  let bSetId = threatBulletData.get()?.bSet.id
  let preferredVal = threatBulletDataListVal.findvalue(@(v) isEqual(v.bSet.id, bSetId))
  threatBulletData.set(preferredVal ?? threatBulletDataListVal?[0])
}
threatBulletDataList.subscribe(updateSelBullet)
updateSelBullet(threatBulletDataList.get())

let armorPiercingMm = Computed(function() {
  let unitName = getTagsUnitName(threatUnit.get()?.name ?? "")
  let { weaponBlkName = "", id = "" } = threatBulletData.get()?.bSet
  if (unitName == "" || weaponBlkName == "")
    return 0.0
  let res = getArmorPiercingByDistance(unitName, weaponBlkName, id, fireDistance.get())
  return round(res ?? 0.0)
})

let threatUnitSearchResults = Computed(function() {
  let searchStr = threatUnitSearchString.get()
  return searchStr == "" ? []
    : searchableUnitsList.get().filter(@(u) isUnitNameMatchSearchStr(u, searchStr, false))
})

return {
  isProtectionAnalysisAvailable
  openProtectionAnalysis

  isProtectionAnalysisActive
  isSimulationMode
  FIRE_DISTANCE_MAX

  isHintVisible
  probabilityColor
  targetScreenX
  targetScreenY

  doFire
  protectionMapUpdate
  isProtectionMapUpdating
  protectionMapUpdProgress

  threatCountriesList
  threatMRanksList
  threatUnitsList
  threatBulletDataList

  inspectedUnit
  inspectedBaseUnit
  threatUnitSearchString
  threatCountry
  threatMRank
  threatUnit
  threatBulletData
  fireDistance

  armorPiercingMm

  threatUnitSearchResults
  selectThreatUnit
}
