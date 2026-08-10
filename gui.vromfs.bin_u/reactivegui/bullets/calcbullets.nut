from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { eachBlock } = require("%sqstd/datablock.nut")
let { ammoReductionFactorsByIdx, ammoReductionFactorDef, BS_VISIBLE, BS_ONLY_EXTERNAL_SLOT, BS_UNLOCKED, BS_BR_PICKUP
} = require("%rGui/bullets/bulletsConst.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")



let ammoReductionFactorDefExt = Computed(@() abTests.get()?.ammoReductionFactorDef.tofloat() ?? ammoReductionFactorDef)
let ammoReductionFactorsByIdxExt = Computed(@() ammoReductionFactorsByIdx
  .map(@(v, i) abTests.get()?[$"ammoReductionFactorsByIdx{i}"].tofloat() ?? v))

let calcBulletStep = @(bInfo) max((bInfo?.catridge ?? 1) * (bInfo?.guns ?? 1), 1)
let calcLeftSteps = @(bStep, bTotalSteps, bullets) bullets.reduce(@(res, bData) res - bData.count / bStep, bTotalSteps)
let calcBulletsStatus = @(bInfo, level, mods, modsCfg) (bInfo?.bulletSets ?? {})
  .map(function(_, name) {
    let { reqModification = "", isHidden = false, reqLevel = 0, isExternalAmmo = false, BR_pickup = false } = bInfo?.fromUnitTags[name]
    let hasMod = reqModification == "" || (mods?[reqModification] ?? false)
    if (isHidden || (!hasMod && !modsCfg?[reqModification].isHidden)) 
      return 0

    return BS_VISIBLE
      | (isExternalAmmo ? BS_ONLY_EXTERNAL_SLOT : 0)
      | (BR_pickup ? BS_BR_PICKUP : 0)
      | ((hasMod || (reqModification == "" && reqLevel <= level))
          ? BS_UNLOCKED
          : 0)
  })

function calcMaxBullets(bTotalSteps, bInfo, bTotalCount, bSlots) {
  let bulletSlots = min(bSlots, bTotalSteps)
  return array(bulletSlots).map(@(_, idx) idx).reduce(function(res, slotIdx) {
    let remaining = bTotalCount - res.total

    local curCount = (bInfo?.catridge ?? 1) * bulletSlots
    let maxCountSteps = (bTotalCount / curCount).tointeger()
    curCount = curCount * maxCountSteps

    res.maxCounts[slotIdx] <- remaining >= curCount ? curCount : remaining
    res.total += curCount
    return res
  }, { maxCounts = {}, total = 0 }).maxCounts
}

function calcChosenBullets(bInfo, stepSize, bulletsStatus, maxBullets,
  hasExtra, bTotalSteps, sBullets, sBulletLimit, ammoReductionFactor, ammoReductionFactorsBySlot, bSlots, addIndex = 0
) {
  let res = []
  if (bInfo == null)
    return res
  let { fromUnitTags, bulletsOrder, bulletSetAvailiable } = bInfo
  let defBulletSlots = min(bSlots, bTotalSteps)
  let differentBulletSlots = bulletSetAvailiable.len()
  let allBulletSlots = max(defBulletSlots, differentBulletSlots)
  local leftSteps = max(bTotalSteps, differentBulletSlots)
  local bulletIdx = 0
  let used = {}
  if (sBullets != null)
    eachBlock(sBullets, function(blk) {
      bulletIdx += 1
      if (sBulletLimit(bulletIdx))
        return
      let { name = null, count = 0 } = blk
      if (name == null)
        return
      let { maxCount = leftSteps } = fromUnitTags?[name]
      let status = bulletsStatus?[name] ?? 0
      if (res.len() >= allBulletSlots
          || (status & BS_UNLOCKED) == 0
          || (name in used && differentBulletSlots == 0)
          || (res.len() + addIndex == 0 && (status & (BS_ONLY_EXTERNAL_SLOT | BS_BR_PICKUP)) != 0))
        return
      let steps = bTotalSteps == 1 ? 1 
        : min(ceil(count.tofloat() / stepSize), leftSteps, maxCount)
      leftSteps -= steps
      let countBullets = steps * stepSize
      let maxBulletsCount = maxBullets?[res.len()] ?? 0
      let bulletsCount = !hasExtra ? countBullets
        : count == 0 ? count
        : maxBulletsCount
      res.append({ name, idx = res.len() + addIndex,
        count = differentBulletSlots == 0 ? bulletsCount : (bulletsCount / differentBulletSlots) })
      used[name] <- true
    })

  if (res.len() < defBulletSlots)
    foreach (bName in bulletsOrder) {
      if (bName in used)
        continue
      let status = bulletsStatus?[bName] ?? 0
      if ((status & BS_UNLOCKED) == 0
          || (res.len() + addIndex == 0 && (status & (BS_ONLY_EXTERNAL_SLOT | BS_BR_PICKUP)) != 0))
        continue
      res.append({ name = bName, count = -1, idx = res.len() + addIndex })
      if (res.len() >= defBulletSlots)
        break
    }

  if (res.len() < differentBulletSlots)
    for (local i = res.len(); i < differentBulletSlots; i++)
      foreach (bName in bulletsOrder) {
        let status = bulletsStatus?[bName] ?? 0
        if ((status & BS_UNLOCKED) != 0
            && (res.len() + addIndex != 0 || (status & (BS_ONLY_EXTERNAL_SLOT | BS_BR_PICKUP)) == 0)) {
          res.append({ name = bName, count = -1, idx = res.len() + addIndex })
          break
        }
      }

  local notInitedCount = res.reduce(@(accum, bData) bData.count < 0 ? accum + 1 : accum, 0)
  if (notInitedCount > 0) {
    let bulletSlotsCount = res.len()
    foreach (bData in res)
      if (bData.count < 0) {
        bData.count = 0
        if (leftSteps > 0) {
          let steps = hasExtra ? min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
            : (bulletSlotsCount == 1 && leftSteps > 1) ? min(ceil(bTotalSteps * ammoReductionFactor), leftSteps)
            : (bulletSlotsCount > 1) ? min(ceil(bTotalSteps * (ammoReductionFactorsBySlot?[bData.idx] ?? 1)), leftSteps)
            : min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
          let defCount = differentBulletSlots == 0 ? steps * stepSize : (steps * stepSize / differentBulletSlots)
          bData.count = hasExtra ? min(defCount, (maxBullets?[bData.idx] ?? 0)) : defCount
          leftSteps -= steps
          notInitedCount--
        }
      }
  }

  return res
}

return {
  calcBulletStep
  calcLeftSteps
  calcBulletsStatus
  calcMaxBullets
  calcChosenBullets

  ammoReductionFactorDefExt
  ammoReductionFactorsByIdxExt
}