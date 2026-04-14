from "%globalsDarg/darg_library.nut" import *
from "math" import fabs
from "string" import format
from "dagor.localize" import doesLocTextExist

function getPriceExtStr(price, currencyId) {
  let locId = $"priceText/{currencyId}"
  let priceStr = type(price) == "float"
    ? format((fabs(price) % 1 > 0.005 && fabs(price) < 10000) ? "%.2f" : "%d", price)
    : price.tostring()
  return doesLocTextExist(locId) ? loc(locId, { price = priceStr }) : $"{currencyId.toupper()} {priceStr}"
}

return {
  getPriceExtStr
}
