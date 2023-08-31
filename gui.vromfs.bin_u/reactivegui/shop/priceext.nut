from "%globalsDarg/darg_library.nut" import *
let { doesLocTextExist } = require("dagor.localize")

let function getPriceExtStr(price, currencyId) {
  let locId = $"priceText/{currencyId}"
  return doesLocTextExist(locId) ? loc(locId, { price }) : $"{currencyId.toupper()} {price}"
}

return {
  getPriceExtStr
}
