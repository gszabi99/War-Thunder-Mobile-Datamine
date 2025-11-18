from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { selSlot, cancelRespawn } = require("%rGui/respawn/respawnState.nut")
let { respawnUnitInfo, respawnUnitMods } = require("%appGlobals/clientState/respawnStateBase.nut")
let { loadUnitBulletsChoice } = require("%rGui/weaponry/loadUnitBullets.nut")
let { register_command } = require("console")
let { setUnitBullets, setOrSwapUnitBullet, resetSavedBullets, applySavedBullets, savedBullets
} = require("%rGui/bullets/savedBullets.nut")
let { BULLETS_PRIM_SLOTS, BULLETS_SEC_SLOTS, BULLETS_LOW_AMOUNT, BULLETS_LOW_PERCENT,
  ammoReductionFactorDef, ammoReductionSecFactorDef
} = require("%rGui/bullets/bulletsConst.nut")
let { calcBulletStep, calcVisibleBullets, calcChosenBullets, calcMaxBullets, calcLeftSteps
} = require("%rGui/bullets/calcBullets.nut")


let unitName = Computed(@() selSlot.get()?.name)
let unitLevel = Computed(@() selSlot.get()?.level ?? 0)
let bulletsInfo = Computed(@() unitName.get() == null ? null
  : loadUnitBulletsChoice(unitName.get())?.commonWeapons.primary) 
let bulletsSecInfo = Computed(function() {
  if (unitName.get() == null)
    return null
  let { secondary = null, special = null } = loadUnitBulletsChoice(unitName.get())?.commonWeapons
  return secondary ?? special
})

let hasChangedCurSlotBullets = Watched(false)
selSlot.subscribe(@(_) hasChangedCurSlotBullets.set(false))

applySavedBullets(unitName.get())
unitName.subscribe(applySavedBullets)

let bulletStep = Computed(@() calcBulletStep(bulletsInfo.get()))
let bulletSecStep = Computed(@() calcBulletStep(bulletsSecInfo.get()))

let bulletTotalCount = Computed(@() (bulletsInfo.get()?.total ?? 1).tofloat())
let bulletSecTotalCount = Computed(@() (bulletsSecInfo.get()?.total ?? 1).tofloat())

let bulletTotalSteps = Computed(@() ceil(bulletTotalCount.get() / bulletStep.get()).tointeger())
let bulletSecTotalSteps = Computed(@() ceil(bulletSecTotalCount.get() / bulletSecStep.get()).tointeger())

let hasExtraBullets = Computed(@() bulletStep.get() * bulletTotalSteps.get() > bulletTotalCount.get())
let hasExtraBulletsSec = Computed(@() bulletSecStep.get() * bulletSecTotalSteps.get() > bulletSecTotalCount.get())

let mods = Computed(function() {
  let curUnitName = unitName.get()
  let unitInfo = respawnUnitInfo.get()
  let defUnitMods = respawnUnitMods.get()
  if (unitInfo == null || curUnitName == null)
    return defUnitMods
  let unitData = unitInfo?.name == curUnitName ? unitInfo
    : unitInfo?.platoonUnits.findvalue(@(v) v.name == curUnitName)
  return unitData?.modifications ?? unitData?.items ?? defUnitMods 
})

let visibleBullets = Computed(@() calcVisibleBullets(bulletsInfo.get(), mods.get()))
let visibleBulletsSec = Computed(@() calcVisibleBullets(bulletsSecInfo.get(), mods.get()))

let maxBulletsCountForExtraAmmo = Computed(@() !hasExtraBullets.get() ? {}
  : calcMaxBullets(bulletTotalSteps.get(), bulletsInfo.get(), bulletTotalCount.get(), BULLETS_PRIM_SLOTS))
let maxBulletsSecCountForExtraAmmo = Computed(@() !hasExtraBulletsSec.get() ? {}
  : calcMaxBullets(bulletSecTotalSteps.get(), bulletsSecInfo.get(), bulletSecTotalCount.get(), BULLETS_SEC_SLOTS))

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

let chosenBulletsAmount = Computed(@() chosenBullets.get().reduce(@(acc, bullet) acc + bullet.count, 0))
let chosenBulletsSecAmount = Computed(@() chosenBulletsSec.get().len() > 0
  ? chosenBulletsSec.get().reduce(@(acc, bullet) acc + bullet.count, 0)
  : -1)
let hasZeroBullets = Computed(@() chosenBulletsAmount.get() == 0 || chosenBulletsSecAmount.get() == 0)
let hasLowBullets = Computed(@() chosenBulletsAmount.get() < BULLETS_LOW_AMOUNT
  || chosenBulletsAmount.get() < bulletsInfo.get().total * BULLETS_LOW_PERCENT / 100)
let hasZeroMainBullets = Computed(@() hasExtraBullets.get()
  && bulletsToSpawn.get().len() > 0
  && bulletsToSpawn.get()[0].count == 0)

function setCurUnitBullets(slotIdx, bName, bCount) {
  if (!setUnitBullets(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), slotIdx, bName, bCount))
    return
  hasChangedCurSlotBullets.set(true)
  cancelRespawn() 
}

function setOrSwapCurUnitBullet(slotIdx, bName) {
  if (!setOrSwapUnitBullet(unitName.get(), chosenBullets.get(), chosenBulletsSec.get(), maxBulletsCountForExtraAmmo.get(),
      maxBulletsSecCountForExtraAmmo.get(), hasExtraBullets.get(), hasExtraBulletsSec.get(), slotIdx, bName))
    return
  hasChangedCurSlotBullets.set(true)
  cancelRespawn() 
}

let bulletLeftSteps = Computed(@() calcLeftSteps(bulletStep.get(), bulletTotalSteps.get(), chosenBullets.get()))
let bulletSecLeftSteps = Computed(@() calcLeftSteps(bulletSecStep.get(), bulletSecTotalSteps.get(), chosenBulletsSec.get()))

register_command(@() resetSavedBullets(unitName.get()), "debug.respawn.reset_saved_bullets")

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
  setOrSwapCurUnitBullet
}