from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { calcVisibleBullets, calcBulletStep, calcChosenBullets, calcMaxBullets, calcLeftSteps,
  mkVisibleBulletsList
} = require("%rGui/bullets/calcBullets.nut")
let { applySavedBullets, savedBullets, setOrSwapUnitBullet, setUnitBullets } = require("%rGui/bullets/savedBullets.nut")
let { BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BULLETS_SPEC_SLOTS, ammoReductionFactorDef, ammoReductionSecFactorDef,
  ammoReductionSpecFactorDef } = require("%rGui/bullets/bulletsConst.nut")
let { unit, unitName, isOwn, unitMods, curBullet, curModId, curBulletCategoryId,
  changeModTabWithUnseenTrigger, changeBulletTabWithUnseenTrigger
} = require("%rGui/unitMods/unitModsState.nut")


let bulletsInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.primary) 
let bulletsSecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.secondary)
let bulletsSpecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.special)

let mods = Computed(@() (unitMods.get() ?? {}).reduce(@(res, val, mod) val ? res.$rawset(mod, 1) : res, {}))

let visibleBullets = Computed(@() calcVisibleBullets(bulletsInfo.get(), mods.get()))
let visibleBulletsSec = Computed(@() calcVisibleBullets(bulletsSecInfo.get(), mods.get()))
let visibleBulletsSpec = Computed(@() calcVisibleBullets(bulletsSpecInfo.get(), mods.get()))

let isBulletSec = Computed(@() (curBulletCategoryId.get() ?? 0) >= BULLETS_PRIM_SLOTS)
let isBulletSpec = Computed(@() (curBulletCategoryId.get() ?? 0) >= BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS)

let visibleBulletsList = Computed(function() {
  let bInfo = isBulletSpec.get()
      ? bulletsSpecInfo.get()
    : isBulletSec.get()
      ? bulletsSecInfo.get()
    : bulletsInfo.get()
  if (bInfo == null)
    return []
  let { bulletSets, bulletsOrder, fromUnitTags } = bInfo
  let visBullets = isBulletSpec.get()
      ? visibleBulletsSpec.get()
    : isBulletSec.get()
      ? visibleBulletsSec.get()
    : visibleBullets.get()
  return mkVisibleBulletsList(bulletsOrder, fromUnitTags, visBullets, curBulletCategoryId.get()).map(@(name) {
    name,
    bSet = bulletSets[name],
    fromUnitTags = fromUnitTags?[name],
    slot = curBulletCategoryId.get()
  })
})

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

let maxBulletsCountForExtraAmmo = Computed(@() !hasExtraBullets.get() ? {}
  : calcMaxBullets(bulletTotalSteps.get(), bulletsInfo.get(), bulletTotalCount.get(), BULLETS_PRIM_SLOTS))
let maxBulletsSecCountForExtraAmmo = Computed(@() !hasExtraBulletsSec.get() ? {}
  : calcMaxBullets(bulletSecTotalSteps.get(), bulletsSecInfo.get(), bulletSecTotalCount.get(), BULLETS_SEC_SLOTS))
let maxBulletsSpecCountForExtraAmmo = Computed(@() !hasExtraBulletsSpec.get() ? {}
  : calcMaxBullets(bulletSpecTotalSteps.get(), bulletsSpecInfo.get(), bulletSpecTotalCount.get(), BULLETS_SPEC_SLOTS))

let chosenBullets = Computed(@() calcChosenBullets(bulletsInfo.get(), unit.get()?.level ?? 0, bulletStep.get(),
  visibleBullets.get(), maxBulletsCountForExtraAmmo.get(), hasExtraBullets.get(), bulletTotalSteps.get(),
  savedBullets.get(),
  @(idx) idx > BULLETS_PRIM_SLOTS,
  ammoReductionFactorDef,
  BULLETS_PRIM_SLOTS))
let primaryCount = Computed(@() chosenBullets.get().len())

let chosenBulletsSec = Computed(@()
  calcChosenBullets(bulletsSecInfo.get(), unit.get()?.level ?? 0, bulletSecStep.get(),
    visibleBulletsSec.get(), maxBulletsSecCountForExtraAmmo.get(), hasExtraBulletsSec.get(), bulletSecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS,
    ammoReductionSecFactorDef,
    BULLETS_SEC_SLOTS,
    BULLETS_PRIM_SLOTS
  ).map(@(s) s.$rawset("visIdx", s.idx - BULLETS_PRIM_SLOTS + primaryCount.get())))
let secondaryCount = Computed(@() chosenBulletsSec.get().len())

let chosenBulletsSpec = Computed(@()
  calcChosenBullets(bulletsSpecInfo.get(), unit.get()?.level ?? 0, bulletSpecStep.get(),
    visibleBulletsSpec.get(), maxBulletsSpecCountForExtraAmmo.get(), hasExtraBulletsSpec.get(), bulletSpecTotalSteps.get(),
    savedBullets.get(),
    @(idx) idx <= BULLETS_PRIM_SLOTS + secondaryCount.get(),
    ammoReductionSpecFactorDef,
    BULLETS_SPEC_SLOTS,
    BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS
  ).map(@(s) s.$rawset("visIdx", s.idx - BULLETS_PRIM_SLOTS + BULLETS_SEC_SLOTS + primaryCount.get())))

let choiceCount = Computed(@() chosenBullets.get().len())
let choiceSecCount = Computed(@() chosenBulletsSec.get().len())
let choiceSpecCount = Computed(@() chosenBulletsSpec.get().len())

let bulletLeftSteps = Computed(@() calcLeftSteps(bulletStep.get(), bulletTotalSteps.get(), chosenBullets.get()))
let bulletSecLeftSteps = Computed(@() calcLeftSteps(bulletSecStep.get(), bulletSecTotalSteps.get(), chosenBulletsSec.get()))
let bulletSpecLeftSteps = Computed(@() calcLeftSteps(bulletSpecStep.get(), bulletSpecTotalSteps.get(), chosenBulletsSpec.get()))

curBulletCategoryId.subscribe(function(cId) {
  if (cId == null)
    return
  curModId.set(null)
  changeModTabWithUnseenTrigger(null)

  let bInfo = isBulletSpec.get()
      ? bulletsSpecInfo.get()
    : isBulletSec.get()
      ? bulletsSecInfo.get()
    : bulletsInfo.get()

  let bullets = isBulletSpec.get()
      ? chosenBulletsSpec.get()
    : isBulletSec.get()
      ? chosenBulletsSec.get()
    : chosenBullets.get()

  let bName = bullets?.findvalue(@(v) v.idx == cId).name
  let bullet = visibleBulletsList.get().findvalue(@(b) b.bSet.id == bInfo?.bulletSets[bName].id)
  curBullet.set(bullet)
})

let curBSetByCategory = Computed(function() {
  let bInfo = isBulletSpec.get()
      ? bulletsSpecInfo.get()
    : isBulletSec.get()
      ? bulletsSecInfo.get()
    : bulletsInfo.get()

  let bullets = isBulletSpec.get()
      ? chosenBulletsSpec.get()
    : isBulletSec.get()
      ? chosenBulletsSec.get()
    : chosenBullets.get()
  let bName = bullets?.findvalue(@(v) v.idx == curBulletCategoryId.get()).name
  return bInfo?.bulletSets[bName]
})

let isCurBulletLocked = Computed(@() (curBullet.get()?.fromUnitTags.reqLevel ?? 0) > (unit.get()?.level ?? 0))
let isCurBulletEnabled = Computed(@() curBSetByCategory.get()?.id == curBullet.get()?.bSet.id)

let applySavedBulletsForOwn = @(uName) isOwn.get() ? applySavedBullets(uName) : null

applySavedBulletsForOwn(unitName.get())
unitName.subscribe(applySavedBulletsForOwn)
isOwn.subscribe(@(_) applySavedBulletsForOwn(unitName.get()))

let setOrSwapCurUnitBullet = @(slotIdx, bName) !isOwn.get() ? null
  : setOrSwapUnitBullet(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(),
      maxBulletsCountForExtraAmmo.get(), maxBulletsSecCountForExtraAmmo.get(), maxBulletsSpecCountForExtraAmmo.get()
      hasExtraBullets.get(), hasExtraBulletsSec.get(), hasExtraBulletsSpec.get(), slotIdx, bName)

let setCurUnitBullets = @(slotIdx, bName, bCount) !isOwn.get() ? null
  : setUnitBullets(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(), slotIdx, bName, bCount)

let onBulletTabChange = @(id) changeBulletTabWithUnseenTrigger(id)

return {
  bulletsInfo
  bulletsSecInfo
  bulletsSpecInfo
  visibleBullets
  visibleBulletsSec
  visibleBulletsSpec
  bulletTotalSteps
  bulletSecTotalSteps
  bulletSpecTotalSteps
  bulletStep
  bulletSecStep
  bulletSpecStep
  maxBulletsCountForExtraAmmo
  maxBulletsSecCountForExtraAmmo
  maxBulletsSpecCountForExtraAmmo
  hasExtraBullets
  hasExtraBulletsSec
  hasExtraBulletsSpec
  bulletLeftSteps
  bulletSecLeftSteps
  bulletSpecLeftSteps

  chosenBullets
  chosenBulletsSec
  chosenBulletsSpec

  choiceCount
  choiceSecCount
  choiceSpecCount

  curBullet
  curBulletCategoryId
  visibleBulletsList

  curBSetByCategory
  isCurBulletLocked
  isCurBulletEnabled

  setOrSwapCurUnitBullet
  setCurUnitBullets

  onBulletTabChange
}