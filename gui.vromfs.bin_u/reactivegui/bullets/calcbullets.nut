from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { eachBlock } = require("%sqstd/datablock.nut")
let { ammoReductionFactorsByIdx, ammoReductionFactorDef } = require("%rGui/bullets/bulletsConst.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")



let ammoReductionFactorDefExt = Computed(@() abTests.get()?.ammoReductionFactorDef.tofloat() ?? ammoReductionFactorDef)
let ammoReductionFactorsByIdxExt = Computed(@() ammoReductionFactorsByIdx
  .map(@(v, i) abTests.get()?[$"ammoReductionFactorsByIdx{i}"].tofloat() ?? v))

let calcBulletStep = @(bInfo) max((bInfo?.catridge ?? 1) * (bInfo?.guns ?? 1), 1)
let calcLeftSteps = @(bStep, bTotalSteps, bullets) bullets.reduce(@(res, bData) res - bData.count / bStep, bTotalSteps)
let calcVisibleBullets = @(bInfo, mods) (bInfo?.bulletSets ?? {}).reduce(function(res, _, name) {
  let { reqModification = "", isHidden = false } = bInfo?.fromUnitTags[name]
  let reqModAmount = mods?[reqModification] ?? 0
  return isHidden || (reqModification != "" && reqModAmount <= 0) ? res : res.$rawset(name, true)
}, {})

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

function calcChosenBullets(bInfo, level, stepSize, visible, maxBullets,
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
      let { reqLevel = 0, isExternalAmmo = false, maxCount = leftSteps } = fromUnitTags?[name]
      if (res.len() >= allBulletSlots
          || !visible?[name]
          || (name in used && differentBulletSlots == 0)
          || reqLevel > level
          || (res.len() == 0 && isExternalAmmo))
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
    foreach (bName in bulletsOrder)
      if ((bName not in used)
          && visible?[bName]
          && (fromUnitTags?[bName].reqLevel ?? 0) <= level
      ) {
        res.append({ name = bName, count = -1, idx = res.len() + addIndex })
        if (res.len() >= defBulletSlots)
          break
      }

  if (res.len() < differentBulletSlots) {
    for (local i = res.len(); i < differentBulletSlots; i++) {
      foreach (bName in bulletsOrder) {
        if (visible?[bName] && (fromUnitTags?[bName].reqLevel ?? 0) <= level) {
          res.append({ name = bName, count = -1, idx = res.len() + addIndex })
          break
        }
      }
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

let mkVisibleBulletsList = @(bulletsOrder, unitTags, visibleBullets, openedSlot)
  bulletsOrder.filter(function(name) {
    let { isExternalAmmo = false } = unitTags?[name]
    let isVisible = visibleBullets?[name] ?? false
    return openedSlot == 0 ? isVisible && !isExternalAmmo : isVisible
  })

return {
  calcBulletStep
  calcLeftSteps
  calcVisibleBullets
  calcMaxBullets
  calcChosenBullets

  mkVisibleBulletsList

  ammoReductionFactorDefExt
  ammoReductionFactorsByIdxExt
}