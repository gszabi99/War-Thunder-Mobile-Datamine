from "%globalScripts/weaponConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setTimeout, deferOnce
from "eventbus" import eventbus_subscribe
from "vehicleModel" import getBulletNameByType, getBulletCountByType, getNextBulletType, getCurrentBulletType,
  changeBulletType
from "%sqstd/math.nut" import ceil
from "%sqstd/underscore.nut" import isEqual
from "%rGui/bullets/calcBullets.nut" import calcBulletStep
from "%rGui/hud/actionBar/actionBarState.nut" import primaryAction, primaryExtraAction, secondaryAction, specAction
from "%rGui/hudState.nut" import playerUnitName, isUnitDelayed, isVisibleOnHud
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice


let nextBulletIdx = Watched(getNextBulletType(TRIGGER_GROUP_PRIMARY))

let currentBulletIdxPrim = Watched(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
let currentBulletIdxSec = Watched(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))
let currentBulletIdxSpec = Watched(getCurrentBulletType(TRIGGER_GROUP_SPECIAL_GUN))
let nextBulletIdxSec = Watched(getNextBulletType(TRIGGER_GROUP_SECONDARY))
let nextBulletIdxSpec = Watched(getNextBulletType(TRIGGER_GROUP_SPECIAL_GUN))

let bulletsCountPrim = Watched(array(3, 0))
let bulletsCountSec = Watched(array(3, 0))
let bulletsCountSpec = Watched(array(3, 0))

let bulletsNamePrim = Watched(array(3, TRIGGER_GROUP_PRIMARY).map(getBulletNameByType))
let bulletsNameSec = Watched(array(3, TRIGGER_GROUP_SECONDARY).map(getBulletNameByType))
let bulletsNameSpec = Watched(array(3, TRIGGER_GROUP_SPECIAL_GUN).map(getBulletNameByType))

let mainBulletCount = Computed(@() bulletsCountPrim.get()[0])
let extraBulletCount = Computed(@() bulletsCountPrim.get()[1])
let mainBulletCountSec = Computed(@() bulletsCountSec.get()[0])
let extraBulletCountSec = Computed(@() bulletsCountSec.get()[1])
let mainBulletCountSpec = Computed(@() bulletsCountSpec.get()[0])
let extraBulletCountSpec = Computed(@() bulletsCountSpec.get()[1])

let bulletsInfo = Computed(function() {
  if ((playerUnitName.get() ?? "") == "")
    return null
  return loadUnitBulletsChoice(playerUnitName.get())?.commonWeapons.primary
})
let bulletsInfoSec = Computed(function() {
  if ((playerUnitName.get() ?? "") == "")
    return null
  return loadUnitBulletsChoice(playerUnitName.get())?.commonWeapons.secondary
})
let bulletsInfoSpec = Computed(function() {
  if ((playerUnitName.get() ?? "") == "")
    return null
  return loadUnitBulletsChoice(playerUnitName.get())?.commonWeapons.special
})
let isSecondaryBulletsSame = Computed(function() {
  if ((playerUnitName.get() ?? "") == "" || bulletsInfo.get() == null || bulletsInfoSec.get() == null)
    return false
  let secondaryOrder = loadUnitBulletsChoice(playerUnitName.get())?.commonWeapons.secondary.bulletsOrder
  return secondaryOrder != null && isEqual(bulletsInfo.get().bulletsOrder, secondaryOrder)
})

let bulletSecStep = Computed(@() calcBulletStep(bulletsInfoSec.get()))
let bulletSecTotalCount = Computed(@() (bulletsInfoSec.get()?.total ?? 1).tofloat())
let bulletSecTotalSteps = Computed(@() ceil(bulletSecTotalCount.get() / bulletSecStep.get()).tointeger())
let bulletSpecStep = Computed(@() calcBulletStep(bulletsInfoSpec.get()))
let bulletSpecTotalCount = Computed(@() (bulletsInfoSpec.get()?.total ?? 1).tofloat())
let bulletSpecTotalSteps = Computed(@() ceil(bulletSpecTotalCount.get() / bulletSpecStep.get()).tointeger())

let isFakeSecondary = Computed(@() bulletsInfoSec.get() == null || bulletSecTotalSteps.get() <= 1)
let isFakeSpecial = Computed(@() bulletsInfoSpec.get() == null || bulletSpecTotalSteps.get() <= 1)
let hasOnlyOneSideGroup = Computed(@() isFakeSecondary.get() != isFakeSpecial.get())

let nextBulletName = Computed(@() bulletsNamePrim.get()?[nextBulletIdx.get()] ?? "")
let currentBulletName = Computed(@() bulletsNamePrim.get()?[currentBulletIdxPrim.get()] ?? "")
let currentBulletNameSec = Computed(@() bulletsNameSec.get()?[currentBulletIdxSec.get()] ?? "")
let currentBulletNameSpec = Computed(@() bulletsNameSpec.get()?[currentBulletIdxSpec.get()] ?? "")
let nextBulletNameSec = Computed(@() bulletsNameSec.get()?[nextBulletIdxSec.get()] ?? "")
let nextBulletNameSpec = Computed(@() bulletsNameSpec.get()?[nextBulletIdxSpec.get()] ?? "")

let mainBulletInfo = Computed(@() bulletsInfo.get()?.bulletSets[bulletsNamePrim.get()[0]])
let extraBulletInfo = Computed(@() bulletsInfo.get()?.bulletSets[bulletsNamePrim.get()[1]])
let withExtraPrimary = Computed(@() (bulletsInfo.get()?.bulletSetAvailiable.len() ?? 0) > 0)
let mainBulletInfoSec = Computed(@() bulletsInfoSec.get()?.bulletSets[bulletsNameSec.get()[0]])
let extraBulletInfoSec = Computed(@() bulletsInfoSec.get()?.bulletSets[bulletsNameSec.get()[1]])
let mainBulletInfoSpec = Computed(@() bulletsInfoSpec.get()?.bulletSets[bulletsNameSpec.get()[0]])
let extraBulletInfoSpec = Computed(@() bulletsInfoSpec.get()?.bulletSets[bulletsNameSpec.get()[1]])

let mkUpdateBulletsState = @(trigger, watch, getter) function updateBulletsState() {
  let newVal = array(3, trigger).map(getter)
  if (!isEqual(newVal, watch.get()))
    watch.set(newVal)
}

let updateBulletsCountPrim = mkUpdateBulletsState(TRIGGER_GROUP_PRIMARY, bulletsCountPrim, getBulletCountByType)
let updateBulletsCountSec = mkUpdateBulletsState(TRIGGER_GROUP_SECONDARY, bulletsCountSec, getBulletCountByType)
let updateBulletsCountSpec = mkUpdateBulletsState(TRIGGER_GROUP_SPECIAL_GUN, bulletsCountSpec, getBulletCountByType)
let updateBulletsNamePrim = mkUpdateBulletsState(TRIGGER_GROUP_PRIMARY, bulletsNamePrim, getBulletNameByType)
let updateBulletsNameSec = mkUpdateBulletsState(TRIGGER_GROUP_SECONDARY, bulletsNameSec, getBulletNameByType)
let updateBulletsNameSpec = mkUpdateBulletsState(TRIGGER_GROUP_SPECIAL_GUN, bulletsNameSpec, getBulletNameByType)

updateBulletsCountPrim()
updateBulletsCountSec()
updateBulletsCountSpec()
updateBulletsNamePrim()
updateBulletsNameSec()
updateBulletsNameSpec()

let updateAllBulletsCount = @() deferOnce(function() {
  updateBulletsCountPrim()
  updateBulletsCountSec()
  updateBulletsCountSpec()
})

let updateAllBulletsState = @() deferOnce(function() {
  updateBulletsCountPrim()
  updateBulletsCountSec()
  updateBulletsCountSpec()
  updateBulletsNamePrim()
  updateBulletsNameSec()
  updateBulletsNameSpec()
})

playerUnitName.subscribe(@(_) updateAllBulletsState())
isUnitDelayed.subscribe(@(_) updateAllBulletsState())
isVisibleOnHud.subscribe(@(v) v ? updateAllBulletsState() : null)

eventbus_subscribe("onBulletsAmountChanged", @(_) updateAllBulletsCount())

primaryAction.subscribe(function(_) {
  currentBulletIdxPrim.set(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
  nextBulletIdx.set(getNextBulletType(TRIGGER_GROUP_PRIMARY))
  updateAllBulletsCount()
})
primaryExtraAction.subscribe(function(_) {
  currentBulletIdxPrim.set(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
  nextBulletIdx.set(getNextBulletType(TRIGGER_GROUP_PRIMARY))
  updateAllBulletsCount()
})

secondaryAction.subscribe(function(_) {
  currentBulletIdxSec.set(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))
  nextBulletIdxSec.set(getNextBulletType(TRIGGER_GROUP_SECONDARY))
  updateAllBulletsCount()
})

specAction.subscribe(function(_) {
  currentBulletIdxSpec.set(getCurrentBulletType(TRIGGER_GROUP_SPECIAL_GUN))
  nextBulletIdxSpec.set(getNextBulletType(TRIGGER_GROUP_SPECIAL_GUN))
  updateAllBulletsCount()
})

const MAX_BULLETS = 2
function toggleNextBullet() {
  for (local offset = 1; offset < MAX_BULLETS; offset++) {
    let idx = (nextBulletIdx.get() + offset) % MAX_BULLETS
    if (getBulletCountByType(TRIGGER_GROUP_PRIMARY, idx) <= 0)
      continue
    changeBulletType(TRIGGER_GROUP_PRIMARY, idx)
    if (isSecondaryBulletsSame.get())
      setTimeout(0.1, @() changeBulletType(TRIGGER_GROUP_SECONDARY, idx)) 
    nextBulletIdx.set(idx)
    return true
  }
  return false
}

function selectBulletSec(idx) {
  changeBulletType(TRIGGER_GROUP_SECONDARY, idx)
  currentBulletIdxSec.set(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))
  nextBulletIdxSec.set(idx)
  updateAllBulletsCount()
}

function selectBulletSpec(idx) {
  changeBulletType(TRIGGER_GROUP_SPECIAL_GUN, idx)
  currentBulletIdxSpec.set(getCurrentBulletType(TRIGGER_GROUP_SPECIAL_GUN))
  nextBulletIdxSpec.set(idx)
  updateAllBulletsCount()
}

return {
  currentBulletIdxPrim
  currentBulletIdxSpec
  currentBulletIdxSec
  nextBulletIdx
  nextBulletName
  currentBulletName
  bulletsInfo
  bulletsInfoSec
  bulletsInfoSpec
  toggleNextBullet
  isSecondaryBulletsSame

  withExtraPrimary
  isFakeSecondary
  isFakeSpecial
  hasOnlyOneSideGroup

  mainBulletInfo
  extraBulletInfo
  mainBulletCount
  extraBulletCount
  bulletsNamePrim
  bulletsNameSec

  mainBulletInfoSec
  extraBulletInfoSec
  mainBulletCountSec
  extraBulletCountSec
  currentBulletNameSec
  nextBulletNameSec
  selectBulletSec

  mainBulletInfoSpec
  extraBulletInfoSpec
  mainBulletCountSpec
  extraBulletCountSpec
  currentBulletNameSpec
  nextBulletNameSpec
  selectBulletSpec

  nextBulletIdxSec
  nextBulletIdxSpec
}
