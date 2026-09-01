from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import ceil
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BULLETS_SPEC_SLOTS,
  ammoReductionSecFactorDef, ammoReductionSpecFactorDef, BS_VISIBLE, BS_ONLY_EXTERNAL_SLOT
from "%rGui/bullets/calcBullets.nut" import calcBulletsStatus, calcBulletStep, calcChosenBullets, calcMaxBullets,
  calcLeftSteps, ammoReductionFactorDefExt, ammoReductionFactorsByIdxExt
from "%rGui/bullets/savedBullets.nut" import applySavedBullets, savedBullets, setOrSwapUnitBullet, setUnitBullets
from "%rGui/unitMods/unitModsState.nut" import unit, unitName, isOwn, mods, unitMods, curBulletId, curModId,
  curBulletCategoryId, changeModTabWithUnseenTrigger, changeBulletTabWithUnseenTrigger
from "%rGui/weaponry/loadUnitBullets.nut" import loadUnitBulletsChoice


let bulletsInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.primary) 
let bulletsSecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.secondary)
let bulletsSpecInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.special)

let bulletsStatus = Computed(@() calcBulletsStatus(bulletsInfo.get(),
  unit.get()?.level ?? 0, unitMods.get(), mods.get()))
let bulletsStatusSec = Computed(@() calcBulletsStatus(bulletsSecInfo.get(),
  unit.get()?.level ?? 0, unitMods.get(), mods.get()))
let bulletsStatusSpec = Computed(@() calcBulletsStatus(bulletsSpecInfo.get(),
  unit.get()?.level ?? 0, unitMods.get(), mods.get()))

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

let isBulletSec = Computed(@() (curBulletCategoryId.get() ?? 0) >= BULLETS_PRIM_SLOTS)
let isBulletSpec = Computed(@() (curBulletCategoryId.get() ?? 0) >= BULLETS_PRIM_SLOTS + secBulletsSlots.get())

let visibleBulletsList = Computed(function() {
  let bInfo = isBulletSpec.get()
      ? bulletsSpecInfo.get()
    : isBulletSec.get()
      ? bulletsSecInfo.get()
    : bulletsInfo.get()
  if (bInfo == null)
    return []
  let { bulletSets, bulletsOrder, fromUnitTags } = bInfo
  let bStatus = isBulletSpec.get()
      ? bulletsStatusSpec.get()
    : isBulletSec.get()
      ? bulletsStatusSec.get()
    : bulletsStatus.get()
  let visibleList = bulletsOrder.filter(function(name) {
    let status = bStatus?[name] ?? 0
    return (status & BS_VISIBLE) != 0 && (curBulletCategoryId.get() != 0 || (status & BS_ONLY_EXTERNAL_SLOT) == 0)
  })
  return visibleList.map(function(name) {
    let tags = fromUnitTags?[name]
    return {
      name,
      bSet = bulletSets[name],
      fromUnitTags = tags,
      slot = curBulletCategoryId.get(),
      status = bStatus?[name] ?? 0
      reqLevel = mods.get()?[tags?.reqModification].reqLevel ?? tags?.reqLevel ?? 0
    }
  })
})

let curBullet = Computed(@() visibleBulletsList.get().findvalue(@(b) b.bSet.id == curBulletId.get()))

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
  curBulletId.set(bullet?.bSet.id)
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

let isCurBulletEnabled = Computed(@() curBSetByCategory.get()?.id == curBulletId.get())

let applySavedBulletsForOwn = @(uName) isOwn.get() ? applySavedBullets(uName) : null

applySavedBulletsForOwn(unitName.get())
unitName.subscribe(applySavedBulletsForOwn)
isOwn.subscribe(@(_) applySavedBulletsForOwn(unitName.get()))

let setOrSwapCurUnitBullet = @(slotIdx, bName) !isOwn.get() ? null
  : setOrSwapUnitBullet(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(),
      maxBulletsCountForExtraAmmo.get(), maxBulletsSecCountForExtraAmmo.get(), maxBulletsSpecCountForExtraAmmo.get(),
      hasExtraBullets.get(), hasExtraBulletsSec.get(), hasExtraBulletsSpec.get(),
      bulletsInfo.get(), bulletsSecInfo.get(), bulletsSpecInfo.get(), slotIdx, bName, secBulletsSlots.get())

let setCurUnitBullets = @(slotIdx, bName, bCount) !isOwn.get() ? null
  : setUnitBullets(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), chosenBulletsSpec.get(), slotIdx, bName, bCount)

let onBulletTabChange = @(id) changeBulletTabWithUnseenTrigger(id)

return {
  bulletsInfo
  bulletsSecInfo
  bulletsSpecInfo
  bulletsStatus
  bulletsStatusSec
  bulletsStatusSpec
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

  visibleBulletsList
  curBullet

  curBSetByCategory
  isCurBulletEnabled

  isFakeSecondary
  isFakeSpecial
  secBulletsSlots
  specBulletsSlots

  setOrSwapCurUnitBullet
  setCurUnitBullets

  onBulletTabChange
}