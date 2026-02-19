from "%globalsDarg/darg_library.nut" import *
let { getEpPresentation } = require("%appGlobals/config/passPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { isEpActive, openEPPurchaseWnd, selectedStage, curStage, getEpIcon,
  EP_VIP, EP_COMMON, EP_NONE, purchasedEp,curOpenEventPass,
  pointsCurStage, pointsPerStage, curEventId, seasonEndTime,
  isEpRewardsInProgress, receiveEpRewards, eventTitle
} = require("%rGui/battlePass/eventPassState.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let battlePassSeason = require("%rGui/battlePass/battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText, progressIconSize, sideTabWidth, vGradientGapSize
} = require("%rGui/battlePass/battlePassPkg.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
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
let { gmEventsList, openGmEventWnd } = require("%rGui/event/gmEventState.nut")
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let gmEventPresentation = require("%appGlobals/config/gmEventPresentation.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")


let bpIconSize = [hdpx(269), hdpx(306)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100) - (sideTabWidth + vGradientGapSize[0]),
  [hdpx(40) + vGradientGapSize[0], hdpx(60)], [hdpx(40), hdpx(200)])

function scrollToCardEP(scrollX, selProgress) {
  selectedStage.set(selProgress)
  if (scrollX > saSize[0] / 2)
    scrollHandler.scrollToX(scrollX - saSize[0] / 2)
}

let header = @() {
  watch = curEventId
  size = [flex(), gamercardHeight]
  margin = saBordersRv
  valign = ALIGN_TOP
  halign = ALIGN_RIGHT
  children = mkCurrenciesBtns([GOLD].extend(getEpPresentation(curEventId.get()).passWndCurrencies))
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
  padding = const [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  pos = [0, hdpx(140)]
  gap = hdpx(10)
  children = [
    levelBlock
    @() {
      watch = [curOpenEventPass, gmEventsList]
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = {
        flow = FLOW_HORIZONTAL
        gap = hdpx(15)
        children = [
          mkBtnOpenTabQuests(curOpenEventPass.get()?.eventId ?? COMMON_TAB)
          curOpenEventPass.get()?.eventName not in gmEventsList.get()
            ? null
            : translucentButton(gmEventPresentation(curOpenEventPass.get()?.eventName).image,
              "",
              @() openGmEventWnd(curOpenEventPass.get()?.eventName))
        ]
      }
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
        padding = [hdpx(55), 0, 0, 0]
        gap = hdpx(10)
        halign = ALIGN_CENTER
        children = [
          @() {
            watch = [curEventId, eventTitle, seasonEndTime]
            flow = FLOW_HORIZONTAL
            children = battlePassSeason(loc(eventTitle.get()), seasonEndTime.get(),
              infoTooltipButton(@() loc(getEpPresentation(curEventId.get()).descLocId)),
              {
                halign = ALIGN_CENTER
                padding = const [hdpx(0), hdpx(200), hdpx(5), hdpx(200)]
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