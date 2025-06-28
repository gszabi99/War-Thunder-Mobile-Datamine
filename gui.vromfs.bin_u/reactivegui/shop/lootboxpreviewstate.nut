from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")


let previewLootboxId = mkWatched(persist, "previewLootboxId", null)
let previewLootbox = Computed(@() serverConfigs.value?.lootboxesCfg?[previewLootboxId.value])
let eventWndLootboxId = mkWatched(persist, "eventWndLootboxId", null)
let eventWndLootbox = Computed(@() serverConfigs.value?.lootboxesCfg?[eventWndLootboxId.value])

function getStepsToNextFixed(lootbox, sConfigs, sProfile) {
  let { rewardsCfg = null } = sConfigs
  let { opened = 0, total = {} } = sProfile?.lootboxStats[lootbox?.name]
  local openingToNext = 0
  foreach (steps, fr in (lootbox?.fixedRewards ?? {})) {
    let id = fr?.rewardId ?? fr 
    if (steps.tointeger() > opened
        && (steps.tointeger() < openingToNext || openingToNext == 0)
        && id in rewardsCfg
        && !isRewardEmpty(rewardsCfg[id], sProfile)
        && null == fr?.lockedBy.findvalue(@(l) (total?[l] ?? 0) > 0))
      openingToNext = steps.tointeger()
  }
  return [opened, openingToNext]
}

let isLootboxPreviewOpen = Computed(@() previewLootboxId.get() != null)
let isEventWndLootboxOpen = Computed(@() eventWndLootboxId.get() != null)

return {
  openLootboxPreview = @(id) previewLootboxId.set(id)
  closeLootboxPreview = @() previewLootboxId.set(null)
  openEventWndLootbox = @(id) eventWndLootboxId.set(id)
  closeEventWndLootbox = @() eventWndLootboxId.set(null)
  previewLootboxId
  previewLootbox
  eventWndLootbox

  getStepsToNextFixed
  isLootboxPreviewOpen
  isEventWndLootboxOpen
}
