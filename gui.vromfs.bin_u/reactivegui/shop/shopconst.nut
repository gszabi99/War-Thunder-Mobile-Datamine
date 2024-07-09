let shopCategories = [
  "SC_OTHER"
  "SC_FEATURED"
  "SC_GOLD"
  "SC_WP"
  "SC_PREMIUM"
  "SC_CONSUMABLES"
  "SC_PLATINUM"
].map(@(v, i) [ v, 100 + i ]).totable()

let goodsTypes = [
  "SGT_UNKNOWN"
  "SGT_GOLD"
  "SGT_WP"
  "SGT_PREMIUM"
  "SGT_UNIT"
  "SGT_CONSUMABLES"
  "SGT_EVT_CURRENCY"
  "SGT_PLATINUM"
  "SGT_LOOTBOX"
  "SGT_BOOSTERS"
].map(@(v, i) [ v, 200 + i ]).totable()

let currencyToGoodsType = {
  gold = goodsTypes.SGT_GOLD
  wp = goodsTypes.SGT_WP
  warbond = goodsTypes.SGT_EVT_CURRENCY
  eventKey = goodsTypes.SGT_EVT_CURRENCY
  platinum = goodsTypes.SGT_PLATINUM
}

return shopCategories.__merge(goodsTypes,
  {
    shopCategories
    goodsTypes
    currencyToGoodsType
  })
