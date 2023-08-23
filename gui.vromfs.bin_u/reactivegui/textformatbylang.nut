let { getCurrentLanguage } = require("dagor.localize")
let { getDecimalFormat, getShortTextFromNum } = require("%sqstd/textFormatByLang.nut")

return {
  decimalFormat = getDecimalFormat(getCurrentLanguage())
  shortTextFromNum = getShortTextFromNum(getCurrentLanguage())
}