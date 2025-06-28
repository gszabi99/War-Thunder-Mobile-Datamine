from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")


let iconSize = hdpxi(34)
let margin = hdpx(10)

let mkGradText = @(text) doubleSideGradient.__merge({
  size = [SIZE_TO_CONTENT, defButtonHeight]
  minWidth = defButtonMinWidth
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(text)
  }.__update(fontSmall)
})

let lockIcon = {
  size = [iconSize, iconSize]
  margin
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#lock_icon.svg:{iconSize}:{iconSize}:P")
  keepAspect = true
}

let checkIcon = {
  size = [iconSize, iconSize]
  margin
  rendObj = ROBJ_IMAGE
  color = 0xFF78FA78
  image = Picture($"ui/gameuiskin#check.svg:{iconSize}:{iconSize}:P")
  keepAspect = true
}

return {
  mkGradText
  lockIcon
  checkIcon
  iconSize
}