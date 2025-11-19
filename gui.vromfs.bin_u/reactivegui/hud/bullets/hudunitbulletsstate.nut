from "%globalsDarg/darg_library.nut" import *
let { getBulletNameByType, getBulletCountByType, getNextBulletType, getCurrentBulletType,
  changeBulletType
} = require("vehicleModel")
let { setTimeout, deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { playerUnitName, isUnitDelayed, isVisibleOnHud } = require("%rGui/hudState.nut")
let { primaryAction, secondaryAction } = require("%rGui/hud/actionBar/actionBarState.nut")
let { eventbus_subscribe } = require("eventbus")

let nextBulletIdx = Watched(getNextBulletType(TRIGGER_GROUP_PRIMARY))
let currentBulletIdxPrim = Watched(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
let currentBulletIdxSec = Watched(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))
let bulletsCountPrim = Watched(array(3, 0))
let bulletsNamePrim = Watched(array(3, TRIGGER_GROUP_PRIMARY).map(getBulletNameByType))
let bulletsNameSec = Watched(array(3, TRIGGER_GROUP_SECONDARY).map(getBulletNameByType))
let mainBulletCount = Computed(@() bulletsCountPrim.get()[0])
let extraBulletCount = Computed(@() bulletsCountPrim.get()[1])

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
let isSecondaryBulletsSame = Computed(function() {
  if ((playerUnitName.get() ?? "") == "" || bulletsInfo.get() == null || bulletsInfoSec.get() == null)
    return false
  let secondaryOrder = loadUnitBulletsChoice(playerUnitName.get())?.commonWeapons.secondary.bulletsOrder
  return secondaryOrder != null && isEqual(bulletsInfo.get().bulletsOrder, secondaryOrder)
})

let nextBulletName = Computed(@() bulletsNamePrim.get()?[nextBulletIdx.get()] ?? "")
let currentBulletName = Computed(@() bulletsNamePrim.get()?[currentBulletIdxPrim.get()] ?? "")
let mainBulletInfo = Computed(@() bulletsInfo.get()?.bulletSets[bulletsNamePrim.get()[0]])
let extraBulletInfo = Computed(@() bulletsInfo.get()?.bulletSets[bulletsNamePrim.get()[1]])

let mkUpdateBulletsState = @(trigger, watch, getter) function updateBulletsState() {
  let newVal = array(3, trigger).map(getter)
  if (!isEqual(newVal, watch.get()))
    watch.set(newVal)
}

let updateBulletsCountPrim = mkUpdateBulletsState(TRIGGER_GROUP_PRIMARY, bulletsCountPrim, getBulletCountByType)
let updateBulletsNamePrim = mkUpdateBulletsState(TRIGGER_GROUP_PRIMARY, bulletsNamePrim, getBulletNameByType)
let updateBulletsNameSec = mkUpdateBulletsState(TRIGGER_GROUP_SECONDARY, bulletsNameSec, getBulletNameByType)

updateBulletsCountPrim()
updateBulletsNamePrim()
updateBulletsNameSec()

let updateAllBulletsCount = @() deferOnce(updateBulletsCountPrim)
let updateAllBulletsState = @() deferOnce(function() {
  updateBulletsCountPrim()
  updateBulletsNamePrim()
  updateBulletsNameSec()
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
secondaryAction.subscribe(@(_) currentBulletIdxSec.set(getCurrentBulletType(TRIGGER_GROUP_SECONDARY)))

let MAX_BULLETS = 2
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

return {
  currentBulletIdxPrim
  currentBulletIdxSec
  nextBulletIdx
  nextBulletName
  currentBulletName
  bulletsInfo
  bulletsInfoSec
  toggleNextBullet
  isSecondaryBulletsSame

  mainBulletInfo
  extraBulletInfo
  mainBulletCount
  extraBulletCount
  bulletsNamePrim
  bulletsNameSec
}
