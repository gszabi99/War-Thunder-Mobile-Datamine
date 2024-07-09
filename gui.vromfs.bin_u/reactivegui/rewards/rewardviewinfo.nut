from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/rewardType.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { statsImages } = require("%appGlobals/config/rewardStatsPresentation.nut")

let NO_DROP_LIMIT = 1000000

let rTypesPriority = {
  stat            = 1000000
  lootbox         = 100000
  unitUpgrade     = 20000
  unit            = 10000
  skin            = 5000
  decorator       = 1000
  currency        = 100
  premium         = 50
  item            = 1
}

let customPriority = {
  decorator = {
    nickFrame     = 1010
    avatar        = 1009
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
}

let slotsByDType = {
  title = 2
}

let dropLimitByType = [G_UNIT, G_UNIT_UPGRADE, G_DECORATOR, G_SKIN]
  .reduce(@(res, id) res.rawset(id, 1), {})

let ignoreSubIdRTypes = [G_CURRENCY, G_LOOTBOX, G_BLUEPRINT].reduce(@(res, t) res.$rawset(t, true), {})

let getPriorirty = @(info)
  customPriority?[info.rType]?[info.id] ?? rTypesPriority?[info.rType] ?? 0

let sortRewardsViewInfo = @(a, b) getPriorirty(b) <=> getPriorirty(a)
  || b.count <=> a.count
  || a.id <=> b.id
  || (a?.subId ?? 0) <=> (b?.subId ?? 0)

// No need to subscribe to allDecorators because it is loaded on game start
let mkViewInfo = @(id, rType, count = 0, subId = "")
  { id, subId, rType, count, slots = slotsByType?[rType] ?? slotsByDType?[allDecorators.value?[id].dType] ?? 1 }

function getRewardsViewInfo(data, multiply = 1) {
  let res = []
  if (!data)
    return res

  if (type(data) == "array")
    return data.map(@(g) mkViewInfo(g.id, g.gType, g.count * multiply, g.subId))

  //typeof(reward) == "table" //compatibility with 2024.04.14
  let { currencies = {}, premiumDays = 0, items = {}, lootboxes = {},
    decorators = [], unitUpgrades = [], units = [], boosters = [], skins = {},
    battleMods = {}
  } = data

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
  return res
}

function getStatsRewardsViewInfo(unlockStage) {
  let res = []
  foreach(stat in unlockStage?.updStats ?? {})
    if (stat.name in statsImages && stat.value.tointeger() > 0)
      res.append({
        rType = "stat"
        count = stat.value.tointeger()
        id = stat.name
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
        source = group[0].source //can be different, but no need to differentiate them unless they have no drop limit
        rewardCfg = group[0].rewardCfg //can be different, but no need to differentiate them unless they have no drop limit
        rType = group[0].rType
        slots = group[0].slots
        count = group[0].count
        countRange = group[group.len() - 1].count
        agregatedRewards = group.map(@(r) {
          count = r.count
          id = r.rewardId
        })
      })
    }

  return res
}

function getLootboxCommonRewardsViewInfo(lootbox) {
  let { name = "", lastReward = "" } = lootbox
  let rewards = lootbox.rewards.map(function(chance, id) {
    let rewardCfg = serverConfigs.value?.rewardsCfg[id]
    let content = getRewardsViewInfo(rewardCfg)?[0]
    return {
      id
      source = name
      rewardCfg
      chance
      content
      dropLimit = lootbox?.dropLimit[id] ?? dropLimitByType?[content?.rType] ?? NO_DROP_LIMIT
      dropLimitRaw = lootbox?.dropLimit[id]
    }
  })
    .filter(@(v) v != null)
    .values()

  if (lastReward != "") {
    let rewardCfg = serverConfigs.value?.rewardsCfg[lastReward]
    rewards.append({
      id = lastReward
      source = name
      rewardCfg
      chance = 0
      content = getRewardsViewInfo(rewardCfg)?[0]
      dropLimit = NO_DROP_LIMIT
      isLastReward = true
    })
  }

  return rewards
    .filter(@(r) r.content != null)
    .sort(@(a, b) b.content.slots <=> a.content.slots
      || a.dropLimit <=> b.dropLimit
      || (a?.isLastReward ?? false) <=> (b?.isLastReward ?? false)
      || a.chance <=> b.chance
      || sortRewardsViewInfo(a.content, b.content))
    .map(@(v) v.content.__update({
        rewardId = v.id
        source = v.source
        rewardCfg = v.rewardCfg
        dropLimit = v.dropLimit
        dropLimitRaw = v?.dropLimitRaw ?? NO_DROP_LIMIT
        isLastReward = v?.isLastReward ?? false
      }))
}

function getLootboxFixedRewardsViewInfo(lootbox) {
  let fixedRewards = []
  let added = {}
  foreach (_value, id in lootbox.fixedRewards) {
    if (id in added)
      continue
    added[id] <- true

    let content = getRewardsViewInfo(serverConfigs.value?.rewardsCfg[id])?[0]
    if (content?.rType == "lootbox") {
      let rewards = getLootboxCommonRewardsViewInfo(serverConfigs.value?.lootboxesCfg[content.id])
      foreach (r in rewards)
        fixedRewards.append(r.__merge({ isJackpot = true, parentSource = lootbox?.name ?? "" }))
    }
    else
      fixedRewards.append({
        id
        isFixed = true
        source = lootbox?.name ?? ""
        chance = 0
        content
        dropLimit = NO_DROP_LIMIT
      })
  }
  return fixedRewards
}

function getLootboxRewardsViewInfo(lootbox, needToGroup = false) {
  let fixedRewards = getLootboxFixedRewardsViewInfo(lootbox)
  let commonRewards = getLootboxCommonRewardsViewInfo(lootbox)
    .filter(@(cR) fixedRewards.findindex(@(fR) fR.rewardId == cR.rewardId) == null)
  return fixedRewards.extend(needToGroup ? groupRewards(commonRewards) : commonRewards)
}

let receivedGoodsToViewInfo = @(rGoods)
  mkViewInfo(rGoods?.id ?? "", rGoods?.gType ?? "", rGoods.count ?? 0, rGoods?.subId ?? "")

let isEmptyByField = {
  decorators = @(value, profile) value.findvalue(@(d) d not in profile?.decorators) == null
  units = @(value, profile) value.findvalue(@(u) u not in profile?.units) == null
  unitUpgrades = @(value, profile) value.findvalue(@(u) !profile?.units[u].isUpgraded) == null
  skins = @(value, profile) value.findvalue(@(skinName, unitName) skinName not in profile?.skins[unitName]) == null
}

let isEmptyByRType = {
  [G_DECORATOR] = @(value, _, profile) value in profile?.decorators,
  [G_UNIT] = @(value, _, profile) value in profile?.units,
  [G_UNIT_UPGRADE] = @(value, _, profile) profile?.units[value].isUpgraded,
  [G_SKIN] = @(unitName, skinName, profile) skinName in profile?.skins[unitName],
}

let isEmptyByType = {
  table = @(value) value.len() == 0
  array = @(value) value.len() == 0
  integer = @(value) value == 0
  float = @(value) value == 0
}

function isRewardEmpty(reward, profile) {
  local res = true
  if (typeof(reward) == "table") //compatibility with 2024.04.14
    foreach(id, value in reward) {
      let empty = isEmptyByField?[id](value, profile)
        ?? isEmptyByType?[type(value)](value)
      if (empty == null) {
        logerr($"Unknown reward field '{id}' type = {type(value)}")
        break
      }
      if (!empty) {
        res = false
        break
      }
    }
  else //typeof(reward) == "array"
    foreach(r in reward)
      if (!(isEmptyByRType?[r.gType](r.id, r.subId, profile) ?? false)) {
        res = false
        break
      }
  return res
}

function isSingleViewInfoRewardEmpty(reward, profile) {
  let { id, rType, subId = "" } = reward
  return isEmptyByRType?[rType](id, subId, profile) ?? false
}

function isViewInfoRewardEmpty(reward, profile) {
  foreach(r in reward)
    if (!isSingleViewInfoRewardEmpty(r, profile))
      return false
  return true
}

function isRewardReceived(lootbox, id, reward, profile) {
  let { name, fixedRewards } = lootbox
  let openCount = profile?.lootboxStats[name].opened ?? 0
  let rollsToReceive = fixedRewards.findindex(@(r) r == id)?.tointeger()
  return isRewardEmpty(reward, profile) || (rollsToReceive != null && rollsToReceive <= openCount)
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
      let { fixedRewards = {} } = configs.lootboxesCfg?[r?.parentSource]
      hideLastReward[true] <- null == fixedRewards.findindex(@(_, c) c.tointeger() > opened)
      return r
    }

    if (isRewardEmpty(r.rewardCfg, profile))
      return r.__merge({ received = 1, dropLimit = 1 })

    if (r?.isFixed) {
      let { opened = 0 } = lootboxStats?[r?.source]
      let { fixedRewards = {} } = configs.lootboxesCfg?[r?.source]
      local received = 0
      local dropLimit = 0
      foreach(countStr, id in fixedRewards)
        if (id == r.id) {
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

  getRewardsViewInfo
  getStatsRewardsViewInfo
  getUnlockRewardsViewInfo
  sortRewardsViewInfo
  joinViewInfo
  getLootboxRewardsViewInfo
  receivedGoodsToViewInfo
  isRewardEmpty
  isViewInfoRewardEmpty
  isSingleViewInfoRewardEmpty
  isRewardReceived
  fillRewardsCounts
}
