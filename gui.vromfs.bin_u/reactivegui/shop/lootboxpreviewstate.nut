from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")


let openConfig = mkWatched(persist, "openConfig", null)
let previewLootboxId = Computed(@() openConfig.value?.id)
let previewLootbox = Computed(@() serverConfigs.value?.lootboxesCfg?[previewLootboxId.value]
  .__merge({ name = previewLootboxId.value }))

function getStepsToNextFixed(lootbox, sConfigs, sProfile) {
  let { rewardsCfg = null } = sConfigs
  let stepsFinished = sProfile?.lootboxStats[lootbox?.name].opened ?? 0
  local stepsToNext = 0
  foreach (steps, id in (lootbox?.fixedRewards ?? {}))
    if (steps.tointeger() > stepsFinished
        && (steps.tointeger() < stepsToNext || stepsToNext == 0)
        && id in rewardsCfg
        && !isRewardEmpty(rewardsCfg[id], sProfile))
      stepsToNext = steps.tointeger()
  return [stepsFinished, stepsToNext]
}

let isLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && !openConfig.value?.isEmbedded)
let isEmbeddedLootboxPreviewOpen = Computed(@() previewLootboxId.value != null && !!openConfig.value?.isEmbedded)

return {
  openLootboxPreview = @(id) openConfig({ id })
  openEmbeddedLootboxPreview = @(id) openConfig({ id, isEmbedded = true })
  closeLootboxPreview = @() openConfig(null)
  previewLootboxId
  previewLootbox
  getStepsToNextFixed
  isLootboxPreviewOpen
  isEmbeddedLootboxPreviewOpen
}
