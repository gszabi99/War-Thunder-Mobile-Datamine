from "%globalsDarg/darg_library.nut" import *
let { buy_decal, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_DECALS, PURCH_TYPE_DECAL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { availableDecals, decalsCfg } = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let { isCustomizationWndAttached } = require("%rGui/unitDetails/unitDetailsState.nut")
let { mkDecalIcon } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")


let decalName = mkWatched(persist, "decalName", null)
let decalPrice = Computed(@() decalsCfg.get()?[decalName.get()].price)
let needShowWnd = keepref(Computed(@() decalPrice.get()
  && decalName.get() not in availableDecals.get()
  && isCustomizationWndAttached.get()))

let close = @() decalName.set(null)

let wndContent = @() {
  watch = decalName
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_CENTER
      text = loc("mainmenu/customization/decals/submitPurchace")
    }.__update(fontSmallAccented)
    mkDecalIcon(decalName.get())
  ]
}

function openImpl() {
  if (decalPrice.get() == null || decalName.get() == null)
    return

  let name = decalName.get()
  let { currencyId, price } = decalPrice.get()
  openMsgBoxPurchase({
    text = wndContent,
    title = loc($"decals/{name}")
    price = { currencyId, price },
    purchase = @() buy_decal(name, currencyId, price, "closebuyDecalWnd"),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_DECALS, PURCH_TYPE_DECAL, name)
    onCancel = close
  })
}

registerHandler("closebuyDecalWnd", @(_) close())

if (needShowWnd.get())
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : close())

return @(id) decalName.set(id)
