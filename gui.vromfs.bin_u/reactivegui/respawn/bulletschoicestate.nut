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


const BULLETS_PRIM_SLOTS = 2
const BULLETS_SEC_SLOTS = 1
const SAVE_ID = "bullets"
let BULLETS_LOW_AMOUNT = 5
let BULLETS_LOW_PERCENT = 25.0

let ammoReductionFactorDef = 0.6 
let ammoReductionSecFactorDef = 1 
let ammoReductionFactorsByIdx = {
  [0] = 0.45, 
  [1] = 0.15 
}

let unitName = Computed(@() selSlot.value?.name)
let unitLevel = Computed(@() selSlot.value?.level ?? 0)
let bulletsInfo = Computed(@() unitName.value == null ? null
  : loadUnitBulletsChoice(unitName.value)?.commonWeapons.primary) 
let bulletsSecInfo = Computed(function() {
  if (unitName.get() == null)
    return null
  let { secondary = null, special = null } = loadUnitBulletsChoice(unitName.get())?.commonWeapons
  return secondary ?? special
})

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

isOnlineSettingsAvailable.subscribe(@(_) savedBullets(null)) 

let calcBulletStep = @(bInfo) max((bInfo?.catridge ?? 1) * (bInfo?.guns ?? 1), 1)
let bulletStep = Computed(@() calcBulletStep(bulletsInfo.get()))
let bulletSecStep = Computed(@() calcBulletStep(bulletsSecInfo.get()))

let bulletTotalCount = Computed(@() (bulletsInfo.value?.total ?? 1).tofloat())
let bulletSecTotalCount = Computed(@() (bulletsSecInfo.get()?.total ?? 1).tofloat())

let bulletTotalSteps = Computed(@() ceil(bulletTotalCount.get() / bulletStep.get()).tointeger())
let bulletSecTotalSteps = Computed(@() ceil(bulletSecTotalCount.get() / bulletSecStep.get()).tointeger())

let hasExtraBullets = Computed(@() bulletStep.get() * bulletTotalSteps.get() > bulletTotalCount.get())
let hasExtraBulletsSec = Computed(@() bulletSecStep.get() * bulletSecTotalSteps.get() > bulletSecTotalCount.get())

let calcVisibleBullets = @(bInfo, respawnUItems) (bInfo?.bulletSets ?? {}).reduce(function(res, _, name) {
  let { reqModification = "", isHidden = false } = bInfo?.fromUnitTags[name]
  return ((reqModification == "" || (respawnUItems?[reqModification] ?? 0) > 0)) && !isHidden ? res.$rawset(name, true)
    : res
}, {})
let visibleBullets = Computed(@() calcVisibleBullets(bulletsInfo.get(), respawnUnitItems.get()))
let visibleBulletsSec = Computed(@() calcVisibleBullets(bulletsSecInfo.get(), respawnUnitItems.get()))

function calcMaxBullets(bTotalSteps, bInfo, bSlots) {
  let bulletSlots = min(bSlots, bTotalSteps)
  return array(bulletSlots).map(@(_, idx) idx).reduce(function(res, slotIdx) {
    let remaining = bulletTotalCount.get() - res.total

    local curCount = (bInfo?.catridge ?? 1) * bulletSlots
    let maxCountSteps = (bulletTotalCount.get() / curCount).tointeger()
    curCount = curCount * maxCountSteps

    res.maxCounts[slotIdx] <- remaining >= curCount ? curCount : remaining
    res.total += curCount
    return res
  }, { maxCounts = {}, total = 0 }).maxCounts
}
let maxBulletsCountForExtraAmmo = Computed(@() !hasExtraBullets.get() ? {}
  : calcMaxBullets(bulletTotalSteps.get(), bulletsInfo.get(), BULLETS_PRIM_SLOTS))
let maxBulletsSecCountForExtraAmmo = Computed(@() !hasExtraBulletsSec.get() ? {}
  : calcMaxBullets(bulletSecTotalSteps.get(), bulletsSecInfo.get(), BULLETS_SEC_SLOTS))

function calcChosenBullets(bInfo, level, stepSize, visible, maxBullets,
  hasExtra, bTotalSteps, sBullets, sBulletLimit, ammoReductionFactor, bSlots, addIndex = 0
) {
  let res = []
  if (bInfo == null)
    return res
  let { fromUnitTags, bulletsOrder } = bInfo
  local leftSteps = bTotalSteps
  local bulletSlots = min(bSlots, bTotalSteps)
  local bulletIdx = 0
  let used = {}
  if (sBullets != null)
    eachBlock(sBullets, function(blk) {
      bulletIdx += 1
      if (sBulletLimit(bulletIdx))
        return
      let { name = null, count = 0 } = blk
      let { reqLevel = 0, isExternalAmmo = false, maxCount = leftSteps } = fromUnitTags?[name]
      if (res.len() >= bulletSlots
          || !visible?[name]
          || name in used
          || reqLevel > level
          || (res.len() == 0 && isExternalAmmo))
        return
      local steps = min(ceil(count.tofloat() / stepSize), leftSteps, maxCount)
      if (bTotalSteps == 1) 
        steps = 1
      leftSteps -= steps
      let countBullets = steps * stepSize
      let maxBulletsCount = maxBullets?[res.len()] ?? 0
      res.append({ name, idx = res.len() + addIndex, count = !hasExtra ? countBullets
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
        res.append({ name = bName, count = -1, idx = res.len() + addIndex })
        if (res.len() >= bulletSlots)
          break
      }

  local notInitedCount = res.reduce(@(accum, bData) bData.count < 0 ? accum + 1 : accum, 0)
  if (notInitedCount > 0) {
    let bulletSlotsCount = res.len()
    foreach (bData in res)
      if (bData.count < 0) {
        bData.count = 0
        if (leftSteps > 0) {
          local steps = min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
          if (!hasExtra) {
            if (bulletSlotsCount == 1 && leftSteps > 1)
              steps = min(ceil(bTotalSteps * ammoReductionFactor), leftSteps)
            else if(bulletSlotsCount > 1)
              steps = min(ceil(bTotalSteps * (ammoReductionFactorsByIdx?[bData.idx] ?? 1)), leftSteps)
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
}

let chosenBullets = Computed(@() calcChosenBullets(bulletsInfo.get(), unitLevel.get(), bulletStep.get(),
  visibleBullets.get(), maxBulletsCountForExtraAmmo.get(), hasExtraBullets.get(), bulletTotalSteps.get(),
  savedBullets.get(),
  @(idx) idx > BULLETS_PRIM_SLOTS,
  ammoReductionFactorDef,
  BULLETS_PRIM_SLOTS))
let chosenBulletsSec = Computed(@() calcChosenBullets(bulletsSecInfo.get(), unitLevel.get(), bulletSecStep.get(),
  visibleBulletsSec.get(), maxBulletsSecCountForExtraAmmo.get(), hasExtraBulletsSec.get(), bulletSecTotalSteps.get(),
  savedBullets.get(),
  @(idx) idx <= BULLETS_PRIM_SLOTS,
  ammoReductionSecFactorDef,
  BULLETS_SEC_SLOTS,
  chosenBullets.get().len()))

let bulletFormat = @(b, c) { name = b.name, count = ceil(b.count / c).tointeger() }
let bulletsToSpawn = Computed(function() {
  let res = chosenBullets.get().map(@(b) bulletFormat(b, bulletsInfo.get()?.catridge ?? 1)) 
  if (bulletsSecInfo.get() == null)
    return res
  if (res.len() < BULLETS_PRIM_SLOTS)
    res.resize(BULLETS_PRIM_SLOTS, { name = "", count = 0 }) 
  let { catridge = 1, bulletsOrder = [""], total = 0} = bulletsSecInfo.get()
  let secBulletsToSpawn = chosenBulletsSec.get().len() > 0
    ? chosenBulletsSec.get().map(@(b) bulletFormat(b, catridge))
    : [bulletFormat({name = bulletsOrder[0], count = total}, catridge)]

  res.extend(secBulletsToSpawn)
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
  setBlkValueByPath(sBlk, $"{SAVE_ID}/{name}", blk)
  eventbus_send("saveProfile", {})
}

function collectChangedBlkBullet(slot, hasChanged, bName, bCount) {
  let blk = DataBlock()
  blk.name = hasChanged ? bName : slot.name
  blk.count = hasChanged ? bCount : slot.count
  return blk
}

function setCurUnitBullets(slotIdx, bName, bCount) {
  if (unitName.value == null)
    return

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets.get())
    blk.bullet <- collectChangedBlkBullet(slot, idx == slotIdx, bName, bCount)
  foreach (idx, slot in chosenBulletsSec.get())
    blk.bullet <- collectChangedBlkBullet(slot, idx + BULLETS_PRIM_SLOTS == slotIdx, bName, bCount)
  savedBullets(blk)
  cancelRespawn() 
  saveBullets(unitName.value, blk)
}

function collectBlkBullet(slot, maxBullets, withExtraBullets, newName) {
  let { name, count } = slot
  let blk = DataBlock()
  blk.name = newName ?? name
  blk.count = (!withExtraBullets || count == 0) ? count : (maxBullets ?? 0)
  return blk
}

function setOrSwapUnitBullet(slotIdx, bName) {
  if (unitName.get() == null)
    return

  let bullets = slotIdx >= BULLETS_PRIM_SLOTS ? chosenBulletsSec.get() : chosenBullets.get()
  let actualBulletIdx = slotIdx % BULLETS_PRIM_SLOTS
  if (actualBulletIdx not in bullets)
    return

  let prevIdx = bullets.findindex(@(s) s.name == bName)
  if (prevIdx == slotIdx)
    return

  let newNames = { [slotIdx] = bName }
  if (prevIdx != null)
    newNames[prevIdx] <- bullets[actualBulletIdx].name

  let blk = DataBlock()
  foreach (idx, slot in chosenBullets.get())
    blk.bullet <- collectBlkBullet(slot, maxBulletsCountForExtraAmmo.get()?[idx],
      hasExtraBullets.get(), newNames?[idx])
  foreach (idx, slot in chosenBulletsSec.get())
    blk.bullet <- collectBlkBullet(slot, maxBulletsSecCountForExtraAmmo.get()?[idx],
      hasExtraBulletsSec.get(), newNames?[idx + BULLETS_PRIM_SLOTS])
  savedBullets(blk)
  cancelRespawn() 
  saveBullets(unitName.get(), blk)
}

let calcLeftSteps = @(bStep, bTotalSteps, bullets) bullets.reduce(@(res, bData) res - bData.count / bStep, bTotalSteps)
let bulletLeftSteps = Computed(@() calcLeftSteps(bulletStep.get(), bulletTotalSteps.get(), chosenBullets.get()))
let bulletSecLeftSteps = Computed(@() calcLeftSteps(bulletSecStep.get(), bulletSecTotalSteps.get(), chosenBulletsSec.get()))

function resetSavedBullets() {
  get_local_custom_settings_blk().removeBlock(SAVE_ID)
  if (unitName.get() != null)
    applySavedBullets(unitName.get())
  eventbus_send("saveProfile", {})
}

register_command(resetSavedBullets, "debug.reset_saved_bullets")

return {
  bulletsInfo
  bulletsSecInfo
  visibleBullets
  visibleBulletsSec
  chosenBullets
  chosenBulletsSec
  bulletsToSpawn
  bulletStep
  bulletSecStep
  bulletTotalSteps
  bulletSecTotalSteps
  bulletLeftSteps
  bulletSecLeftSteps
  hasLowBullets
  hasZeroBullets
  hasChangedCurSlotBullets
  hasExtraBullets
  hasExtraBulletsSec
  hasZeroMainBullets
  maxBulletsCountForExtraAmmo
  maxBulletsSecCountForExtraAmmo

  setCurUnitBullets
  setOrSwapUnitBullet

  BULLETS_PRIM_SLOTS
}