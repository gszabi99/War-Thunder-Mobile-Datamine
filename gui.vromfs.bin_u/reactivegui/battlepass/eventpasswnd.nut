from "%globalsDarg/darg_library.nut" import *

let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { closeEventPassWnd, isEpSeasonActive, isEpActive, openEPPurchaseWnd, selectedStage, curStage, getEpIcon,
  EP_VIP, EP_COMMON, EP_NONE, purchasedEp,curOpenEventPass,
  pointsCurStage, pointsPerStage, curEventId, seasonEndTime,
  isEpRewardsInProgress, receiveEpRewards
} = require("%rGui/battlePass/eventPassState.nut")
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
let eventPassRewardsList = require("%rGui/battlePass/eventPassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let bpRewardDesc = require("%rGui/battlePass/bpRewardDesc.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { COMMON_TAB } = require("%rGui/quests/questsState.nut")

isEpSeasonActive.subscribe(@(isActive) isActive ? null : closeEventPassWnd())

let bpIconSize = [hdpx(269), hdpx(306)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100) - (sideTabWidth + vGradientGapSize[0]),
  [hdpx(40) + vGradientGapSize[0], hdpx(60)], [hdpx(40), hdpx(200)])

function scrollToCardEP(scrollX, selProgress) {
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
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCardEP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
  children = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage)
    eventPassRewardsList(stages)
  ]
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccented)

let epLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmall)

let levelBlock = @() {
  watch = curStage
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
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
  ]
}

let leftMiddle = {
  size = FLEX_V
  padding = const [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = [
    levelBlock
    @() {
      watch = curOpenEventPass
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        taskDesc
        mkBtnOpenTabQuests(curOpenEventPass.get()?.eventId ?? COMMON_TAB)
      ]
    }
  ]
}

let openPurchBpButton = @(text) textButtonMultiline(utf8ToUpper(text), openEPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = [purchasedEp, curEventId, isEpActive]
  size = [defButtonMinWidth, flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    (curEventId.get() ?? "") == "" ? null
      : {
          size = bpIconSize
          rendObj = ROBJ_IMAGE
          image = Picture($"{getEpIcon(purchasedEp.get(), curEventId.get())}:{bpIconSize[0]}:{bpIconSize[1]}:P")
          fallbackImage = Picture($"ui/gameuiskin#event_pass_icon_not_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
          opacity = isEpActive.get() ? 1 : 0.5
        }
    purchasedEp.get() == EP_COMMON
        ? openPurchBpButton(loc("eventPass/upgrade"))
      : purchasedEp.get() == EP_NONE
        ? openPurchBpButton(loc("eventPass/btn_buy"))
      : purchasedEp.get() == EP_VIP
        ? {
            size = [flex(), defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("eventpass/active"))
          }.__update(fontTinyAccented)
      : { size = [flex(), defButtonHeight] }
  ].filter(@(v) v != null)
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
            watch = [curEventId, seasonEndTime]
            flow = FLOW_HORIZONTAL

            children = battlePassSeason($"events/name/{curEventId.get()}", seasonEndTime.get(),
              infoTooltipButton(@() loc("eventPass/desc")),
              {
                halign = ALIGN_CENTER
                padding = const [hdpx(20), hdpx(200)]
              }
            )
          }
          stageData == null ? null
            : bpRewardDesc(stageData,
                { lockText = "eventpass/lock", paidText = "eventpass/paid" },
                curStage,
                @() receiveEpRewards(stageData.progress),
                isEpRewardsInProgress)
        ]
      }
      rightMiddle
    ]
  }
}

let contentEP = @(stagesList, recommendInfo) @() {
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
  contentEP
  scrollToCardEP
}