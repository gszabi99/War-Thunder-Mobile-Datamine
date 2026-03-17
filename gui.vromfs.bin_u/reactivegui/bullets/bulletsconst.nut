const BULLETS_PRIM_SLOTS = 2
const BULLETS_SEC_SLOTS = 1
const BULLETS_SPEC_SLOTS = 1

return {
  BULLETS_PRIM_SLOTS,
  BULLETS_SEC_SLOTS,
  BULLETS_SPEC_SLOTS,
  BULLETS_LOW_AMOUNT = 5,
  BULLETS_LOW_PERCENT = 25.0,

  ammoReductionFactorDef = 0.40,
  ammoReductionSecFactorDef = 1,
  ammoReductionSpecFactorDef = 1,
  ammoReductionFactorsByIdx = {
    [0] = 0.35, 
    [1] = 0.05 
  }
}