from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isBpActive, openBPPurchaseWnd, selectedStage, curStage, getBpIcon,
  BP_VIP, BP_COMMON, BP_NONE, purchasedBp, battlePassGoods, pointsCurStage, pointsPerStage,
  receiveBpRewards, isBpRewardsInProgress, bpSeasonEndTime,
  bpLevelPrice, isBPLevelPurchaseInProgress
} = require("%rGui/battlePass/battlePassState.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { bpCurProgressbar, bpProgressText, progressIconSize, contentH, mkRewardsPannable, mkTimeEndsAtText, mkPassIcon
} = require("%rGui/battlePass/passPkg.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let bpProgressBar = require("%rGui/battlePass/bpProgressBar.nut")
let battlePassRewardsList = require("%rGui/battlePass/battlePassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let bpRewardDesc = require("%rGui/battlePass/bpRewardDesc.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let buyBPLevelMsg = require("%rGui/battlePass/buyBPLevelMsg.nut")

let scrollHandler = ScrollHandler()

function scrollToCardBP(scrollX, selProgress) {
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
  key = "bpRewardsList"
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCardBP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
  children = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage,
      bpLevelPrice, isBPLevelPurchaseInProgress, buyBPLevelMsg)
    battlePassRewardsList(stages)
  ]
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccentedShaded)

let bpLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmallShaded)

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
    bpLevelLabel($"{loc("mainmenu/rank")} {curStage.get()}")
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
    mkTimeEndsAtText(bpSeasonEndTime, { key = "battle_pass_time" }) 
    levelBlock
  ]
}

let openPurchBpButton = @(text) textButtonMultiline(utf8ToUpper(text), openBPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = [isBpActive, purchasedBp]
  size = [defButtonMinWidth, FLEX]
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    mkPassIcon([purchasedBp, eventSeason, isBpActive],
      @() getBpIcon(purchasedBp.get(), eventSeason.get()),
      @() isBpActive.get(),
      "ui/gameuiskin#bp_icon_not_active.avif")
    purchasedBp.get() == BP_COMMON && battlePassGoods.get()[BP_VIP] != null
        ? openPurchBpButton(loc("battlePass/upgrade"))
      : purchasedBp.get() == BP_NONE && battlePassGoods.get()[BP_COMMON] != null
        ? openPurchBpButton(loc("battlePass/btn_buy"))
      : purchasedBp.get() != BP_NONE
        ? {
            size = [FLEX, defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("battlepass/active"))
          }.__update(fontTinyAccented)
      : { size = [FLEX, defButtonHeight] }
  ]
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
              { lockText = "battlepass/lock", paidText = "battlepass/paid" },
              curStage,
              @() receiveBpRewards(stageData.progress),
              isBpRewardsInProgress)
      }
      rightMiddle
    ]
  }
}

let contentBP = @(stagesList, recommendInfo, isFullScreenWidth) @() {
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
            key = "battle_pass_progress_bar" 
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
  contentBP
  scrollToCardBP
}