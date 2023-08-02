let shopCategories = [
  "SC_OTHER"
  "SC_GOLD"
  "SC_WP"
  "SC_PREMIUM"
  "SC_UNIT"
  "SC_CONSUMABLES"
].map(@(v, i) [ v, 100 + i ]).totable()

let goodsTypes = [
  "SGT_UNKNOWN"
  "SGT_GOLD"
  "SGT_WP"
  "SGT_PREMIUM"
  "SGT_UNIT"
  "SGT_CONSUMABLES"
].map(@(v, i) [ v, 200 + i ]).totable()

return shopCategories.__merge(goodsTypes,
  {
    shopCategories
    goodsTypes
  })
