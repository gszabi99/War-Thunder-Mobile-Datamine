from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import defer
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/campaign.nut" import campConfigs
from "%appGlobals/pServer/pServerApi.nut" import shopPurchaseInProgress, toggle_item_activation,
  itemActivationInProgress
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/rewardType.nut" import G_ITEM
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
from "%rGui/components/spinner.nut" import mkWaitDimmingSpinner
from "%rGui/components/activationCheckbox.nut" import mkActivationCheckbox
from "%rGui/components/textButton.nut" import textButtonPricePurchase, textButtonCommon, textButtonInactive
from "%rGui/mainMenu/gamercard.nut" import mkCurrenciesBtns
from "%rGui/navState.nut" import registerScene
from "%rGui/shop/goodsView/goodsConsumables.nut" import mkImg
from "%rGui/shop/goodsView/sharedParts.nut" import mkBgParticles, tinyLimitReachedPlate
from "%rGui/shop/purchaseGoods.nut" import purchaseGoods
from "%rGui/shop/shopState.nut" import shopGoods
from "%rGui/shop/unseenPurchasesState.nut" import addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler,
  markPurchasesSeen
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkColoredGradientY, simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim, mkPressTransitionScale
from "%rGui/style/stdColors.nut" import warningTextColor
from "itemsBuyState.nut" import isOpenedItemWnd, closeItemWnd, getCheapestGoods, itemsForPurchaseIds
import "itemsConvertWnd.nut" as openBarterWnd


const btnHeight = hdpx(90)
const borderWidth = hdpx(2)
let bgSize = [hdpxi(370), hdpxi(412)]
let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)

let barterBtnOvr = { ovr = { size = [bgSize[0] + borderWidth * 2, btnHeight], minWidth = 0 } }
let barterBtnText = utf8ToUpper(loc("item/conversion/btn_barter"))

let animTrigger = @(id) $"changeItemCount_{id}"

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != G_ITEM)
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

let defImageItemOpt = { size = hdpxi(350), pos = const [hdpx(50), 0]}
let largeImageItemOptDict = {
  firework_kit = { pos = const [hdpx(60), -hdpx(15)]}
  spare = { pos = const [hdpx(70), 0]}
}

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0xFFEDE4C7
}

let header = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  text = utf8ToUpper(loc("item/buyTitle"))
}.__update(fontMedium)


let mkPricePlate = @(goods, hasLimitReached) {
  size = const [FLEX, btnHeight]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = priceBgGrad
  children = hasLimitReached ? tinyLimitReachedPlate
    : goods.price > 0
      ? textButtonPricePurchase(null,
          mkCurrencyComp(goods.price, goods.currencyId),
          @() null,
          { ovr = { size = FLEX, minWidth = 0, behavior = null } })
    : null
}

let gamercardPannel = @(currencies) headerGradientWithRightBlock(
  [
    backButton(closeItemWnd)
    header
  ],
  @() {
    watch = currencies
    children = mkCurrenciesBtns(currencies.get())
  })

let cardTitle = @(id) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  padding = hdpx(30)
  text = utf8ToUpper(loc($"item/{id}"))
}.__update(fontVeryTinyAccentedShaded)

let cardHeader = @(id) {
  padding = hdpx(10)
  valign = ALIGN_CENTER
  size = FLEX_H
  maxHeight = evenPx(60)
  children = cardTitle(id)
}

function itemImg(reward) {
  if (reward == null)
    return null

  let { id, count } = reward
  let { size = defImageItemOpt.size, pos = defImageItemOpt.pos } = largeImageItemOptDict?[id] ?? {}

  return {
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      mkImg(id, size, pos)
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        padding = hdpx(15)
        children = {
          rendObj = ROBJ_TEXT
          color = 0x90909090
          text = count
        }.__update(fontWtBig)
      }
    ]
  }
}

function itemSlot(goodsInfo, count, limit, sf) {
  let countChangeAnim = [{
    prop = AnimProp.scale, from = const [1,1], to = const [1.3, 1.3],
    duration = 1, trigger = animTrigger(goodsInfo.itemId), easing = DoubleBlink
  }]
  return {
    rendObj = ROBJ_SOLID
    color = 0xFF645858
    borderColor = 0x40FFFFFF
    borderWidth
    padding = hdpx(2)
    children = [
      sf & S_HOVER ? bgHiglight : null
      mkBgParticles(bgSize)
      {
        rendObj = ROBJ_IMAGE
        size = bgSize
        image = Picture($"ui/gameuiskin/shop_bg_slot.avif:{bgSize[0]}:{bgSize[1]}:P")
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        children = [
          cardHeader(goodsInfo.itemId)
          {
            size = FLEX
            children = itemImg(goodsInfo.goods.rewards[0])
          }
          @() {
            watch = count
            size = FLEX_H
            rendObj = ROBJ_IMAGE
            flipX = true
            flow = FLOW_VERTICAL
            image = simpleHorGrad
            color = 0x80000000
            padding = hdpx(10)
            children = {
              size = const [FLEX, SIZE_TO_CONTENT]
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              color = limit <= 0 || limit > count.get() ? 0xFFFFFFFF : warningTextColor
              text = utf8ToUpper(limit <= 0 ? loc("item/balance", {count = count.get()})
                : loc("item/balanceWithLimit", { count = count.get(), limit }))
              transform = const { pivot = [0, 0.5] }
              animations = countChangeAnim
            }.__update(fontVeryTinyAccentedShaded)
          }
        ]
      }
    ]
  }
}

function itemCard(goodsInfo, count, hasLimitReached) {
  let stateFlags = Watched(0)
  let hasSpinner = Computed(@() shopPurchaseInProgress.get() == goodsInfo.id)
  let waitSpinner = mkWaitDimmingSpinner(hasSpinner)

  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    flow = FLOW_VERTICAL
    sound = const { click  = "click" }
    onElemState = @(sf) stateFlags.set(sf)
    onClick = hasLimitReached ? null : @() purchaseGoods(goodsInfo.id)
    gap = -hdpx(2)
    children = [
      @() {
        watch = campConfigs
        children = [
          itemSlot(
            goodsInfo,
            count,
            campConfigs.get().allItems?[goodsInfo.itemId].limit ?? 0,
            stateFlags.get())
          waitSpinner
        ]
      }
      mkPricePlate(goodsInfo, hasLimitReached)
    ]
    ...mkPressTransitionScale(stateFlags.get())
  }
}

function mkUseCheckbox(itemId) {
  let isDisabled = Computed(@() servProfile.get()?.items[itemId].isDisabled ?? false)
  let hasSpinner = Computed(@() itemActivationInProgress.get() == itemId)
  return mkActivationCheckbox(isDisabled, hasSpinner, @() toggle_item_activation(itemId, !isDisabled.get()))
}

let mkGoods = @(goods) @() {
  watch = goods
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  gap = hdpx(50)
  children = goods.get().map(function(g) {
    let hasBarter = Computed(@() null != (campConfigs.get()?.itemConversionsCfg ?? {})
      .findvalue(@(items) null != items.findindex(@(_, itemId) itemId == g.itemId)))
    let count = Computed(@() servProfile.get()?.items[g.itemId].count ?? 0)
    let startCountAnim = @(_) anim_start(animTrigger(g.itemId))
    let hasLimitReached = Computed(function() {
      let { limit = 0 } = campConfigs.get()?.allItems[g.itemId]
      return limit > 0 && limit <= count.get()
    })
    let isOptional = Computed(@() campConfigs.get()?.allItems?[g.itemId].isOptional ?? false)
    let useCheckbox = mkUseCheckbox(g.itemId)
    let inactiveBarterBtn = textButtonInactive(barterBtnText, @() null, barterBtnOvr)
    let commonBarterBtn = textButtonCommon(barterBtnText, @() openBarterWnd(g.itemId), barterBtnOvr)
    return @() {
      watch = [hasBarter, hasLimitReached, isOptional]
      key = count
      onAttach = @() count.subscribe(startCountAnim)
      onDetach = @() count.unsubscribe(startCountAnim)
      flow = FLOW_VERTICAL
      gap = hdpx(12)
      children = [
        itemCard(g, count, hasLimitReached.get())
        isOptional.get() ? useCheckbox : null
        !hasBarter.get() ? null
          : hasLimitReached.get() ? inactiveBarterBtn
          : commonBarterBtn
      ]
    }
  })
}

let wndKey = {}
function mkContent() {
  let goodsForPurchase = Computed(@() itemsForPurchaseIds.get().reduce(function(res, name) {
    let goods = getCheapestGoods(shopGoods.get(),
      @(g) g.rewards.len() == 1 && g.rewards[0].id == name && g.rewards[0].gType == G_ITEM)
    if (goods == null)
      return res
    let { price = 0, currencyId = "" } = goods?.price
    return res.append({ id = goods.id, goods, price, currencyId, itemId = name })
  }, []))

  let currencysIds = Computed(function() {
    let res = {}
    foreach (g in goodsForPurchase.get())
      res[g.currencyId] <- true
    return res.keys()
  })
  return bgShaded.__merge({
    key = wndKey
    size = FLEX
    padding = saBordersRv

    onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)

    children = [
      gamercardPannel(currencysIds)
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = mkGoods(goodsForPurchase)
      }
    ]
    animations = wndSwitchAnim
  })
}

registerScene("itemsBuyWnd", mkContent, closeItemWnd, isOpenedItemWnd)