from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/rewards/rewardViewInfo.nut" import getAllLootboxRewardsViewInfo, fillRewardsCounts
from "%rGui/shop/lootboxPreviewState.nut" import previewLootboxId


let isOpened = mkWatched(persist, "isOpened", false)
let selectedLootbox = mkWatched(persist, "selectedLootbox", null)
let lootboxesCfg = Computed(@() serverConfigs.get()?.lootboxesCfg ?? {})
let allLootboxes = Computed(@() lootboxesCfg.get().keys().sort())
let curLootbox = Computed(@() allLootboxes.get().contains(selectedLootbox.get()) ? selectedLootbox.get()
  : allLootboxes.get()?[0])
let rewardsViewInfo = Computed(@() !curLootbox.get() ? null
  : getAllLootboxRewardsViewInfo(lootboxesCfg.get()?[curLootbox.get()]))
let allRewards = Computed(@() !rewardsViewInfo.get() ? {}
  : fillRewardsCounts(rewardsViewInfo.get(), servProfile.get(), serverConfigs.get()))

let openDebugLootbox = @() isOpened.set(true)

register_command(function() {
  if (previewLootboxId.get() != null)
    selectedLootbox.set(previewLootboxId.get())
  isOpened.set(true)
}, "ui.debug.lootboxes_rewards")

return {
  allLootboxes,
  curLootbox,
  allRewards,
  isOpened,
  selectedLootbox
  openDebugLootbox,
}
