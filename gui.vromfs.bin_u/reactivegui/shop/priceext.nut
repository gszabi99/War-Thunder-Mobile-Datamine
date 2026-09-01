from "%globalsDarg/darg_library.nut" import *
from "dagor.localize" import doesLocTextExist
from "math" import fabs, round
from "string" import format
from "types" import Float


function getPriceExtStr(price, currencyId) {
  let locId = $"priceText/{currencyId}"
  let isFloat = price instanceof Float
  let needFloatCents = isFloat && fabs(price) % 1 > 0.005 && fabs(price) < 10000
  let priceStr = isFloat && needFloatCents ? format("%.2f", price)
    : isFloat ? format("%d", round(price))
    : price.tostring()
  return doesLocTextExist(locId) ? loc(locId, { price = priceStr }) : $"{currencyId.toupper()} {priceStr}"
}

return {
  getPriceExtStr
}
