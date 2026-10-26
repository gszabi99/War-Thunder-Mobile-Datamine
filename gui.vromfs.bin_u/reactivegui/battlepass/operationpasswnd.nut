from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding, bpCardHeight
import "%rGui/battlePass/bpProgressBar.nut" as bpProgressBar
from "%rGui/battlePass/bpRewardDesc.nut" import bpObsoleteRewardDesc
import "%rGui/battlePass/buyOPLevelMsg.nut" as buyOPLevelMsg
import "%rGui/battlePass/operationPassRewardsList.nut" as operationPassRewardsList
from "%rGui/battlePass/operationPassState.nut" import isOPActive, openOPPurchaseWnd, selectedStage, curStage,
  getOPIcon, OP_VIP, OP_COMMON, OP_NONE, purchasedOP, operationPassGoods, pointsCurStage, pointsPerStage,
  receiveOPRewards, isOPRewardsInProgress, OPCampaign, opSeasonNumber, opSeasonEndTime, OPLevelPrice,
  isOPLevelPurchaseInProgress
from "%rGui/battlePass/passPkg.nut" import mkLevelProgressBlock, progressIconSize, contentH,
  mkRewardsPannable, mkPassIcon
from "%rGui/battlePass/passRewardsListComp.nut" import bgCard
from "%rGui/components/buttonStyles.nut" import PURCHASE, defButtonHeight, defButtonMinWidth
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/textButton.nut" import textButtonMultiline
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardPlateVip, getRewardPlateSize
from "%rGui/rewards/rewardViewInfo.nut" import isSingleViewInfoRewardEmpty
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/components/timerBlock.nut" import mkTimerBlock


const TIME_TO_HIDE_AD = 4
const HIDE_AD_TRIGGER = "hideOPLastReward"
const startAdPointX = hdpx(700)
const endAdPointX = hdpx(2000)
const moveAdDuration = 1
let scrollHandler = ScrollHandler()

let showedAdForCampaigns = mkWatched(persist, "showedAdForCampaigns", {})
let isShowedAdForOPCampaign = Computed(@() OPCampaign.get() in showedAdForCampaigns.get())

let saveShowedAdCampaign = @(camp) showedAdForCampaigns.mutate(@(v) v[camp] <- true)

opSeasonNumber.subscribe(@(_) showedAdForCampaigns.set({}))

function scrollToCardOP(scrollX, selProgress) {
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

function operationPassLastRewardAd(stagesList, recommendInfo) {
  if (stagesList == null || stagesList.len() == 0 || recommendInfo == null)
    return null

  let { scrollLastRewardX, lastRewardProgress } = recommendInfo
  let stageInfo = stagesList.findvalue(@(v) v.progress == lastRewardProgress) ?? stagesList.top()

  let { viewInfo, isVip = false, progress = 0 } = stageInfo
  let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  let stateFlags = Watched(0)
  let needHideLastRewardAd = Watched(false)

  let canHideAd = Computed(@() needHideLastRewardAd.get() && (stateFlags.get() & (S_ACTIVE | S_HOVER)) == 0)
  let isEmptyReward = Computed(@() viewInfo != null && isSingleViewInfoRewardEmpty(viewInfo, servProfile.get()))
  let startHideAnim = @(v) v ? anim_start(HIDE_AD_TRIGGER) : null

  let adContent = doubleSideGradient.__merge({
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    padding = const [hdpx(10), hdpx(30)]
    screenOffs = const [0, hdpx(25)]
    children = {
      size = [cardWidth, bpCardHeight]
      children = [
        {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = bgCard
        }
        {
          padding = bpCardPadding
          children = {
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = viewInfo == null ? { size = bpCardStyle.boxSize }
              : isVip ? mkRewardPlateVip(viewInfo, bpCardStyle)
              : mkRewardPlate(viewInfo, bpCardStyle)
          }
        }
      ]
    }
  })
  let adAnimations = [
    { prop = AnimProp.translate, from = [startAdPointX, 0], to = const [0, 0], delay = 0, duration = moveAdDuration, easing = InQuad,
      play = true, onFinish = @() resetTimeout(TIME_TO_HIDE_AD, @() needHideLastRewardAd.set(true)) }
    { prop = AnimProp.translate, from = const [0, 0], to = [endAdPointX, 0], duration = moveAdDuration, easing = OutQuad,
      onFinish = @() saveShowedAdCampaign(OPCampaign.get()), trigger = HIDE_AD_TRIGGER }
    { prop = AnimProp.translate, from = [endAdPointX, 0], to = [endAdPointX, 0], delay = moveAdDuration,
      duration = moveAdDuration, trigger = HIDE_AD_TRIGGER }
  ]

  return @() {
    watch = [isShowedAdForOPCampaign, isEmptyReward]
    key = canHideAd
    onAttach = @() canHideAd.subscribe(startHideAnim)
    onDetach = @() canHideAd.unsubscribe(startHideAnim)
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    function onClick() {
      needHideLastRewardAd.set(true)
      scrollToCardOP(scrollLastRewardX, progress)
    }
    children = isShowedAdForOPCampaign.get() || isEmptyReward.get() ? null
      : adContent
    transform = {}
    animations = adAnimations
  }
}

function rewardsList(stages, recommendInfo) {
  let barAndCards = [
    bpProgressBar(stages, curStage, pointsCurStage, pointsPerStage,
      OPLevelPrice, isOPLevelPurchaseInProgress, buyOPLevelMsg)
    operationPassRewardsList(stages)
  ]
  return @() {
    key = "opRewardsList"
    watch = serverConfigs
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    onAttach = @() scrollToCardOP(recommendInfo.get().scrollX, recommendInfo.get().selProgress)
    children = barAndCards
  }
}

let taskDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(300)
  text = loc("battlepass/tasksDesc")
}.__update(fontTinyAccentedShaded)

let opLevelLabel = @(text) { rendObj = ROBJ_TEXT, text }.__update(fontSmallShaded)

let levelProgressBlock = mkLevelProgressBlock(pointsCurStage, pointsPerStage)

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
    opLevelLabel($"{loc("mainmenu/rank")} {curStage.get()}")
    levelProgressBlock
    taskDesc
  ]
}

let leftMiddle = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  children = [
    mkTimerBlock(opSeasonEndTime)
    levelBlock
  ]
}

let openPurchOpButton = @(text) textButtonMultiline(utf8ToUpper(text), openOPPurchaseWnd,
  PURCHASE.__merge({ hotkeys = ["^J:Y"] }))

let noOPButton = { size = [FLEX, defButtonHeight] }

let rightMiddle = @() {
  watch = [purchasedOP, operationPassGoods]
  size = [defButtonMinWidth, FLEX]
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  gap = hdpx(35)
  children = [
    mkPassIcon([purchasedOP, OPCampaign, isOPActive],
      @() getOPIcon(purchasedOP.get(), OPCampaign.get()),
      @() isOPActive.get(),
      "ui/gameuiskin#bp_icon_not_active.avif")
    purchasedOP.get() == OP_COMMON && operationPassGoods.get()[OP_VIP] != null
        ? openPurchOpButton(loc("operationPass/upgrade"))
      : purchasedOP.get() == OP_NONE
        ? openPurchOpButton(loc("operationPass/btn_buy"))
      : purchasedOP.get() != OP_NONE
        ? {
            size = [FLEX, defButtonHeight]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = utf8ToUpper(loc("operationpass/active"))
          }.__update(fontTinyAccented)
      : noOPButton
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
          : bpObsoleteRewardDesc(stageData,
              const { lockText = "operationpass/lock", paidText = "operationpass/paid" },
              curStage,
              @() receiveOPRewards(stageData.progress),
              isOPRewardsInProgress)
      }
      rightMiddle
    ]
  }
}

function contentOP(stagesList, recommendInfo, isFullScreenWidth) {
  let progressIconSpacer = {
    key = "battle_pass_progress_bar" 
    size = [FLEX, progressIconSize[1]]
  }
  return @() {
    watch = stagesList
    size = FLEX
    onDetach = @() saveShowedAdCampaign(OPCampaign.get())
    children = {
      size = [FLEX, contentH]
      flow = FLOW_VERTICAL
      gap = hdpx(15)
      children = [
        middlePart(stagesList.get())
        {
          size = FLEX_H
          margin = const [0, 0, hdpx(30), 0]
          children = [
            progressIconSpacer
            mkRewardsPannable(rewardsList(stagesList.get(), recommendInfo),
              scrollHandler, isFullScreenWidth)
            operationPassLastRewardAd(stagesList.get(), recommendInfo.get())
            scrollArrowsBlock
          ]
        }
      ]
    }
    animations = wndSwitchAnim
  }
}

register_command(@() showedAdForCampaigns.set({}), "ui.debug.operationPass.resetBestRewardAd")

return {
  contentOP
  scrollToCardOP
}