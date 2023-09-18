from "%globalsDarg/darg_library.nut" import *
let { isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { eventLootboxes, eventLootboxesRaw } = require("eventLootboxes.nut")
let { onSchRewardReceive, schRewards, schRewardsStatus } = require("%rGui/shop/schRewardsState.nut")


let isEventWndOpen = mkWatched(persist, "isEventWndOpen", false)
let curLootbox = Watched(null)
let curLootboxIndex = Computed(@() eventLootboxes.value?.findindex(@(v) v.name == curLootbox.value) ?? -1)

let eventRewards = Computed(@() schRewards.value
  .filter(@(v) v.lootboxes.findindex(@(_, key) key in eventLootboxesRaw.value))
  .map(@(v, key) v.__merge(schRewardsStatus.value?[key] ?? {})))

let showLootboxAds = @(id) onSchRewardReceive(eventRewards.value?[id])

let function openEventWnd() {
  if (isOfflineMenu) {
    openFMsgBox({ text = "Not supported in the offline mode" })
    return
  }
  isEventWndOpen(true)
}

return {
  isEventWndOpen
  openEventWnd
  closeEventWnd = @() isEventWndOpen(false)
  closeLootboxWnd = @() curLootbox(null)
  curLootbox
  curLootboxIndex
  showLootboxAds
  eventRewards
}