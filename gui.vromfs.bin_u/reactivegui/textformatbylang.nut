let { getCurrentLanguage } = require("dagor.localize")
let { getDecimalFormat } = require("%sqstd/textFormatByLang.nut")

return {
  decimalFormat = getDecimalFormat(getCurrentLanguage())
}