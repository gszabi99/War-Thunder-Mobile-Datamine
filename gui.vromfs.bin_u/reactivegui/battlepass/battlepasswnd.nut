from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { register_command } = require("console")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { battlePassOpenCounter, openBattlePassWnd, closeBattlePassWnd, isBpSeasonActive, isBpActive,
  mkBpStagesList, openBPPurchaseWnd, selectedStage, curStage, maxStage, bpIconActive
} = require("battlePassState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { mkBtnOpenTabQuests } = require("%rGui/quests/btnOpenQuests.nut")
let { textButtonMultiline } = require("%rGui/components/textButton.nut")
let { PURCHASE, defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let battlePassSeason = require("battlePassSeason.nut")
let { bpCurProgressbar, bpProgressText } = require("battlePassPkg.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let bpProgressBar = require("bpProgressBar.nut")
let battlePassRewardsList = require("battlePassRewardsList.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
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
      size = [flex(), SIZE_TO_CONTENT]
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
  size = [flex(),hdpx(363)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    mkScrollArrow(scrollHandler, MR_L)
    mkScrollArrow(scrollHandler, MR_R)
  ]
}

let rewardsList = @(stages) function() {
  let rewardsStages = []
  foreach (idx, s in stages) {
    let rewInfo = []
    foreach(key, count in s.rewards) {
      let reward = serverConfigs.get().userstatRewards?[key]
      rewInfo.extend(getRewardsViewInfo(reward, count))
    }
    let viewInfo = rewInfo.sort(sortRewardsViewInfo)?[0]
    rewardsStages.append(s.__merge({
      viewInfo
      nextSlots = 0
    }))
    if (idx > 0)
      rewardsStages[idx - 1].nextSlots = viewInfo?.slots ?? 1
  }
  return {
    key = "bpRewardsList"
    watch = serverConfigs
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    function onAttach() {
      local scrollX = -bpCardMargin
      local selProgress = null
      foreach(s in rewardsStages) {
        if (s.canReceive
            || (!s.isReceived && (!s.isPaid || isBpActive.value))) {
          selProgress = s.progress
          scrollX += bpCardMargin + bpCardPadding[1]
            + getRewardPlateSize(s.viewInfo?.slots ?? 1, bpCardStyle)[0] / 2
          break
        }
        scrollX += bpCardMargin + 2 * bpCardPadding[1]
          + getRewardPlateSize(s.viewInfo?.slots ?? 1, bpCardStyle)[0]
      }
      selectedStage(selProgress ?? rewardsStages?[rewardsStages.len() - 1].progress ?? 0)
      if (scrollX > saSize[0] / 2)
        scrollHandler.scrollToX(scrollX - saSize[0] / 2)
    }
    children = [
      bpProgressBar(rewardsStages)
      battlePassRewardsList(rewardsStages)
    ]
  }
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccented)

let bpLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmall)

let levelBlock = @() {
  watch = [curStage, maxStage]
  vplace = ALIGN_TOP
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  children = curStage.get() >= maxStage.get() ? bpLevelLabel(loc("battlepass/maxLevel"))
    : [
        bpLevelLabel($"{loc("mainmenu/rank")} {curStage.get()}")
        {
          size = [hdpx(300), SIZE_TO_CONTENT]
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
  size = [SIZE_TO_CONTENT, flex()]
  padding = [hdpx(10), 0, hdpx(20), 0]
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
          size = [hdpx(109), hdpx(109)]
        })
      ]
    }
  ]
}

let rightMiddle = @() {
  watch = isBpActive
  size = [defButtonMinWidth, flex()]
  padding = [hdpx(10), 0, hdpx(20), 0]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    @() {
      watch = bpIconActive
      size = bpIconSize
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = isBpActive.value
        ? Picture($"{bpIconActive.get()}:{bpIconSize[0]}:{bpIconSize[1]}:P")
        : Picture($"ui/gameuiskin#bp_icon_not_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
      fallbackImage = Picture($"ui/gameuiskin#bp_icon_not_active.avif:{bpIconSize[0]}:{bpIconSize[1]}:P")
      opacity = isBpActive.value ? 1 : 0.5
    }
    isBpActive.get()
      ? {
          size = [flex(), defButtonHeight]
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = utf8ToUpper(loc("battlepass/active"))
        }.__update(fontTinyAccented)
      : textButtonMultiline(utf8ToUpper(loc("battlePass/btn_buy")), openBPPurchaseWnd, PURCHASE.__merge({ hotkeys = ["^J:Y"] }))
  ]
}

let middlePart = @(stagesList) @(){
  watch = selectedStage
  size = flex()
  flow = FLOW_HORIZONTAL
  children = [
    leftMiddle
    {
      size = flex()
      children = selectedStage.value not in stagesList ? null
        : bpRewardDesc(stagesList[selectedStage.value])
    }
    rightMiddle
  ]
}

let content = @(stagesList) @() {
  watch = stagesList
  size = flex()
  flow = FLOW_VERTICAL
  gap = hdpx(15)
  children = [
    middlePart(stagesList.get())
    {
      size = [sw(100), SIZE_TO_CONTENT]
      hplace = ALIGN_CENTER
      children = [
        rewardPannable(rewardsList(stagesList.get()),
          { pos = [0, 0], size = [flex(), SIZE_TO_CONTENT], clipChilden = false },
          {
            size = [flex(), SIZE_TO_CONTENT]
            behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ],
            scrollHandler = scrollHandler
          })
        scrollArrowsBlock
      ]
    }
  ]
}

let wndKey = {}
let battlePassWnd = @() {
  key = wndKey
  size = flex()
  padding = saBordersRv
  gap = hdpx(10)
  flow = FLOW_VERTICAL
  children = [
    header
    content(mkBpStagesList())
  ]
  animations = wndSwitchAnim
}

register_command(openBattlePassWnd, "ui.battle_pass_open")
register_command(closeBattlePassWnd, "ui.battle_pass_close")

registerScene("battlePassWnd", battlePassWnd, closeBattlePassWnd, battlePassOpenCounter)
setSceneBg("battlePassWnd", "ui/images/bp_bg_01.avif")
