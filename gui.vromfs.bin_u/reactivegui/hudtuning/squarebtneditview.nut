from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/hudTouchButtonStyle.nut" import touchButtonSize
from "%rGui/style/hudColors.nut" import hudPearlGrayColor, hudTransparentColor


const borderWidth = hdpxi(1)
let colorActive = hudPearlGrayColor

let imgSizeBase = (touchButtonSize * 0.8  + 0.5).tointeger()

function mkSquareBtnEditView(image, scale = 1.0) {
  let imgSize = scaleEven(imgSizeBase, scale)
  return {
    size = scaleEven(touchButtonSize, scale)
    rendObj = ROBJ_BOX
    borderColor = colorActive
    fillColor = hudTransparentColor
    borderWidth
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_IMAGE
      size = imgSize
      image = Picture($"{image}:{imgSize}")
      keepAspect = KEEP_ASPECT_FIT
      color = colorActive
    }
  }
}

return mkSquareBtnEditView
