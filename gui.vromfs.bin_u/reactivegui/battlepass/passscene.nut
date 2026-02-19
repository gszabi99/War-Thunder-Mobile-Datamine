from "%globalsDarg/darg_library.nut" import *
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { getOPPresentation, getBPPresentation, getEpPresentation } = require("%appGlobals/config/passPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bpCardStyle, bpCardPadding, bpCardMargin } = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { passOpenCounter, closePassScene, passPageId, playerSelectedScene, passPageIdx
  BATTLE_PASS, EVENT_PASS, OPERATION_PASS, visibleTabs, seenPasses, markPassesSeen, isPassGoodsUnseen } = require("passState.nut")
let { mkBpStagesList, isBpVipActive, isBpCommonActive, hasBpRewardsToReceive, battlePassGoods, lastStageBpProgress, seasonNumber
} = require("%rGui/battlePass/battlePassState.nut")
let { mkEpStagesList, isEpVipActive, isEpCommonActive, eventBgImage, hasEpRewardsToReceive, eventPassGoods, lastStageEpProgress, curEventId
} = require("%rGui/battlePass/eventPassState.nut")
let { mkOPStagesList, isOpVipActive, isOpCommonActive, OPCampaign, hasOPRewardsToReceive, operationPassGoods, lastStageOpProgress
} = require("%rGui/battlePass/operationPassState.nut")
let { contentBP, scrollToCardBP } = require("battlePassWnd.nut")
let { contentEP, scrollToCardEP } = require("eventPassWnd.nut")
let { contentOP, scrollToCardOP } = require("operationPassWnd.nut")
let { sideTabWidth, vGradientGapSize, tabSize, tabIconSize, sideTabPadding } = require("battlePassPkg.nut")

let sceneBg = keepref(Computed(function() {
  let id = passPageId.get()
  if (id == BATTLE_PASS)
    return { bg = "ui/images/bp_bg_01.avif", bgColor = getBPPresentation(seasonNumber.get()).bgColor }
  if (id != null && id.startswith(EVENT_PASS))
    return { bg = eventBgImage.get(), bgColor = getEpPresentation(curEventId.get()).bgColor }
  let { bg, bgColor } = getOPPresentation(OPCampaign.get())
  return { bg, bgColor }
}))

let tabs = {
  [BATTLE_PASS] = {
    mkStagesList = mkBpStagesList
    lastRewardProgress = lastStageBpProgress
    isVipActive = isBpVipActive
    isCommonActive = isBpCommonActive
    hasReward = hasBpRewardsToReceive
    goods = battlePassGoods
    scrollToCard = scrollToCardBP
    content = contentBP
    icon = @(_) "ui/gameuiskin#icon_bp.svg"
  },
  [EVENT_PASS] = {
    mkStagesList = mkEpStagesList
    lastRewardProgress = lastStageEpProgress
    isVipActive = isEpVipActive
    isCommonActive = isEpCommonActive
    hasReward = hasEpRewardsToReceive
    goods = eventPassGoods
    scrollToCard = scrollToCardEP
    content = contentEP
    icon = @(_) "ui/gameuiskin#event_pass_icon.svg"
  },
  [OPERATION_PASS] = {
    mkStagesList = mkOPStagesList
    lastRewardProgress = lastStageOpProgress
    isVipActive = isOpVipActive
    isCommonActive = isOpCommonActive
    hasReward = hasOPRewardsToReceive
    goods = operationPassGoods
    scrollToCard = scrollToCardOP
    content = contentOP
    icon = @(camp) getOPPresentation(camp).iconTab
  },
}

let getTabData = @(passName) passName == null ? null
  : passName.startswith(EVENT_PASS) ? tabs[EVENT_PASS]
  : tabs?[passName]

passPageId.subscribe(function(v) {
  let { goods = null } = getTabData(v)
  if (goods != null)
    markPassesSeen(goods.get().reduce(@(res, g) g?.id ? res.append(g.id) : res, []))
})

function mkTab(idx, name, campaign) {
  let data = getTabData(name)
  let icon = data.icon(campaign)
  let { hasReward, goods } = data
  let isActive = Computed(@() passPageIdx.get() == idx)
  let isUnseen = Computed(@() isPassGoodsUnseen(goods.get(), seenPasses.get()))
  return @() {
    watch = [isActive, hasReward, isUnseen]
    size = tabSize
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    flipX = true
    behavior = Behaviors.Button
    onClick = @() playerSelectedScene.set(name)
    color = isActive.get() ? selectColor : 0xFF000000
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        size = tabIconSize
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon}:{tabIconSize}:{tabIconSize}:P")
        keepAspect = true
      }
      isActive.get() || (!hasReward.get() && !isUnseen.get()) ? null
        : priorityUnseenMark.__merge({ pos = [-0.35 * tabSize[0], -0.25 * tabSize[1]] })
    ]
  }
}

let wndKey = {}

function wnd() {
  if (visibleTabs.get().len == 0 )
    return { watch = [passPageId, visibleTabs] }

  let data = getTabData(passPageId.get())
  if (!data)
    return {
      watch = [passPageId, visibleTabs]
      padding = saBordersRv
      children = backButton(closePassScene)
    }

  let { mkStagesList, scrollToCard, content, isVipActive, isCommonActive, lastRewardProgress } = data
  let stagesList = mkStagesList()
  let recommendInfo = Computed(function(prev) {
    local scrollX = -bpCardMargin
    local selProgress = 0
    local scrollLastRewardX = 0
    local isFound = false

    foreach(s in stagesList.get()) {
      let rewardPlateW = getRewardPlateSize(s.viewInfo?.slots ?? 1, bpCardStyle)[0]
      let fullStep = bpCardMargin + 2 * bpCardPadding[1] + rewardPlateW

      if (s.progress <= lastRewardProgress.get())
        scrollLastRewardX += fullStep

      if (!isFound) {
        if (s.canReceive || (!s.isReceived && (!s.isPaid || (!s?.isVip && isCommonActive.get()) || (s?.isVip && isVipActive.get())))) {
          scrollX += bpCardMargin + bpCardPadding[1] + rewardPlateW / 2
          selProgress = s.progress
          isFound = true
        } else {
          scrollX += fullStep
          selProgress = s.progress
        }
      }
    }

    let res = { scrollX, scrollLastRewardX, lastRewardProgress = lastRewardProgress.get(), selProgress }
    return isEqual(prev, res) ? prev : res
  })
  recommendInfo.subscribe(@(v) !v ? null : scrollToCard(v.scrollX, v.selProgress))

  return {
    watch = [passPageId, visibleTabs]
    key = wndKey
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = {
      size = vGradientGapSize
      rendObj = ROBJ_SOLID
      color = 0xFFACACAC
    }
    children = [
      {
        padding = sideTabPadding
        size = [sideTabWidth, sh(100)]
        rendObj = ROBJ_SOLID
        color = 0x80000000
        flow = FLOW_VERTICAL
        gap = hdpx(60)
        children = [
          backButton(closePassScene)
          @() {
            watch = [visibleTabs, OPCampaign]
            flow = FLOW_VERTICAL
            hplace = ALIGN_RIGHT
            gap = hdpx(10)
            children = visibleTabs.get().map(@(v, idx) mkTab(idx, v, OPCampaign.get()))
          }
        ]
      }
      content(stagesList, recommendInfo)
    ]
    animations = wndSwitchAnim
  }
}
registerScene("passScene", wnd, closePassScene, passOpenCounter)

setSceneBg("passScene", sceneBg.get()?.bg, sceneBg.get()?.bgColor)
sceneBg.subscribe(@(v) setSceneBg("passScene", v?.bg, v?.bgColor))