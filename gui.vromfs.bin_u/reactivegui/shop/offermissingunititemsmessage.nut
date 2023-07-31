from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { shopGoods } = require("shopState.nut")
let { itemsCfgOrdered, orderByItems } = require("%appGlobals/itemsState.nut")
let { items } = require("%appGlobals/pServer/campaign.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonBattle, mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, PURCHASE } = require("%rGui/components/buttonStyles.nut")
let { decorativeLineBgMW, bgMW } = require("%rGui/style/stdColors.nut")
let { shopPurchaseInProgress, buy_goods } = require("%appGlobals/pServer/pServerApi.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { mkCurrencyComp, CS_INCREASED_ICON, mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { addCustomUnseenPurchHandler, removeCustomUnseenPurchHandler, markPurchasesSeen
} = require("unseenPurchasesState.nut")
let { balanceWp, balanceGold } = require("%appGlobals/currenciesState.nut")
let { CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { ceil } = require("%sqstd/math.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")

let itemsGap = hdpx(50)
let itemImageSize = hdpxi(80)

let itemBuyingWidth = hdpx(1000)
let itemBuyingHeaderHeight = sh(8)
let insideIndent = hdpxi(50)

let itemSize = hdpx(160)

let WND_UID = "itemWnd"
let close = @() removeModalWindow(WND_UID)

let decorativeLine = @(){
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = decorativeLineBgMW
  size = [ itemBuyingWidth, hdpx(6) ]
}

let itemBuyingHeader = @(unit){
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = bgMW
  size = [ itemBuyingWidth, itemBuyingHeaderHeight ]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text =  loc("header/notFullBattleItems", {unitName = getPlatoonOrUnitName(unit, loc)?? ""})
  }.__update(fontMedium)
}

let function getCheapestGoods(allGoods, isFit) {
  let byCurrency = {}
  foreach(goods in allGoods) {
    if (!isFit(goods))
      continue
    let { currencyId = "", price = 0 } = goods?.price
    if (price <= 0)
      continue
    let foundPrice = byCurrency?[currencyId].price.price
    if (foundPrice == null || foundPrice > price)
      byCurrency[currencyId] <- goods
  }
  return byCurrency?.wp ?? byCurrency.findvalue(@(_) true)
}

let mkMissingItemsComp = @(unit) Computed(function() {
  let res = []
  let unitItemsPerUse = unit?.itemsPerUse ?? 0
  let consumablesList = itemsCfgOrdered.value.filter(@(i) i.name != "spare")
  foreach (cfg in consumablesList) {
    let { battleLimit = 0, itemsPerUse = 0, name = "" } = cfg
    if (battleLimit <= 0)
      continue
    let perUse = itemsPerUse <= 0 ? unitItemsPerUse : itemsPerUse
    let reqItems = perUse * battleLimit
    let hasItems = items.value?[name].count ?? 0
    if (reqItems <= hasItems)
      continue
    let goods = getCheapestGoods(shopGoods.value, @(goods) (goods?.items[name] ?? 0) > 0)
    let { price = 0 } = goods?.price
    if (price > 0)
      res.append({ itemId = name, reqItems, hasItems, goods })
  }
  return res
})

let function mkItemsRewards(goods) {
  if (goods.items.len() == 0)
    return null
  let list = []
  foreach (itemId, count in goods.items)
    if (count > 0)
      list.append({ itemId, count,
        order = orderByItems?[itemId] ?? orderByItems.len()
      })
  list.sort(@(a, b) a.order <=> b.order)
  return {
    flow = FLOW_HORIZONTAL
    gap = itemsGap
    children = list.map(@(i) mkCurrencyComp(i.count, i.itemId, CS_INCREASED_ICON))
  }
}


let function mkPurchaseBtn(goods, toBattle) {
  let { currencyId, price } = goods.price
  let balance = currencyId == "wp" ? balanceWp : balanceGold
  let textColor = CS_GAMERCARD.__merge({
    textColor = balance.value < price ? 0xFFFF0000 : 0xFFFFFFFF
  })
  let stylePurchase = mergeStyles(PURCHASE,textColor)
  return [
    textButtonBattle(utf8ToUpper(loc("mainmenu/toBattle/short")),
      function() {
        close()
        toBattle()
    })
    mkCustomButton(mkCurrencyComp(price, currencyId),
      function() {
        if (!showNoBalanceMsgIfNeed(price, currencyId, close))
          buy_goods(goods.id, currencyId, price)
    }, stylePurchase)
  ]
}

let mkMsButtons = @(goods, toBattle)
  mkSpinnerHideBlock(Computed(@() shopPurchaseInProgress.value != null),
    mkPurchaseBtn(goods, toBattle),
    {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(130)
    })

let countText = @(count){
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
  text = count
}.__update(fontTiny)

let function mkMsgContent(item, needSwitchAnim, toBattle) {
  return {
    key = item.itemId
    rendObj = ROBJ_9RECT
    image = gradTranspDoubleSideX
    padding = [ insideIndent, 0 ]
    size = [ flex(), SIZE_TO_CONTENT ]
    texOffs = [0 , gradDoubleTexOffset]
    screenOffs = [0, hdpx(120)]
    color = bgMW
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      @(){
        pos = [-hdpx(35), 0]
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        padding = [ insideIndent*2, 0 ]
        children = [
          @() {
            size = [hdpx(160), hdpx(160)]
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/images/offer_item_slot_bg.avif:{itemSize}:{itemSize}")
            children = [
              mkCurrencyImage(item.itemId , itemImageSize, {
                margin = hdpx(10)
              })
              {
                size = [itemSize, hdpx(35)]
                vplace = ALIGN_BOTTOM
                valign = ALIGN_CENTER
                halign = ALIGN_RIGHT
                rendObj = ROBJ_SOLID
                color = 0x80000000
                flow = FLOW_HORIZONTAL
                gap = hdpx(5)
                children = countText(item.hasItems)
              }
            ]
          }
          {
            margin = [0, hdpx(25),0,hdpx(25)]
            size = [hdpx(80), hdpx(60)]
            valign = ALIGN_CENTER
            rendObj = ROBJ_IMAGE
            image = Picture($"!ui/gameuiskin#arrow_icon.svg:{hdpx(80)}:{hdpx(60)}:P")
          }
          {
            size = [hdpx(105), hdpx(105)]
            rendObj = ROBJ_BOX
            color = 0xFFFFFFFF
            borderColor = 0xFFFFFFFF
            borderWidth = 2
            flow = FLOW_VERTICAL
            children = [
              {
                rendObj = ROBJ_IMAGE
                size = [hdpx(105), hdpx(105)]
                image = Picture($"!ui/gameuiskin#hud_consumable_repair.svg:{itemSize}:{itemSize}:P")
              }
              @() {
                size = [flex(), hdpx(30)]
                vplace = ALIGN_BOTTOM
                valign = ALIGN_CENTER
                halign = ALIGN_CENTER
                rendObj = ROBJ_SOLID
                color = 0x80000000
                flow = FLOW_HORIZONTAL
                gap = hdpx(5)
                children = countText("".concat(ceil(item.hasItems*100/item.reqItems).tostring() , "/10"))
              }
            ]
          }
        ]
      }
      @() {
        pos = [hdpx(250), 0]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        children = [
          msgBoxText(loc("msg/doYouWantPurchase"), { size = [hdpx(300), SIZE_TO_CONTENT] }.__update(fontTiny))
          mkItemsRewards(item.goods)
        ]
      }
      mkMsButtons(item.goods, toBattle)
    ]
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [0, 0], to = [hdpx(100), 0],
        duration = 0.5, easing = CosineFull, playFadeOut = true}
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5
         easing = OutQuad, play = needSwitchAnim}
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3,
        easing = OutQuad, playFadeOut = true}
    ]
  }
}

let isPurchNoNeedResultWindow = @(purch) purch?.source == "purchaseInternal"
  && null == purch.goods.findvalue(@(g) g.gType != "item" && g.gType != "currency" && g.gType != "premium")
let markPurchasesSeenDelayed = @(purchList) defer(@() markPurchasesSeen(purchList.keys()))


let function itemsPurchaseMessage(missItems, toBattle, unit) {
  let function content(){
    let itemToShow = Computed(@() missItems.value?[0])
    local needSwitchAnim = false
    return {
      watch = [itemToShow, missItems]
      size = [flex(), SIZE_TO_CONTENT]
      function onAttach() {
        needSwitchAnim = true
      }
      children = itemToShow.value == null ? null
        : mkMsgContent(itemToShow.value, needSwitchAnim, toBattle)
    }
  }
  addModalWindow(bgShaded.__merge({
    key = WND_UID
    onAttach = @() addCustomUnseenPurchHandler(isPurchNoNeedResultWindow, markPurchasesSeenDelayed)
    onDetach = @() removeCustomUnseenPurchHandler(markPurchasesSeenDelayed)
    size = flex()
    children = @() {
      flow = FLOW_VERTICAL
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = [ itemBuyingWidth, SIZE_TO_CONTENT ]
      children =
        [
          decorativeLine
          itemBuyingHeader(unit)
          content
          decorativeLine
        ]
    }
    animations = wndSwitchAnim
  }))
}


let function offerMissingUnitItemsMessage(unit, toBattle) {
  if (unit == null) {
    toBattle()
    return
  }

  let missItems = mkMissingItemsComp(unit)
  if (missItems.value.len() == 0) {
    toBattle()
    return
  }

  missItems.subscribe(@(v) v.len() == 0 ? close() : null)
  itemsPurchaseMessage(missItems, toBattle, unit)

}

return offerMissingUnitItemsMessage
