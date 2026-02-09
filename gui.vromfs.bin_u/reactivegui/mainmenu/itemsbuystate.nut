from "%globalsDarg/darg_library.nut" import *
let { specialEventGamercardItems } = require("%rGui/event/eventState.nut")
let { itemsOrder } = require("%appGlobals/itemsState.nut")
let { isItemAllowedForUnit } = require("%rGui/unit/unitItemAccess.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")

let isOpenedItemWnd = mkWatched(persist, "isOpenedItemWnd", false)
let closeItemWnd = @() isOpenedItemWnd.set(false)

let itemsForPurchaseIds = Computed(function() {
  let res = clone itemsOrder.get()
    .filter(function(v) {
      if (curSlots.get().len() == 0)
        return isItemAllowedForUnit(v, hangarUnit.get()?.name ?? "")
      foreach (slot in curSlots.get())
        if (isItemAllowedForUnit(v,slot.name))
          return true
      return false
    })
  if (!specialEventGamercardItems.get())
    return res
  foreach (spItem in specialEventGamercardItems.get())
    res.append(spItem.itemId)
  return res
})

function getCheapestGoods(allGoods, isFit) {
  let byCurrency = {}
  foreach (goods in allGoods) {
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


return {
  isOpenedItemWnd
  closeItemWnd
  getCheapestGoods
  itemsForPurchaseIds
}
