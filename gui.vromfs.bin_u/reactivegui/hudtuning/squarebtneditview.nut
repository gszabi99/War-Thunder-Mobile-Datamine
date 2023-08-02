from "%globalsDarg/darg_library.nut" import *
let { btnBgColor, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")

let borderWidth = hdpxi(1)
let colorActive = 0xFFDADADA

let imgSize = (touchButtonSize * 0.8  + 0.5).tointeger()

let mkSquareBtnEditView = @(image) {
  size = [touchButtonSize, touchButtonSize]
  rendObj = ROBJ_BOX
  borderColor = colorActive
  fillColor = btnBgColor.empty
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
