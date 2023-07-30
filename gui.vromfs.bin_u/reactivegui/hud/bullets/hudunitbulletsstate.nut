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
let nextBulletCountPrim = Watched(0)
let nextBulletCountSec = Watched(0)

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

let nextBulletCount = Computed(@() nextBulletCountPrim.value + (isSecondaryBulletsSame.value ? nextBulletCountSec.value : 0))
let nextBulletName = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return getBulletNameByType(TRIGGER_GROUP_PRIMARY, nextBulletIdx.value)
})
let nextBulletInfo = Computed(@() bulletsInfo.value?.bulletSets[nextBulletName.value])

let currentBulletName = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return getBulletNameByType(TRIGGER_GROUP_PRIMARY, currentBulletIdxPrim.value)
})

let updateNextBulletCountP = @()
  nextBulletCountPrim(getBulletCountByType(TRIGGER_GROUP_PRIMARY, nextBulletIdx.value))
updateNextBulletCountP()
nextBulletIdx.subscribe(@(_) updateNextBulletCountP())
primaryAction.subscribe(function(_) {
  currentBulletIdxPrim(getCurrentBulletType(TRIGGER_GROUP_PRIMARY))
  nextBulletIdx(getNextBulletType(TRIGGER_GROUP_PRIMARY))
  updateNextBulletCountP()
})

let updateNextBulletCountS = @()
  nextBulletCountSec(getBulletCountByType(TRIGGER_GROUP_SECONDARY, nextBulletIdx.value))
updateNextBulletCountS()
nextBulletIdx.subscribe(@(_) updateNextBulletCountS())
secondaryAction.subscribe(function(_) {
  currentBulletIdxSec(getCurrentBulletType(TRIGGER_GROUP_SECONDARY))
  updateNextBulletCountS()
})

let MAX_BULLETS = 6
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

let function isExistBulletTypes() {
  for (local offset = 1; offset < MAX_BULLETS; offset++) {
    local idx = (nextBulletIdx.value + offset) % MAX_BULLETS
    if (getBulletCountByType(TRIGGER_GROUP_PRIMARY, idx) > 0)
      return true
  }
  return false
}

let needShowToggle = Computed(function() {
  let name = playerUnitName.value //warning disable: -declared-never-used
  let upd = isUnitDelayed.value //warning disable: -declared-never-used
  return nextBulletInfo.value != null && isExistBulletTypes()
})

return {
  currentBulletIdxPrim
  currentBulletIdxSec
  nextBulletIdx
  nextBulletCount
  nextBulletName
  currentBulletName
  nextBulletInfo
  bulletsInfo
  toggleNextBullet
  isSecondaryBulletsSame
  needShowToggle
}