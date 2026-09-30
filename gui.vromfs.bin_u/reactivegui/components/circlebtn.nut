from "%globalsDarg/darg_library.nut" import *
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/style/gradients.nut" import btnBorderGradient, btnPrimaryBgGradient, btnCommonBgGradient,
  btnInactiveBgGradient
from "%rGui/style/stdColors.nut" import textColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale


const defBtnSize = evenPx(68)
const defImgSize = evenPx(40)
const borderWidth = hdpx(2)
const imageTintColor = 0xFFFFFFFF

let circleBtnStyles = freeze({
  COMMON = { bgImage = btnCommonBgGradient, borderImage = btnBorderGradient, imgColor = textColor }
  PRIMARY = { bgImage = btnPrimaryBgGradient, borderImage = btnBorderGradient, imgColor = textColor }
  INACTIVE = {
    bgImage = btnInactiveBgGradient
    borderColor = buttonStyles.INACTIVE.ovr.borderColor
    imgColor = buttonStyles.INACTIVE.childOvr.color
  }
})

function mkCircleBtn(image, onClick, style = circleBtnStyles.COMMON, clickableInfo = null) {
  let { bgImage, imgColor, borderImage = null, borderColor = 0,
    size = defBtnSize, imgSize = defImgSize, imgRotate = 0 } = style
  let hasBorderImage = borderImage != null
  let stateFlags = Watched(0)

  return @() {
    watch = stateFlags
    size

    rendObj = ROBJ_BOX
    borderColor = hasBorderImage ? 0 : borderColor
    fillColor = hasBorderImage ? imageTintColor : 0
    borderWidth = hasBorderImage ? 0 : borderWidth
    borderRadius = size / 2
    image = !hasBorderImage || (stateFlags.get() & S_HOVER) ? null : borderImage

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    onClick
    clickableInfo
    sound = { click  = "click" }

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        size = size - 2 * borderWidth
        rendObj = ROBJ_BOX
        borderColor = 0
        fillColor = imageTintColor
        borderWidth = 0
        borderRadius = size / 2 - borderWidth
        image = bgImage
      }
      {
        size = imgSize
        rendObj = ROBJ_IMAGE
        image = Picture($"{image}:{imgSize}")
        color = imgColor
        keepAspect = true
        transform = { rotate = imgRotate }
      }
    ]
  }.__update(mkPressTransitionScale(stateFlags.get()))
}

return {
  mkCircleBtn
  circleBtnStyles
}
