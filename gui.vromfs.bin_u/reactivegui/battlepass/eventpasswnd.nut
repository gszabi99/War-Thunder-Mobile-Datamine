from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { register_command } = require("console")
let { isEqual } = require("%sqstd/underscore.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { eventPassOpenCounter, openEventPassWnd, closeEventPassWnd, isEpSeasonActive, isEpActive,
  mkEpStagesList, openEPPurchaseWnd, selectedStage, curStage, getEpIcon,
  EP_VIP, EP_COMMON, EP_NONE, purchasedEp,curOpenEventPass,
  pointsCurStage, pointsPerStage, eventBgImage, curEventId, seasonEndTime,
  isEpRewardsInProgress, receiveEpRewards
} = require("%rGui/battlePass/eventPassState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let battlePassSeason = require("%rGui/battlePass/battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText, progressIconSize } = require("%rGui/battlePass/battlePassPkg.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let bpProgressBar = require("%rGui/battlePass/bpProgressBar.nut")
let eventPassRewardsList = require("%rGui/battlePass/eventPassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let bpRewardDesc = require("%rGui/battlePass/bpRewardDesc.nut")
let { bpCardStyle, bpCardPadding, bpCardMargin } = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { COMMON_TAB } = require("%rGui/quests/questsState.nut")

isEpSeasonActive.subscribe(@(isActive) isActive ? null : closeEventPassWnd())

let bpIconSize = [hdpx(269), hdpx(306)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100),
  [saBorders[0], saBorders[0]])

function scrollToCard(scrollX, selProgress) {
  selectedStage.set(selProgress)
  if (scrollX > saSize[0] / 2)
    scrollHandler.scrollToX(scrollX - saSize[0] / 2)
}

let header = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = [
    @(){
      watch = [curEventId, seasonEndTime]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        backButton(closeEventPassWnd)
        battlePassSeason($"events/name/{curEventId.get()}", seasonEndTime.get(), infoTooltipButton(@() loc("eventPass/desc")))
      ]
    }
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      gap = hdpx(70)
      children = [
        mkCurrencyBalance(WP)
        mkCurrencyBalance(GOLD)
      ]
    }
  ]
}

let scrollArrowsBlock = {
  size = const [flex(),hdpx(363)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L)
    mkScrollArrow(scrollHandler, MR_R)
  ]
}

let rewardsList = @(stages, recommendInfo) @() {
  key = "bpRewardsList"
  watch = serverConfigs
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  onAttach = @() scrollToCard(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
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
  children = [
    levelBlock
    @() {
      watch = curOpenEventPass
      vplace = ALIGN_BOTTOM
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        taskDesc
        mkBtnOpenTabQuests(curOpenEventPass.get()?.eventId ?? COMMON_TAB, {
          sizeBtn = [hdpx(109), hdpx(109)],
          iconSize = hdpx(85)
          size = hdpx(109)
        })
      ]
    }
  ]
}

let openPurchBpButton = @(text) textButtonMultiline(utf8ToUpper(text), openEPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let rightMiddle = @() {
  watch = purchasedEp
  size = [defButtonMinWidth, flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    @() {
      watch = [purchasedEp, curEventId, isEpActive]
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
  ]
}

let middlePart = @(stagesList) function() {
  let stageData = stagesList.findvalue(@(s) s.progress == selectedStage.get())
  return {
    watch = selectedStage
    size = flex()
    flow = FLOW_HORIZONTAL
    children = [
      leftMiddle
      {
        size = flex()
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

let content = @(stagesList, recommendInfo) @() {
  watch = stagesList
  size = flex()
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  children = [
    middlePart(stagesList.get())
    {
      size = const [sw(100), SIZE_TO_CONTENT]
      hplace = ALIGN_CENTER
      children = [
        {
          key = "battle_pass_progress_bar" 
          size = [flex(), progressIconSize[1]]
        }
        rewardPannable(rewardsList(stagesList.get(), recommendInfo),
          { pos = [0, 0], size = FLEX_H, clipChilden = false },
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

let wndKey = {}
function battlePassWnd() {
  let stagesList = mkEpStagesList()
  let recommendInfo = Computed(function(prev) {
    local scrollX = -bpCardMargin
    local selProgress = 0
    foreach(s in stagesList.get()) {
      selProgress = s.progress
      if (s.canReceive
          || (!s.isReceived && (!s.isPaid || isEpActive.get()))) {
        scrollX += bpCardMargin + bpCardPadding[1]
          + getRewardPlateSize(s.viewInfo?.slots ?? 1, bpCardStyle)[0] / 2
        break
      }
      scrollX += bpCardMargin + 2 * bpCardPadding[1]
        + getRewardPlateSize(s.viewInfo?.slots ?? 1, bpCardStyle)[0]
    }
    let res = { scrollX, selProgress }
    return isEqual(prev, res) ? prev : res
  })
  recommendInfo.subscribe(@(v) scrollToCard(v.scrollX, v.selProgress))
  return {
    key = wndKey
    size = flex()
    padding = saBordersRv
    rendObj = ROBJ_SOLID
    color = 0x70000000
    gap = hdpx(10)
    flow = FLOW_VERTICAL
    children = [
      header
      content(stagesList, recommendInfo)
    ]
    animations = wndSwitchAnim
  }
}

register_command(@(id) openEventPassWnd(id), "ui.eventpass_open")
register_command(closeEventPassWnd, "ui.eventpass_close")

registerScene("eventPassWnd", battlePassWnd, closeEventPassWnd, eventPassOpenCounter)
setSceneBg("eventPassWnd", eventBgImage.get())
eventBgImage.subscribe(@(v) setSceneBg("eventPassWnd", v))
