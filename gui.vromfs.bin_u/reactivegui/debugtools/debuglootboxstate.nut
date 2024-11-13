from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")

let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { getAllLootboxRewardsViewInfo, fillRewardsCounts } = require("%rGui/rewards/rewardViewInfo.nut")
let { previewLootboxId } = require("%rGui/shop/lootboxPreviewState.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let selectedLootbox = mkWatched(persist, "selectedLootbox", null)
let lootboxesCfg = Computed(@() serverConfigs.get()?.lootboxesCfg ?? {})
let rewardsViewInfo = Computed(@() !selectedLootbox.get() ? null
  : getAllLootboxRewardsViewInfo(lootboxesCfg.get()?[selectedLootbox.get()]))
let allRewards = Computed(@() !rewardsViewInfo.get() ? {}
  : fillRewardsCounts(rewardsViewInfo.get(), servProfile.get(), serverConfigs.get()))

let openDebugLootbox = @() isOpened.set(true)

register_command(function() {
  if (previewLootboxId.get() != null)
    selectedLootbox.set(previewLootboxId.get())
  isOpened.set(true)
}, "ui.debug.lootboxes_rewards")

return {
  lootboxesCfg,
  allRewards,
  isOpened,
  selectedLootbox
  openDebugLootbox,
}
