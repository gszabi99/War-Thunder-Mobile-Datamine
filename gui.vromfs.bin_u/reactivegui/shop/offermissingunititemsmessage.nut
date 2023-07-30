from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { shopGoods } = require("shopState.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { itemsCfgOrdered } = require("%appGlobals/itemsState.nut")
let { items } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let itemsPurchaseMessage = require("itemsPurchaseMessage.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkCustomMsgBoxWnd, msgBoxText } = require("%rGui/components/msgBox.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")


let wndWidth = hdpx(1500)
let wndHeight = hdpx(700)
let itemsGap = hdpx(50)

let WND_UID = "offerMissingUnitItemsMessage" //we no need several such messages at all.
let close = @() removeModalWindow(WND_UID)
let skipForUnitName = mkWatched(persist, "skipForUnitName", null)

isInBattle.subscribe(@(_) skipForUnitName(null))

let mkItemsList = @(orderedItems) {
  flow = FLOW_HORIZONTAL
  gap = itemsGap
  children = orderedItems.map(@(i) mkCurrencyComp(i.count, i.itemId, CS_INCREASED_ICON))
}

let msgWithItemsList = @(msg, counts, countKey) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  halign = ALIGN_CENTER
  children = [
    msgBoxText(msg, { size = [flex(), SIZE_TO_CONTENT] })
    mkItemsList(counts.map(@(c) { itemId = c.itemId, count = c[countKey] }))
  ]
}

let mkMsgContent = @(missItems, unit) function() {
  return {
    watch = missItems
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(30)
    children = [
      msgWithItemsList(
        loc("msg/requiredItemsForBattle",
          { unit = colorize(userlogTextColor, loc(getUnitLocId(unit.name))) }),
        missItems.value,
        "reqItems")
      msgWithItemsList(loc("msg/currentItemsForBattle"), missItems.value, "hasItems")
      msgBoxText(loc("msg/canReplenishItemsInShop"), { size = [flex(), SIZE_TO_CONTENT] })
    ]
  }
}

let mkMsgButtons = @(missItems, toBattle) [
  textButtonCommon(utf8ToUpper(loc("msgbox/btn_replenish")),
    function() {
      close()
      itemsPurchaseMessage(missItems.value?[0].itemId)
    })
  textButtonPrimary(utf8ToUpper(loc("mainmenu/toBattle/short")),
    function() {
      close()
      toBattle()
    })
]

let mkMissingItemsComp = @(unit) Computed(function() {
  let res = []
  let unitItemsPerUse = unit?.itemsPerUse ?? 0
  foreach (cfg in itemsCfgOrdered.value) {
    let { battleLimit = 0, itemsPerUse = 0, name = "" } = cfg
    if (battleLimit <= 0)
      continue
    let perUse = itemsPerUse <= 0 ? unitItemsPerUse : itemsPerUse
    let reqItems = perUse * battleLimit
    let hasItems = items.value?[name].count ?? 0
    if (reqItems <= hasItems)
      continue
    let goods = shopGoods.value.findvalue(@(goods) (name in goods?.items) && (goods?.price.price ?? 0) > 0)
    let { currencyId = "", price = 0 } = goods?.price
    if (price > 0 && (balance.value?[currencyId] ?? 0) >= price)
      res.append({ itemId = name, reqItems, hasItems, goods })
  }
  return res
})

let function offerMissingUnitItemsMessage(unit, toBattle) {
  close()
  if (unit == null || skipForUnitName.value == unit.name) {
    toBattle()
    return
  }
  let missItems = mkMissingItemsComp(unit)
  if (missItems.value.len() == 0) {
    toBattle()
    return
  }

  skipForUnitName(unit.name)
  missItems.subscribe(@(v) v.len() == 0 ? close() : null)

  addModalWindow(bgShaded.__merge({
    key = WND_UID
    size = flex()
    children = mkCustomMsgBoxWnd(loc("header/notFullBattleItems"),
      mkMsgContent(missItems, unit),
      mkMsgButtons(missItems, toBattle),
      { size = [wndWidth, wndHeight]
    })
    animations = wndSwitchAnim
  }))
}

return offerMissingUnitItemsMessage
