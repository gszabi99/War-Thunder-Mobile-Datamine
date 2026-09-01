from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/rewards/rewardViewInfo.nut" import getAllLootboxRewardsViewInfo, fillRewardsCounts
from "%rGui/shop/lootboxPreviewState.nut" import previewLootboxId


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
