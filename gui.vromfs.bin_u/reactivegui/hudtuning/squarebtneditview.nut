from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudTouchButtonStyle.nut" import touchButtonSize
from "%rGui/style/hudColors.nut" import hudPearlGrayColor, hudTransparentColor


const borderWidth = hdpxi(1)
let colorActive = hudPearlGrayColor

let imgSize = (touchButtonSize * 0.8  + 0.5).tointeger()

let mkSquareBtnEditView = @(image) {
  size = [touchButtonSize, touchButtonSize]
  rendObj = ROBJ_BOX
  borderColor = colorActive
  fillColor = hudTransparentColor
  borderWidth
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = [imgSize, imgSize]
    image = Picture($"{image}:{imgSize}:{imgSize}")
    keepAspect = KEEP_ASPECT_FIT
    color = colorActive
  }
}

return mkSquareBtnEditView
