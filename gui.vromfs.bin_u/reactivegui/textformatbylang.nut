from "dagor.localize" import getCurrentLanguage
from "%sqstd/textFormatByLang.nut" import getDecimalFormat, getShortTextFromNum


return {
  decimalFormat = getDecimalFormat(getCurrentLanguage())
  shortTextFromNum = getShortTextFromNum(getCurrentLanguage())
}