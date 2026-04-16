from "%globalsDarg/darg_library.nut" import *
from "math" import fabs, round
from "string" import format
from "dagor.localize" import doesLocTextExist

function getPriceExtStr(price, currencyId) {
  let locId = $"priceText/{currencyId}"
  let isFloat = type(price) == "float"
  let needFloatCents = isFloat && fabs(price) % 1 > 0.005 && fabs(price) < 10000
  let priceStr = isFloat && needFloatCents ? format("%.2f", price)
    : isFloat ? format("%d", round(price))
    : price.tostring()
  return doesLocTextExist(locId) ? loc(locId, { price = priceStr }) : $"{currencyId.toupper()} {priceStr}"
}

return {
  getPriceExtStr
}
