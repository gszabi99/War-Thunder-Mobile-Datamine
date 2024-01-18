from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getPriceExtStr } = require("%rGui/shop/priceExt.nut")
let currencyStyles = require("currencyStyles.nut")
let { CS_COMMON, CS_GAMERCARD } = currencyStyles
let { eventSeason } = require("%rGui/event/eventState.nut")

let defCoef = 1

let iconsCoef = {
  ship_tool_kit = 1.6
  ship_smoke_screen_system_mod = 1.5
  tank_tool_kit_expendable = 1.5
  tank_extinguisher = 1.6
  spare = 1.8
  firework_kit = 1.4
  warbond = 1.4
  eventKey = 1.2
  nybond = 1.4
  ircm_kit = 1.4
}
let maxIconsCoef = iconsCoef.reduce(@(a, b) max(a, b))

let getSizeIcon = @(currencyId, size) (size * (iconsCoef?[currencyId] ?? defCoef) + 0.5).tointeger()

let icons = {
  // Currencies
  wp   = "ui/gameuiskin#currency_lions.svg"
  gold = "ui/gameuiskin#currency_eagles.svg"
  unitExp = "ui/gameuiskin#experience_icon.svg"
  playerExp = "ui/gameuiskin#experience_icon.svg"
  warbond = "ui/gameuiskin#warbond_icon.avif"
  eventKey = "ui/gameuiskin#key_icon.avif"
  nybond = "ui/gameuiskin#warbond_christmas_icon.avif"
  // Consumables
  ship_tool_kit = "ui/gameuiskin#shop_consumables_repair_gamercard.avif"
  ship_smoke_screen_system_mod = "ui/gameuiskin#shop_consumables_smoke_gamercard.avif"
  tank_tool_kit_expendable = "ui/gameuiskin#shop_consumables_tank_repair_gamercard.avif"
  tank_extinguisher = "ui/gameuiskin#shop_consumables_tank_extinguisher_gamercard.avif"
  spare = "ui/gameuiskin#shop_consumables_tank_cards_gamercard.avif"
  firework_kit = "ui/gameuiskin#icon_fireworks.avif"
  ircm_kit = "ui/gameuiskin#icon_ircm.avif"
  // Placeholder
  placeholder = "ui/gameuiskin#icon_primary_attention.svg"
}

let dynamicIcons = {
  warbond = @(season) $"ui/gameuiskin#warbond_icon_{season}.avif"
  eventKey = @(season) $"ui/gameuiskin#key_icon_{season}.avif"
}

let currencyIconsColor = {
  playerExp = 0xFFFFB70B
  unitExp = 0xFF7EE2FF
}

let getCurrencyImage = @(id) icons?[id] ?? icons.placeholder
let getCurrencyPicture = @(id, iconSize) Picture($"{getCurrencyImage(id)}:{iconSize}:{iconSize}:P")
let getDynamicPicture = @(id, iconSize, season) Picture($"{dynamicIcons?[id](season)}:{iconSize}:{iconSize}:P")

let function mkCurrencyImage (id, size, ovr = {}){
  let iconSize = getSizeIcon(id, size)
  return @() {
    watch = eventSeason
    rendObj = ROBJ_IMAGE
    size = [iconSize, iconSize]
    vplace = ALIGN_CENTER
    color = currencyIconsColor?[id] ?? 0xFFFFFFFF
    keepAspect = KEEP_ASPECT_FIT
    image = id in dynamicIcons
        ? getDynamicPicture(id, iconSize, eventSeason.get())
      : getCurrencyPicture(id, iconSize)
    fallbackImage = id not in dynamicIcons ? null : getCurrencyPicture(id, iconSize)
  }.__update(ovr)
 }

let mkCurrencyText = @(value, style) {
  rendObj = ROBJ_TEXT
  text = type(value) == "integer" ? decimalFormat(value) : value
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

let function strikeThrough(content, style = CS_COMMON) {
  return {
    children = [
      content
      {
        size = flex()
        rendObj = ROBJ_VECTOR_CANVAS
        commands = [
          [VECTOR_COLOR, Color(0, 0, 0, 56)],
          [VECTOR_WIDTH, style.discountStrikeWidth + hdpx(4)],
          [VECTOR_LINE, 0, 90, 100, 20],
          [VECTOR_WIDTH, style.discountStrikeWidth + hdpx(2)],
          [VECTOR_LINE, 0, 90, 100, 20],
          [VECTOR_COLOR, style.textColor],
          [VECTOR_WIDTH, style.discountStrikeWidth],
          [VECTOR_LINE, 0, 90, 100, 20],
        ]
      }
    ]
  }
}

let function mkDiscountPriceComp(fullValue, value, currencyId, style = CS_COMMON) {
  let price = value > 0
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
      strikeThrough(mkCurrencyComp(fullValue, currencyId, oldPriceStyle), style)
      price
    ]
  }
}

let function mkDiscountPriceExtComp(basePrice, discountedPrice, currencyId, style = CS_COMMON) {
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

let function mkExp(value, color, style = CS_GAMERCARD) {
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
        text = decimalFormat(value)
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
  maxIconsCoef

  mkCurrencyComp
  mkDiscountPriceComp
  mkPriceExtText
  mkDiscountPriceExtComp
  mkExp
}))
