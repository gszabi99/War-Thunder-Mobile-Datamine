from "%globalsDarg/darg_library.nut" import *
let { apply_unit_level_rewards } = require("%appGlobals/pServer/pServerApi.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")

let currentUnit = mkWatched(persist, "unitForReceiveRewards", null)
let isUnitRewardsModalOpen = Computed(@() currentUnit.get() != null)

let openUnitRewardsModal = @(unit) currentUnit.set(unit)
let closeUnitRewardsModal = @() currentUnit.set(null)

let levelRewardsCfg = Computed(@() serverConfigs.get()?.unitLevelRewards?[curCampaign.get()])

let rewardUnitLevelInfo = Computed(function() {
  if (!currentUnit.get())
    return { minLevel = 0, maxLevel = 0, isEqual = true }
  let { receivedUnitLvlRewards = {} } = servProfile.get()
  let { name, level } = currentUnit.get()
  let receivedRewards = receivedUnitLvlRewards?[name] ?? {}

  let maxLevel = level
  local minLevel = 0

  foreach(key, _ in receivedRewards)
    if (key.tointeger() > minLevel)
      minLevel = key.tointeger()

  return {
    minLevel,
    maxLevel,
    isEqual = minLevel == maxLevel
  }
})

let rewardsToReceive = Computed(function() {
  if (!currentUnit.get() || levelRewardsCfg.get() == null || rewardUnitLevelInfo.get().isEqual)
    return []

  let { receivedUnitLvlRewards = {} } = servProfile.get()
  let { name, level } = currentUnit.get()

  let receivedRewards = receivedUnitLvlRewards?[name]
  let aggregator = {}

  foreach (rlevel, rewards in levelRewardsCfg.get()) {
    let intRLevel = rlevel.tointeger()
    if (intRLevel <= level
      && (receivedRewards == null || rlevel not in receivedRewards)
      && intRLevel >= rewardUnitLevelInfo.get().minLevel)
        foreach (reward in rewards) {
          if (reward.id not in aggregator)
            aggregator[reward.id] <- clone reward
          else
            aggregator[reward.id].count += reward.count
        }
  }

  let res = []
  foreach(reward in aggregator)
    res.append(reward)
  return res
})

let receiveUnitRewards = @(unitName, campaign) apply_unit_level_rewards(unitName, campaign)
let receivedRewards = Computed(@() servProfile.get()?.receivedUnitLvlRewards ?? {})
let unitRewardsCfg = Computed(@() serverConfigs.get()?.unitLevelRewards)

let unseenUnitLvlRewardsList = Computed(function() {
  let res = {}
  foreach (name, unit in campMyUnits.get()) {
    let { level = 0, isPremium = false, campaign = "" } = unit
    let rewardsCfgByCampaign = unitRewardsCfg.get()?[campaign]

    if (level == 0 || isPremium || !rewardsCfgByCampaign)
      continue

    let receivedRewardsByUnit = receivedRewards.get()?[name] ?? {}

    foreach (rLevel, _ in rewardsCfgByCampaign)
      if (rLevel.tointeger() <= level && rLevel not in receivedRewardsByUnit) {
        res[name] <- true
        break
      }
  }
  return res
})

return {
  currentUnit
  rewardsToReceive
  receiveUnitRewards
  rewardUnitLevelInfo
  openUnitRewardsModal
  isUnitRewardsModalOpen
  unseenUnitLvlRewardsList
  closeUnitRewardsModal
}
