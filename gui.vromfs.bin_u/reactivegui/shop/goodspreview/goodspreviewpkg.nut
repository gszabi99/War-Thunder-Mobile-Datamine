from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { get_time_msec } = require("dagor.time")
let { stop_prem_cutscene } = require("hangar")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { previewGoods, isPreviewGoodsPurchasing } = require("%rGui/shop/goodsPreviewState.nut")
let purchaseGoods = require("%rGui/shop/purchaseGoods.nut")
let { buyPlatformGoods } = require("%rGui/shop/platformGoods.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")

let { mkCustomButton, buttonStyles, mergeStyles } = require("%rGui/components/textButton.nut")
let { mkCurrencyComp, mkPriceExtText, CS_BIG, mkCurrencyImage} = require("%rGui/components/currencyComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { doubleSideGradient, doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let backButton = require("%rGui/components/backButton.nut")
let { gradCircularSqCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")

let activeItemId = Watched(null)

let currencyStyle = CS_BIG
let purchGap = hdpx(20)
let horGap = hdpx(60)
let oldPriceTranslate = [0,
  purchGap + 0.5 * buttonStyles.defButtonHeight + 0.5 * calc_str_box("2", currencyStyle.fontStyle)[1]]
let itemSize = hdpx(160)
let goldImageSize = hdpxi(120)
let itemImageSize = hdpxi(80)
let itemCurrencySize = hdpxi(25)

//animation preview header
let aTimePackNameFull = 0.5
let aTimePackNameBack = 0.3
let aTimeBackBtn = aTimePackNameFull - aTimePackNameBack
//animation prices & time
let aTimeTime = 0.4
let aTimePriceMove = 0.3
let aTimePriceBounce = 0.15
let aTimePriceStrike = 0.15
let aTimeFinalPriceShow = 0.2
let aTimeFinalPriceBounce = 0.3
let aTimeFinalPriceGlow = 0.1
let aTimePriceFull = aTimePriceMove + aTimePriceBounce + aTimeFinalPriceShow + aTimeFinalPriceBounce
//animation items
let aTimeInfoItem = 0.3
let aTimeInfoItemOffset = 0.15
let aTimeInfoLight = 0.2

let ANIM_SKIP = {}
let ANIM_SKIP_DELAY = {}

let customItemImage = {
  gold = {
    image = "ui/gameuiskin/shop_eagles_02.avif"
    ovr = {
      size = [goldImageSize * 555 / 291, goldImageSize]
      pos = [0.2 * goldImageSize, -0.07 * goldImageSize]
    }
  }
}

let function opacityAnims(duration, delay, soundName = "", skipTrigger = ANIM_SKIP_DELAY) {
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

let function colorAnims(duration, delay, skipTrigger = ANIM_SKIP_DELAY) {
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
let function oldPriceBlock(child, animStartTime) {
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

let purchStyle = buttonStyles.PURCHASE.__merge({ hotkeys = ["^J:X"] })
let function mkPurchButton(content, onClick, animStartTime) {
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
    { size = [SIZE_TO_CONTENT, defButtonHeight] })
}

let function unifyBasePrice(basePrice, finalPrice) {
  if ((100 * finalPrice).tointeger() % 100 == 0)
    return basePrice
  return (100 * basePrice).tointeger() % 100 == 0 ? basePrice - 0.01 : basePrice
}

let purchaseButtonBlock = @(animStartTime) function() {
  let res = {
    watch = previewGoods
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = purchGap
  }
  let goods = previewGoods.value
  let { price = null, priceExt = null, discountInPercent = 0 } = goods
  if ((price?.price ?? 0) > 0) {
    let finalPrice = discountInPercent <= 0 ? price.price : round(price.price * (1.0 - (discountInPercent / 100.0)))
    return res.__update({
      children = [
        finalPrice == price.price ? null
          : oldPriceBlock(mkCurrencyComp(price.price, price.currencyId, currencyStyle), animStartTime)
        mkPurchButton(
          mkCurrencyComp(finalPrice, price.currencyId, currencyStyle),
          withBqEvent(goods, @() purchaseGoods(goods?.id)),
          animStartTime)
      ]
    })
  }
  if ((priceExt?.price ?? 0) > 0) {
    local basePrice = discountInPercent <= 0 ? priceExt.price
      : unifyBasePrice(round(priceExt.price / (1.0 - (discountInPercent / 100.0))), priceExt.price)
    return res.__update({
      children = [
        basePrice == priceExt.price ? null
          : oldPriceBlock(mkPriceExtText(basePrice, priceExt.currencyId, currencyStyle), animStartTime)
        mkPurchButton(
          mkPriceExtText(priceExt.price, priceExt.currencyId, currencyStyle),
          withBqEvent(goods, @() buyPlatformGoods(goods)),
          animStartTime)
      ]
    })
  }
  return res
}

let mkTimeLeftText = @(endTime) function() {
  let res = { watch = serverTime, rendObj = ROBJ_TEXT }
  let timeLeft = endTime - serverTime.value
  if (timeLeft < 0)
    return res.__update({
      text = utf8ToUpper(loc("lastChance"))
      color = 0xFFFFA406
    }, fontSmall)
  return res.__update({
    text = secondsToTimeSimpleString(timeLeft)
    color = 0xFFFFFFFF
    monoWidth = hdpx(38)
  }, fontBig)
}

let function previewGoodsTimeLeft() {
  let { endTime = 0 } = previewGoods.value
  if (endTime <= 0)
    return { watch = previewGoods }
  return {
    watch = previewGoods
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        size = [hdpx(350), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc("limitedTimeOffer"))
        color = 0xFFFFFFFF
        halign = ALIGN_RIGHT
      }.__update(fontTiny)
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

let mkPriceWithTimeBlock = @(animStartTime) doubleSideGradient.__merge({
  pos = [doubleSideGradientPaddingX, 0]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = horGap
  children = [
    previewGoodsTimeLeft
    purchaseButtonBlock(animStartTime + aTimeTime)
  ]
  animations = opacityAnims(aTimeTime, animStartTime, "price")
})

let function mkItemImpl(itemId, count, start) {
  let { image = null,  ovr = {} } = customItemImage?[itemId]
  let size = ovr?.size ?? [itemImageSize, itemImageSize]
  let isCurrency = itemId == "wp" || itemId == "gold"
  let countText = {
    rendObj = ROBJ_TEXT
    color = 0xFFFFFFFF
    text = decimalFormat(count)
  }.__update(fontTiny)
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [itemSize, itemSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{itemSize}:{itemSize}")
    behavior = Behaviors.Button
    picSaturate = stateFlags.value & S_ACTIVE ? 2
      : stateFlags.value & S_HOVER ? 1.5
      : 1
    clickableInfo = loc("options/info")
    onClick = @() null
    function onElemState(sf) {
      stateFlags(sf)
      let isActive = (sf & S_ACTIVE) != 0
      if (isActive != (activeItemId.value == itemId))
        activeItemId(isActive ? itemId : null)
    }
    onDetach = @() activeItemId.value == itemId ? activeItemId(null) : null
    children = [
      image != null
        ? {
            size
            margin = hdpx(10)
            hplace = ALIGN_CENTER
            rendObj = ROBJ_IMAGE
            image = Picture($"{image}:{size[0]}:{size[1]}:P")
            keepAspect = KEEP_ASPECT_FIT
          }.__update(ovr)
        : mkCurrencyImage(itemId, itemImageSize, {
            margin = hdpx(10)
          }).__update(ovr)
      {
        size = [flex(), hdpx(35)]
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        rendObj = ROBJ_SOLID
        color = 0x80000000
        flow = FLOW_HORIZONTAL
        gap = hdpx(5)
        children = !isCurrency ? countText
          : [
              mkCurrencyImage(itemId, itemCurrencySize)
              countText
            ]
      }
    ]
    animations = opacityAnims(aTimeInfoItem, start + aTimeInfoLight)
  }
}

let function mkItem(itemId, count, idx, animStartTime) {
  let start = animStartTime + aTimeInfoItemOffset * idx
  return {
    size = [itemSize, itemSize]
    children = [
      {
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
      mkItemImpl(itemId, count, start)
    ]
  }
}

let function mkPreviewItems(goods, animStartTime) {
  let { items = {}, wp = 0, gold = 0 } = goods
  if (items.len() == 0 && gold == 0 && wp == 0)
    return null
  let itemsLeft = clone items
  let children = []
  if (gold > 0)
    children.append(mkItem("gold", gold, children.len(), animStartTime))
  if (wp > 0)
    children.append(mkItem("wp", wp, children.len(), animStartTime))
  foreach (itemId in itemsOrderFull)
    if (itemId in itemsLeft)
      children.append(mkItem(itemId, delete itemsLeft[itemId], children.len(), animStartTime))
  foreach (itemId, count in itemsLeft)
    children.append(mkItem(itemId, count, children.len(), animStartTime))
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children
  }
}

let function doubleClickListener(onDoubleClick) {
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
  color = 0xFFA0A0A0
  text
  animations = opacityAnims(1.0, appearDelay)
}.__update(fontTiny)

let mkActiveItemHint = @(ovr = {}) @() activeItemId.value == null ? { watch = activeItemId }
  : doubleSideGradient.__merge(
      {
        watch = activeItemId
        children = {
          size = [hdpx(500), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = "\n".concat(
            colorize(0xFFFFFFFF, loc($"item/{activeItemId.value}")),
            loc($"item/{activeItemId.value}/desc")
          )
          color = 0xFFA0A0A0
        }.__update(fontSmall)
      },
      ovr)

return {
  activeItemId

  purchaseButtonBlock
  previewGoodsTimeLeft
  mkPreviewHeader
  mkPriceWithTimeBlock
  mkItem
  mkPreviewItems
  mkActiveItemHint
  mkInfoText
  opacityAnims
  colorAnims
  doubleClickListener

  ANIM_SKIP
  ANIM_SKIP_DELAY
  aTimePackNameFull
  aTimePackNameBack
  aTimeBackBtn
  aTimeInfoItem
  aTimeInfoItemOffset
  aTimeInfoLight
  aTimePriceFull

  horGap
}