from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene, setSceneBg } = require("%rGui/navState.nut")
let { isBPPurchaseWndOpened, closeBPPurchaseWnd, isBpSeasonActive, curStage, sendBpBqEvent,
  purchasedBp, bpPurchasedUnlock, bpPaidRewardsUnlock, bpFreeRewardsUnlock, battlePassGoods, getBpIcon,
  BP_NONE, BP_COMMON, BP_VIP, getBpName, seasonEndTime
} = require("battlePassState.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")
let { purchaseGoods, purchaseGoodsSeq } = require("%rGui/shop/purchaseGoods.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getRewardsViewInfo, shopGoodsToRewardsViewInfo, joinViewInfo, sortRewardsViewInfo
} = require("%rGui/rewards/rewardViewInfo.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let battlePassSeason = require("battlePassSeason.nut")
let { mkRewardPlate, mkRewardPlateVip } = require("%rGui/rewards/rewardPlateComp.nut")
let { bpCardStyle } = require("bpCardsStyle.nut")
let { textButtonPricePurchase, buttonStyles, mergeStyles, mkCustomButton } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PRIMARY } = buttonStyles
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow, scrollArrowImageSmall } = require("%rGui/components/scrollArrows.nut")
let { PLATINUM } = require("%appGlobals/currenciesState.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

isBpSeasonActive.subscribe(@(isActive) isActive ? null : closeBPPurchaseWnd())

let { boxSize, boxGap } = bpCardStyle
let rewardsListGap = 1.5 * boxGap
let bpIconSize = hdpxi(400)
let blocksGap = isWidescreen ? 3 * boxGap : boxGap

let rightBlockWidth = 1.5 * bpIconSize
let rewardSlotsInRow = (saSize[0] - rightBlockWidth - blocksGap + boxGap) / (boxSize + boxGap)
let swIconSz = hdpx(70)

let contentGap = hdpx(25)
let wndContentHeight = saSize[1] - gamercardHeight - contentGap
let contentGradientSize = [contentGap, saBorders[1]]

let playerSelectedBp = mkWatched(persist, "playerSelectedBp", null)

let header = {
  size = [flex(), gamercardHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    backButton(closeBPPurchaseWnd)
    battlePassSeason
    { size = flex() }
    mkCurrenciesBtns([PLATINUM])
  ]
}

let mkRewardInstant = @(vInfo) (vInfo?.isVip ? mkRewardPlateVip : mkRewardPlate)(vInfo, bpCardStyle)

let rangeText = @(range) range[0] == range[1] ? range[0].tostring()
  : $"{range[0]}-{range[1]}"

let mkRewardWithProgress = @(vInfo) {
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [
    {
      size = FLEX_H
      valign = ALIGN_BOTTOM
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("mainmenu/rank/short")
        }.__update(fontVeryTiny)
        {
          hplace = ALIGN_RIGHT
          rendObj = ROBJ_TEXT
          text = rangeText(vInfo.sRange)
        }.__update(fontTiny)
      ]
    }
    mkRewardInstant(vInfo)
  ]
}

function rewardsBlock(text, viewInfo, rewardCtor) {
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
        children = row.list.map(rewardCtor)
      }))
  }
}

function rewardsToViewInfo(rewards, servConfigs) {
  let res = []
  foreach(id, data in rewards) {
    let reward = servConfigs?.userstatRewards[id]
    if (!reward)
      continue
    let viewInfo = getRewardsViewInfo(reward, data.count)
      .map(@(vi) vi.__update({ sRange = data.sRange }))
    joinViewInfo(res, viewInfo,
      function(to, from) {
        to.sRange = [min(to.sRange[0], from.sRange[0]), max(to.sRange[1], from.sRange[1])]
      })
  }
  return res
}

let rewardsList = @(selBpInfo) function() {
  let res = {
    watch = [bpPurchasedUnlock, bpPaidRewardsUnlock, bpFreeRewardsUnlock, curStage, serverConfigs, selBpInfo, purchasedBp]
    size = FLEX_H
  }
  if (bpPaidRewardsUnlock.value == null)
    return res

  let viewInfoExclusive = []
  let viewInfoOnPurchase = []
  let viewInfoAddLevels = []
  let viewInfoOnProgress = []
  let tgtStage = curStage.get()
  let maxProgress = max((bpPaidRewardsUnlock.get()?.stages.top().progress ?? tgtStage),
    (bpFreeRewardsUnlock.get()?.stages.top().progress ?? tgtStage))
  let levelsToAdd = selBpInfo.get()?.bpType != BP_VIP ? 0 : min(10, maxProgress - tgtStage)
  let tgtStageAdd = tgtStage + levelsToAdd

  let rewardsOnPurchase = purchasedBp.get() != BP_NONE ? {}
    : (bpPurchasedUnlock.value?.stages[0].rewards ?? {})
        .map(@(count) { count, sRange = [0, 0] })
  let rewardsAddLevels = {}
  let rewardsOnProgress = {}
  let unlocksList = levelsToAdd ? [bpFreeRewardsUnlock.get(), bpPaidRewardsUnlock.get()] : [bpPaidRewardsUnlock.get()]
  foreach(unlock in unlocksList) {
    let { lastRewardedStage = 0, stages = [] } = unlock
    let startProgress = unlock == bpFreeRewardsUnlock.get() ? tgtStage : -1
    let endProgress = unlock == bpFreeRewardsUnlock.get() ? tgtStageAdd : null
    foreach (idx, s in stages) {
      if (idx < lastRewardedStage || s.progress <= startProgress || s.progress > (endProgress ?? s.progress))
        continue
      let list = s.progress <= tgtStage ? rewardsOnPurchase
        : s.progress <= tgtStageAdd ? rewardsAddLevels
        : rewardsOnProgress
      foreach(key, count in s.rewards)
        if (key not in list)
          list[key] <- { count, sRange = [s.progress, s.progress] }
        else {
          list[key].count += count
          list[key].sRange[1] = s.progress
        }
    }
  }
  viewInfoOnPurchase.extend(rewardsToViewInfo(rewardsOnPurchase, serverConfigs.get())
    .sort(sortRewardsViewInfo))
  viewInfoAddLevels.extend(rewardsToViewInfo(rewardsAddLevels, serverConfigs.get())
    .sort(sortRewardsViewInfo))
  if (purchasedBp.get() == BP_NONE)
    viewInfoOnProgress.extend(rewardsToViewInfo(rewardsOnProgress, serverConfigs.get())
      .sort(sortRewardsViewInfo))

  let { goods = null } = selBpInfo.get()
  if (goods != null) {
    let vi = shopGoodsToRewardsViewInfo(goods).sort(sortRewardsViewInfo)
    if (selBpInfo.get().bpType == BP_VIP)
      vi.each(@(v) v.$rawset("isVip", true))
    viewInfoExclusive.extend(vi)
  }

  return res.__update({
    children = {
      key = selBpInfo.get()?.bpType
      size = FLEX_H
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = rewardsListGap
      children = [
        rewardsBlock(
          viewInfoExclusive.len() == 0 ? loc("battlePass/receiveOnPurchase")
            : loc("battlePass/receiveOnPurchase/exclusive", { count = viewInfoExclusive.len() }),
          viewInfoOnPurchase.extend(viewInfoExclusive), mkRewardInstant)
        rewardsBlock(loc("battlepass/levelsBonus", { num = levelsToAdd }),
          viewInfoAddLevels, mkRewardInstant)
        rewardsBlock(loc("battlePass/receiveOnProgress"), viewInfoOnProgress, mkRewardWithProgress)
      ]
      animations = wndSwitchAnim
    }
  })
}

function getNextFromList(list, cur) {
  let idx = (list.indexof(cur) ?? -1) + 1
  return list?[idx % list.len()]
}

let battlePassIcon = @(bpList, selBpInfo) function() {
  let children = []
  foreach(idx, bp in bpList.get()) {
    let isCurrent = bp == selBpInfo.get()
    let child = {
      key = bp.bpType
      size = [bpIconSize, bpIconSize]
      pos = [idx * bpIconSize / 2, 0]
      rendObj = ROBJ_IMAGE
      image = Picture($"{getBpIcon(bp.bpType, eventSeason.get())}:{bpIconSize}:{bpIconSize}:P")
      color = isCurrent ? 0xFFFFFFFF : 0x40404040
      keepAspect = true
      transform = { scale = isCurrent ? [1.0, 1.0] : [0.9, 0.9] }
      transitions = [
        { prop = AnimProp.color, duration = 0.3, easing = InOutQuad }
        { prop = AnimProp.scale, duration = 0.3, easing = InOutQuad }
      ]
    }
    if (isCurrent)
      children.append(child)
    else
      children.insert(0, child)
  }
  return {
    watch = [bpList, selBpInfo, eventSeason]
    size = [bpIconSize * (bpList.get().len() + 1) / 2, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    behavior = Behaviors.Button
    onClick = @() playerSelectedBp.set(getNextFromList(bpList.get(), selBpInfo.get())?.bpType)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = getBpName(selBpInfo.get()?.bpType)
        hplace = ALIGN_CENTER
      }.__update(fontBig)
      {
        size = [flex(), bpIconSize]
        children
      }
    ]
  }
}

let buyBlock = @(bpList, selBpInfo) function() {
  let { goods = null, price = null, purchList = null } = selBpInfo.get()
  return {
    watch = [purchasedBp, bpList, selBpInfo]
    size = [flex(), defButtonHeight]
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    children = [
      bpList.get().len() <= 1 ? null
        : mkCustomButton(
            {
              size = [swIconSz, swIconSz]
              rendObj = ROBJ_IMAGE
              image = Picture($"ui/gameuiskin#decor_change_icon.svg:{swIconSz}:{swIconSz}:P")
              keepAspect = true
            },
            @() playerSelectedBp.set(getNextFromList(bpList.get(), selBpInfo.get())?.bpType),
            mergeStyles(PRIMARY, { ovr = { minWidth = defButtonHeight } }))
      purchasedBp.get() == selBpInfo.get()?.bpType
        ? {
            rendObj = ROBJ_TEXT
            text = loc("battlePass/alreadyBought")
          }.__update(fontSmall)
        : (price?.price ?? 0) > 0
          ? textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
              mkCurrencyComp(price.price, price.currencyId)
              function() {
                sendBpBqEvent("purchase_pass_press")
                let battlePassRemainder = loc("battlepass/remainder", {
                  time = colorize(userlogTextColor, secondsToHoursLoc(seasonEndTime.get() - serverTime.get()))
                })
                if (purchList == null)
                  purchaseGoods(goods?.id, battlePassRemainder)
                else
                  purchaseGoodsSeq(purchList, getBpName(selBpInfo.get()?.bpType), battlePassRemainder)
              },
              { ovr = { minWidth = bpIconSize }})
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

let rightBlock = @(bpList, selBpInfo) {
  size = [rightBlockWidth, flex()]
  flow = FLOW_VERTICAL
  gap = { size = flex() }
  children = [
    battlePassIcon(bpList, selBpInfo)
    buyBlock(bpList, selBpInfo)
  ]
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight + contentGradientSize[0] + contentGradientSize[1],
  contentGradientSize)
let scrollHandler = ScrollHandler()

let content = @(bpList, selBpInfo) {
  size = [flex(), wndContentHeight]
  flow = FLOW_HORIZONTAL
  gap = blocksGap
  children = [
    {
      size = flex()
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

let mkGoodsCfg = @(bpType, goods, price, purchList = null) { bpType, goods, price, purchList }

let function bpPurchaseWnd() {
  let bpList = Computed(function() {
    let res = []
    let goodsCommon = battlePassGoods.get()[BP_COMMON]
    let goodsVip = battlePassGoods.get()[BP_VIP]

    if (purchasedBp.get() == BP_NONE) {
      if (goodsCommon == null)
        return res
      res.append(mkGoodsCfg(BP_COMMON, goodsCommon, goodsCommon.price))
      if (goodsVip?.price.currencyId == goodsCommon.price.currencyId)
        res.append(mkGoodsCfg(BP_VIP, goodsVip,
          goodsCommon.price.__merge({ price = goodsCommon.price.price + goodsVip.price.price }),
          [goodsCommon, goodsVip]))
      return res
    }

    if (goodsVip != null)
      res.append(mkGoodsCfg(BP_VIP, goodsVip, goodsVip.price))
    return res
  })
  let selIndex = Computed(@() bpList.get().findindex(@(v) v.bpType == playerSelectedBp.get())
    ?? bpList.get().len() - 1)
  let selBpInfo = Computed(@() bpList.get()?[selIndex.get()])

  return {
    key = {}
    size = flex()
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

registerScene("bpPurchaseWnd", bpPurchaseWnd, closeBPPurchaseWnd, isBPPurchaseWndOpened)
setSceneBg("bpPurchaseWnd", "ui/images/bp_bg_01.avif")
