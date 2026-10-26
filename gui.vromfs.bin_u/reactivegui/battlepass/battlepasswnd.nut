from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/screenMath.nut" import scaleArr
from "%sqstd/string.nut" import utf8ToUpper
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/pServerApi.nut" import receive_bp_reward, battlePassInProgress
from "%appGlobals/config/passPresentation.nut" import getGradePresentation
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_BP_PAGE, getRewardPlateSize
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardReceivedMark, mkRewardLocked, mkRewardUnitFlag,
  mkRewardBorder
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo
from "%rGui/battlePass/battlePassState.nut" import curBpPages, curBpGrade, curBpGoods, curBpCurPoints,
  curBpId, curBpTotalPoints, curBpEndTime, isPurchaseWndOpened
from "%rGui/battlePass/bpRewardDesc.nut" import bpRewardDesc, getLocByRType
from "%rGui/battlePass/passPkg.nut" import mkPassIcon, contentH, defPassIconSize
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/textButton.nut" import textButtonPurchase, textButtonPricePurchaseLow
from "%rGui/components/paginator.nut" import mkPaginatorCurPage
from "%rGui/components/timerBlock.nut" import mkTimerBlock
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, mkCurrencyImage
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/event/eventState.nut" import eventSeasonIdx
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase, showNoBalanceMsgAdd
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/style/gradients.nut" import simpleHorGrad


let wndKey = {}
let boardRatio = 1.125
let boardHeight = contentH.tointeger()
let boardWidth = (contentH / boardRatio).tointeger()
let iconSize = hdpxi(40)
let pagePadding = [boardHeight * 0.065, boardWidth * 0.15]

let selectedPage = Watched(0)
let selectedSlotIdx = Watched(0)

function mkSlotViewInfo(profileBpInfo, slot, slotIdx, page, pageIdx) {
  let { reqPoints } = page
  let { limit, cost, reqPassGrade } = slot
  let { totalPoints = 0, curPoints = 0, received = {}, grade = 0 } = profileBpInfo
  let isAboveLimit = limit != 0 && (received?[pageIdx][slotIdx] ?? 0) >= limit
  let hasReqPagePoints = totalPoints >= reqPoints
  let hasReqRewardPoints = curPoints >= cost
  let hasReqGrade = grade >= reqPassGrade
  let canReceive = !isAboveLimit && hasReqGrade && hasReqPagePoints && hasReqRewardPoints
  return {
    ...slot
    viewInfo = getRewardsViewInfo(slot.rewards)
    pageIdx
    slotIdx
    isReceived = isAboveLimit
    canReceive
    descLoc = isAboveLimit ? loc("battlepass/receivedRew")
      : canReceive ? loc("battlepass/receive")
      : !hasReqGrade ? loc(slot.reqPassGrade == 1 ? "battlepass/paid" : "battlepass/paid/vip")
      : loc("battlepass/lock/points", {
          battlePassPointsIcon = "<icon/>"
          value = !hasReqPagePoints ? reqPoints - totalPoints : cost - curPoints
        })
  }
}

let selectedReward = Computed(function() {
  let pageIdx = selectedPage.get()
  let slotIdx = selectedSlotIdx.get()
  let page = curBpPages.get()?[pageIdx]
  let slot = page?.slots[slotIdx]
  return slot == null ? null
    : mkSlotViewInfo(servProfile.get()?.battlePasses[curBpId.get()], slot, slotIdx, page, pageIdx)
})

let openPurchBpButton = @(text) textButtonPurchase(utf8ToUpper(text), @() isPurchaseWndOpened.set(true),
  { hotkeys = ["^J:Y"], ovr = { size = const [SIZE_TO_CONTENT, hdpxi(70)], minWidth = hdpxi(320) }})

let noBpButton = { size = [FLEX, defButtonHeight] }

let getSlotsInRow = @(width, style) max(2, (width + style.boxGap).tointeger() / (style.boxSize + style.boxGap))

let mkRewardFlag = @(reward, rStyle) @() {
  watch = serverConfigs
  children = mkRewardUnitFlag(serverConfigs.get()?.allUnits?[reward.id], rStyle)
}

let topLeftIconCtor = {
  [G_BLUEPRINT] = mkRewardFlag,
  [G_UNIT_UPGRADE] = mkRewardFlag,
  [G_UNIT] = mkRewardFlag,
}

function mkSlot(slot, rawReward, rStyle) {
  let reward = { ...slot, ...rawReward }
  let { isReceived, canReceive } = reward

  let lockedIcon = !canReceive && !isReceived ? mkRewardLocked(rStyle) : topLeftIconCtor?[rawReward.rType](reward, rStyle)
  let rewardReceivedMark = isReceived ? mkRewardReceivedMark(rStyle) : null
  let rewardPlate = mkRewardPlate(reward, rStyle)

  let isSelected = Computed(@() reward.pageIdx == selectedPage.get() && reward.slotIdx == selectedSlotIdx.get())
  return @() {
    watch = isSelected
    behavior = Behaviors.Button
    key = {}
    function onClick() {
      selectedPage.set(reward.pageIdx)
      selectedSlotIdx.set(reward.slotIdx)
    }
    children = [
      rewardPlate
      lockedIcon
      rewardReceivedMark
      isSelected.get() ? mkRewardBorder : null
    ]
  }
}

let mkIndicatorCtor = @(rewardPlateSize) @(page, setPage) {
  size = FLEX_V
  flow = FLOW_VERTICAL
  gap = { size = FLEX }
  padding = [0, 0, hdpx(4), 0]
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      valign = ALIGN_BOTTOM
      vplace = ALIGN_BOTTOM
      text = loc("mainmenu/page", { page = page + 1 })
    }.__update(fontTinyAccented)
    @() {
      watch = curBpPages
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      valign = ALIGN_BOTTOM
      children = array(curBpPages.get().len()).map(@(_, i) {
        size = [0.5 * rewardPlateSize[0], i == page ? hdpx(16) : hdpx(10)]
        rendObj = ROBJ_SOLID
        behavior = Behaviors.Button
        color = i == page ? 0xFFFFFFFF : 0xB0000000
        onClick = @() setPage(i)
        sound = { click = "click" }
      })
    }
  ]
}

function getRows(pages, page, width, style) {
  let slotsInRow = getSlotsInRow(width, style)
  let rows = []
  let { slots = [] } = pages[page]
  local slotsLeft = 0
  foreach (_, slot in slots) {
    let viewInfo = getRewardsViewInfo(slot.rewards)
    foreach (reward in viewInfo) {
      if (reward.slots > slotsLeft) {
        rows.append([])
        slotsLeft = slotsInRow
      }
      slotsLeft -= reward.slots
      rows.top().append(mkSlot(slot, reward, style))
    }
  }
  return rows
}

function pageContent(style) {
  let rewardPlateSize = getRewardPlateSize(1, style)
  let blockWidth = min(boardWidth, rewardPlateSize[0] * 4 + style.boxGap * 3)

  let curBpPagesViewInfo = Computed(function() {
    let bpId = curBpId.get()
    let profileBpInfo = servProfile.get()?.battlePasses[bpId]
    return curBpPages.get().map(@(p, pIdx) {
      ...p,
      slots = p.slots.map(@(s, sIdx) mkSlotViewInfo(profileBpInfo, s, sIdx, p, pIdx))
    })
  })

  return {
    size = FLEX
    halign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      {
        size = [blockWidth, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = style.boxGap
        children = [
          mkTimerBlock(curBpEndTime, {}, { rendObj = null })
          @() {
            watch = [curBpPagesViewInfo, selectedPage]
            flow = FLOW_VERTICAL
            gap = style.boxGap
            children = getRows(curBpPagesViewInfo.get(), selectedPage.get(), blockWidth, style).map(@(children) {
              flow = FLOW_HORIZONTAL
              gap = style.boxGap
              children
            })
          }
        ]
      }
      {
        flow = FLOW_VERTICAL
        vplace = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        gap = hdpx(8)
        children = [
          function() {
            let pointsDifference = curBpPages.get()[selectedPage.get()].reqPoints - curBpTotalPoints.get()
            return {
              watch = [curBpPages, selectedPage, curBpTotalPoints, curBpId]
              children = pointsDifference <= 0 ? null
                : {
                    size = [boardWidth, SIZE_TO_CONTENT]
                    halign = ALIGN_CENTER
                    padding = hdpx(12)
                    rendObj = ROBJ_BOX
                    fillColor = 0x26000000
                    children = {
                      rendObj = ROBJ_TEXTAREA
                      behavior = Behaviors.TextArea

                      embed = {
                        icon = mkCurrencyImage(curBpId.get(),
                          get_font_metrics(fontTinyAccented.font, fontTinyAccented.fontSize).ascent * 0.75,
                          { imageValign = ALIGN_BOTTOM })
                      }
                      text = loc("battlepass/lock/points", { battlePassPointsIcon = "<icon/>", value = pointsDifference })
                    }.__update(fontTinyAccented)
                  }
            }
          }
          mkPaginatorCurPage(selectedPage, Computed(@() curBpPages.get().len() - 1), {}, evenPx(70),
            mkIndicatorCtor(rewardPlateSize))
        ]
      }
    ]
  }
}

let mkLockLayer = @() {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x80000000
  valign = ALIGN_CENTER
  padding = hdpx(12)
  children = {
    size = iconSize
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/gameuiskin#lock_icon.svg:{iconSize}:P")
  }
}

function findRewardToOpen(pages, totalPoints, curPoints, grade) {
  for (local pageIdx = pages.len() - 1; pageIdx >= 0; pageIdx--) {
    let page = pages[pageIdx]
    if (page.reqPoints > totalPoints)
      continue
    for (local slotIdx = page.slots.len() - 1; slotIdx >= 0; slotIdx--) {
      let slot = page.slots[slotIdx]
      if (curPoints >= slot.cost && grade >= slot.reqPassGrade)
        return { slotIdx, pageIdx }
    }
  }
  return { slotIdx = 0, pageIdx = 0 }
}

let battlePassContent = @() {
  watch = curBpId
  key = wndKey
  size = FLEX
  halign = ALIGN_CENTER
  function onAttach() {
    let { slotIdx, pageIdx } = findRewardToOpen(curBpPages.get(), curBpTotalPoints.get(), curBpCurPoints.get(), curBpGrade.get())
    selectedPage.set(pageIdx)
    selectedSlotIdx.set(slotIdx)
  }
  children = curBpId.get() == null ? null
    : {
        size = FLEX
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = hdpx(24)
        children = [
          {
            size = [boardWidth, boardHeight]
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/images/event_s39_board.avif:{boardWidth}:{boardHeight}:P")
            padding = pagePadding
            children = pageContent(REWARD_STYLE_BP_PAGE)
          }
          @() {
            watch = [selectedReward, curBpId]
            size = [FLEX, boardHeight - hdpx(64)]
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            flow = FLOW_VERTICAL
            gap = hdpx(40)
            children = selectedReward.get() == null ? null
              : [
                  bpRewardDesc(selectedReward.get(), curBpId.get())
                  mkSpinnerHideBlock(battlePassInProgress,
                    {
                      size = const [SIZE_TO_CONTENT, hdpxi(90)]
                      minWidth = hdpxi(320)
                      children = [
                        textButtonPricePurchaseLow(utf8ToUpper(loc("mainmenu/btnClaim")),
                          mkCurrencyComp(selectedReward.get().cost, curBpId.get()).__update({ margin = [0, 0, 0, hdpx(32)] })
                          @() selectedReward.get().isReceived ? null
                                : selectedReward.get().canReceive && selectedReward.get().cost == 0
                                  ? receive_bp_reward(curBpId.get(), selectedReward.get().pageIdx,
                                      selectedReward.get().slotIdx, selectedReward.get().cost)
                                : curBpGrade.get() < selectedReward.get().reqPassGrade
                                  ? isPurchaseWndOpened.set(true)
                                : curBpPages.get()[selectedReward.get().pageIdx].reqPoints - curBpTotalPoints.get() > 0
                                  ? showNoBalanceMsgAdd(selectedReward.get().cost,
                                      curBpPages.get()[selectedReward.get().pageIdx].reqPoints
                                        - curBpTotalPoints.get(), curBpId.get(), null)
                                : openMsgBoxPurchase({
                                    text = loc("shop/needMoneyQuestion",
                                      { item = colorize(userlogTextColor,
                                          getLocByRType(selectedReward.get().viewInfo[0].rType,
                                            selectedReward.get().viewInfo[0].id))}),
                                    price = {
                                      price = selectedReward.get().cost
                                      currencyId = curBpId.get()
                                    },
                                    purchase = @() receive_bp_reward(curBpId.get(), selectedReward.get().pageIdx,
                                      selectedReward.get().slotIdx, selectedReward.get().cost)
                                    bqInfo = null
                                  })
                          {
                            ovr = {
                              size = FLEX,
                              minWidth = hdpxi(320)
                            }.__update(!selectedReward.get().canReceive ? { transform = null } : {})
                          })
                        selectedReward.get().canReceive ? null : mkLockLayer()
                      ]
                    })
                ]
          }
          function() {
            let curGrade = curBpGrade.get()
            let curId = curBpId.get()
            local hasBoughtAny = false
            local hasAnyAvailableToBuy = false
            foreach (g in curBpGoods.get()) {
              if (hasBoughtAny && hasAnyAvailableToBuy)
                break
              foreach (r in g.requirements) {
                if (r.id == curId) {
                  if (curGrade > r.valueInt)
                    hasBoughtAny = true
                  if (curGrade == r.valueInt)
                    hasAnyAvailableToBuy = true
                }
              }
            }
            return {
              watch = [curBpGoods, curBpId, curBpGrade]
              size = FLEX_V
              rendObj = ROBJ_IMAGE
              image = simpleHorGrad
              color = 0x80000000
              padding = [contentH * 0.05, saBordersRv[1], 0, 0]
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              valign = ALIGN_TOP
              gap = hdpx(20)
              children = [
                mkPassIcon([curBpGrade, curBpId, eventSeasonIdx],
                  @() getGradePresentation(curBpId.get(), curBpGrade.get()).icon(eventSeasonIdx.get())
                  @() curBpGrade.get() > 0,
                  "ui/gameuiskin#bp_icon_not_active.avif",
                  scaleArr(defPassIconSize, 0.8))
                hasBoughtAny && hasAnyAvailableToBuy
                    ? openPurchBpButton(loc("battlePass/upgrade/short"))
                  : hasAnyAvailableToBuy
                    ? openPurchBpButton(loc("battlePass/btn_buy/short"))
                  : hasBoughtAny
                    ? {
                        size = [FLEX, defButtonHeight]
                        halign = ALIGN_CENTER
                        valign = ALIGN_BOTTOM
                        rendObj = ROBJ_TEXTAREA
                        behavior = Behaviors.TextArea
                        text = utf8ToUpper(loc("battlepass/active"))
                      }.__update(fontTinyAccented)
                  : noBpButton
              ]
            }
          }
        ]
      }
  animations = wndSwitchAnim
}

curBpId.subscribe(function(_) {
  let { slotIdx, pageIdx } = findRewardToOpen(curBpPages.get(), curBpTotalPoints.get(), curBpCurPoints.get(), curBpGrade.get())
  selectedPage.set(pageIdx)
  selectedSlotIdx.set(slotIdx)
})
selectedPage.subscribe(@(_) selectedSlotIdx.set(0))

return {
  battlePassContent
}