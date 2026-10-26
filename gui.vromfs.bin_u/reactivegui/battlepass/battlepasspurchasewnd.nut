from "%globalsDarg/darg_library.nut" import *
from "math" import ceil
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/currenciesState.nut" import PLATINUM
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%appGlobals/config/passPresentation.nut" import getGradePresentation
from "%appGlobals/rewardType.nut" import G_BP_POINTS
import "%rGui/battlePass/battlePassSeason.nut" as battlePassSeason
from "%rGui/battlePass/battlePassState.nut" import curBpId, curBpGoods, curBpGrade, curBpTotalPoints, curBpPages,
  curBpEndTime, curBpCurPoints, getGradeToClaimByGoods, isPurchaseWndOpened, sendBpBqEvent
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow, scrollArrowImageSmall
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPricePurchase, buttonStyles, mergeStyles, mkCustomButton
from "%rGui/event/eventState.nut" import eventSeasonIdx
from "%rGui/event/eventLocName.nut" import curEventLoc
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardPlateVip
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, shopGoodsToRewardsViewInfo, joinViewInfo,
  sortRewardsViewInfo, isSingleViewInfoRewardEmpty
from "%rGui/seasonScene/seasonSceneState.nut" import bgScene
from "%rGui/shop/purchaseGoods.nut" import purchaseGoods, purchaseGoodsSeq
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/unlocks/userstat.nut" import registerUnlocksSceneToUpdate


let { defButtonHeight, PRIMARY } = buttonStyles

let { boxSize, boxGap } = bpCardStyle
let rewardsListGap = 1.5 * boxGap
const bpIconSize = hdpxi(400)
let blocksGap = isWidescreen ? 3 * boxGap : boxGap

const rightBlockWidth = 1.5 * bpIconSize
let rewardSlotsInRow = (saSize[0] - rightBlockWidth - blocksGap + boxGap) / (boxSize + boxGap)
const swIconSz = hdpx(70)

const contentGap = hdpx(25)
let wndContentHeight = saSize[1] - gamercardHeight - contentGap
let contentGradientSize = [contentGap, saBorders[1]]

let playerSelectedGrade = mkWatched(persist, "playerSelectedGrade", 0)

let currenciesBtns = mkCurrenciesBtns(const [PLATINUM])

let header = @() {
  watch = [curEventLoc, curBpEndTime]
  size = [FLEX, gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    backButton(@() isPurchaseWndOpened.set(false))
    battlePassSeason(curEventLoc.get(), curBpEndTime.get())
    const { size = FLEX }
    currenciesBtns
  ]
}

let mkRewardInstant = @(vInfo) (vInfo?.isVip ? mkRewardPlateVip : mkRewardPlate)(vInfo, bpCardStyle)

function rewardsBlock(text, viewInfo) {
  if (viewInfo.len() == 0)
    return null

  let totalSlots = viewInfo.reduce(@(res, v) res + v.slots, 0)
  let totalRows = max(1, ceil(totalSlots.tofloat() / rewardSlotsInRow).tointeger())
  let slotsPerRow = ceil(totalSlots.tofloat() / totalRows).tointeger()

  let byRows = array(totalRows).map(@(_) { slotsLeft = slotsPerRow, list = [] })
  foreach(v in viewInfo)
    foreach(idx, row in byRows)
      if (idx >= totalRows - 1 || row.slotsLeft >= v.slots) {
        row.slotsLeft -= v.slots
        row.list.append(v)
        break
      }

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = boxGap
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = $"{text}{colon}"
      }.__update(fontSmallAccented)
    ]
      .extend(byRows.map(@(row) {
        flow = FLOW_HORIZONTAL
        gap = boxGap
        children = row.list.map(mkRewardInstant)
      }))
  }
}

function rewardsToViewInfo(allSlots) {
  let res = []
  foreach(slot in allSlots) {
    let viewInfo = getRewardsViewInfo(slot.rewards)
    joinViewInfo(res, viewInfo)
  }
  return res
}

let rewardsList = @(selBpInfo) function() {
  let { points = 0, grade = 0, goods = null } = selBpInfo.get()

  let rewardsOnPurchase = []
  let rewardsAddPoints = []
  let { received = {} } = servProfile.get()?.battlePasses?[curBpId.get()]
  local potentialSpent = 0

  for (local pIdx = curBpPages.get().len() - 1; pIdx >= 0; pIdx--) {
    let p = curBpPages.get()[pIdx]
    for (local sIdx = p.slots.len() - 1; sIdx >= 0; sIdx--) {
      let s = p.slots[sIdx]
      let isReceived = s.limit != 0 && (received?[pIdx][sIdx] ?? 0) >= s.limit
      if (s.reqPassGrade > (grade ?? 0) || isReceived)
        continue

      let potentialLeft = curBpCurPoints.get() - potentialSpent
      if (p.reqPoints <= curBpTotalPoints.get() && s.cost <= potentialLeft) {
        potentialSpent += s.cost
        rewardsOnPurchase.append(s)
      }
      else if (p.reqPoints <= points + curBpTotalPoints.get() && s.cost <= potentialLeft + points && points > 0) {
        potentialSpent += s.cost
        rewardsAddPoints.append(s)
      }
    }
  }

  let profile = servProfile.get()
  let viewInfoOnPurchase = rewardsToViewInfo(rewardsOnPurchase)
    .filter(@(v) !isSingleViewInfoRewardEmpty(v, profile))
    .sort(sortRewardsViewInfo)
  let viewInfoAddPoints = rewardsToViewInfo(rewardsAddPoints)
    .filter(@(v) !isSingleViewInfoRewardEmpty(v, profile))
    .sort(sortRewardsViewInfo)

  local viewInfoExclusive = []
  if (goods != null) {
    viewInfoExclusive = shopGoodsToRewardsViewInfo(goods)
      .filter(@(v) !isSingleViewInfoRewardEmpty(v, profile))
      .sort(sortRewardsViewInfo)
    if (getGradePresentation(curBpId.get(), grade)?.isVip)
      viewInfoExclusive.each(@(v) v.$rawset("isVip", true))
  }

  return {
    watch = [curBpPages, curBpId, curBpCurPoints, selBpInfo, servProfile, curBpTotalPoints]
    size = FLEX_H
    children = {
      key = grade
      size = FLEX_H
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = rewardsListGap
      children = [
        rewardsBlock(loc("battlePass/receiveOnPurchase/exclusive", { count = viewInfoExclusive.len() }), viewInfoExclusive)
        rewardsBlock(loc("battlePass/claimOnPurchase"), viewInfoOnPurchase)
        rewardsBlock(loc("battlepass/pointsBonus", { num = points }), viewInfoAddPoints)
      ].filter(@(v) v != null)
      animations = wndSwitchAnim
    }
  }
}

let onSelectBp = @(list, cur)
  playerSelectedGrade.set(list.len() == 0 ? null : list[((list.indexof(cur) ?? -1) + 1) % list.len()]?.grade)

function battlePassIcon(bpList, selBpInfo) {
  let iconTransitions = [
    { prop = AnimProp.color, duration = 0.3, easing = InOutQuad }
    { prop = AnimProp.scale, duration = 0.3, easing = InOutQuad }
  ]
  return function() {
    let children = []
    foreach (idx, bp in bpList.get()) {
      let isCurrent = bp == selBpInfo.get()
      let child = {
        key = bp.grade
        size = const [bpIconSize, bpIconSize]
        pos = [idx * bpIconSize * 0.5, 0]
        rendObj = ROBJ_IMAGE
        image = Picture($"{getGradePresentation(curBpId.get(), bp.grade).icon(eventSeasonIdx.get())}:{bpIconSize}:{bpIconSize}:P")
        color = isCurrent ? 0xFFFFFFFF : 0x40404040
        keepAspect = true
        transform = isCurrent ? const { scale = [1.0, 1.0] } : const { scale = [0.9, 0.9] }
        transitions = iconTransitions
      }
      if (isCurrent)
        children.append(child)
      else
        children.insert(0, child)
    }
    return {
      watch = [curBpId, bpList, selBpInfo, eventSeasonIdx]
      size = [bpIconSize * (bpList.get().len() + 1) * 0.5, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      behavior = Behaviors.Button
      onClick = @() onSelectBp(bpList.get(), selBpInfo.get())
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc(getGradePresentation(curBpId.get(), selBpInfo.get()?.grade).locId)
          hplace = ALIGN_CENTER
        }.__update(fontBig)
        {
          size = [FLEX, bpIconSize]
          children
        }
      ]
    }
  }
}

function buyBlock(bpList, selBpInfo) {
  let switchBpButton = mkCustomButton(
    {
      size = const [swIconSz, swIconSz]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#decor_change_icon.svg:{swIconSz}:{swIconSz}:P")
      keepAspect = true
    },
    @() onSelectBp(bpList.get(), selBpInfo.get()),
    mergeStyles(PRIMARY, { ovr = { minWidth = defButtonHeight } }))
  let purchaseBtnOvr = { ovr = { minWidth = bpIconSize } }
  return function() {
    let { goods = null, purchList = [], grade = null } = selBpInfo.get()
    let { price = 0, currencyId = null } = selBpInfo.get()?.price
    return {
      watch = [curBpId, bpList, selBpInfo]
      size = [FLEX, defButtonHeight]
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = hdpx(30)
      children = [
        bpList.get().len() <= 1 ? null : switchBpButton
        price > 0
          ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
              mkCurrencyComp(price, currencyId)
              function() {
                sendBpBqEvent("purchase_pass_press")
                let battlePassRemainder = loc("battlepass/remainder", {
                  time = colorize(userlogTextColor, secondsToHoursLoc(curBpEndTime.get() - serverTime.get()))
                })
                if (purchList.len() <= 1)
                  purchaseGoods(goods?.id, battlePassRemainder)
                else
                  purchaseGoodsSeq(purchList,
                    loc(getGradePresentation(curBpId.get(), grade).locId), battlePassRemainder)
              },
              purchaseBtnOvr)
          : {
              size = FLEX_H
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              text = loc("error/googleplay/GP_ITEM_UNAVAILABLE")
              halign = ALIGN_CENTER
            }.__update(fontSmall)
      ]
    }
  }
}

let rightBlock = @(bpList, selBpInfo) {
  size = const [rightBlockWidth, FLEX]
  flow = FLOW_VERTICAL
  gap = { size = FLEX }
  children = [
    battlePassIcon(bpList, selBpInfo)
    mkSpinnerHideBlock(Computed(@() shopPurchaseInProgress.get() != null),
      buyBlock(bpList, selBpInfo),
      {
        size = [ FLEX, defButtonHeight ]
        halign = ALIGN_CENTER
      })
  ]
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight + contentGradientSize[0] + contentGradientSize[1],
  contentGradientSize)
let scrollHandler = ScrollHandler()

let content = @(bpList, selBpInfo) {
  size = [FLEX, wndContentHeight]
  flow = FLOW_HORIZONTAL
  gap = blocksGap
  children = [
    {
      size = FLEX
      children = [
        pannableArea(
          rewardsList(selBpInfo),
          {},
          { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
        mkScrollArrow(scrollHandler, MR_B, scrollArrowImageSmall, { vplace = ALIGN_TOP, pos = [0, wndContentHeight] })
      ]
    }
    rightBlock(bpList, selBpInfo)
  ]
}

function bpPurchaseWnd() {
  let bpList = Computed(function() {
    let res = []
    local price = 0
    local points = 0
    let purchList = []
    foreach (goods in curBpGoods.get()) {
      let gradeToClaim = getGradeToClaimByGoods(goods, curBpId.get())
      if (curBpGrade.get() >= gradeToClaim)
        continue

      local goodsPrice = goods.price
      local goodsPoints = 0
      local hasPurchList = false
      if (purchList.len() == 0 || null != purchList.findvalue(@(g) g.price.currencyId == goods.price.currencyId)) {
        price += goods.price.price
        goodsPrice = { ...goods.price, price }

        points += goods.rewards.reduce(@(addPoints, r) r.gType == G_BP_POINTS ? addPoints + r.count : addPoints, 0)
        goodsPoints = points

        purchList.append(goods)
        hasPurchList = true
      }
      res.append({
        grade = gradeToClaim,
        points = goodsPoints,
        goods,
        price = goodsPrice,
        purchList = hasPurchList ? clone purchList : []
      })
    }
    return res
  })
  let selBpInfo = Computed(@() bpList.get().findvalue(@(v) v.grade == playerSelectedGrade.get())
    ?? bpList.get()?[bpList.get().len() - 1])

  return {
    key = {}
    size = FLEX
    padding = saBordersRv
    flow = FLOW_VERTICAL
    gap = contentGap
    children = [
      header
      content(bpList, selBpInfo)
    ]
    animations = wndSwitchAnim
  }
}

const sceneId = "bpPurchaseWnd"
registerScene(sceneId, bpPurchaseWnd, @() isPurchaseWndOpened.set(false), isPurchaseWndOpened)
setSceneBg(sceneId, bgScene.get()?.bg, bgScene.get()?.bgColor)
bgScene.subscribe(@(v) setSceneBg(sceneId, v?.bg, v?.bgColor))
registerUnlocksSceneToUpdate(sceneId)