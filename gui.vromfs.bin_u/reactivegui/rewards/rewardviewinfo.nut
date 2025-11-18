from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hasStatsImage } = require("%appGlobals/config/rewardStatsPresentation.nut")

let NO_DROP_LIMIT = 1000000

let rTypesPriority = {
  stat            = 1000000
  lootbox         = 100000
  unitUpgrade     = 20000
  unit            = 10000
  blueprint       = 9000
  discount        = 8000
  skin            = 5000
  decorator       = 1000
  booster         = 500
  currency        = 100
  premium         = 50
  item            = 1
}

let customPriority = {
  decorator = {
    avatar        = 1010
    nickFrame     = 1009
    title         = 1008
  }
  currency = {
    gold          = 110
    eventKey      = 109
    warbond       = 108
    wp            = 30
  }
  item = {
    spare         = 40
  }
}

let slotsByType = {
  unitUpgrade = 2
  battleMod = 2
  unit = 2
  blueprint = 2
  prizeTicket = 2
  discount = 2
}

let slotsByDType = {
  title = 2
}

let dropLimitByType = [G_UNIT, G_UNIT_UPGRADE, G_DECORATOR, G_SKIN]
  .reduce(@(res, id) res.rawset(id, 1), {})

let ignoreSubIdRTypes = [G_CURRENCY, G_LOOTBOX, G_BLUEPRINT].reduce(@(res, t) res.$rawset(t, true), {})


let getDecoratorType = memoize(@(id) serverConfigs.get()?.allDecorators[id].dType)

let getPriorirty = @(info)
  info.rType == "decorator" ? customPriority.decorator?[getDecoratorType(info.id)]
    : (customPriority?[info.rType]?[info.id] ?? rTypesPriority?[info.rType] ?? 0)

let sortRewardsViewInfo = @(a, b) getPriorirty(b) <=> getPriorirty(a)
  || b.count <=> a.count
  || a.id <=> b.id
  || (a?.subId ?? 0) <=> (b?.subId ?? 0)

let sortRewardsWithOrder = @(a, b) b.rewardOrder <=> a.rewardOrder
  || b.slots <=> a.slots
  || (a?.isLastReward ?? false) <=> (b?.isLastReward ?? false)
  || sortRewardsViewInfo(a, b)

let mkViewInfo = @(id, rType, count = 0, subId = "")
  { id, subId, rType, count, slots = slotsByType?[rType] ?? slotsByDType?[getDecoratorType(id)] ?? 1 }

let getRewardsViewInfo = @(data, multiply = 1)
  (data ?? []).map(@(g) mkViewInfo(g.id, g.gType, g.count * multiply, g.subId))

function shopGoodsToRewardsViewInfo(data, multiply = 1) {
  let { currencies = {}, premiumDays = 0, items = {}, lootboxes = {},
    decorators = [], unitUpgrades = [], units = [], boosters = [], skins = {},
    battleMods = {}, decals = [], rewards = null
  } = data

  if (rewards != null)
    return getRewardsViewInfo(rewards).filter(@(r) r.rType != G_STAT || hasStatsImage(r.id, r.subId))

  
  let res = []
  foreach (id in unitUpgrades)
    res.append(mkViewInfo(id, G_UNIT_UPGRADE))
  foreach (id in units)
    if (!unitUpgrades.contains(id))
      res.append(mkViewInfo(id, G_UNIT))

  foreach(id, value in currencies)
    if (value > 0)
      res.append(mkViewInfo(id, G_CURRENCY, value * multiply))

  if (premiumDays > 0)
    res.append(mkViewInfo("", G_PREMIUM, premiumDays * multiply))

  foreach (id in decorators)
    res.append(mkViewInfo(id, G_DECORATOR))
  foreach (id, count in items)
    res.append(mkViewInfo(id, G_ITEM, count * multiply))
  foreach (id, count in lootboxes)
    res.append(mkViewInfo(id, G_LOOTBOX, count * multiply))
  foreach (id, count in boosters)
    res.append(mkViewInfo(id, G_BOOSTER, count * multiply))
  foreach (unitName, skinName in skins)
    res.append(mkViewInfo(unitName, G_SKIN, 0, skinName))
  foreach (id, count in battleMods)
    res.append(mkViewInfo(id, G_BATTLE_MOD, count))
  foreach (id in decals)
    res.append(mkViewInfo(id, G_DECAL))
  return res
}

function getStatsRewardsViewInfo(unlockStage) {
  let res = []
  foreach(stat in unlockStage?.updStats ?? {})
    if (hasStatsImage(stat.name, stat.mode) && stat.value.tointeger() > 0)
      res.append({
        rType = "stat"
        count = stat.value.tointeger()
        id = stat.name
        subId = stat.mode
        slots = 1
      })
  return res
}

function getUnlockRewardsViewInfo(unlockStage, servConfigs) {
  let res = getStatsRewardsViewInfo(unlockStage)
  foreach (id, count in unlockStage?.rewards ?? {}) {
    let reward = servConfigs?.userstatRewards[id]
    res.extend(getRewardsViewInfo(reward, count))
  }
  return res
}

let customJoin = {
  unit = {
    function unitUpgrade(resV, _) {
      resV.rType = G_UNIT_UPGRADE
      return true
    }
  }
  unitUpgrade = { unit = @(_, __) true }
  skin = { skin = @(a, b) a.subId == b.subId }
}

function joinSingleViewInfo(resV, joiningV, onJoin) {
  if (resV.id != joiningV.id)
    return false
  let customRes = customJoin?[resV.rType][joiningV.rType](resV, joiningV)
  if (customRes != null) {
    if (customRes)
      onJoin?(resV, joiningV)
    return customRes
  }

  if (resV.rType != joiningV.rType)
    return false
  resV.count += joiningV.count
  onJoin?(resV, joiningV)
  return true
}

function joinViewInfo(resViewInfo, joiningViewInfo, onJoin = null) {
  foreach(new in joiningViewInfo) {
    let found = resViewInfo.findvalue(@(v) joinSingleViewInfo(v, new, onJoin))
    if (found == null)
      resViewInfo.append(clone new)
  }
  return resViewInfo
}

let findIndexForJoin = @(viewInfoList, viewInfo)
  viewInfoList.findindex(@(v) joinSingleViewInfo(clone viewInfo, v, null))

let function addTbl(res, id) {
  if (id not in res)
    res[id] <- {}
  return res[id]
}

let function addArray(res, id) {
  if (id not in res)
    res[id] <- []
  return res[id]
}

function groupRewards(rewards) {
  let res = []
  let groupedRewards = {}
  foreach(r in rewards)
    if (r.dropLimit != NO_DROP_LIMIT || !!r?.isLastReward)
      res.append(r)
    else
      addArray(addTbl(groupedRewards, r.rType), r.id)
        .append(r)

  foreach(groupList in groupedRewards)
    foreach(group in groupList) {
      if (group.len() == 1) {
        res.append(group[0])
        continue
      }

      group.sort(@(a, b) a.count <=> b.count)
      res.append({
        dropLimit = NO_DROP_LIMIT
        dropLimitRaw = NO_DROP_LIMIT
        id = group[0].id
        subId = group[0].subId
        source = group[0].source 
        rewardCfg = group[0].rewardCfg 
        rType = group[0].rType
        slots = group[0].slots
        count = group[0].count
        countRange = group[group.len() - 1].count
        chance = group[0].chance
        rewardOrder = group.findvalue(@(r) (r?.rewardOrder ?? 0) != 0)?.rewardOrder ?? 0
        agregatedRewards = group.map(@(r) {
          count = r.count
          id = r.rewardId
        })
      })
    }

  return res
}

function getLootboxCommonRewardsViewInfo(lootbox, lockedBy = []) {
  let { name = "", lastReward = "", rewardsOrder = {} } = lootbox
  let rewards = lootbox.rewards.map(function(chance, id) {
    let rewardCfg = serverConfigs.get()?.rewardsCfg[id]
    let content = getRewardsViewInfo(rewardCfg)?[0]
    return {
      id
      source = name
      rewardOrder = rewardsOrder?[id] ?? 0
      rewardCfg
      chance
      content
      dropLimit = lootbox?.dropLimit[id] ?? dropLimitByType?[content?.rType] ?? NO_DROP_LIMIT
      dropLimitRaw = lootbox?.dropLimit[id]
      lockedBy
    }
  })
    .filter(@(v) v != null)
    .values()

  if (lastReward != "") {
    let rewardCfg = serverConfigs.get()?.rewardsCfg[lastReward]
    rewards.append({
      id = lastReward
      source = name
      rewardOrder = rewardsOrder?[lastReward] ?? 0
      rewardCfg
      chance = 0
      content = getRewardsViewInfo(rewardCfg)?[0]
      dropLimit = NO_DROP_LIMIT
      isLastReward = true
    })
  }

  return rewards
    .filter(@(r) r.content != null)
    .sort(@(a, b) b.rewardOrder <=> a.rewardOrder
      || b.content.slots <=> a.content.slots
      || a.dropLimit <=> b.dropLimit
      || (a?.isLastReward ?? false) <=> (b?.isLastReward ?? false)
      || a.chance <=> b.chance
      || sortRewardsViewInfo(a.content, b.content))
    .map(@(v) v.content.__update({
        chance = v.chance
        rewardId = v.id
        source = v.source
        rewardCfg = v.rewardCfg
        dropLimit = v.dropLimit
        rewardOrder = v?.rewardOrder ?? 0
        dropLimitRaw = v?.dropLimitRaw ?? NO_DROP_LIMIT
        isLastReward = v?.isLastReward ?? false
      }))
}

function getLootboxFixedRewardsViewInfo(lootbox) {
  let fixedRewards = []
  let added = {}
  foreach (fr in lootbox.fixedRewards) {
    let id = fr?.rewardId ?? fr 
    if (id in added)
      continue
    added[id] <- true

    let lockedBy = fr?.lockedBy ?? []
    let rewardCfg = serverConfigs.get()?.rewardsCfg[id]
    let content = getRewardsViewInfo(rewardCfg)?[0]
    if (content?.rType == "lootbox") {
      let rewards = getLootboxCommonRewardsViewInfo(serverConfigs.get()?.lootboxesCfg[content.id], lockedBy)
      foreach (r in rewards)
        fixedRewards.append(r.__merge({ isJackpot = true, parentSource = lootbox?.name ?? "", parentRewardId = id, lockedBy }))
    }
    else
      fixedRewards.append({
        id
        rewardCfg
        isFixed = true
        source = lootbox?.name ?? ""
        chance = 0
        content
        dropLimit = NO_DROP_LIMIT
        lockedBy
      })
  }
  return fixedRewards
}

function getLootboxRewardsViewInfo(lootbox, needToGroup = false) {
  let fixedRewards = getLootboxFixedRewardsViewInfo(lootbox)
  let commonRewards = getLootboxCommonRewardsViewInfo(lootbox)
    .filter(@(cR) fixedRewards.findindex(@(fR) fR?.rewardId && cR?.rewardId && fR.rewardId == cR.rewardId) == null)
  return fixedRewards.extend(needToGroup ? groupRewards(commonRewards) : commonRewards)
}

let getAllLootboxRewardsViewInfo = @(lootbox)
  getLootboxFixedRewardsViewInfo(lootbox).extend(
    groupRewards(getLootboxCommonRewardsViewInfo(lootbox)).sort(sortRewardsWithOrder))


let getLootboxOpenRewardViewInfo = @(lootbox, servConfigs, multiply = 1)
  getRewardsViewInfo(servConfigs?.rewardsCfg[lootbox?.openReward] ?? [], multiply)

let receivedGoodsToViewInfo = @(rGoods)
  mkViewInfo(rGoods?.id ?? "", rGoods?.gType ?? "", rGoods.count ?? 0, rGoods?.subId ?? "")

let isEmptyByRType = {
  [G_DECORATOR] = @(value, _, profile, __) value in profile?.decorators,
  [G_UNIT] = @(value, _, profile, __) value in profile?.units,
  [G_UNIT_UPGRADE] = @(value, _, profile, __) profile?.units[value].isUpgraded,
  [G_SKIN] = @(unitName, skinName, profile, _) skinName in profile?.skins[unitName],
  [G_BLUEPRINT] = @(value, _, profile, configs) value in profile?.units
    || (profile?.blueprints?[value] ?? 0) >= (configs?.allBlueprints[value].targetCount ?? 0),
  [G_LOOTBOX] = @(value, _, profile, _) value in profile?.lootboxes,
  [G_DECAL] = @(id, _, profile, _) id in profile?.decals,
}

function isRewardEmpty(reward, profile) {
  local res = true
  foreach(r in reward)
    if (!(isEmptyByRType?[r.gType](r.id, r.subId, profile, serverConfigs.get()) ?? false)) {
      res = false
      break
    }
  return res
}

function isSingleViewInfoRewardEmpty(reward, profile) {
  let { id, rType, subId = "" } = reward
  return isEmptyByRType?[rType](id, subId, profile, serverConfigs.get()) ?? false
}

function isViewInfoRewardEmpty(reward, profile) {
  foreach(r in reward)
    if (!isSingleViewInfoRewardEmpty(r, profile))
      return false
  return true
}

function canReceiveFixedReward(lootbox, id, reward, profile) {
  let { name, fixedRewards } = lootbox
  let { opened = 0, total = {} } = profile?.lootboxStats[name]
  let rollToReceive = fixedRewards
    .findindex(@(fr, idxStr) (fr?.rewardId ?? fr) == id  
      && idxStr.tointeger() > opened
      && null == fr?.lockedBy.findvalue(@(l) (total?[l] ?? 0) > 0))
  return !isRewardEmpty(reward, profile) && rollToReceive != null
}

function fillRewardsCounts(rewards, profile, configs) {
  let hasRewards = {}
  let hideLastReward = {}
  let { lootboxStats = null } = profile
  let res = rewards.map(function(r) {
    let { isJackpot = false } = r
    if (r?.isLastReward) {
      if (!isJackpot) {
        hideLastReward[false] <- false
        return r
      }

      let { opened = 0 } = lootboxStats?[r?.parentSource]
      let { fixedRewards = {} } = configs?.lootboxesCfg[r?.parentSource]
      hideLastReward[true] <- null == fixedRewards.findindex(@(_, c) c.tointeger() > opened)
      return r
    }

    if (isRewardEmpty(r.rewardCfg, profile))
      return r.__merge({ received = 1, dropLimit = 1 })

    if (r?.isFixed) {
      let { opened = 0 } = lootboxStats?[r?.source]
      let { fixedRewards = {} } = configs?.lootboxesCfg[r?.source]
      local received = 0
      local dropLimit = 0
      foreach(countStr, fr in fixedRewards)
        if ((fr?.rewardId ?? fr) == r.id) { 
          dropLimit++
          if (countStr.tointeger() <= opened)
            received++
        }
      if (received < dropLimit)
        hasRewards[isJackpot] <- true
      return r.__merge({ received, dropLimit })
    }

    if (r.dropLimitRaw == NO_DROP_LIMIT) {
      hasRewards[isJackpot] <- true
      return r
    }

    let received = lootboxStats?[r?.source].total[r.rewardId] ?? 0
    if (received < r.dropLimit)
      hasRewards[isJackpot] <- true
    return r.__merge({ received })
  })

  return hideLastReward.len() == 0 ? res
    : res.filter(@(r) !r?.isLastReward || (!hideLastReward?[r?.isJackpot] && !hasRewards?[r?.isJackpot]))
}

return {
  NO_DROP_LIMIT
  ignoreSubIdRTypes
  isEmptyByRType

  getRewardsViewInfo
  shopGoodsToRewardsViewInfo
  getStatsRewardsViewInfo
  getUnlockRewardsViewInfo
  sortRewardsViewInfo
  joinViewInfo
  findIndexForJoin
  getLootboxRewardsViewInfo
  getAllLootboxRewardsViewInfo
  getLootboxOpenRewardViewInfo
  receivedGoodsToViewInfo
  isRewardEmpty
  isViewInfoRewardEmpty
  isSingleViewInfoRewardEmpty
  canReceiveFixedReward
  fillRewardsCounts
}
