from "%globalsDarg/darg_library.nut" import *
let { decimalFormat, shortTextFromNum } = require("%rGui/textFormatByLang.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getIconSize, currencyIconsColor, getCurrencyImage, getCurrencyFallback
} = require("%appGlobals/config/currencyPresentation.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON, CS_GAMERCARD } = currencyStyles


function mkCurrencyImage (id, size, ovr = {}) {
  let iconSize = getIconSize(id, size)
  return {
    rendObj = ROBJ_IMAGE
    size = [iconSize, iconSize]
    vplace = ALIGN_CENTER
    color = currencyIconsColor?[id] ?? 0xFFFFFFFF
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{getCurrencyImage(id)}:{iconSize}:{iconSize}:P")
    fallbackImage = Picture($"{getCurrencyFallback(id)}:{iconSize}:{iconSize}:P")
  }.__update(ovr)
}

let currencyFormat = @(v) type(v) != "integer" ? v
  : v > 100000000 ? shortTextFromNum(v)
  : decimalFormat(v)

let mkCurrencyText = @(value, style) {
  rendObj = ROBJ_TEXT
  text = currencyFormat(value)
  color = style.textColor
  fontFxColor = style.fontFxColor
  fontFxFactor = style.fontFxFactor
  fontFx = style.fontFx
}.__update(style.fontStyle)

let mkCurrencyComp = @(value, currencyId, style = CS_COMMON, imgChild = null) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = style.iconGap
  children = [
    mkCurrencyImage(currencyId, style.iconSize, { key = style?.iconKey, children = imgChild })
    mkCurrencyText(value, style)
  ]
}

let mkFreeText = @(style = CS_COMMON) {
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(loc("shop/free"))
  color = style.textColor
  fontFxColor = style.fontFxColor
  fontFxFactor = style.fontFxFactor
  fontFx = style.fontFx
}.__update(style.fontStyle)

let mkPriceExtText = @(price, currencyId, style = CS_COMMON) {
  rendObj = ROBJ_TEXT
  text = getPriceExtStr(price, currencyId)
  color = style.textColor
  fontFxColor = style.fontFxColor
  fontFxFactor = style.fontFxFactor
  fontFx = style.fontFx
}.__update(style.fontStyle)

function strikeThrough(content, style = CS_COMMON) {
  return {
    children = [
      content
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [
          [VECTOR_COLOR, 0xFFE02A14],
          [VECTOR_WIDTH, style.discountStrikeWidth],
          [VECTOR_LINE, 0, 90, 100, 20],
        ]
      }
    ]
  }
}

function mkDiscountPriceComp(fullValue, value, currencyId, style = CS_COMMON) {
  let isFree = value == "0" || value == 0
  let price = !isFree
    ? mkCurrencyComp(value, currencyId, style)
    : mkFreeText(style)
  if (fullValue == value)
    return price
  let oldPriceStyle = style.__merge({ fontStyle = style.discountFontStyle })
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = style.discountPriceGap
    children = [
      price
      !isFree
        ? strikeThrough(mkCurrencyText(fullValue, oldPriceStyle), style)
        : null
    ]
  }
}

function mkDiscountPriceExtComp(basePrice, discountedPrice, currencyId, style = CS_COMMON) {
  let price = discountedPrice > 0
    ? mkPriceExtText(discountedPrice, currencyId, style)
    : mkFreeText(style)
  if (basePrice == discountedPrice)
    return price
  let oldPriceStyle = style.__merge({ fontStyle = style.discountFontStyle })
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = style.discountPriceGap
    children = [
      strikeThrough(mkPriceExtText(basePrice, currencyId, oldPriceStyle), style)
      price
    ]
  }
}

function mkExp(value, color, style = CS_GAMERCARD) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = style.iconGap
    children = [
      {
        size = [ style.iconSize, style.iconSize ]
        rendObj = ROBJ_IMAGE
        image = Picture($"!ui/gameuiskin#experience_icon.svg:{style.iconSize}:{style.iconSize}")
        keepAspect = KEEP_ASPECT_FIT
        color
      }
      {
        rendObj = ROBJ_TEXT
        text = type(value) == "integer" ? decimalFormat(value) : value
        color
        fontFxColor = style.fontFxColor
        fontFxFactor = style.fontFxFactor
        fontFx = style.fontFx
      }.__update(style.fontStyle)
    ]
  }
}

return freeze(currencyStyles.__merge({
  mkCurrencyImage
  mkCurrencyText
  currencyIconsColor

  mkFreeText
  mkCurrencyComp
  mkDiscountPriceComp
  mkPriceExtText
  mkDiscountPriceExtComp
  mkExp
}))
