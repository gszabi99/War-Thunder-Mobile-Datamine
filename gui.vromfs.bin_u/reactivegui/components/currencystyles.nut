from "%globalsDarg/darg_library.nut" import *

let CS_COMMON = {
  iconSize = hdpxi(45)
  iconGap = hdpx(12)
  fontStyle = fontSmall
  textColor = Color(255, 255, 255)
  fontFxColor = Color(0, 0, 0, 255)
  fontFxFactor = 50
  fontFx = FFT_GLOW
  discountFontStyle = fontTiny
  discountStrikeWidth = hdpx(4)
  discountPriceGap = hdpx(24)
}

let CS_INCREASED_ICON = CS_COMMON.__merge({
  iconSize = hdpxi(60)
  discountFontStyle = fontSmall
})

let gamercardGap = sw(100) >= hdpx(2200) ? hdpx(45)
  : sw(100) >= hdpx(2000) ? hdpx(30)
  : hdpx(25)

let CS_GAMERCARD = sw(100) >= hdpx(2100)
  ? CS_INCREASED_ICON
  : CS_COMMON.__merge({
      fontStyle = fontTinyAccented
    })

return freeze({
  gamercardGap
  CS_SMALL = CS_COMMON.__merge({ fontStyle = fontTiny, iconSize = hdpxi(30) })
  CS_COMMON
  CS_NO_BALANCE = CS_COMMON.__merge({ textColor = 0xFFFF4040 })
  CS_INCREASED_ICON
  CS_GAMERCARD
  CS_BIG = CS_INCREASED_ICON.__merge({ fontStyle = fontMedium, iconSize = hdpxi(60) })
})