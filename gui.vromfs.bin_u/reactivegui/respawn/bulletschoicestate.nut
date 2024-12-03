from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let DataBlock = require("DataBlock")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { ceil } = require("%sqstd/math.nut")
let { eachBlock, isDataBlock } = require("%sqstd/datablock.nut")
let { selSlot, cancelRespawn } = require("respawnState.nut")
let { respawnUnitItems } = require("%appGlobals/clientState/respawnStateBase.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { register_command } = require("console")


const BULLETS_SLOTS = 2
const SAVE_ID = "bullets"
let BULLETS_LOW_AMOUNT = 5
let BULLETS_LOW_PERCENT = 25.0

let ammoReductionFactorDef = 0.6 // for only one slot
let ammoReductionFactorsByIdx = {
  [0] = 0.45, // for first slot
  [1] = 0.15 // for second slot
}

let unitName = Computed(@() selSlot.value?.name)
let unitLevel = Computed(@() selSlot.value?.level ?? 0)
let bulletsInfo = Computed(@() unitName.value == null ? null
  : loadUnitBulletsChoice(unitName.value)?.commonWeapons.primary) //not support weapon presets yet beacause they are all empty.
let bulletsInfoSec = Computed(@() unitName.value == null ? null
  : loadUnitBulletsChoice(unitName.value)?.commonWeapons.secondary) //not support weapon presets yet beacause they are all empty.

let hasChangedCurSlotBullets = Watched(false)
selSlot.subscribe(@(_) hasChangedCurSlotBullets(false))

let savedBullets = Watched(null)
function loadSavedBullets(name) {
  if (name == null)
    return null
  let sBlk = get_local_custom_settings_blk()
  let res = getBlkValueByPath(sBlk, $"{SAVE_ID}/{name}")
  if (!isDataBlock(res))
    return null
  let resExt = DataBlock()
  resExt.setFrom(res)
  return resExt
}
let applySavedBullets = @(name) savedBullets(loadSavedBullets(name))
applySavedBullets(unitName.value)
unitName.subscribe(applySavedBullets)

isOnlineSettingsAvailable.subscribe(@(_) savedBullets(null)) //at this point local_custom_settings_blk can change, so clear link on its part.

let bulletStep = Computed(function() {
  let { catridge = 1, guns = 1 } = bulletsInfo.value
  return max(catridge * guns, 1)
})
let bulletTotalCount = Computed(@() (bulletsInfo.value?.total ?? 1).tofloat())
let bulletTotalSteps = Computed(@()
  ceil(bulletTotalCount.get() / bulletStep.value).tointeger())
let hasExtraBullets = Computed(@() bulletStep.get() * bulletTotalSteps.get() > bulletTotalCount.get())

let visibleBullets = Computed(function() {
  let res = {}
  if (bulletsInfo.value == null)
    return res
  let { fromUnitTags, bulletSets } = bulletsInfo.value
  foreach(name, _ in bulletSets) {
    let { reqModification = "" } = fromUnitTags?[name]
    if (reqModification == "" || (respawnUnitItems.value?[reqModification] ?? 0) > 0)
      res[name] <- true
  }
  return res
})

let maxBulletsCountForExtraAmmo = Computed(function() {
  if(!hasExtraBullets.get())
    return {}
  let bulletSlots = min(BULLETS_SLOTS, bulletTotalSteps.get())
  let { catridge = 1 } = bulletsInfo.get()

  return array(bulletSlots).map(@(_, idx) idx).reduce(function(res, slotIdx) {
    let remaining = bulletTotalCount.get() - res.total

    local curCount = catridge * bulletSlots
    let maxCountSteps = (bulletTotalCount.get() / curCount).tointeger()
    curCount = curCount * maxCountSteps

    res.maxCounts[slotIdx] <- remaining >= curCount ? curCount : remaining
    res.total += curCount
    return res
  }, { maxCounts = {}, total = 0 }).maxCounts
})

let chosenBullets = Computed(function() {
  let res = []
  if (bulletsInfo.value == null)
    return res
  let { fromUnitTags, bulletsOrder } = bulletsInfo.value
  let level = unitLevel.value
  let stepSize = bulletStep.value
  let visible = visibleBullets.value
  let maxBullets = maxBulletsCountForExtraAmmo.get()
  let hasExtra = hasExtraBullets.get()
  local leftSteps = bulletTotalSteps.value
  local bulletSlots = min(BULLETS_SLOTS, bulletTotalSteps.value)
  let used = {}
  if (savedBullets.value != null)
    eachBlock(savedBullets.value, function(blk) {
      let { name = null, count = 0 } = blk
      let { reqLevel = 0, isExternalAmmo = false, maxCount = leftSteps } = fromUnitTags?[name]
      if (res.len() >= bulletSlots
          || !visible?[name]
          || name in used
          || reqLevel > level
          || (res.len() == 0 && isExternalAmmo))
        return
      local steps = min(ceil(count.tofloat() / stepSize), leftSteps, maxCount)
      if (bulletTotalSteps.value == 1) //special case when user have saved 0 (and disabled choose slider)
        steps = 1
      leftSteps -= steps
      let countBullets = steps * stepSize
      let maxBulletsCount = maxBullets?[res.len()] ?? 0
      res.append({ name, idx = res.len(), count = !hasExtra ? countBullets
        : count == 0 ? count
        : maxBulletsCount })
      used[name] <- true
    })

  if (res.len() < bulletSlots)
    foreach (bName in bulletsOrder)
      if ((bName not in used)
          && visible?[bName]
          && (fromUnitTags?[bName].reqLevel ?? 0) <= level
      ) {
        res.append({ name = bName, count = -1, idx = res.len() })
        if (res.len() >= bulletSlots)
          break
      }

  local notInitedCount = res.reduce(@(accum, bData) bData.count < 0 ? accum + 1 : accum, 0)
  if (notInitedCount > 0) {
    let bulletSlotsCount = res.len()
    let totalSteps = bulletTotalSteps.get()
    foreach (bData in res)
      if (bData.count < 0) {
        bData.count = 0
        if (leftSteps > 0) {
          local steps = min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
          if (!hasExtra) {
            if (bulletSlotsCount == 1 && leftSteps > 1)
              steps = min(ceil(totalSteps * ammoReductionFactorDef), leftSteps)
            else if(bulletSlotsCount > 1)
              steps = min(ceil(totalSteps * (ammoReductionFactorsByIdx?[bData.idx] ?? 1)), leftSteps)
            bData.count = steps * stepSize
          }
          else
            bData.count = min(steps * stepSize, (maxBullets?[bData.idx] ?? 0))
          leftSteps -= steps
          notInitedCount--
        }
      }
  }

  return res
})

let bulletsToSpawn = Computed(function() {
  let { catridge = 1 } = bulletsInfo.value
  let res = chosenBullets.value.map(@(b) { name = b.name, count = ceil(b.count / catridge).tointeger() }) //need send catriges count for spawn instead of bullets count

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
let hasZeroMainBullets = Computed(@() hasExtraBullets.get()
  && bulletsToSpawn.get().len() > 0
  && bulletsToSpawn.get()[0].count == 0)

function saveBullets(name, blk) {
  hasChangedCurSlotBullets(true)
  let sBlk = get_local_custom_settings_blk()
  setBlkValueByPath(sBlk, $"{SAVE_ID}/{name}", blk)//-param-pos
  eventbus_send("saveProfile", {})
}

function setCurUnitBullets(slotIdx, bName, bCount) {
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

function setOrSwapUnitBullet(slotIdx, bName) {
  if (unitName.get() == null || slotIdx not in chosenBullets.get())
    return
  let prevIdx = chosenBullets.get().findindex(@(s) s.name == bName)
  if (prevIdx == slotIdx)
    return

  let newNames = { [slotIdx] = bName }
  if (prevIdx != null)
    newNames[prevIdx] <- chosenBullets.get()[slotIdx].name

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets.get()) {
    let maxBulletsCount = maxBulletsCountForExtraAmmo.get()?[idx] ?? 0
    let { name, count } = slot
    let bBlk = DataBlock()
    bBlk.name = newNames?[idx] ?? name
    bBlk.count = !hasExtraBullets.get() ? count
      : count == 0 ? count
      : maxBulletsCount
    blk.bullet <- bBlk
  }
  savedBullets(blk)
  cancelRespawn() //to respawn on chosen bullets after
  saveBullets(unitName.get(), blk)
}

let bulletLeftSteps = Computed(function() {
  let stepSize = bulletStep.value
  local leftSteps = bulletTotalSteps.value
  foreach (bData in chosenBullets.value)
    leftSteps -= bData.count / stepSize
  return leftSteps
})

function resetSavedBullets() {
  get_local_custom_settings_blk().removeBlock(SAVE_ID)
  if (unitName.get() != null)
    applySavedBullets(unitName.get())
  eventbus_send("saveProfile", {})
}

register_command(resetSavedBullets, "debug.reset_saved_bullets")

return {
  bulletsInfo
  visibleBullets
  chosenBullets
  bulletsToSpawn
  bulletStep
  bulletTotalSteps
  bulletLeftSteps
  hasLowBullets
  hasZeroBullets
  hasChangedCurSlotBullets
  hasExtraBullets
  hasZeroMainBullets
  maxBulletsCountForExtraAmmo

  setCurUnitBullets
  setOrSwapUnitBullet
}