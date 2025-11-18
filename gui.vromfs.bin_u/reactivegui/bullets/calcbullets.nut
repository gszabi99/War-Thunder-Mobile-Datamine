from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { eachBlock } = require("%sqstd/datablock.nut")
let { ammoReductionFactorsByIdx } = require("%rGui/bullets/bulletsConst.nut")


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
  hasExtra, bTotalSteps, sBullets, sBulletLimit, ammoReductionFactor, bSlots, addIndex = 0
) {
  let res = []
  if (bInfo == null)
    return res
  let { fromUnitTags, bulletsOrder } = bInfo
  let bulletSlots = min(bSlots, bTotalSteps)
  local leftSteps = bTotalSteps
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
      let steps = bTotalSteps == 1 ? 1 
        : min(ceil(count.tofloat() / stepSize), leftSteps, maxCount)
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
          let steps = hasExtra ? min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
            : (bulletSlotsCount == 1 && leftSteps > 1) ? min(ceil(bTotalSteps * ammoReductionFactor), leftSteps)
            : (bulletSlotsCount > 1) ? min(ceil(bTotalSteps * (ammoReductionFactorsByIdx?[bData.idx] ?? 1)), leftSteps)
            : min(leftSteps, fromUnitTags?[bData.name].maxCount ?? leftSteps)
          bData.count = hasExtra ? min(steps * stepSize, (maxBullets?[bData.idx] ?? 0)) : steps * stepSize
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
}