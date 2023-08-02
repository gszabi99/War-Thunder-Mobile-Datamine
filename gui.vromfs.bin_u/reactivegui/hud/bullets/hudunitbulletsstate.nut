from "%globalsDarg/darg_library.nut" import *
let { getBulletNameByType, getBulletCountByType, getNextBulletType, getCurrentBulletType,
  changeBulletType
} = require("vehicleModel")
let { setTimeout } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { playerUnitName, isUnitDelayed } = require("%rGui/hudState.nut")
let { primaryAction, secondaryAction } = require("%rGui/hud/actionBar/actionBarState.nut")

let nextBulletIdx = Watched(getNextBulletType(TRIGGER_GROUP_PRIMARY))
let currentBulletIdxPrim = Watched(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
let currentBulletIdxSec = Watched(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))

let bulletsInfo = Computed(function() {
  if ((playerUnitName.value ?? "") == "")
    return null
  return loadUnitBulletsChoice(playerUnitName.value)?.commonWeapons.primary  //todo: load preset by weapon here if not empty (choice?[weaponName])
})
let isSecondaryBulletsSame = Computed(function() {
  if ((playerUnitName.value ?? "") == "" || bulletsInfo.value == null)
    return false
  let secondaryOrder = loadUnitBulletsChoice(playerUnitName.value)?.commonWeapons.secondary.bulletsOrder
  return secondaryOrder != null && isEqual(bulletsInfo.value.bulletsOrder, secondaryOrder)
})

let nextBulletName = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return getBulletNameByType(TRIGGER_GROUP_PRIMARY, nextBulletIdx.value)
})
let currentBulletName = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return getBulletNameByType(TRIGGER_GROUP_PRIMARY, currentBulletIdxPrim.value)
})

let mainBulletInfo = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return bulletsInfo.value?.bulletSets[getBulletNameByType(TRIGGER_GROUP_PRIMARY, 0)]
})
let extraBulletInfo = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return bulletsInfo.value?.bulletSets[getBulletNameByType(TRIGGER_GROUP_PRIMARY, 1)]
})

let mainBulletCount = Watched(getBulletCountByType(TRIGGER_GROUP_PRIMARY, 0))
let extraBulletCount = Watched(getBulletCountByType(TRIGGER_GROUP_PRIMARY, 1))

let function updateBulletsCount() {
  mainBulletCount(getBulletCountByType(TRIGGER_GROUP_PRIMARY, 0))
  extraBulletCount(getBulletCountByType(TRIGGER_GROUP_PRIMARY, 1))
}
playerUnitName.subscribe(@(_) updateBulletsCount())
isUnitDelayed.subscribe(@(_) updateBulletsCount())

primaryAction.subscribe(function(_) {
  currentBulletIdxPrim(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
  nextBulletIdx(getNextBulletType(TRIGGER_GROUP_PRIMARY))
  updateBulletsCount()
})
secondaryAction.subscribe(@(_) currentBulletIdxSec(getCurrentBulletType(TRIGGER_GROUP_SECONDARY)))

let MAX_BULLETS = 2
let function toggleNextBullet() {
  for (local offset = 1; offset < MAX_BULLETS; offset++) {
    let idx = (nextBulletIdx.value + offset) % MAX_BULLETS
    if (getBulletCountByType(TRIGGER_GROUP_PRIMARY, idx) <= 0)
      continue
    changeBulletType(TRIGGER_GROUP_PRIMARY, idx)
    if (isSecondaryBulletsSame.value)
      setTimeout(0.1, @() changeBulletType(TRIGGER_GROUP_SECONDARY, idx)) //cant set next 2 bullets at single frame
    nextBulletIdx(idx)
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
  toggleNextBullet
  isSecondaryBulletsSame

  mainBulletInfo
  extraBulletInfo
  mainBulletCount
  extraBulletCount
}
