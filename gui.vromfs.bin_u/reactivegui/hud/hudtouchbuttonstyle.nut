from "%globalsDarg/darg_library.nut" import *

let touchButtonSize = shHud(10)

let btnBgColor = {
  empty     = 0x60000000
  emptyWithBackground = 0x80000000
  ready     = 0x80177274
  broken    = 0x99996203
  noAmmo    = 0x21000000
}

let btnBgColorShaded = btnBgColor.map(@(c) (mul_color(c, 0.65) & 0xFFFFFF) | (c & 0xCC000000))

let style = {
  touchButtonSize
  touchButtonMargin      = shHud(4)
  touchMenuButtonSize    = shHud(6)
  borderWidth            = hdpx(3)

  zoneRadiusX = 2.5 * touchButtonSize
  zoneRadiusY = touchButtonSize

  getSvgImage = @(id, sizeX, sizeY = null) Picture($"ui/gameuiskin#{id}.svg:{sizeX}:{sizeY ?? sizeX}")

  imageColor             = Color(255, 255, 255)
  imageDisabledColor     = Color(77, 77, 77, 77)

  textColor              = Color(255, 255, 255)
  textDisabledColor      = Color(77, 77, 77, 77)

  btnBgColor
  btnBgColorShaded

  borderColor            = Color(218, 218, 218)
  borderColorPushed      = Color(0, 0, 0, 0)
  borderNoAmmoColor      = Color(77, 77, 77, 77)
  borderCurWeaponColor   = Color(255, 255, 255)
}

return style
