from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { registerScene } = require("%rGui/navState.nut")
let { GPT_SLOTS, previewType, previewGoods, closeGoodsPreview, openPreviewCount, GPT_BLUEPRINT, openedGoodsId,
  openedUnitFromTree
} = require("%rGui/shop/goodsPreviewState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { goodsLimitReset } = require("%appGlobals/pServer/campaign.nut")
let { serverTimeDay, getDay, untilNextDaySec } = require("%appGlobals/userstats/serverTimeDay.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { registerHandler, shopPurchaseInProgress, shopGenSlotInProgress,
  gen_goods_slots, buy_goods_slot, increase_goods_limit, reset_reward_slots
} = require("%appGlobals/pServer/pServerApi.nut")
let { openMsgBox, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { openMsgBoxPurchase, showNoBalanceMsgIfNeed, PURCHASE_BOX_UID } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_SHOP, PURCH_TYPE_GOODS_SLOT, PURCH_TYPE_GOODS_LIMIT, PURCH_TYPE_GOODS_REROLL_SLOTS,
  mkBqPurchaseInfo
} = require("%rGui/shop/bqPurchaseInfo.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")

let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp, mkFreeText } = require("%rGui/components/currencyComp.nut")
let { textButtonPricePurchase, buttonsHGap, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PRIMARY } = buttonStyles
let { getSlotsPreviewBg, getSlotsTexts } = require("%appGlobals/config/goodsPresentation.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, getRewardPlateSize, progressBarHeight
} = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateBg, mkRewardPlateImage, mkRewardPlateTexts, mkRewardSearchPlate,
  mkRewardDisabledBkg, mkRewardReceivedMark, mkRewardUnitFlag
} = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { getGoodsLocName } = require("%rGui/shop/goodsView/goods.nut")
let { withTooltip, tooltipDetach, mkTooltipText } = require("%rGui/tooltip.nut")
let { infoTooltipButton } = require("%rGui/components/infoButton.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")
let { revealAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")


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
let freeRerolls = Computed(@() goodsRewardSlots.get()?.freeRerolls ?? 0)
let rewardSlots = Computed(@() servProfile.get()?.rewardSlots[previewGoods.get()?.id])
let selIndex = Watched(-1)

let AUTO_REQUEST_AFTER_ERROR_TIME = 10
let freeRefreshErrorSoon = Watched(null)
let needFreeRefreshSlots = keepref(Computed(function() {
  if (!isAttached.get()
      || freeRefreshErrorSoon.get() == previewGoods.get()?.id
      || shopPurchaseInProgress.get() == previewGoods.get()?.id
      || shopGenSlotInProgress.get() == previewGoods.get()?.id
      || rerollCost.get() == null) //this mean that slots config is exists
    return false
  return getDay(rewardSlots.get()?.time ?? 0) != serverTimeDay.get()
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

rewardSlots.subscribe(@(_) selIndex.set(-1))

let txt = @(text, ovr = {}) { rendObj = ROBJ_TEXT, text }.__update(fontSmallAccented, ovr)

function balanceButtons() {
  let currencies = []
  let list = [
    previewGoods.get()?.price.currencyId
    previewGoods.get()?.limitResetPrice.currencyId
    rerollCost.get()?.currencyId
  ]
  foreach(c in list)
    if ((c ?? "") != "" && !currencies.contains(c))
      currencies.append(c)
  return {
    watch = [previewGoods, rerollCost]
    children = mkCurrenciesBtns(currencies)
  }
}

function headerText() {
  let previewG = previewGoods.get()
  let excludeGoods = serverConfigs.get()?.allBlueprints.reduce(@(res, v, unitName) (campMyUnits.get()?[unitName] != null
    || (servProfile.get()?.blueprints[unitName] ?? 0) >= (v?.targetCount ?? 0)) ? res.$rawset(unitName, true)
      : res, {}) ?? {}
  let allLeftSlotNames = goodsRewardSlots.get()?.variants.reduce(@(res, v)
    !excludeGoods?[v[0].id] ? res.append(loc(getUnitLocId(v[0].id))) : res, []) ?? []
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
          size = [hdpx(52), hdpx(52)]
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

function mkTimeLeftInfo(ovr = {}) {
  let text = Computed(@() secondsToHoursLoc(untilNextDaySec(serverTime.get())))
  return @() {
    watch = openedGoodsId
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    children = [
      txt(loc(getSlotsTexts(openedGoodsId.get()).updateIn))
      @() txt(text.get(), { watch = text })
    ]
  }.__update(ovr)
}

function mkDisableBkgWithTooltip(isPurchased, rStyle) {
  let stateFlags = Watched(0)
  let key = {}

  return {
    key
    size = flex()
    behavior = Behaviors.Button
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() { content = mkTimeLeftInfo({ halign = ALIGN_CENTER }) })
    children = isPurchased ? mkRewardReceivedMark(rStyle) : mkRewardDisabledBkg
  }
}

function mkSlot(slotIdx, reward, rStyle) {
  let size = getRewardPlateSize(reward.slots, rStyle)
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selIndex.get() == slotIdx)
  let unit = Computed(@() serverConfigs.value?.allUnits?[reward.id])

  return @() {
    watch = [isSelected, stateFlags, rewardSlots, unit, openedUnitFromTree]
    size
    behavior = Behaviors.Button
    onElemState = @(v) rewardSlots.get()?.isPurchased ? null : stateFlags(v)
    onClick = @() rewardSlots.get()?.isPurchased
        ? null
      : isSelected.get()
        ? unitDetailsWnd({ name = reward.id })
      : selIndex.set(slotIdx)
    sound = rewardSlots.get()?.isPurchased ? {} : { click  = "click" }
    onAttach = @() openedUnitFromTree.get() == unit.get()?.name ? selIndex.set(slotIdx) : null

    children = [
      mkRewardPlateBg(reward, rStyle)
      mkRewardPlateImage(reward, rStyle)
      !isSelected.get() && !(stateFlags.get() & S_HOVER) ? null
        : mkHightlightPlate(isSelected.get(), rStyle)
      mkRewardPlateTexts(reward, rStyle)
      reward.rType == GPT_BLUEPRINT && unit.get() != null ? mkRewardUnitFlag(unit.get(), rStyle) : null
      !rewardSlots.get()?.isPurchased ? null
        : mkDisableBkgWithTooltip(rewardSlots.get()?.purchasedIdx == slotIdx, rStyle)
    ]
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14 }]
    animations = openedUnitFromTree.get() == unit.get()?.name ? rerollUnitAnim : null
  }
}

function fillRewardsByRows(goods, slotsInRowMax, style) {
  let res = []
  let rewards = goods.map(@(g) getRewardsViewInfo(g)[0])
  let totalSlots = rewards.reduce(@(tsRes, r) tsRes + r.slots, 0)
  let rowsCount = totalSlots / slotsInRowMax + ((totalSlots % slotsInRowMax) ? 1 : 0)
  if (rowsCount == 0)
    return res
  let slotsInRowMin = totalSlots / rowsCount + ((totalSlots % rowsCount) ? 1 : 0)

  local curRowSlots = slotsInRowMax
  foreach(slotIdx, r in rewards) {
    if (curRowSlots >= slotsInRowMin || curRowSlots + r.slots > slotsInRowMax) {
      res.append([])
      curRowSlots = 0
    }
    curRowSlots += r.slots
    res.top().append(mkSlot(slotIdx, r, style))
  }
  return res
}

let playPurchaseSound = @(currencyId)
  playSound(currencyId == GOLD ? "meta_products_for_gold" : "meta_products_for_money")

function purchaseSelectedSlot(id, price, currencyId) {
  if (selIndex.get() < 0) //blueprints list was refreashed behind confirm message
    return
  buy_goods_slot(id, selIndex.get(), currencyId, price)
  playPurchaseSound(currencyId)
}

function increaseLimit(id, price, currencyId) {
  increase_goods_limit(id, currencyId, price)
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

function purchaseSlotBtn(id, priceCfg) {
  let { price = 0, currencyId = "" } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  return textButtonPricePurchase(utf8ToUpper(loc("btn/buySelected")),
    mkCurrencyComp(price, currencyId),
    @() tryOpenPurchSlotMsgBox(id, price, currencyId))
}

function rerollBtn(id, priceCfg, isFree, styleOvr) {
  let { price = 0, currencyId = "" } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  return textButtonPricePurchase(utf8ToUpper(loc("btn/rerollItems")),
    isFree ? mkFreeText() : mkCurrencyComp(price, currencyId),
    @() previewGoods.get()?.id == null || (!isFree
          && showNoBalanceMsgIfNeed(price, currencyId, mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_REROLL_SLOTS, id)))
        ? null
      : rerollSlots(previewGoods.get()?.id, price, currencyId),
    styleOvr)
}

function skipWaitBtn(id, priceCfg, purchCount) {
  let { price = 0, currencyId = "", priceInc = 0 } = priceCfg
  if (price <= 0 || currencyId == "")
    return null

  let priceFinal = price + priceInc * purchCount
  return textButtonPricePurchase(utf8ToUpper(loc("btn/skipWait")),
    mkCurrencyComp(priceFinal, currencyId),
    @() openSelGoodsMsgBoxPurch(loc("shop/needMoneyQuestion_wait"), priceFinal, currencyId, increaseLimit,
      mkBqPurchaseInfo(PURCH_SRC_SHOP, PURCH_TYPE_GOODS_LIMIT, id)))
}

let buttons = @(hasRerollAnim) function() {
  let res = {
    watch = [shopGenSlotInProgress, shopPurchaseInProgress, previewGoods, rewardSlots, rerollCost,
      goodsLimitReset, serverTimeDay, freeRerolls
    ]
    size = [SIZE_TO_CONTENT, defButtonHeight]
  }
  if (previewGoods.get() == null)
    return res

  let { id, price, limitResetPrice } = previewGoods.get()
  let { isPurchased = false, usedFree = 0 } = rewardSlots.get()
  let isFree = usedFree < freeRerolls.get()
  return res.__update({
    flow = FLOW_HORIZONTAL
    gap = buttonsHGap
    valign = ALIGN_CENTER
    children = shopGenSlotInProgress.get() == id ? null
      : shopPurchaseInProgress.get() ? spinner
      : isPurchased
        ? [
            mkTimeLeftInfo()
            skipWaitBtn(id, limitResetPrice,
              serverTimeDay.get() != getDay(goodsLimitReset.get()?[id].time ?? 0) ? 0 : goodsLimitReset.get()?[id].count)
          ]
      : [
          rerollBtn(id, rerollCost.get(), isFree, hasRerollAnim ? rerollButtonStyle : PRIMARY)
          purchaseSlotBtn(id, price)
        ]
  })
}

function content() {
  let isActual = Computed(@() shopGenSlotInProgress.get() != previewGoods.get()?.id
    && getDay(rewardSlots.get()?.time ?? 0) == serverTimeDay.get())
  return function() {
    let { goods = [], isPurchased = false } = rewardSlots.get()
    let style = goods.len() > MAX_BIG_SLOTS ? REWARD_STYLE_SMALL : REWARD_STYLE_MEDIUM
    let { boxSize, boxGap } = style
    let slotsInRow = (maxWndWidth + boxGap) / (boxSize + boxGap)
    let rows = !isActual.get() || shopGenSlotInProgress.get() ? []
      : fillRewardsByRows(goods, slotsInRow, style)
    let curUnit = openedUnitFromTree.get()
    let hasAnySlot = rows.len() > 0
    let hasRerollHint = !isPurchased && hasAnySlot && curUnit != null
      && !goods.reduce(@(res, g) res.$rawset(g[0].id, true), {})?[curUnit]

    return {
      watch = [rewardSlots, isActual, shopGenSlotInProgress, openedGoodsId, openedUnitFromTree]
      size = flex()
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = blockGap
      children = [
        {
          size = [SIZE_TO_CONTENT, max(2, rows.len()) * (boxSize + boxGap) - boxGap]
          flow = FLOW_VERTICAL
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          gap = boxGap
          children = shopGenSlotInProgress.get() ? spinner
            : rows.map(@(children) {
                flow = FLOW_HORIZONTAL
                gap = boxGap
                children
              })
        }
        isPurchased ? null
          : txt(hasAnySlot ? utf8ToUpper(loc("shop/pickOneItem")) : utf8ToUpper(loc(getSlotsTexts(openedGoodsId.get()).missing)))
        hasAnySlot ? buttons(hasRerollHint) : null
        {
          size = [flex(), hdpx(24)]
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
