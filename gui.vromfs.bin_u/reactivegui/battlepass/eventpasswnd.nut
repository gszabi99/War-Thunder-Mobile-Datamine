from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/passPresentation.nut" import getEpPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%rGui/battlePass/bpProgressBar.nut" as bpProgressBar
import "%rGui/battlePass/bpRewardDesc.nut" as bpRewardDesc
import "%rGui/battlePass/buyEPLevelMsg.nut" as buyEPLevelMsg
import "%rGui/battlePass/eventPassRewardsList.nut" as eventPassRewardsList
from "%rGui/battlePass/eventPassState.nut" import isEpActive, openEPPurchaseWnd, selectedStage, curStage, getEpIcon,
  EP_VIP, EP_COMMON, EP_NONE, purchasedEp, pointsCurStage, pointsPerStage, curEventId, isEpRewardsInProgress,
  receiveEpRewards, epSeasonEndTime, eventLevelPrice, isEPLevelPurchaseInProgress
from "%rGui/battlePass/passPkg.nut" import bpCurProgressbar, bpProgressText, progressIconSize, contentH,
  mkRewardsPannable, mkPassIcon
from "%rGui/components/buttonStyles.nut" import PURCHASE, defButtonHeight, defButtonMinWidth
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/textButton.nut" import textButtonMultiline
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/components/timerBlock.nut" import mkTimerBlock


let scrollHandler = ScrollHandler()

function scrollToCardEP(scrollX, selProgress) {
  selectedStage.set(selProgress)
  if (scrollX > saSize[0] / 2)
    scrollHandler.scrollToX(scrollX - saSize[0] / 2)
}

let scrollArrowsBlock = {
  size = FLEX
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
  ]
}

let rewardsList = @(stages, recommendInfo) @() {
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCardEP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
  children = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage,
      eventLevelPrice, isEPLevelPurchaseInProgress, buyEPLevelMsg)
    eventPassRewardsList(stages)
  ]
}

let taskDesc = @() {
  watch = curEventId
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc(getEpPresentation(curEventId.get()).shortDescLocId)
}.__update(fontTinyAccentedShaded)

let epLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmallShaded)

let levelBlock = @() {
  watch = curStage
  rendObj = ROBJ_IMAGE
  image = simpleHorGrad
  color = 0xAA000000
  flipX = true
  flow = FLOW_VERTICAL
  padding = hdpx(10)
  gap = hdpx(15)
  children = [
    epLevelLabel($"{loc("mainmenu/rank")} {curStage.get()}")
    {
      size = const [hdpx(300), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        bpCurProgressbar(pointsCurStage, pointsPerStage)
        bpProgressText(pointsCurStage, pointsPerStage)
      ]
    }
    taskDesc
  ]
}

let leftMiddle = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  children = [
    mkTimerBlock(epSeasonEndTime)
    levelBlock
  ]
}

let openPurchBpButton = @(text) textButtonMultiline(utf8ToUpper(text), openEPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = [purchasedEp, curEventId, isEpActive]
  size = [defButtonMinWidth, FLEX]
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    (curEventId.get() ?? "") == "" ? null
      : mkPassIcon([purchasedEp, curEventId, isEpActive],
          @() getEpIcon(purchasedEp.get(), curEventId.get()),
          @() isEpActive.get(),
          "ui/gameuiskin#event_pass_icon_not_active.avif")
    purchasedEp.get() == EP_COMMON
        ? openPurchBpButton(loc("eventPass/upgrade"))
      : purchasedEp.get() == EP_NONE
        ? openPurchBpButton(loc(getEpPresentation(curEventId.get()).btnBuyLocId))
      : purchasedEp.get() == EP_VIP
        ? {
            size = [FLEX, defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("eventpass/active"))
          }.__update(fontTinyAccented)
      : { size = [FLEX, defButtonHeight] }
  ].filter(@(v) v != null)
}

let middlePart = @(stagesList) function() {
  let stageData = stagesList.findvalue(@(s) s.progress == selectedStage.get())
  return {
    watch = selectedStage
    size = FLEX
    children = [
      leftMiddle
      {
        size = FLEX
        children = stageData == null ? null
          : bpRewardDesc(stageData,
              { lockText = "eventpass/lock", paidText = "eventpass/paid" },
              curStage,
              @() receiveEpRewards(stageData.progress),
              isEpRewardsInProgress)
      }
      rightMiddle
    ]
  }
}

let contentEP = @(stagesList, recommendInfo, isFullScreenWidth) @() {
  watch = stagesList
  size = FLEX
  children = {
    size = [FLEX, contentH]
    flow = FLOW_VERTICAL
    gap = hdpx(15)
    children = [
      middlePart(stagesList.get())
      {
        size = FLEX_H
        margin = [0, 0, hdpx(30), 0]
        children = [
          {
            size = [FLEX, progressIconSize[1]]
          }
          mkRewardsPannable(rewardsList(stagesList.get(), recommendInfo),
            scrollHandler, isFullScreenWidth)
          scrollArrowsBlock
        ]
      }
    ]
  }
  animations = wndSwitchAnim
}

return {
  contentEP
  scrollToCardEP
}