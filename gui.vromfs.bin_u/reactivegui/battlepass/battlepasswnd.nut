from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { register_command } = require("console")
let { isEqual } = require("%sqstd/underscore.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { battlePassOpenCounter, openBattlePassWnd, closeBattlePassWnd, isBpSeasonActive, isBpActive,
  mkBpStagesList, openBPPurchaseWnd, selectedStage, curStage, getBpIcon,
  BP_VIP, BP_COMMON, BP_NONE, purchasedBp, battlePassGoods
} = require("battlePassState.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let battlePassSeason = require("battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText, progressIconSize } = require("battlePassPkg.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let bpProgressBar = require("bpProgressBar.nut")
let battlePassRewardsList = require("battlePassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { horizontalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let bpRewardDesc = require("bpRewardDesc.nut")
let { bpCardStyle, bpCardPadding, bpCardMargin } = require("bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { COMMON_TAB } = require("%rGui/quests/questsState.nut")


isBpSeasonActive.subscribe(@(isActive) isActive ? null : closeBattlePassWnd())

let bpIconSize = [hdpx(298), hdpx(181)]
let scrollHandler = ScrollHandler()

let rewardPannable = horizontalPannableAreaCtor(sw(100),
  [saBorders[0], saBorders[0]])

function scrollToCard(scrollX, selProgress) {
  selectedStage(selProgress)
  if (scrollX > saSize[0] / 2)
    scrollHandler.scrollToX(scrollX - saSize[0] / 2)
}

let header = {
  size = [flex(), gamercardHeight]
  valign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children =[
        backButton(closeBattlePassWnd)
        battlePassSeason
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
    bpProgressBar(stages)
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
        bpCurProgressbar
        bpProgressText
      ]
    }
  ]
}

let leftMiddle = {
  size = FLEX_V
  padding = const [hdpx(10), 0, hdpx(20), 0]
  children = [
    levelBlock
    {
      vplace = ALIGN_BOTTOM
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        taskDesc
        mkBtnOpenTabQuests(COMMON_TAB, {
          sizeBtn = [hdpx(109), hdpx(109)],
          iconSize = hdpx(85)
          size = hdpx(109)
        })
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
      opacity = isBpActive.value ? 1 : 0.5
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
  let stageData = stagesList.findvalue(@(s) s.progress == selectedStage.value)
  return {
    watch = selectedStage
    size = flex()
    flow = FLOW_HORIZONTAL
    children = [
      leftMiddle
      {
        size = flex()
        children = stageData == null ? null : bpRewardDesc(stageData)
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
  let stagesList = mkBpStagesList()
  let recommendInfo = Computed(function(prev) {
    local scrollX = -bpCardMargin
    local selProgress = 0
    foreach(s in stagesList.get()) {
      selProgress = s.progress
      if (s.canReceive
          || (!s.isReceived && (!s.isPaid || isBpActive.value))) {
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
    gap = hdpx(10)
    flow = FLOW_VERTICAL
    children = [
      header
      content(stagesList, recommendInfo)
    ]
    animations = wndSwitchAnim
  }
}

register_command(openBattlePassWnd, "ui.battle_pass_open")
register_command(closeBattlePassWnd, "ui.battle_pass_close")

registerScene("battlePassWnd", battlePassWnd, closeBattlePassWnd, battlePassOpenCounter)
setSceneBg("battlePassWnd", "ui/images/bp_bg_01.avif")
