from "math" import max
from "%sqstd/math.nut" import roundToDigits


function roundPrice(value, digits = 2) {
  if (value <= 0.0)
    return 0
  return max(1, roundToDigits(value, digits).tointeger())
}

return {
  roundPrice
}