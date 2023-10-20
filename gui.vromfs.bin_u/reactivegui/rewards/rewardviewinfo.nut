from "%globalsDarg/darg_library.nut" import *
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")

let UNREACHABLE_INT = 1000000

let rTypesPriority = [
  "unknown"
  "unitUpgrade"
  "unit"
  "currency"
  "premium"
  "decorator"
  "item"
  "lootbox"
].reduce(@(res, v, idx) res.__update({ [v] = idx + 1 }), {})

let slotsByType = {
  unitUpgrade = 2
  unit = 2
}

let slotsByDType = {
  title = 2
}

let dropLimitByType = ["unit", "unitUpgrade", "decorator"]
  .reduce(@(res, id) res.rawset(id, 1), {})

let sortRewardsViewInfo = @(a, b) (rTypesPriority?[a.rType] ?? 0) <=> (rTypesPriority?[b.rType] ?? 0)
  || (a.rType != "currency" ? 0 : ((orderByCurrency?[a.id] ?? 0) <=> (orderByCurrency?[b.id] ?? 0)))
  || (a.rType != "item" ? 0 : ((orderByItems?[a.id] ?? 0) <=> (orderByItems?[b.id] ?? 0)))
  || b.count <=> a.count
  || a.id <=> b.id

// No need to subscribe to allDecorators because it is loaded on game start
let mkViewInfo = @(id, rType, count = 0)
  { id, rType, count, slots = slotsByType?[rType] ?? slotsByDType?[allDecorators.value?[id].dType] ?? 1 }

let function getRewardsViewInfo(data, multiply = 1) {
  let res = []
  if (!data)
    return res
  let { gold = 0, wp = 0, warbond = 0, eventKey = 0, premiumDays = 0, items = {}, lootboxes = {},
    decorators = [], unitUpgrades = [], units = [] } = data
  if (unitUpgrades.len() != 0)
    foreach (id in unitUpgrades)
      res.append(mkViewInfo(id, "unitUpgrade"))
  if (units.len() != 0)
    foreach (id in units)
      if (!unitUpgrades.contains(id))
        res.append(mkViewInfo(id, "unit"))
  if (gold > 0)
    res.append(mkViewInfo("gold", "currency", gold * multiply))
  if (wp > 0)
    res.append(mkViewInfo("wp", "currency", wp * multiply))
  if (warbond > 0)
    res.append(mkViewInfo("warbond", "currency", warbond * multiply))
  if (eventKey > 0)
    res.append(mkViewInfo("eventKey", "currency", eventKey * multiply))
  if (premiumDays > 0)
    res.append(mkViewInfo("", "premium", premiumDays * multiply))
  if (decorators.len() != 0)
    foreach (id in decorators)
      res.append(mkViewInfo(id, "decorator"))
  if (items.len() != 0)
    foreach (id, count in items)
      res.append(mkViewInfo(id, "item", count * multiply))
  if (lootboxes.len() != 0)
    foreach (id, count in lootboxes)
      res.append(mkViewInfo(id, "lootbox", count * multiply))
  return res
}

let function groupRewards(rewards) {
  let dropLimitRewards = rewards.filter(@(r) r?.dropLimit != UNREACHABLE_INT)
  let dropChanceRewards = rewards.filter(@(r) r?.dropLimit == UNREACHABLE_INT)

  local groupedRewards = {}
  foreach (r in dropChanceRewards) {
    if (r.id not in groupedRewards)
      groupedRewards[r.id] <- []
    groupedRewards[r.id].append(r)
  }

  foreach (group in groupedRewards)
    group.sort(@(a, b) a.count <=> b.count)

  groupedRewards = groupedRewards.map(function(group) {
    let countRange = group.len() > 1 ? group[group.len() - 1].count : null
    return {
      dropLimit = UNREACHABLE_INT
      id = group[0].id
      rType = group[0].rType
      slots = group[0].slots
      count = group[0].count
    }.__update(countRange ? { countRange } : {})
  })

  return dropLimitRewards.extend(groupedRewards.values())
}

let function getLootboxCommonRewardsViewInfo(lootbox) {
  let rewards = lootbox.rewards.map(function(chance, id) {
    let content = getRewardsViewInfo(serverConfigs.value?.rewardsCfg[id])?[0]
    return {
      id
      chance
      content
      dropLimit = lootbox?.dropLimit[id] ?? dropLimitByType?[content?.rType] ?? UNREACHABLE_INT
    }
  })

  return rewards
    .values()
    .filter(@(r) r.content != null)
    .sort(@(a, b) a.dropLimit <=> b.dropLimit
      || a.chance <=> b.chance
      || sortRewardsViewInfo(a.content, b.content))
    .map(@(v) v.content.__update({ rewardId = v.id, dropLimit = v.dropLimit }))
}

let function getLootboxFixedRewardsViewInfo(lootbox) {
  let fixedRewards = []
  foreach (_value, id in lootbox.fixedRewards) {
    let content = getRewardsViewInfo(serverConfigs.value?.rewardsCfg[id])?[0]
    if (content?.rType == "lootbox") {
      let rewards = getLootboxCommonRewardsViewInfo(serverConfigs.value?.lootboxesCfg[content.id])
      foreach (r in rewards)
        if (fixedRewards.findindex(@(v) v.rewardId == r.rewardId) == null)
          fixedRewards.append(r.__merge({ isFixed = true }))
    }
  }
  return fixedRewards
}

let function getLootboxRewardsViewInfo(lootbox, needToGroup = false) {
  let fixedRewards = getLootboxFixedRewardsViewInfo(lootbox)
  let commonRewards = getLootboxCommonRewardsViewInfo(lootbox)
    .filter(@(cR) fixedRewards.findindex(@(fR) fR.rewardId == cR.rewardId) == null)
  return fixedRewards.extend(needToGroup ? groupRewards(commonRewards) : commonRewards)
}

let receivedGoodsToViewInfo = @(rGoods)
  mkViewInfo(rGoods?.id ?? "", rGoods?.gType ?? "", rGoods.count ?? 0)

let isEmptyByField = {
  decorators = @(value, profile) value.findvalue(@(d) d not in profile?.decorators) == null
  units = @(value, profile) value.findvalue(@(u) u not in profile?.units) == null
  unitUpgrades = @(value, profile) value.findvalue(@(u) !profile?.units[u].isUpgraded) == null
}

let isEmptyByType = {
  table = @(value) value.len() == 0
  array = @(value) value.len() == 0
  integer = @(value) value == 0
  float = @(value) value == 0
}

let function isRewardEmpty(reward, profile) {
  local res = true
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
  return res
}

let function isRewardReceived(lootbox, id, reward, profile) {
  let { name, fixedRewards } = lootbox
  let openCount = profile?.lootboxStats[name].opened ?? 0
  let rollsToReceive = fixedRewards.findindex(@(r) r == id)?.tointeger()
  return isRewardEmpty(reward, profile) || (rollsToReceive != null && rollsToReceive <= openCount)
}

return {
  getRewardsViewInfo
  sortRewardsViewInfo
  getLootboxRewardsViewInfo
  receivedGoodsToViewInfo
  isRewardEmpty
  isRewardReceived
}
