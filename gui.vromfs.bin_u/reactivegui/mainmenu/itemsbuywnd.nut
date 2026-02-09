from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { G_ITEM } = require("%appGlobals/rewardType.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isOpenedItemWnd, closeItemWnd, getCheapestGoods, itemsForPurchaseIds } = require("itemsBuyState.nut")
let { warningTextColor } = require("%rGui/style/stdColors.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { gamercardHeight } = require("%rGui/style/gamercardStyle.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkColoredGradientY, simpleHorGrad } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { mkWaitDimmingSpinner } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPricePurchase, textButtonCommon, textButtonInactive } = require("%rGui/components/textButton.nut")
let { shopPurchaseInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { tinyLimitReachedPlate } = require("%rGui/shop/goodsView/sharedParts.nut")
let { mkImg } = require("%rGui/shop/goodsView/goodsConsumables.nut")
let { purchaseGoods } = require("%rGui/shop/purchaseGoods.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("%rGui/shop/unseenPurchasesState.nut")
let openBarterWnd = require("itemsConvertWnd.nut")


const btnHeight = hdpx(90)
let borderWidth = hdpx(2)
let bgSize = [hdpxi(296), hdpxi(330)]
let priceBgGrad = mkColoredGradientY(0xFF72A0D0, 0xFF588090, 12)

let barterBtnOvr = { ovr = { size = [bgSize[0] + borderWidth * 2, btnHeight], minWidth = 0 } }
let barterBtnText = utf8ToUpper(loc("item/conversion/btn_barter"))

let animTrigger = @(id) $"changeItemCount_{id}"

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != G_ITEM)
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))

let defImageItemOpt = { size = hdpxi(250), pos = [hdpx(60), -hdpx(15)]}
let largeImageItemOptDict = {
  firework_kit = { size = hdpxi(350), pos = [hdpx(60), -hdpx(15)]}
}

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFFEDE4C7
}

let header = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  text = utf8ToUpper(loc("item/buyTitle"))
}.__update(fontMedium)


let mkPricePlate = @(goods, hasLimitReached) {
  size = const [flex(), btnHeight]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = priceBgGrad
  children = hasLimitReached ? tinyLimitReachedPlate
    : goods.price > 0
      ? textButtonPricePurchase(null,
          mkCurrencyComp(goods.price, goods.currencyId),
          @() null,
          { ovr = { size = flex(), minWidth = 0, behavior = null } })
    : null
}

let gamercardPannel = @(currencys) @() {
  watch = currencys
  size = [flex(), gamercardHeight]
  vplace = ALIGN_TOP
  children = [
    backButton(closeItemWnd)
    mkCurrenciesBtns(currencys.get())
  ]
}

let cardTitle = @(id) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_LEFT
  padding = hdpx(30)
  text = utf8ToUpper(loc($"item/{id}"))
}.__update(fontVeryTinyAccented)

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
  let { size, pos } = largeImageItemOptDict?[id] ?? defImageItemOpt

  return {
    size = flex()
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

let itemSlot = @(goodsInfo, count, limit, sf) {
  rendObj = ROBJ_SOLID
  color = 0xFF645858
  borderColor = 0x40FFFFFF
  borderWidth
  padding = hdpx(2)
  children = [
    sf & S_HOVER ? bgHiglight : null
    {
      rendObj = ROBJ_IMAGE
      size = bgSize
      image = Picture($"ui/gameuiskin/shop_bg_slot.avif:{bgSize[0]}:{bgSize[1]}:P")
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        cardHeader(goodsInfo.itemId)
        {
          size = flex()
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
            size = [flex(), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            color = limit <= 0 || limit > count.get() ? 0xFFFFFFFF : warningTextColor
            text = utf8ToUpper(limit <= 0 ? loc("item/balance", {count = count.get()})
              : loc("item/balanceWithLimit", { count = count.get(), limit }))
            transform = { pivot = [0, 0.5] }
            animations = [{
              prop = AnimProp.scale, from = [1,1], to = [1.3, 1.3],
              duration = 1, trigger = animTrigger(goodsInfo.itemId), easing = DoubleBlink
            }]
          }.__update(fontVeryTinyAccentedShaded)
        }
      ]
    }
  ]
}

function itemCard(goodsInfo, count, hasLimitReached) {
  let stateFlags = Watched(0)
  let hasSpinner = Computed(@() shopPurchaseInProgress.get() == goodsInfo.id)

  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    flow = FLOW_VERTICAL
    sound = { click  = "click" }
    transform = { scale = (stateFlags.get() & S_ACTIVE) ? [0.95, 0.95] : [1, 1] }
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
          mkWaitDimmingSpinner(hasSpinner)
        ]
      }
      mkPricePlate(goodsInfo, hasLimitReached)
    ]
  }
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
    count.subscribe(@(_) anim_start(animTrigger(g.itemId)))
    let hasLimitReached = Computed(function() {
      let { limit = 0 } = campConfigs.get()?.allItems[g.itemId]
      return limit > 0 && limit <= count.get()
    })
    return @() {
      watch = [hasBarter, hasLimitReached]
      flow = FLOW_VERTICAL
      gap = hdpx(12)
      children = [
        itemCard(g, count, hasLimitReached.get())
        !hasBarter.get() ? null
          : hasLimitReached.get() ? textButtonInactive(barterBtnText, @() null, barterBtnOvr)
          : textButtonCommon(barterBtnText, @() openBarterWnd(g.itemId), barterBtnOvr)
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
    size = flex()
    padding = saBordersRv

    onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)

    children = [
      gamercardPannel(currencysIds)
      {
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = hdpx(30)
        children = [
          header
          mkGoods(goodsForPurchase)
        ]
      }
    ]
    animations = wndSwitchAnim
  })
}

registerScene("itemsBuyWnd", mkContent, closeItemWnd, isOpenedItemWnd)