from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { get_time_msec } = require("dagor.time")
let { stop_prem_cutscene } = require("hangar")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { abTests } = require("%appGlobals/pServer/campaign.nut")
let { getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { unhideModals } = require("%rGui/components/modalWindows.nut")
let { previewGoods, isPreviewGoodsPurchasing, HIDE_PREVIEW_MODALS_ID } = require("%rGui/shop/goodsPreviewState.nut")
let { purchaseGoods } = require("%rGui/shop/purchaseGoods.nut")
let { buyPlatformGoods } = require("%rGui/shop/platformGoods.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToTimeSimpleString, TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { mkCurrencyComp, mkPriceExtText, CS_BIG, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { shopGoodsToRewardsViewInfo, sortRewardsViewInfo, isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlateBg, mkRewardPlateImage, mkRewardPlateTexts, mkRewardReceivedMark
} = require("%rGui/rewards/rewardPlateComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gradCircularSqCorners, gradCircCornerOffset, gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { getEventLoc, MAIN_EVENT_ID, eventSeason, specialEvents } = require("%rGui/event/eventState.nut")
let { discountTagOffer, discountOfferTagH } = require("%rGui/components/discountTag.nut")
let { G_ITEM } = require("%appGlobals/rewardType.nut")


let activeItemId = Watched(null)

let currencyStyle = CS_BIG
let addHintPadding = hdpx(10)
let purchGap = hdpx(20)
let horGap = hdpx(60)
let oldPriceTranslate = [0,
  purchGap + 0.5 * defButtonHeight + 0.5 * calc_str_box("2", currencyStyle.fontStyle)[1]]

//animation preview header
let aTimePackNameFull = 0.5
let aTimePackNameBack = 0.3
let aTimeBackBtn = aTimePackNameFull - aTimePackNameBack
//animation prices & time
let aTimeTime = 0.4
let aTimePriceMove = 0.3
let aTimePriceBounce = 0.15
let aTimePriceStrike = 0.15
let aTimeDiscountTagScale = 0.3
let aTimeDiscountTagMove = 0.15
let aTimeFinalPriceShow = 0.2
let aTimeFinalPriceBounce = 0.3
let aTimeFinalPriceGlow = 0.1
let aTimePriceFull = aTimePriceMove + aTimePriceBounce + aTimeFinalPriceShow + aTimeFinalPriceBounce + aTimeDiscountTagScale
//animation items
let aTimeInfoItem = 0.3
let aTimeInfoItemOffset = 0.15
let aTimeInfoLight = 0.2

let ANIM_SKIP = {}
let ANIM_SKIP_DELAY = {}

function opacityAnims(duration, delay, soundName = "", skipTrigger = ANIM_SKIP_DELAY) {
  let res = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, easing = InQuad, play = true, duration, delay,
      trigger = skipTrigger }
  ]
  if (delay > 0)
    res.insert(0,
      { prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = delay, play = true,
        trigger = ANIM_SKIP, sound = { stop = soundName } }
    )
  return res
}

function colorAnims(duration, delay, skipTrigger = ANIM_SKIP_DELAY) {
  let res = [
    { prop = AnimProp.color, from = 0, easing = InQuad, play = true, duration, delay, trigger = skipTrigger }
  ]
  if (delay > 0)
    res.insert(0, { prop = AnimProp.color, from = 0, to = 0, play = true, duration = delay, trigger = ANIM_SKIP })
  return res
}

let withBqEvent = @(goods, action) function() {
  if ((goods?.endTime ?? 0) > 0) //offer
    sendOfferBqEvent("gotoPurchaseFromInfo", goods.campaign)
  stop_prem_cutscene()
  action()
}

let needPriceBlockZOrder = Watched(false)
function oldPriceBlock(child, animStartTime) {
  local start = get_time_msec() + (1000 * (animStartTime + aTimePriceMove)).tointeger()
  local end = start + (1000 * aTimePriceStrike).tointeger()
  local isFinished = false
  return @() {
    watch = needPriceBlockZOrder
    key = needPriceBlockZOrder
    zOrder = needPriceBlockZOrder.value ? Layers.Upper : Layers.Default
    children = [
      child
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        lineWidth = hdpx(5)
        color = 0xFFE02A14
        commands = []
        behavior = Behaviors.RtPropUpdate
        function update() {
          if (isFinished)
            return null
          let time = get_time_msec()
          if (time <= start)
            return null
          if (time >= end)
            isFinished = true
          return {
            commands = [[VECTOR_LINE, -20, 65,
              lerpClamped(start, end, -20, 120, time),
              lerpClamped(start, end, 65, 35, time)
            ]]
          }
        }
      }
    ]
    transform = {}
    animations = opacityAnims(aTimeTime, animStartTime - aTimeTime)
      .append(
        { prop = AnimProp.translate, from = oldPriceTranslate, to = oldPriceTranslate, play = true,
          duration = animStartTime, trigger = ANIM_SKIP,
          onEnter = @() needPriceBlockZOrder(true),
          function onAbort() {
            needPriceBlockZOrder(false)
            if (start > get_time_msec()) {
              start = get_time_msec()
              end = start + (1000 * aTimePriceStrike).tointeger()
            }
          },
        }
        { prop = AnimProp.translate, from = oldPriceTranslate, easing = InOutQuad, play = true,
          duration = aTimePriceMove, delay = animStartTime, trigger = ANIM_SKIP
          onExit = @() needPriceBlockZOrder(false),
        }
        { prop = AnimProp.translate, to = [0, hdpx(10)], easing = CosineFull, play = true,
          duration = aTimePriceBounce, delay = animStartTime + aTimePriceMove, trigger = ANIM_SKIP_DELAY }
      )
  }
}

let mkHighlight = @(duration, start, appear) {
  size = flex()
  rendObj = ROBJ_9RECT
  image = gradCircularSqCorners
  texOffs = [gradCircCornerOffset, gradCircCornerOffset]
  screenOffs = hdpx(30)
  opacity = 0.0
  color = 0x00C0C0C0
  transform = {}
  animations = opacityAnims(appear, start)
    .append(
      { prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
        duration, delay = start + appear, trigger = ANIM_SKIP }
      { prop = AnimProp.opacity, from = 1.0, play = true,
        duration = appear, delay = start + appear + duration, trigger = ANIM_SKIP }
      { prop = AnimProp.scale, from = [1.05, 1.1], to = [1.15, 1.3], easing = CosineFull, play = true,
        duration = duration + appear, delay = start + appear, trigger = ANIM_SKIP }
    )
}

let spinnerBlockOvr = {
  size = [SIZE_TO_CONTENT, defButtonHeight]
  minWidth = defButtonMinWidth
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}

let purchStyle = buttonStyles.PURCHASE.__merge({ hotkeys = ["^J:X"] })
function mkPurchButton(content, onClick, animStartTime) {
  let start = animStartTime + aTimePriceMove + aTimePriceStrike
  let animations = opacityAnims(aTimeFinalPriceShow, start)
    .append(
      { prop = AnimProp.scale, to = [1.5, 1.5], easing = CosineFull, play = true,
        duration = aTimeFinalPriceBounce, delay = start + aTimeFinalPriceShow, trigger = ANIM_SKIP })
  return mkSpinnerHideBlock(isPreviewGoodsPurchasing,
    {
      children = [
        mkCustomButton(
          content,
          onClick,
          mergeStyles(purchStyle,
            {
              hotkeyBlockOvr = { transform = {}, animations }
              childOvr = { transform = {}, animations }
            })),
        mkHighlight(aTimeFinalPriceGlow, start, 0.1)
      ]
    },
    spinnerBlockOvr)
}

function unifyBasePrice(basePrice, finalPrice) {
  if ((100 * finalPrice).tointeger() % 100 == 0)
    return basePrice
  return (100 * basePrice).tointeger() % 100 == 0 ? basePrice - 0.01 : basePrice
}

function getPriceInfo(goods) {
  if (goods == null)
    return null
  let { price = null, priceExt = null, discountInPercent = 0 } = goods
  if ((price?.price ?? 0) > 0) {
    local basePrice = discountInPercent <= 0 ? price.price
      : unifyBasePrice(round(price.price / (1.0 - (discountInPercent / 100.0))), price.price).tointeger()
    return {
      discountInPercent
      priceCtor = mkCurrencyComp
      basePrice
      finalPrice = price.price
      currencyId = price.currencyId
      function buy() {
        purchaseGoods(goods.id)
        unhideModals(HIDE_PREVIEW_MODALS_ID)
      }
    }
  }
  if ((priceExt?.price ?? 0) > 0) {
    local basePrice = discountInPercent <= 0 ? priceExt.price
      : unifyBasePrice(round(priceExt.price / (1.0 - (discountInPercent / 100.0))), priceExt.price).tointeger()
    return {
      discountInPercent
      priceCtor = mkPriceExtText
      basePrice
      finalPrice = priceExt.price
      currencyId = priceExt.currencyId
      function buy() {
        buyPlatformGoods(goods)
        unhideModals(HIDE_PREVIEW_MODALS_ID)
      }
    }
  }
  return null
}

let discountMarginBlock = [hdpx(32), 0, 0, 0]
let abTestDiscountViewCfg = {
  old_price = {
    discountCtor = @(priceBlock, _, _) priceBlock
    gap = purchGap
    priceStyle = CS_BIG
  }
  old_price_and_discount = {
    discountCtor = @(priceBlock, discountPrice, ovr) {
      flow = FLOW_HORIZONTAL
      margin = discountMarginBlock
      valign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      gap = hdpx(32)
      children = [
        priceBlock
        discountTagOffer(discountPrice, ovr)
      ]
    }
    gap = 0
    priceStyle = CS_COMMON
  }
  discount = {
    discountCtor = @(_, discountPrice, ovr) {
      margin = discountMarginBlock
      hplace = ALIGN_RIGHT
      children = discountTagOffer(discountPrice, ovr)
    }
    gap = 0
    priceStyle = CS_COMMON
  }
}

let purchaseButtonBlock = @(animStartTime) function() {
  let res = {
    watch = [previewGoods, abTests]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
  }
  let goods = previewGoods.value
  let info = getPriceInfo(goods)
  if (info == null)
    return res

  let { gap = purchGap, priceStyle = CS_BIG,
    discountCtor = @(priceBlock, _, _) priceBlock
  } = abTestDiscountViewCfg?[abTests.get()?.offerDiscountView] ?? abTestDiscountViewCfg.old_price
  res.gap <- gap

  let { priceCtor, basePrice, finalPrice, currencyId, buy, discountInPercent } = info
  let priceBlock = finalPrice == basePrice ? null
    : oldPriceBlock(priceCtor(basePrice, currencyId, priceStyle), animStartTime)
  return res.__update({
    children = [
      discountCtor(priceBlock, discountInPercent, { transform = { pivot = [1, 1] },
        animations = opacityAnims(aTimeFinalPriceShow, animStartTime + aTimePriceMove + aTimePriceStrike)
          .append(
            { prop = AnimProp.translate, from=[0, discountOfferTagH], duration = aTimeDiscountTagMove,
              delay = animStartTime + aTimePriceMove + aTimePriceStrike, play = true, easing = Linear, trigger = ANIM_SKIP }
            { prop = AnimProp.scale, to = [1.2, 1.2], easing = CosineFull, play = true,
              duration = aTimeDiscountTagScale, delay = animStartTime + aTimePriceMove + aTimePriceStrike, trigger = ANIM_SKIP }
          )})
      mkPurchButton(
        priceCtor(finalPrice, currencyId, currencyStyle),
        withBqEvent(goods, buy),
        animStartTime)
    ]
  })
}

let purchaseButtonNoOldPrice = function() {
  let res = { watch = previewGoods }
  let goods = previewGoods.value
  let info = getPriceInfo(goods)
  if (info == null)
    return res

  let { priceCtor, finalPrice, currencyId, buy } = info
  return res.__update({
    children = mkSpinnerHideBlock(isPreviewGoodsPurchasing,
      mkCustomButton(
        priceCtor(finalPrice, currencyId, currencyStyle),
        withBqEvent(goods, buy),
        purchStyle),
      spinnerBlockOvr)
  })
}

let mkTimeLeftText = @(endTime) function() {
  let res = { watch = serverTime, rendObj = ROBJ_TEXT }
  let timeLeft = endTime - serverTime.value
  if (timeLeft < 0)
    return res.__update({
      text = utf8ToUpper(loc("lastChance"))
      color = 0xFFFFA406
    }, fontSmall)
  if (timeLeft >= TIME_DAY_IN_SECONDS)
    return res.__update({ text = $"▩{secondsToHoursLoc(timeLeft)}" }, fontMedium)
  return res.__update({
    text = secondsToTimeSimpleString(timeLeft)
    monoWidth = hdpx(38)
  }, fontBig)
}

let previewGoodsTimeLeft = @(halign, width = hdpx(350)) function() {
  let endTime = previewGoods.get()?.endTime ?? previewGoods.get()?.timeRange.end ?? 0
  if (endTime <= 0)
    return { watch = previewGoods }
  let text = utf8ToUpper(loc("limitedTimeOffer"))
  return {
    watch = previewGoods
    flow = FLOW_VERTICAL
    halign
    children = [
      {
        size = [width, SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text
        color = 0xFFFFFFFF
        halign
      }.__update(
        getFontToFitWidth({ rendObj = ROBJ_TEXT, text }.__update(fontTiny),
          width, [fontVeryTiny, fontTiny]))
      mkTimeLeftText(endTime)
    ]
  }
}

let mkPreviewHeader = @(textW, onBack, animStartTime) doubleSideGradient.__merge({
  pos = [-doubleSideGradientPaddingX, 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = horGap
  children = [
    backButton(onBack, { animations = opacityAnims(aTimeBackBtn, aTimePackNameBack + animStartTime, "element_appear") })
    @() {
      watch = textW
      rendObj = ROBJ_TEXT
      color = 0xFFFFFFFF
      text = utf8ToUpper(textW.value)
      transform = { pivot = [0, 0.5] }
      animations = opacityAnims(0.5 * aTimePackNameFull, animStartTime).append(
        { prop = AnimProp.translate, from = [-hdpx(100), 0.0], to = [0.0, 0.0], easing = InQuad, play = true,
          duration = 0.5 * aTimePackNameFull, delay = animStartTime, trigger = ANIM_SKIP }
        { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.1, 1.1], easing = CosineFull, play = true,
          duration = aTimePackNameFull, delay = animStartTime, trigger = ANIM_SKIP_DELAY }
      )
    }.__update(fontBig)
  ]
  animations = colorAnims(aTimePackNameBack, animStartTime)
})

let mkTimeBlock = @(animStartTime, child) doubleSideGradient.__merge({
  pos = [doubleSideGradientPaddingX, 0]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = horGap
  children = [
    previewGoodsTimeLeft(ALIGN_RIGHT)
    child
  ]
  animations = opacityAnims(aTimeTime, animStartTime, "price")
})

let mkPriceWithTimeBlock = @(animStartTime) mkTimeBlock(animStartTime, purchaseButtonBlock(animStartTime + aTimeTime))
let mkPriceWithTimeBlockNoOldPrice = @(animStartTime) mkTimeBlock(animStartTime, purchaseButtonNoOldPrice)

let mkTimeBlockCentered = @(animStartTime) doubleSideGradient.__merge({
  padding = [doubleSideGradientPaddingY, hdpx(25)]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = previewGoodsTimeLeft(ALIGN_CENTER, hdpx(500))
  animations = opacityAnims(aTimeTime, animStartTime, "price")
})

let mkPriceBlockCentered = @(animStartTime) doubleSideGradient.__merge({
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = purchaseButtonBlock(animStartTime + aTimeTime)
  animations = opacityAnims(aTimeTime, animStartTime, "price")
})

let mkItemBlink = @(start) {
  size = flex()
  rendObj = ROBJ_9RECT
  image = gradCircularSqCorners
  texOffs = [gradCircCornerOffset, gradCircCornerOffset]
  screenOffs = hdpx(30)
  opacity = 0.0
  transform = {}
  animations = opacityAnims(aTimeInfoLight, start, "element_appear", ANIM_SKIP)
    .append(
      { prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
        duration = aTimeInfoItem, delay = start + aTimeInfoLight, trigger = ANIM_SKIP }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.25, 1.25], easing = CosineFull, play = true,
        duration = aTimeInfoLight + aTimeInfoItem, delay = start, trigger = ANIM_SKIP }
    )
}

function mkItemImpl(r, rStyle, start) {
  let itemId = r.id
  let stateFlags = Watched(0)
  let isRewardReceived = Computed(@() isRewardEmpty([{ gType = r.rType }.__merge(r)], servProfile.get()))
  return @() {
    watch = [stateFlags, isRewardReceived]
    behavior = Behaviors.Button
    clickableInfo = loc("options/info")
    onClick = @() null
    function onElemState(sf) {
      stateFlags(sf)
      if (r.rType != G_ITEM)
        return
      let isActive = (sf & S_ACTIVE) != 0
      if (isActive != (activeItemId.value == itemId))
        activeItemId(isActive ? itemId : null)
    }
    onDetach = @() activeItemId.value == itemId ? activeItemId(null) : null
    children = [
      mkRewardPlateBg(r, rStyle).__update({
        picSaturate = stateFlags.value & S_ACTIVE ? 2
          : stateFlags.value & S_HOVER ? 1.5
          : 1
      })
      mkRewardPlateImage(r, rStyle)
      mkRewardPlateTexts(r, rStyle)
      isRewardReceived.get() ? mkRewardReceivedMark(rStyle) : null
    ]
    animations = opacityAnims(aTimeInfoItem, start + aTimeInfoLight)
  }
}

function mkItem(r, rStyle, idx, animStartTime) {
  let start = animStartTime + aTimeInfoItemOffset * idx
  return {
    children = [
      mkItemBlink(start)
      mkItemImpl(r, rStyle, start)
    ]
  }
}

function mkPreviewItems(goods, animStartTime) {
  if (goods == null)
    return null
  let info = shopGoodsToRewardsViewInfo(goods.__merge({ units = [], unitUpgrades = [] }))
    .sort(sortRewardsViewInfo)
  return info.len() == 0 ? null : {
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = info.map(@(r, idx) mkItem(r, REWARD_STYLE_MEDIUM, idx, animStartTime))
  }
}

function doubleClickListener(onDoubleClick) {
  local lastClickMsec = 0
  return {
    size = flex()
    behavior = Behaviors.Button
    function onClick() {
      let time = get_time_msec()
      if (time - lastClickMsec <= 300) {
        onDoubleClick()
        lastClickMsec = 0
      }
      else
        lastClickMsec = time
    }
  }
}

let mkInfoText = @(text, appearDelay) {
  rendObj = ROBJ_TEXT
  text
  animations = opacityAnims(1.0, appearDelay)
}.__update(fontTiny)

let activeItemHint = @() activeItemId.value == null ? { watch = activeItemId }
  : {
      watch = [activeItemId, eventSeason, specialEvents]
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = 0xFF000000
      padding = [addHintPadding, saBorders[0] + addHintPadding]
      children = {
        size = [hdpx(500), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = "\n".concat(
          colorize(0xFFFFFFFF, loc($"item/{activeItemId.value}",
            { name = getEventLoc(MAIN_EVENT_ID, eventSeason.get(), specialEvents.get()) })),
          loc($"item/{activeItemId.value}/desc")
        )
        color = 0xFFD0D0D0
      }.__update(fontTiny)
    }

return {
  activeItemId

  mkPreviewHeader
  mkPriceWithTimeBlock
  mkPriceWithTimeBlockNoOldPrice
  mkTimeBlockCentered
  mkPriceBlockCentered
  mkPreviewItems
  activeItemHint
  mkInfoText
  opacityAnims
  colorAnims
  doubleClickListener
  oldPriceBlock

  ANIM_SKIP
  ANIM_SKIP_DELAY
  aTimePackNameFull
  aTimePackNameBack
  aTimeBackBtn
  aTimeInfoItem
  aTimeInfoItemOffset
  aTimeInfoLight
  aTimePriceFull
  aTimePriceMove
  aTimePriceStrike

  horGap
}