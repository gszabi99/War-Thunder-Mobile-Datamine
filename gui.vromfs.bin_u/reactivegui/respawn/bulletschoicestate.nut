from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%sqstd/math.nut" import ceil
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BULLETS_LOW_AMOUNT,
  BULLETS_LOW_PERCENT, BULLETS_SPEC_SLOTS, ammoReductionSecFactorDef, ammoReductionSpecFactorDef, BS_BR_PICKUP
from "%rGui/bullets/calcBullets.nut" import calcBulletStep, calcBulletsStatus, calcChosenBullets, calcMaxBullets,
  calcLeftSteps, ammoReductionFactorDefExt, ammoReductionFactorsByIdxExt
from "%rGui/bullets/savedBullets.nut" import setUnitBullets, setOrSwapUnitBullet, resetSavedBullets,
  applySavedBullets, savedBullets
from "%rGui/respawn/respawnState.nut" import selSlot, cancelRespawn
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice

const BR_PICKUP_RESERVE = 999

let unitName = Computed(@() selSlot.get()?.name)
let bulletsInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.primary) 

let bulletsSecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.secondary)
let bulletsSpecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.special)

let hasChangedCurSlotBullets = Watched(false)
selSlot.subscribe(@(_) hasChangedCurSlotBullets.set(false))

applySavedBullets(unitName.get())
unitName.subscribe(applySavedBullets)

let bulletStep = Computed(@() calcBulletStep(bulletsInfo.get()))
let bulletSecStep = Computed(@() calcBulletStep(bulletsSecInfo.get()))
let bulletSpecStep = Computed(@() calcBulletStep(bulletsSpecInfo.get()))

let bulletTotalCount = Computed(@() (bulletsInfo.get()?.total ?? 1).tofloat())
let bulletSecTotalCount = Computed(@() (bulletsSecInfo.get()?.total ?? 1).tofloat())
let bulletSpecTotalCount = Computed(@() (bulletsSpecInfo.get()?.total ?? 1).tofloat())

let bulletTotalSteps = Computed(@() ceil(bulletTotalCount.get() / bulletStep.get()).tointeger())
let bulletSecTotalSteps = Computed(@() ceil(bulletSecTotalCount.get() / bulletSecStep.get()).tointeger())
let bulletSpecTotalSteps = Computed(@() ceil(bulletSpecTotalCount.get() / bulletSpecStep.get()).tointeger())

let hasExtraBullets = Computed(@() bulletStep.get() * bulletTotalSteps.get() > bulletTotalCount.get())
let hasExtraBulletsSec = Computed(@() bulletSecStep.get() * bulletSecTotalSteps.get() > bulletSecTotalCount.get())
let hasExtraBulletsSpec = Computed(@() bulletSpecStep.get() * bulletSpecTotalSteps.get() > bulletSpecTotalCount.get())


let isFakeSecondary = Computed(@() bulletsSecInfo.get() == null
  || (bulletSecTotalSteps.get() <= 1 && bulletsSecInfo.get().bulletSets.len() <= 1))
let isFakeSpecial = Computed(@() bulletsSpecInfo.get() == null
  || (bulletSpecTotalSteps.get() <= 1 && bulletsSpecInfo.get().bulletSets.len() <= 1))
let hasOnlyOneSideGroup = Computed(@() isFakeSecondary.get() != isFakeSpecial.get())

let secBulletsSlots = Computed(@() !isFakeSecondary.get() && hasOnlyOneSideGroup.get() ? BULLETS_PRIM_SLOTS : BULLETS_SEC_SLOTS)
let specBulletsSlots = Computed(@() !isFakeSpecial.get() && hasOnlyOneSideGroup.get() ? BULLETS_PRIM_SLOTS : BULLETS_SPEC_SLOTS)

let calcBulletsStatusSlot = @(info, slot) slot == null ? {}
  : calcBulletsStatus(info, slot.level, slot.mods, slot.modPresetCfg)
let bulletsStatus = Computed(@() calcBulletsStatusSlot(bulletsInfo.get(), selSlot.get()))
let bulletsStatusSec = Computed(@() calcBulletsStatusSlot(bulletsSecInfo.get(), selSlot.get()))
let bulletsStatusSpec = Computed(@() calcBulletsStatusSlot(bulletsSpecInfo.get(), selSlot.get()))

let maxBulletsCountForExtraAmmo = Computed(@() !hasExtraBullets.get() ? {}
  : calcMaxBullets(bulletTotalSteps.get(), bulletsInfo.get(), bulletTotalCount.get(), BULLETS_PRIM_SLOTS))
let maxBulletsSecCountForExtraAmmo = Computed(@() !hasExtraBulletsSec.get() ? {}
  : calcMaxBullets(bulletSecTotalSteps.get(), bulletsSecInfo.get(), bulletSecTotalCount.get(), secBulletsSlots.get()))
let maxBulletsSpecCountForExtraAmmo = Computed(@() !hasExtraBulletsSpec.get() ? {}
  : calcMaxBullets(bulletSpecTotalSteps.get(), bulletsSpecInfo.get(), bulletSpecTotalCount.get(), specBulletsSlots.get()))

let chosenBullets = Computed(@() calcChosenBullets(bulletsInfo.get(), bulletStep.get(),
  bulletsStatus.get(), maxBulletsCountForExtraAmmo.get(), hasExtraBullets.get(), bulletTotalSteps.get(),
  savedBullets.get(),
  @(idx) idx > BULLETS_PRIM_SLOTS,
  ammoReductionFactorDefExt.get(),
  ammoReductionFactorsByIdxExt.get(),
  BULLETS_PRIM_SLOTS))
let primaryCount = Computed(@() chosenBullets.get().len())

let chosenBulletsSec = Computed(@()
  calcChosenBullets(bulletsSecInfo.get(), bulletSecStep.get(),
    bulletsStatusSec.get(), maxBulletsSecCountForExtraAmmo.get(), hasExtraBulletsSec.get(), bulletSecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS,
    ammoReductionSecFactorDef,
    ammoReductionFactorsByIdxExt.get(),
    secBulletsSlots.get(),
    BULLETS_PRIM_SLOTS
  ).map(@(s) s.$rawset("visIdx", s.idx - BULLETS_PRIM_SLOTS + primaryCount.get())))
let secondaryCount = Computed(@() chosenBulletsSec.get().len())

let chosenBulletsSpec = Computed(@()
  calcChosenBullets(bulletsSpecInfo.get(), bulletSpecStep.get(),
    bulletsStatusSpec.get(), maxBulletsSpecCountForExtraAmmo.get(), hasExtraBulletsSpec.get(), bulletSpecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS + secondaryCount.get(),
    ammoReductionSpecFactorDef,
    ammoReductionFactorsByIdxExt.get(),
    specBulletsSlots.get(),
    BULLETS_PRIM_SLOTS + secBulletsSlots.get()
  ).map(@(s) s.$rawset("visIdx", (s.idx - (BULLETS_PRIM_SLOTS + secBulletsSlots.get())) + primaryCount.get() + secondaryCount.get())))

let isBrPickupBullet = @(status, bullet) ((status?[bullet.name] ?? 0) & BS_BR_PICKUP) != 0
let bulletFormat = @(b, c, tg) { name = b.name, count = ceil(b.count / c).tointeger(), triggerGroup = tg }
let bulletsToSpawn = Computed(function() {
  let primTg = bulletsInfo.get()?.triggerGroup ?? "primary"
  let primCatridge = bulletsInfo.get()?.catridge ?? 1
  let status = bulletsStatus.get()
  let res = chosenBullets.get().map(function(b) {
    let formatB = bulletFormat(b, primCatridge, primTg)
    if (isBrPickupBullet(status, b))
      formatB.count = BR_PICKUP_RESERVE
    return formatB
  })
  if (isFakeSecondary.get() && isFakeSpecial.get())
    return res

  if (!isFakeSecondary.get()) {
    let secTg = bulletsSecInfo.get()?.triggerGroup ?? "secondary"
    let { catridge = 1, bulletsOrder = [""], total = 0 } = bulletsSecInfo.get()
    let secBulletsToSpawn = chosenBulletsSec.get().len() > 0
      ? chosenBulletsSec.get().map(@(b) bulletFormat(b, catridge, secTg))
      : [bulletFormat({ name = bulletsOrder[0], count = total }, catridge, secTg)]
    res.extend(secBulletsToSpawn)
  }

  if (!isFakeSpecial.get()) {
    let specTg = bulletsSpecInfo.get()?.triggerGroup ?? "special"
    let specCatridge = bulletsSpecInfo.get()?.catridge ?? 1
    let specBulletsOrder = bulletsSpecInfo.get()?.bulletsOrder ?? [""]
    let specTotal = bulletsSpecInfo.get()?.total ?? 0
    let specBulletsToSpawn = chosenBulletsSpec.get().len() > 0
      ? chosenBulletsSpec.get().map(@(b) bulletFormat(b, specCatridge, specTg))
      : [bulletFormat({ name = specBulletsOrder[0], count = specTotal }, specCatridge, specTg)]
    res.extend(specBulletsToSpawn)
  }

  return res
})

let brPickupPrimIdx = Computed(@() chosenBullets.get().findindex(@(bullet) isBrPickupBullet(bulletsStatus.get(), bullet)) ?? -1)
let chosenBulletsAmount = Computed(@() chosenBullets.get()
  .reduce(@(acc, bullet) isBrPickupBullet(bulletsStatus.get(), bullet) ? acc : acc + bullet.count, 0))
let chosenBulletsSecAmount = Computed(@() chosenBulletsSec.get().len() > 0
  ? chosenBulletsSec.get().reduce(@(acc, bullet) isBrPickupBullet(bulletsStatusSec.get(), bullet) ? acc : acc + bullet.count, 0)
  : -1)
let chosenBulletsSpecAmount = Computed(@() chosenBulletsSpec.get().len() > 0
  ? chosenBulletsSpec.get().reduce(@(acc, bullet) isBrPickupBullet(bulletsStatusSpec.get(), bullet) ? acc : acc + bullet.count, 0)
  : -1)
let hasZeroBullets = Computed(@() chosenBulletsAmount.get() == 0 || chosenBulletsSecAmount.get() == 0 || chosenBulletsSpecAmount.get() == 0)
let hasLowBullets = Computed(@() chosenBulletsAmount.get() < BULLETS_LOW_AMOUNT
  || chosenBulletsAmount.get() < bulletsInfo.get().total * BULLETS_LOW_PERCENT / 100)
let hasZeroMainBullets = Computed(@() hasExtraBullets.get()
  && bulletsToSpawn.get().len() > 0
  && bulletsToSpawn.get()[0].count == 0)

function setCurUnitBullets(slotIdx, bName, bCount) {
  if (!setUnitBullets(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(), slotIdx, bName, bCount))
    return
  hasChangedCurSlotBullets.set(true)
  cancelRespawn() 
}

function setOrSwapCurUnitBullet(slotIdx, bName) {
  if (!setOrSwapUnitBullet(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(),
      maxBulletsCountForExtraAmmo.get(), maxBulletsSecCountForExtraAmmo.get(), maxBulletsSpecCountForExtraAmmo.get(),
      hasExtraBullets.get(), hasExtraBulletsSec.get(), hasExtraBulletsSpec.get(),
      bulletsInfo.get(), bulletsSecInfo.get(), bulletsSpecInfo.get(), slotIdx, bName,
      secBulletsSlots.get()))
    return
  hasChangedCurSlotBullets.set(true)
  cancelRespawn() 
}

let bulletLeftSteps = Computed(@() calcLeftSteps(bulletStep.get(), bulletTotalSteps.get(), chosenBullets.get()))
let bulletSecLeftSteps = Computed(@() calcLeftSteps(bulletSecStep.get(), bulletSecTotalSteps.get(), chosenBulletsSec.get()))
let bulletSpecLeftSteps = Computed(@() calcLeftSteps(bulletSpecStep.get(), bulletSpecTotalSteps.get(), chosenBulletsSpec.get()))

register_command(@() resetSavedBullets(unitName.get()), "debug.respawn.reset_saved_bullets")

return {
  bulletsInfo
  bulletsSecInfo
  bulletsSpecInfo
  bulletsStatus
  bulletsStatusSec
  bulletsStatusSpec
  chosenBullets
  brPickupPrimIdx
  chosenBulletsSec
  chosenBulletsSpec
  bulletsToSpawn
  bulletStep
  bulletSecStep
  bulletSpecStep
  bulletTotalSteps
  bulletSecTotalSteps
  bulletSpecTotalSteps
  bulletLeftSteps
  bulletSecLeftSteps
  bulletSpecLeftSteps
  hasLowBullets
  hasZeroBullets
  hasChangedCurSlotBullets
  hasExtraBullets
  hasExtraBulletsSec
  hasExtraBulletsSpec
  hasZeroMainBullets
  maxBulletsCountForExtraAmmo
  maxBulletsSecCountForExtraAmmo
  maxBulletsSpecCountForExtraAmmo
  isFakeSecondary
  isFakeSpecial
  secBulletsSlots
  specBulletsSlots

  setCurUnitBullets
  setOrSwapCurUnitBullet
}