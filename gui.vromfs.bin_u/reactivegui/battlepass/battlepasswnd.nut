from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let {  closeBattlePassWnd, isBpSeasonActive, isBpActive,
  openBPPurchaseWnd, selectedStage, curStage, getBpIcon, seasonEndTime,
  BP_VIP, BP_COMMON, BP_NONE, purchasedBp, battlePassGoods, pointsCurStage, pointsPerStage, seasonName,
  receiveBpRewards, isBpRewardsInProgress
} = require("%rGui/battlePass/battlePassState.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
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
let battlePassRewardsList = require("%rGui/battlePass/battlePassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let bpRewardDesc = require("%rGui/battlePass/bpRewardDesc.nut")
let { COMMON_TAB } = require("%rGui/quests/questsState.nut")

isBpSeasonActive.subscribe(@(isActive) isActive ? null : closeBattlePassWnd())

let bpIconSize = [hdpx(298), hdpx(181)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100) - (sideTabWidth + vGradientGapSize[0]),
  [hdpx(40) + vGradientGapSize[0], hdpx(60)], [hdpx(40), hdpx(200)])

function scrollToCardBP(scrollX, selProgress) {
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
  key = "bpRewardsList"
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCardBP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
  children = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage)
    battlePassRewardsList(stages)
  ]
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccented)

let bpLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmall)

let levelBlock = @() {
  watch = curStage
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
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
        mkBtnOpenTabQuests(COMMON_TAB)
      ]
    }
  ]
}

let openPurchBpButton = @(text) textButtonMultiline(utf8ToUpper(text), openBPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = [isBpActive, purchasedBp]
  size = [defButtonMinWidth, flex()]
  padding = const [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    @() {
      watch = [purchasedBp, eventSeason, isBpActive, battlePassGoods]
      size = bpIconSize
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{getBpIcon(purchasedBp.get(), eventSeason.get())}:{bpIconSize[0]}:{bpIconSize[1]}:P")
      fallbackImage = Picture($"ui/gameuiskin#bp_icon_not_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
      opacity = isBpActive.get() ? 1 : 0.5
    }
    purchasedBp.get() == BP_COMMON && battlePassGoods.get()[BP_VIP] != null
        ? openPurchBpButton(loc("battlePass/upgrade"))
      : purchasedBp.get() == BP_NONE && battlePassGoods.get()[BP_COMMON] != null
        ? openPurchBpButton(loc("battlePass/btn_buy"))
      : purchasedBp.get() != BP_NONE
        ? {
            size = [flex(), defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("battlepass/active"))
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
                { lockText = "battlepass/lock", paidText = "battlepass/paid" },
                curStage,
                @() receiveBpRewards(stageData.progress),
                isBpRewardsInProgress)
        ]
      }
      rightMiddle
    ]
  }
}

let contentBP = @(stagesList, recommendInfo) @() {
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
  contentBP
  scrollToCardBP
}