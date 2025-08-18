from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { currencyToFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { registerScene } = require("%rGui/navState.nut")
let { GPT_SLOTS, previewType, previewGoods, closeGoodsPreview, openPreviewCount, GPT_BLUEPRINT, openedGoodsId,
  openedUnitFromTree
} = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { todayPurchasesCount } = require("%appGlobals/pServer/campaign.nut")
let { serverTimeDay, getDay, dayOffset, untilNextDaySec } = require("%appGlobals/userstats/serverTimeDay.nut")
let { registerHandler, shopPurchaseInProgress, shopGenSlotInProgress,
  gen_goods_slots, buy_goods_slot, reset_reward_slots
} = require("%appGlobals/pServer/pServerApi.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { openMsgBoxPurchase, PURCHASE_BOX_UID } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, PURCH_TYPE_GOODS_SLOT, PURCH_TYPE_GOODS_REROLL_SLOTS,
  mkBqPurchaseInfo
} = require("%rGui/shop/bqPurchaseInfo.nut")
let { getAdjustedPriceInfo } = require("%rGui/shop/goodsUtils.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")

let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { textButtonPricePurchase, buttonsHGap, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PRIMARY } = buttonStyles
let { getSlotsPreviewBg, getSlotsTexts } = require("%appGlobals/config/goodsPresentation.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, getRewardPlateSize, progressBarHeight
} = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkRewardPlateTexts, mkRewardSearchPlate,
  mkRewardUnitFlag
} = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardsViewInfo, isRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { mkTooltipText } = require("%rGui/tooltip.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { revealAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { secondsToTimeAbbrString } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let MAX_BIG_SLOTS = 8
let maxWndWidth = min(saSize[0], hdpxi(2200))
let blockGap = buttonsHGap

let selBorderColor = 0xFFFFFFFF
let hoverBorderColor = 0x40404040
let borderHeight = hdpx(8)

let rerollTrigger = {}
let rerollUnitAnim = [{
  prop = AnimProp.scale, from = [1.0, 1.0], to = [1.15, 1.15],
  duration = 1, play = true, rerollTrigger, easing = DoubleBlink
}]
let rerollButtonStyle = PRIMARY.__merge({
  ovr = PRIMARY.ovr.__merge({ animations = rerollUnitAnim, transform = {} })
})


let isAttached = Watched(false)
let openCount = Computed(@() previewType.get() == GPT_SLOTS ? openPreviewCount.get() : 0)
let goodsRewardSlots = Computed(@() serverConfigs.get()?.goodsRewardSlots[previewGoods.get()?.slotsPreset])
let rerollCost = Computed(@() goodsRewardSlots.get()?.rerollCost)
let rewardSlots = Computed(@() servProfile.get()?.rewardSlots[previewGoods.get()?.id])
let selIndex = Watched(-1)
let previewGoodsWithUpdatedPrice = Computed(function() {
  let goods = previewGoods.get()
  if (goods == null)
    return null
  let { count = 0, lastTime = 0 } = todayPurchasesCount.get()?[goods.id]
  return goods.__merge({
    price = getAdjustedPriceInfo(goods,
      serverTimeDay.get() == getDay(lastTime, dayOffset.get()) ? count : 0)
  })
})

let AUTO_REQUEST_AFTER_ERROR_TIME = 10
let freeRefreshErrorSoon = Watched(null)
let needFreeRefreshSlots = keepref(Computed(function() {
  if (!isAttached.get()
      || freeRefreshErrorSoon.get() == previewGoods.get()?.id
      || shopPurchaseInProgress.get() == previewGoods.get()?.id
      || shopGenSlotInProgress.get() == previewGoods.get()?.id
      || rerollCost.get() == null) 
    return false
  let { time = 0, isPurchased = false, goods = [] } = rewardSlots.get()
  return getDay(time, dayOffset.get()) != serverTimeDay.get()
    || isPurchased
    || (goods.len() > 0 && null == goods.findvalue(@(g) !isRewardEmpty(g, servProfile.get())))
}))

selIndex.subscribe(function(_) {
  if (isAttached.get())
    closeMsgBox(PURCHASE_BOX_UID)
})

let resetError = @() freeRefreshErrorSoon.set(null)
registerHandler("autoGenerateGoodsSlots",
  function(res, context) {
    if (res?.error == null)
      return
    freeRefreshErrorSoon.set(context.goodsId)
    resetTimeout(AUTO_REQUEST_AFTER_ERROR_TIME, resetError)
  })

function freeRefreshSlots() {
  if (!needFreeRefreshSlots.get())
    return
  let { id = null } = previewGoods.get()
  if (id != null)
    gen_goods_slots(id, "", 0, { id = "autoGenerateGoodsSlots", goodsId = id })
}

needFreeRefreshSlots.subscribe(@(_) deferOnce(freeRefreshSlots))

let txt = @(text, ovr = {}) { rendObj = ROBJ_TEXT, text }.__update(fontSmallAccented, ovr)

function balanceButtons() {
  let currencies = []
  let list = [
    previewGoodsWithUpdatedPrice.get()?.price.currencyId
    rerollCost.get()?.currencyId
  ]
  foreach(c in list)
    if ((c ?? "") != "" && !currencies.contains(c))
      currencies.append(c)
  return {
    watch = [previewGoodsWithUpdatedPrice, rerollCost]
    children = mkCurrenciesBtns(currencies)
  }
}

function timer() {
  let { count = 0 } = todayPurchasesCount.get()?[previewGoods.get()?.id]
  if(count == 0)
    return { watch = [ todayPurchasesCount, previewGoods] }
  let timerText = secondsToTimeAbbrString(untilNextDaySec(serverTime.get(), dayOffset.get()))
  return {
    watch = [dayOffset, serverTime, previewGoods, todayPurchasesCount]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = loc("shop/hint/updatePriceTimer", { time = timerText })
  }.__update(fontSmall)
}

function headerText() {
  let previewG = previewGoods.get()
  let allLeftSlotNames = (goodsRewardSlots.get()?.variants ?? []).reduce(
    @(res, v) isRewardEmpty(v, servProfile.get()) ? res
      : res.append(loc(getUnitLocId(v[0].id))),
    [])
  let description = loc(getSlotsTexts(openedGoodsId.get()).description)
  return {
    watch = [previewGoods, openedGoodsId, goodsRewardSlots, campMyUnits, serverConfigs, servProfile] 
    flow = FLOW_HORIZONTAL
    gap = hdpx(30)
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        color = 0xFFFFFFFF
        text = previewG == null ? null : getGoodsLocName(previewG)
      }.__update(fontBig)
      infoTooltipButton(
        @() mkTooltipText(allLeftSlotNames.len() == 0 ? description
          : "\n\n".concat(description, loc("shop/hint/availableSlots", { slots = ", ".join(allLeftSlotNames) })), fontTinyAccented),
        { halign = ALIGN_RIGHT },
        {
          size = hdpx(52)
          fillColor = 0x80000000
          children = {
            rendObj = ROBJ_TEXT
            text = "i"
            halign = ALIGN_CENTER
          }.__update(fontTinyAccented)
        })
    ]
  }
}

let headerPanel = {
  size = [flex(), gamercardHeight]
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = blockGap
  children = [
    backButton(closeGoodsPreview)
    headerText
    { size = flex() }
    balanceButtons
  ]
}

let highlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 25, 22, 31,-22))

let mkHightlightPlate = @(isSelected, rStyle) {
  size = flex()
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      flipY = true
      image = highlight()
      animations = revealAnimation(0)
      transform = { rotate = 180 }
      opacity = 0.5
    }
    {
      size = [flex(), borderHeight]
      pos = [0, -borderHeight]
      rendObj = ROBJ_BOX
      hplace = ALIGN_TOP
      fillColor = isSelected ? selBorderColor : hoverBorderColor
    }
    !isSelected ? null
      : {
          pos = [0, -progressBarHeight]
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_LEFT
          padding = hdpx(5)
          children = mkRewardSearchPlate(rStyle)
        }
  ]
}

function mkSlot(reward, rStyle) {
  let size = getRewardPlateSize(reward.slots, rStyle)
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selIndex.get() == reward.slotIdx)
  let unit = Computed(@() serverConfigs.get()?.allUnits?[reward.id])

  return @() {
    watch = [isSelected, stateFlags, rewardSlots, unit, openedUnitFromTree]
    key = unit
    size
    behavior = Behaviors.Button
    onElemState = @(v) rewardSlots.get()?.isPurchased ? null : stateFlags.set(v)
    onClick = @() rewardSlots.get()?.isPurchased
        ? null
      : isSelected.get()
        ? unitDetailsWnd({ name = reward.id })
      : selIndex.set(reward.slotIdx)
    sound = rewardSlots.get()?.isPurchased ? {} : { click  = "click" }
    onAttach = @() openedUnitFromTree.get() == unit.get()?.name ? selIndex.set(reward.slotIdx) : null

    children = [
      mkRewardPlateBg(reward, rStyle)
      mkRewardPlateImage(reward, rStyle)
      !isSelected.get() && !(stateFlags.get() & S_HOVER) ? null
        : mkHightlightPlate(isSelected.get(), rStyle)
      mkRewardPlateTexts(reward, rStyle)
      reward.rType == GPT_BLUEPRINT && unit.get() != null ? mkRewardUnitFlag(unit.get(), rStyle) : null
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14 }]
    animations = openedUnitFromTree.get() == unit.get()?.name ? rerollUnitAnim : null
  }
}

function fillRewardsByRows(rewards, slotsInRowMax, style) {
  let res = []
  let totalSlots = rewards.reduce(@(tsRes, r) tsRes + r.slots, 0)
  let rowsCount = totalSlots / slotsInRowMax + ((totalSlots % slotsInRowMax) ? 1 : 0)
  if (rowsCount == 0)
    return res
  let slotsInRowMin = totalSlots / rowsCount + ((totalSlots % rowsCount) ? 1 : 0)

  local curRowSlots = slotsInRowMax
  foreach(r in rewards) {
    if (curRowSlots >= slotsInRowMin || curRowSlots + r.slots > slotsInRowMax) {
      res.append([])
      curRowSlots = 0
    }
    curRowSlots += r.slots
    res.top().append(mkSlot(r, style))
  }
  return res
}

let playPurchaseSound = @(currencyId)
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")

function purchaseSelectedSlot(id, price, currencyId) {
  if (selIndex.get() < 0) 
    return
  buy_goods_slot(id, selIndex.get(), currencyId, price)
  playPurchaseSound(currencyId)
}

function rerollSlots(id, price, currencyId) {
  gen_goods_slots(id, currencyId, price)
  playPurchaseSound(currencyId)
  anim_start(rerollTrigger)
}

let openSelGoodsMsgBoxPurch = @(text, price, currencyId, action, bqInfo) openMsgBoxPurchase({
  text,
  price = { price, currencyId },
  purchase = @() previewGoods.get()?.id == null ? null : action(previewGoods.get()?.id, price, currencyId),
  bqInfo
})

function tryOpenPurchSlotMsgBox(goodsId, price, currencyId) {
  let { id = null, gType = null, count = null } = rewardSlots.get()?.goods[selIndex.get()][0]
  if (id == null) {
    openMsgBox({ text = loc("msg/selectSlotForPurchase") })
    return
  }
  let text = $"{loc("blueprints/title", { count })} {loc(getUnitLocId(id))}"
  openSelGoodsMsgBoxPurch(loc("shop/needMoneyQuestion_buy", { item = colorize(userlogTextColor, text) }),
    price, currencyId, purchaseSelectedSlot,
    mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_SLOT, $"{goodsId}:{gType}/{id}x{count}"))
}

function purchaseSlotBtn(id, priceCfg, toFullId) {
  let { price = 0, currencyId = "" } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  let currencyFullId = toFullId?[currencyId] ?? currencyId
  return textButtonPricePurchase(utf8ToUpper(loc("btn/buySelected")),
    mkCurrencyComp(price, currencyFullId),
    @() tryOpenPurchSlotMsgBox(id, price, currencyFullId))
}

function rerollBtn(id, priceCfg, toFullId, styleOvr) {
  let { price = 0, currencyId = "" } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  let currencyFullId = toFullId?[currencyId] ?? currencyId
  return textButtonPricePurchase(utf8ToUpper(loc("btn/rerollItems")),
    mkCurrencyComp(price, currencyFullId),
    @() openSelGoodsMsgBoxPurch(loc("shop/needMoneyQuestion_reroll"),
      price, currencyFullId, rerollSlots,
      mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_REROLL_SLOTS, id)),
    styleOvr)
}

let buttons = @(hasRerollAnim) function() {
  let res = {
    watch = [shopGenSlotInProgress, shopPurchaseInProgress, previewGoodsWithUpdatedPrice,
      rerollCost, serverTimeDay, currencyToFullId]
    minHeight = defButtonHeight
  }
  if (previewGoodsWithUpdatedPrice.get() == null)
    return res

  let { id, price } = previewGoodsWithUpdatedPrice.get()
  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    valign = ALIGN_BOTTOM
    children = shopGenSlotInProgress.get() == id ? null
      : shopPurchaseInProgress.get() ? spinner
      : [
          rerollBtn(id, rerollCost.get(), currencyToFullId.get(), hasRerollAnim ? rerollButtonStyle : PRIMARY)
          {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              timer
              purchaseSlotBtn(id, price, currencyToFullId.get())
            ]
          }
        ]
  })
}

function content() {
  let availableRewards = Computed(function(prev) {
    let { time = 0, goods = [] } = rewardSlots.get()
    if (shopGenSlotInProgress.get() || getDay(time, dayOffset.get()) != serverTimeDay.get())
      return isEqual(prev, []) ? prev : []
    let res = goods.reduce(
      @(res, g, idx) isRewardEmpty(g, servProfile.get()) ? res
        : res.append(getRewardsViewInfo(g)[0].__update({ slotIdx = idx })),
      [])
    return isEqual(prev, res) ? prev : res
  })
  let isPurchased = Computed(@() rewardSlots.get()?.isPurchased ?? false)
  return function() {
    let rewards = availableRewards.get()
    let style = rewards.len() > MAX_BIG_SLOTS ? REWARD_STYLE_SMALL : REWARD_STYLE_MEDIUM
    let { boxSize, boxGap } = style
    let slotsInRow = (maxWndWidth + boxGap) / (boxSize + boxGap)
    let rows = fillRewardsByRows(rewards, slotsInRow, style)
    let curUnit = openedUnitFromTree.get()
    let hasAnySlot = rows.len() > 0
    let hasRerollHint = !isPurchased.get() && hasAnySlot && curUnit != null
      && !rewards.reduce(@(res, r) res.$rawset(r.id, true), {})?[curUnit]

    let setSelIdx = @() selIndex.set(availableRewards.get().len() == 1 ? availableRewards.get()[0].slotIdx : -1)
    let rewardSlotsSubscription = @(_) setSelIdx()
    return {
      watch = [shopGenSlotInProgress, openedGoodsId, openedUnitFromTree, isPurchased, availableRewards]
      size = flex()
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = blockGap
      children = [
        isPurchased.get() || availableRewards.get().len() == 1 ? null
          : txt(hasAnySlot ? utf8ToUpper(loc("shop/pickOneItem"))
            : utf8ToUpper(loc(getSlotsTexts(openedGoodsId.get()).missing)))
        {
          key = availableRewards
          size = [SIZE_TO_CONTENT, max(2, rows.len()) * (boxSize + boxGap) - boxGap]
          flow = FLOW_VERTICAL
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          gap = boxGap
          function onAttach() {
            setSelIdx()
            rewardSlots.subscribe(rewardSlotsSubscription)
          }
          onDetach = @() rewardSlots.unsubscribe(rewardSlotsSubscription)
          children = shopGenSlotInProgress.get() ? spinner
            : rows.map(@(children) {
                flow = FLOW_HORIZONTAL
                gap = boxGap
                children
              })
        }
        hasAnySlot ? buttons(hasRerollHint) : null
        {
          size = const [flex(), hdpx(24)]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = !hasRerollHint ? null
            : txt(loc("shop/hint/rerollForUnit", { unitName = loc(getUnitLocId(curUnit)) }), {
                animations = rerollUnitAnim
                transform = {}
              })
        }
      ]
    }
  }
}

function onDetach() {
  isAttached.set(false)
  openedUnitFromTree.set(null)
}

let previewWnd = bgShaded.__merge({
  key = openCount
  size = flex()
  onAttach = @() isAttached.set(true)
  onDetach

  children = [
    @() {
      watch = previewGoods
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture(getSlotsPreviewBg(previewGoods.get()?.id))
      keepAspect = KEEP_ASPECT_FILL
    }
    {
      size = flex()
      margin = saBordersRv
      flow = FLOW_VERTICAL
      children = [
        headerPanel
        content()
      ]
    }
  ]
  animations = wndSwitchAnim
})

register_command(@() reset_reward_slots(), "meta.reset_reward_slots")

registerScene("goodsSlotsPreviewWnd", previewWnd, closeGoodsPreview, openCount)
