from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { closeOperationPassWnd, isOPSeasonActive, isOPActive,
  openOPPurchaseWnd, selectedStage, curStage, getOPIcon, seasonEndTime,
  OP_VIP, OP_COMMON, OP_NONE, purchasedOP, operationPassGoods, pointsCurStage, pointsPerStage, seasonName,
  receiveOPRewards, isOPRewardsInProgress, OPCampaign
} = require("%rGui/battlePass/operationPassState.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let battlePassSeason = require("%rGui/battlePass/battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText, progressIconSize, sideTabWidth, vGradientGapSize
} = require("%rGui/battlePass/battlePassPkg.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let bpProgressBar = require("%rGui/battlePass/bpProgressBar.nut")
let operationPassRewardsList = require("%rGui/battlePass/operationPassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let bpRewardDesc = require("%rGui/battlePass/bpRewardDesc.nut")
let { PERSONAL_TAB } = require("%rGui/quests/questsState.nut")

isOPSeasonActive.subscribe(@(isActive) isActive ? null : closeOperationPassWnd())

let opIconSize = [hdpx(298), hdpx(181)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100) - (sideTabWidth + vGradientGapSize[0]),
  [hdpx(40) + vGradientGapSize[0], hdpx(60)], [hdpx(40), hdpx(200)])

function scrollToCardOP(scrollX, selProgress) {
  selectedStage.set(selProgress)
  if (scrollX > saSize[0] / 2)
    scrollHandler.scrollToX(scrollX - saSize[0] / 2)
}

let header = {
  size = [flex(), gamercardHeight]
  margin = saBordersRv
  valign = ALIGN_TOP
  halign = ALIGN_RIGHT
  children = mkCurrencyBalance(GOLD)
}

let scrollArrowsBlock = {
  size = flex()
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L, scrollArrowImageSmall)
    mkScrollArrow(scrollHandler, MR_R, scrollArrowImageSmall)
  ]
}

let rewardsList = @(stages, recommendInfo) @() {
  key = "opRewardsList"
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCardOP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
  children = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage)
    operationPassRewardsList(stages)
  ]
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccented)

let opLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmall)

let levelBlock = @() {
  watch = curStage
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  children = [
    opLevelLabel($"{loc("mainmenu/rank")} {curStage.get()}")
    {
      size = const [hdpx(300), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        bpCurProgressbar(pointsCurStage, pointsPerStage)
        bpProgressText(pointsCurStage, pointsPerStage)
      ]
    }
  ]
}

let leftMiddle = {
  size = FLEX_V
  padding = const [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    levelBlock
    {
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        taskDesc
        mkBtnOpenTabQuests(PERSONAL_TAB)
      ]
    }
  ]
}

let openPurchOpButton = @(text) textButtonMultiline(utf8ToUpper(text), openOPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = [purchasedOP, operationPassGoods]
  size = [defButtonMinWidth, flex()]
  padding = const [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    @() {
      watch = [purchasedOP, isOPActive, OPCampaign]
      size = opIconSize
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{getOPIcon(purchasedOP.get(), OPCampaign.get())}:{opIconSize[0]}:{opIconSize[1]}:P")
      fallbackImage = Picture($"ui/gameuiskin#bp_icon_not_active.avif:{opIconSize[0]}:{opIconSize[1]}:P")
      opacity = isOPActive.get() ? 1 : 0.5
    }
    purchasedOP.get() == OP_COMMON && operationPassGoods.get()[OP_VIP] != null
        ? openPurchOpButton(loc("operationPass/upgrade"))
      : purchasedOP.get() == OP_NONE
        ? openPurchOpButton(loc("operationPass/btn_buy"))
      : purchasedOP.get() != OP_NONE
        ? {
            size = [flex(), defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("operationpass/active"))
          }.__update(fontTinyAccented)
      : { size = [flex(), defButtonHeight] }
  ]
}

let middlePart = @(stagesList) function() {
  let stageData = stagesList.findvalue(@(s) s.progress == selectedStage.get())
  return {
    watch = selectedStage
    size = flex()
    margin = [saBorders[1], saBorders[0], 0, hdpx(20)]
    flow = FLOW_HORIZONTAL
    children = [
      leftMiddle
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(20)
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = [seasonName, seasonEndTime]
            halign = ALIGN_CENTER
            children = battlePassSeason(seasonName.get(), seasonEndTime.get(), null,
              {
                halign = ALIGN_CENTER
                padding = const [hdpx(20), hdpx(200)]
              }
            )
          }
          stageData == null ? null
            : bpRewardDesc(stageData,
                { lockText = "operationpass/lock", paidText = "operationpass/paid" },
                curStage,
                @() receiveOPRewards(stageData.progress),
                isOPRewardsInProgress)
        ]
      }
      rightMiddle
    ]
  }
}

let contentOP = @(stagesList, recommendInfo) @() {
  watch = stagesList
  size = flex()
  children = [
    header
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        middlePart(stagesList.get())
        {
          size = [sw(100) - sideTabWidth, SIZE_TO_CONTENT]
          hplace = ALIGN_CENTER
          margin = [0, 0, saBorders[1], 0]
          children = [
            {
              key = "battle_pass_progress_bar" 
              size = [flex(), progressIconSize[1]]
            }
            rewardPannable(rewardsList(stagesList.get(), recommendInfo),
              { pos = [-hdpx(20), 0], size = FLEX_H, clipChilden = false },
              {
                size = FLEX_H
                behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
                scrollHandler = scrollHandler
              })
            scrollArrowsBlock
          ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

return {
  contentOP
  scrollToCardOP
}