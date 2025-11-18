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

let CS_SMALL_INCREASED_ICON = CS_COMMON.__merge({
  fontStyle = fontTiny
  iconSize = hdpxi(50)
})

let CS_INACTIVE_ICON = CS_COMMON.__merge({
  textColor = 0x80808080
  fontFxFactor = 0
})

let gamercardGap = sw(100) >= hdpx(2200) ? hdpx(45)
  : sw(100) >= hdpx(2000) ? hdpx(30)
  : hdpx(25)

let CS_GAMERCARD = CS_COMMON.__merge({
  fontStyle = fontTinyAccented
  iconSize = hdpxi(40)
})

return freeze({
  gamercardGap
  CS_TINY = CS_COMMON.__merge({ fontStyle = fontVeryVeryTinyAccented, iconSize = hdpxi(22), iconGap = hdpx(4) })
  CS_SMALL = CS_COMMON.__merge({ fontStyle = fontTiny, iconSize = hdpxi(30) })
  CS_SMALL_INCREASED_ICON
  CS_COMMON
  CS_NO_BALANCE = CS_COMMON.__merge({ textColor = 0xFFFFFFFF })
  CS_INCREASED_ICON
  CS_INACTIVE_ICON
  CS_GAMERCARD
  CS_BIG = CS_INCREASED_ICON.__merge({ fontStyle = fontMedium, iconSize = hdpxi(60) })
  CS_RESPAWN = CS_INCREASED_ICON.__merge({ iconGap = 0 })
})