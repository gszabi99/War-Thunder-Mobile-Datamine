from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { shopGoods } = require("shopState.nut")
let { balanceWp, balanceGold, WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { orderByItems } = require("%appGlobals/itemsState.nut")
let { shopPurchaseInProgress, buy_goods } = require("%appGlobals/pServer/pServerApi.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkCustomMsgBoxWnd, msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { mkCurrencyComp, CS_INCREASED_ICON, CS_NO_BALANCE } = require("%rGui/components/currencyComp.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { textButtonPurchase } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let closeWndBtn = require("%rGui/components/closeWndBtn.nut")

let wndWidth = hdpx(1500)
let wndHeight = hdpx(700)
let itemsGap = hdpx(50)

let WND_UID = "itemsPurchaseWindow" //we no need several such messages at all.
let close = @() removeModalWindow(WND_UID)

shopPurchaseInProgress.subscribe(@(v) v == null ? close() : null)

let btnClose = closeWndBtn(close)

let function mkItemsRewards(goods) {
  let { items = {} } = goods
  if (items.len() == 0)
    return null
  let list = []
  foreach (itemId, count in items)
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

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = 0xFFC0C0C0
  text
}.__update(fontSmall)

let costMessage = @(goods, balance) function() {
  let { currencyId, price } = goods.price
  local locId = "shop/willCostYou"
  let replaceTable = { ["{price}"] = mkCurrencyComp(price, currencyId) } //warning disable: -forgot-subst
  if (price > balance) {
    locId = "shop/willCostYouButNotEnough"
    replaceTable["{priceDiff}"] <- mkCurrencyComp(price - balance, currencyId, CS_NO_BALANCE) //warning disable: -forgot-subst
  }
  return {
    flow = FLOW_HORIZONTAL
    children = mkTextRow(loc(locId), mkText, replaceTable)
  }
}

let mkMsgContent = @(goods, balance) {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(50)
  children = [
    msgBoxText(loc("msg/doYouWantPurchase"), { size = [flex(), SIZE_TO_CONTENT] })
    mkItemsRewards(goods)
    costMessage(goods, balance)
  ]
}

let mkPurchaseBtn = @(goods)
  textButtonPurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
    function() {
      let { currencyId, price } = goods.price
      if (!showNoBalanceMsgIfNeed(price, currencyId, close))
        buy_goods(goods.id, currencyId, price)
    })

let mkMsButtons = @(goods)
  mkSpinnerHideBlock(Computed(@() shopPurchaseInProgress.value != null),
    mkPurchaseBtn(goods),
    {
      size = [SIZE_TO_CONTENT, defButtonHeight]
      valign = ALIGN_CENTER
    })

let function itemsPurchaseMessage(itemId) {
  close()
  let goodsW = Computed(@() shopGoods.value.findvalue(@(goods) (itemId in goods?.items) && (goods?.price.price ?? 0) > 0))
  if (goodsW.value == null) {
    openMsgBox({ text = loc("msg/notAvailablePurchaseYet", { item = loc($"item/{itemId}") }) })
    return
  }
  goodsW.subscribe(@(v) v == null ? close() : null)
  let balanceW = Computed(@() goodsW.value?.price.currencyId == WP ? balanceWp.value
    : goodsW.value?.price.currencyId == GOLD ? balanceGold.value
    : 0)

  addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = flex()
    children = @() {
      watch = [goodsW, balanceW]
      gap = hdpx(10)
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = goodsW.value == null ? null
        : [
            mkCustomMsgBoxWnd(null, mkMsgContent(goodsW.value, balanceW.value),
              [mkMsButtons(goodsW.value)],
              { size = [wndWidth, wndHeight] })
            btnClose
          ]
    }
    animations = wndSwitchAnim
  }))
}

return itemsPurchaseMessage
