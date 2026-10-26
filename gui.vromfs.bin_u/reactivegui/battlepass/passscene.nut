from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import isEqual
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%appGlobals/config/passPresentation.nut" import getOPPresentation
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding, bpCardMargin
from "%rGui/battlePass/operationPassState.nut" import OPCampaign
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/rewards/rewardStyles.nut" import getRewardPlateSize
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideY, gradTexSize, simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor
from "battlePassObsoleteWnd.nut" import contentBP, scrollToCardBP
from "eventPassWnd.nut" import contentEP, scrollToCardEP
from "operationPassWnd.nut" import contentOP, scrollToCardOP
from "passPkg.nut" import sideTabWidth, vGradientGapSize, tabSize, tabIconSize
from "passState.nut" import passPageId, playerSelectedScene, passPageIdx, BATTLE_PASS, EVENT_PASS, OPERATION_PASS,
  visibleTabs, seenPasses, isPassGoodsUnseen, getTabStateData


let lineGradientVert = mkBitmapPictureLazy(4, gradTexSize, mkGradientCtorDoubleSideY(0, 0x80000000, 0.07))

let tabs = {
  [BATTLE_PASS] = {
    scrollToCard = scrollToCardBP
    content = contentBP
    icon = @(_) "ui/gameuiskin#icon_bp.svg"
  },
  [EVENT_PASS] = {
    scrollToCard = scrollToCardEP
    content = contentEP
    icon = @(_) "ui/gameuiskin#event_pass_icon.svg"
  },
  [OPERATION_PASS] = {
    scrollToCard = scrollToCardOP
    content = contentOP
    icon = @(camp) getOPPresentation(camp).iconTab
  },
}

let getTabData = @(passName) passName == null ? null
  : passName.startswith(EVENT_PASS) ? tabs[EVENT_PASS]
  : tabs?[passName]

function mkTab(idx, name, campaign) {
  let dataState = getTabStateData(name)
  let { hasReward = null, mkHasReward = null, goods = null, mkGoods = null } = dataState
  let isActive = Computed(@() passPageIdx.get() == idx)

  let hasAnyReward = hasReward ?? mkHasReward?(Watched(name)) ?? Watched(false)
  let tabGoods = goods ?? mkGoods?(name) ?? Watched(null)
  let isUnseen = Computed(@() isPassGoodsUnseen(tabGoods.get(), seenPasses.get()))
  let tabIcon = {
    size = tabIconSize
    rendObj = ROBJ_IMAGE
    image = Picture($"{getTabData(name).icon(campaign)}:{tabIconSize}:{tabIconSize}:P")
    keepAspect = true
  }
  let unseenMark = priorityUnseenMark.__merge({ pos = [-0.35 * tabSize[0], -0.25 * tabSize[1]] })
  return @() {
    watch = [isActive, hasAnyReward, isUnseen]
    size = tabSize
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    color = isActive.get() ? selectColor : 0xFF000000
    flipX = true
    behavior = Behaviors.Button
    onClick = @() playerSelectedScene.set(name)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      tabIcon
      isActive.get() || (!hasAnyReward.get() && !isUnseen.get()) ? null
        : unseenMark
    ]
  }
}

let mkTabContent = @(isFullScreenWidth) function () {
  let data = getTabData(passPageId.get())
  let dataState = getTabStateData(passPageId.get())
  if (!data || !dataState)
    return { watch = passPageId }

  let { content, scrollToCard } = data
  let { mkStagesList, isVipActive, isCommonActive, lastRewardProgress } = dataState
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
        if (s.canReceive
            || (!s.isReceived && (!s.isPaid
              || (!s?.isVip && isCommonActive.get())
              || (s?.isVip && isVipActive.get())
              || s?.canBuyLevel))) {
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
  let scrollToRecommended = @(v) !v ? null : scrollToCard(v.scrollX, v.selProgress)

  return {
    watch = passPageId
    size = flex()
    padding = isFullScreenWidth ? [0, saBorders[0]] : [0, saBorders[0], 0, 0]
    children = {
      key = recommendInfo
      size = FLEX
      onAttach = @() recommendInfo.subscribe(scrollToRecommended)
      onDetach = @() recommendInfo.unsubscribe(scrollToRecommended)
      children = content(stagesList, recommendInfo, isFullScreenWidth)
    }
  }
}

let wndKey = {}
let visibleTabsCount = Computed(@() visibleTabs.get().len())
let tabsGap = {
  size = vGradientGapSize
  rendObj = ROBJ_SOLID
  color = 0xFFACACAC
}

function passSceneWnd() {
  if (visibleTabsCount.get() == 0 )
    return { watch = visibleTabsCount }

  let vertGradient = lineGradientVert()
  return {
    watch = visibleTabsCount
    key = wndKey
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = tabsGap
    children = [
      visibleTabsCount.get() <= 1 ? null
        : @() {
            watch = [visibleTabs, OPCampaign]
            size = [sideTabWidth, sh(100)]
            rendObj = ROBJ_IMAGE
            image = vertGradient
            flow = FLOW_VERTICAL
            halign = ALIGN_RIGHT
            gap = hdpx(10)
            children = visibleTabs.get().map(@(v, idx) mkTab(idx, v, OPCampaign.get()))
          }
      mkTabContent(visibleTabsCount.get() <= 1)
    ]
    animations = wndSwitchAnim
  }
}

return {
  passSceneWnd
}
