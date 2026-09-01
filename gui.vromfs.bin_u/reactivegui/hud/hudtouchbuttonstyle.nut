from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/options/hudStyleOptions.nut" import isHudPrimaryStyle
from "%rGui/style/hudColors.nut" import hudWhiteColor, hudTransparentColor, hudPearlGrayColor, hudSmokyGreyColor,
  hudVeilGrayColorFade, hudBlueColorFade, hudDarkOliveColor, hudExtraLightBlackColor


let touchButtonSize = shHud(10)
let touchSizeForRhombButton = touchButtonSize * 0.9

let btnBgStyle = Computed(@() {
  empty  = hudTransparentColor
  ready  = isHudPrimaryStyle.get() ? hudWhiteColor : hudBlueColorFade
  broken = hudDarkOliveColor
  noAmmo = hudExtraLightBlackColor
})

let style = {
  touchButtonSize
  touchSizeForRhombButton
  touchButtonMargin      = shHud(4)
  touchMenuButtonSize    = shHud(6)
  borderWidth            = hdpx(3)

  zoneRadiusX            = 2.5 * touchButtonSize
  zoneRadiusY            = touchButtonSize

  countHeightUnderActionItem = (0.4 * touchButtonSize).tointeger()

  getSvgImage            = @(id, sizeX, sizeY = null) Picture($"ui/gameuiskin#{id}.svg:{sizeX}:{sizeY ?? sizeX}")

  btnBgStyle

  imageColor             = hudWhiteColor
  imageDisabledColor     = hudSmokyGreyColor

  textColor              = hudWhiteColor
  textDisabledColor      = hudSmokyGreyColor

  borderColor            = hudPearlGrayColor
  borderColorPushed      = hudVeilGrayColorFade
  borderNoAmmoColor      = hudSmokyGreyColor
  borderCurWeaponColor   = hudWhiteColor
}

return style
