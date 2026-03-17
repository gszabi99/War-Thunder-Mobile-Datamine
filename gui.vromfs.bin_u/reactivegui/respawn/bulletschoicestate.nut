from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { selSlot, cancelRespawn } = require("%rGui/respawn/respawnState.nut")
let { respawnUnitInfo, respawnUnitMods } = require("%appGlobals/clientState/respawnStateBase.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { register_command } = require("console")
let { setUnitBullets, setOrSwapUnitBullet, resetSavedBullets, applySavedBullets, savedBullets
} = require("%rGui/bullets/savedBullets.nut")
let { BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BULLETS_LOW_AMOUNT, BULLETS_LOW_PERCENT, BULLETS_SPEC_SLOTS,
  ammoReductionFactorDef, ammoReductionSecFactorDef, ammoReductionSpecFactorDef
} = require("%rGui/bullets/bulletsConst.nut")
let { calcBulletStep, calcVisibleBullets, calcChosenBullets, calcMaxBullets, calcLeftSteps
} = require("%rGui/bullets/calcBullets.nut")


let unitName = Computed(@() selSlot.get()?.name)
let unitLevel = Computed(@() selSlot.get()?.level ?? 0)
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

let mods = Computed(function() {
  let curUnitName = unitName.get()
  let unitInfo = respawnUnitInfo.get()
  let defUnitMods = respawnUnitMods.get()
  if (unitInfo == null || curUnitName == null)
    return defUnitMods
  let unitData = unitInfo?.name == curUnitName ? unitInfo
    : unitInfo?.platoonUnits.findvalue(@(v) v.name == curUnitName)
  return unitData?.modifications ?? defUnitMods
})

let visibleBullets = Computed(@() calcVisibleBullets(bulletsInfo.get(), mods.get()))
let visibleBulletsSec = Computed(@() calcVisibleBullets(bulletsSecInfo.get(), mods.get()))
let visibleBulletsSpec = Computed(@() calcVisibleBullets(bulletsSpecInfo.get(), mods.get()))

let maxBulletsCountForExtraAmmo = Computed(@() !hasExtraBullets.get() ? {}
  : calcMaxBullets(bulletTotalSteps.get(), bulletsInfo.get(), bulletTotalCount.get(), BULLETS_PRIM_SLOTS))
let maxBulletsSecCountForExtraAmmo = Computed(@() !hasExtraBulletsSec.get() ? {}
  : calcMaxBullets(bulletSecTotalSteps.get(), bulletsSecInfo.get(), bulletSecTotalCount.get(), BULLETS_SEC_SLOTS))
let maxBulletsSpecCountForExtraAmmo = Computed(@() !hasExtraBulletsSpec.get() ? {}
  : calcMaxBullets(bulletSpecTotalSteps.get(), bulletsSpecInfo.get(), bulletSpecTotalCount.get(), BULLETS_SPEC_SLOTS))

let chosenBullets = Computed(@() calcChosenBullets(bulletsInfo.get(), unitLevel.get(), bulletStep.get(),
  visibleBullets.get(), maxBulletsCountForExtraAmmo.get(), hasExtraBullets.get(), bulletTotalSteps.get(),
  savedBullets.get(),
  @(idx) idx > BULLETS_PRIM_SLOTS,
  ammoReductionFactorDef,
  BULLETS_PRIM_SLOTS))
let primaryCount = Computed(@() chosenBullets.get().len())

let chosenBulletsSec = Computed(@()
  calcChosenBullets(bulletsSecInfo.get(), unitLevel.get(), bulletSecStep.get(),
    visibleBulletsSec.get(), maxBulletsSecCountForExtraAmmo.get(), hasExtraBulletsSec.get(), bulletSecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS,
    ammoReductionSecFactorDef,
    BULLETS_SEC_SLOTS,
    BULLETS_PRIM_SLOTS
  ).map(@(s) s.$rawset("visIdx", s.idx - BULLETS_PRIM_SLOTS + primaryCount.get())))
let secondaryCount = Computed(@() chosenBulletsSec.get().len())

let chosenBulletsSpec = Computed(@()
  calcChosenBullets(bulletsSpecInfo.get(), unitLevel.get(), bulletSpecStep.get(),
    visibleBulletsSpec.get(), maxBulletsSpecCountForExtraAmmo.get(), hasExtraBulletsSpec.get(), bulletSpecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS + secondaryCount.get(),
    ammoReductionSpecFactorDef,
    BULLETS_SPEC_SLOTS,
    BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS
  ).map(@(s) s.$rawset("visIdx", (s.idx - (BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS)) + primaryCount.get() + secondaryCount.get())))

let bulletFormat = @(b, c) { name = b.name, count = ceil(b.count / c).tointeger() }
let bulletsToSpawn = Computed(function() {
  let res = chosenBullets.get().map(@(b) bulletFormat(b, bulletsInfo.get()?.catridge ?? 1)) 
  if (bulletsSecInfo.get() == null && bulletsSpecInfo.get() == null)
    return res
  if (res.len() < BULLETS_PRIM_SLOTS)
    res.resize(BULLETS_PRIM_SLOTS, { name = "", count = 0 }) 
  let { catridge = 1, bulletsOrder = [""], total = 0 } = bulletsSecInfo.get()
  let secBulletsToSpawn = chosenBulletsSec.get().len() > 0
    ? chosenBulletsSec.get().map(@(b) bulletFormat(b, catridge))
    : [bulletFormat({ name = bulletsOrder[0], count = total }, catridge)]

  let specCatridge = bulletsSpecInfo.get()?.catridge ?? 1
  let specBulletsOrder = bulletsSpecInfo.get()?.bulletsOrder ?? [""]
  let specTotal = bulletsSpecInfo.get()?.total ?? 0
  let specBulletsToSpawn = chosenBulletsSpec.get().len() > 0
    ? chosenBulletsSpec.get().map(@(b) bulletFormat(b, specCatridge))
    : [bulletFormat({ name = specBulletsOrder[0], count = specTotal }, specCatridge)]

  res.extend(secBulletsToSpawn, specBulletsToSpawn)
  return res
})

let chosenBulletsAmount = Computed(@() chosenBullets.get().reduce(@(acc, bullet) acc + bullet.count, 0))
let chosenBulletsSecAmount = Computed(@() chosenBulletsSec.get().len() > 0
  ? chosenBulletsSec.get().reduce(@(acc, bullet) acc + bullet.count, 0)
  : -1)
let chosenBulletsSpecAmount = Computed(@() chosenBulletsSpec.get().len() > 0
  ? chosenBulletsSpec.get().reduce(@(acc, bullet) acc + bullet.count, 0)
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
      hasExtraBullets.get(), hasExtraBulletsSec.get(), hasExtraBulletsSpec.get(), slotIdx, bName))
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
  visibleBullets
  visibleBulletsSec
  visibleBulletsSpec
  chosenBullets
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

  setCurUnitBullets
  setOrSwapCurUnitBullet
}