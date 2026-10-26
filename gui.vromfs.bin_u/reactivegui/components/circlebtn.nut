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
    opacity = 0.5
  }
})

let mkImage = @(image, style) {
  size = style?.imgSize ?? defImgSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{style?.imgSize ?? defImgSize}")
  color = style.imgColor
  keepAspect = true
  transform = { rotate = style?.imgRotate ?? 0 }
}

function mkCircleBtn(content, onClick, style = circleBtnStyles.COMMON, clickableInfo = null) {
  let { bgImage, borderImage = null, borderColor = 0, size = defBtnSize, opacity = 1 } = style
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
    opacity
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
      content
    ]
    ...mkPressTransitionScale(stateFlags.get())
  }
}

return {
  mkCircleBtn
  mkCircleImgBtn = @(image, onClick, style = circleBtnStyles.COMMON, clickableInfo = null)
    mkCircleBtn(mkImage(image, style), onClick, style, clickableInfo)
  circleBtnStyles
}
