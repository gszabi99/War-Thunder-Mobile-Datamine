from "math" import max
let { roundToDigits } = require("%sqstd/math.nut")

function roundPrice(value, digits = 2) {
  if (value <= 0.0)
    return 0
  return max(1, roundToDigits(value, digits).tointeger())
}

return {
  roundPrice
}