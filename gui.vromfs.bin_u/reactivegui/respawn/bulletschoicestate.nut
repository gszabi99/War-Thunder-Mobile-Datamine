from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let DataBlock = require("DataBlock")
let { get_blk_value_by_path, set_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let { ceil } = require("%sqstd/math.nut")
let { eachBlock, isDataBlock } = require("%sqstd/datablock.nut")
let { selSlot, cancelRespawn } = require("respawnState.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { round } = require("math")

const BULLETS_SLOTS = 2
const SAVE_ID = "bullets"
let BULLETS_LOW_AMOUNT = 5
let BULLETS_LOW_PERCENT = 25.0

let unitName = Computed(@() selSlot.value?.name)
let unitLevel = Computed(@() selSlot.value?.level ?? 0)
let bulletsInfo = Computed(@() unitName.value == null ? null
  : loadUnitBulletsChoice(unitName.value)?.commonWeapons.primary) //not support weapon presets yet beacause they are all empty.
let bulletsInfoSec = Computed(@() unitName.value == null ? null
  : loadUnitBulletsChoice(unitName.value)?.commonWeapons.secondary) //not support weapon presets yet beacause they are all empty.

let savedBullets = Watched(null)
let function loadSavedBullets(name) {
  if (name == null)
    return null
  let sBlk = get_local_custom_settings_blk()
  let res = get_blk_value_by_path(sBlk, $"{SAVE_ID}/{name}")
  return isDataBlock(res) ? res : null
}
let applySavedBullets = @(name) savedBullets(loadSavedBullets(name))
applySavedBullets(unitName.value)
unitName.subscribe(applySavedBullets)

isOnlineSettingsAvailable.subscribe(@(_) savedBullets(null)) //at this point local_custom_settings_blk can change, so clear link on its part.

let bulletStep = Computed(function() {
  let { catridge = 1, guns = 1 } = bulletsInfo.value
  return max(catridge * guns, 1)
})
let bulletTotalSteps = Computed(@()
  ceil((bulletsInfo.value?.total ?? 1).tofloat() / bulletStep.value).tointeger())

let chosenBullets = Computed(function() {
  let res = []
  if (bulletsInfo.value == null)
    return res
  let { fromUnitTags, bulletsOrder, bulletSets } = bulletsInfo.value
  let level = unitLevel.value
  let stepSize = bulletStep.value
  local leftSteps = bulletTotalSteps.value
  let used = {}
  if (savedBullets.value != null)
    eachBlock(savedBullets.value, function(blk) {
      let { name = null, count = 0 } = blk
      if (res.len() >= BULLETS_SLOTS
          || name not in bulletSets
          || name in used
          || (fromUnitTags?[name].reqLevel ?? 0) > level)
        return
      let steps = min(leftSteps, ceil(count.tofloat() / stepSize))
      leftSteps -= steps
      res.append({ name, count = steps * stepSize, idx = res.len() })
      used[name] <- true
    })

  if (res.len() < BULLETS_SLOTS)
    foreach (bName in bulletsOrder)
      if ((bName not in used) && (fromUnitTags?[bName].reqLevel ?? 0) <= level) {
        res.append({ name = bName, count = -1, idx = res.len() })
        if (res.len() >= BULLETS_SLOTS)
          break
      }

  local notInitedCount = res.reduce(@(accum, bData) bData.count < 0 ? accum + 1 : accum, 0)
  if (notInitedCount > 0)
    foreach (bData in res)
      if (bData.count < 0) {
        let steps = leftSteps / notInitedCount
        leftSteps -= steps
        bData.count = stepSize * round(steps / 2.0)
        notInitedCount--
      }

  return res
})

let bulletsToSpawn = Computed(function() {
  let { catridge = 1 } = bulletsInfo.value
  let res = chosenBullets.value.map(@(b) { name = b.name, count = b.count / catridge }) //need send catriges count for spawn instead of bullets count

  if (bulletsInfoSec.value == null)
    return res
  let { bulletsOrder, total } = bulletsInfoSec.value
  res.append({ name = bulletsOrder[0], count = total })
  return res
})

let chosenBulletsAmount = Computed(@() chosenBullets.value.reduce(@(acc, bullet) acc + bullet.count, 0))
let hasZeroBullets = Computed(@() chosenBulletsAmount.value == 0)
let hasLowBullets = Computed(@() chosenBulletsAmount.value < BULLETS_LOW_AMOUNT
  || chosenBulletsAmount.value < bulletsInfo.value.total * BULLETS_LOW_PERCENT / 100)

let function saveBullets(name, blk) {
  let sBlk = get_local_custom_settings_blk()
  set_blk_value_by_path(sBlk, $"{SAVE_ID}/{name}", blk)//-param-pos
  send("saveProfile", {})
}

let function setCurUnitBullets(slotIdx, bName, bCount) {
  if (unitName.value == null)
    return

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets.value) {
    let bBlk = DataBlock()
    bBlk.name = (idx == slotIdx) ? bName : slot.name
    bBlk.count = (idx == slotIdx) ? bCount : slot.count
    blk.bullet <- bBlk
  }
  savedBullets(blk)
  cancelRespawn() //to respawn on chosen bullets after
  saveBullets(unitName.value, blk)
}

let function setOrSwapUnitBullet(slotIdx, bName) {
  if (unitName.value == null || slotIdx not in chosenBullets.value)
    return
  let prevIdx = chosenBullets.value.findindex(@(s) s.name == bName)
  if (prevIdx == slotIdx)
    return

  let newNames = { [slotIdx] = bName }
  if (prevIdx != null)
    newNames[prevIdx] <- chosenBullets.value[slotIdx].name

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets.value) {
    let bBlk = DataBlock()
    bBlk.name = newNames?[idx] ?? slot.name
    bBlk.count = slot.count
    blk.bullet <- bBlk
  }
  savedBullets(blk)
  cancelRespawn() //to respawn on chosen bullets after
  saveBullets(unitName.value, blk)
}

let bulletLeftSteps = Computed(function() {
  let stepSize = bulletStep.value
  local leftSteps = bulletTotalSteps.value
  foreach (bData in chosenBullets.value)
    leftSteps -= bData.count / stepSize
  return leftSteps
})

return {
  bulletsInfo
  chosenBullets
  bulletsToSpawn
  bulletStep
  bulletTotalSteps
  bulletLeftSteps
  hasLowBullets
  hasZeroBullets

  setCurUnitBullets
  setOrSwapUnitBullet
}