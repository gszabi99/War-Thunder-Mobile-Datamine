from "%globalsDarg/darg_library.nut" import *
let { isRewardsListOpen, closeRewardsList, rewardsList } = require("questsState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShadedDark, bgMessage } = require("%rGui/style/backgrounds.nut")
let { fadedTextColor } = require("%rGui/shop/unseenPurchaseComps.nut")
let { mkQuestRewardPlate } = require("rewardsComps.nut")

let wndWidth = saSize[0]
let rewardsGapX = hdpx(40)
let rewardsGapY = hdpx(70)
let paddingY = hdpx(100)

let WND_UID = "questRewardsWnd"
let close = @() removeModalWindow(WND_UID)

let wndTitle = {
  rendObj = ROBJ_TEXT
  color = fadedTextColor
  text = loc("quests/rewardsList")
}.__update(fontBig)

let mkContent = @(rewards) {
  size = [flex(), SIZE_TO_CONTENT]
  padding = [paddingY, 0]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = closeRewardsList
  flow = FLOW_VERTICAL
  gap = rewardsGapY
  children = [
    wndTitle
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      gap = rewardsGapX
      children = rewards.map(@(r, idx) mkQuestRewardPlate(r, idx))
    }
  ]
}

let questRewardsWnd = {
  size = [wndWidth, SIZE_TO_CONTENT]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    bgMessage.__merge({size = flex()})
    @() {
      watch = rewardsList
      size = [flex(), SIZE_TO_CONTENT]
      children = mkContent(rewardsList.get() ?? [])
    }
  ]
}

let showRewardsList = @() addModalWindow(bgShadedDark.__merge({
  key = WND_UID
  size = flex()
  onClick = closeRewardsList
  children = questRewardsWnd
  animations = wndSwitchAnim
}))

if (isRewardsListOpen.value)
  showRewardsList()
isRewardsListOpen.subscribe(@(v) v ? showRewardsList() : close())
