from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/clanPresentation.nut" import getClanBg
from "%rGui/style/gradients.nut" import gradRadial
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/style/stdColors.nut" import hoverColor, textColor


const editIconPath = "ui/gameuiskin#menu_edit.svg"
const editIconShadeColor = 0xFF000000
const iconToSizeRatio = 0.6
const frameToSizeRatio = 0.9

let mkBadgePartImg = @(img, size, color) {
  size
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{img}.svg:{size}:P")
  color
}

let mkBadgeLayerChildren = @(badge, size) {
  size
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_BOX
  fillColor = 0
  borderWidth = hdpx(2)
  children = [
    mkBadgePartImg(badge.badge_icon, (size * iconToSizeRatio).tointeger(), badge.badge_icon_color)
    mkBadgePartImg(badge.badge_frame, (size * frameToSizeRatio).tointeger(), badge.badge_frame_color)
  ]
}

let mkClanBadgeImage = @(badge, size) {
  size
  rendObj = ROBJ_IMAGE
  image = getClanBg(badge.badge_bg_color)
  children = mkBadgeLayerChildren(badge, size)
}

let mkClanBadgePreview = @(badgeW, size) @() {
  watch = badgeW
  ...mkClanBadgeImage(badgeW.get(), size)
}

function mkClanBadgeBtn(badgeW, size, onClick) {
  let sf = Watched(0)
  let editSize = (size * 0.2).tointeger()
  return @() {
    watch = [badgeW, sf]
    size
    behavior = Behaviors.Button
    sound = const { click = "click" }
    onClick
    onElemState = @(s) sf.set(s)
    rendObj = ROBJ_IMAGE
    image = getClanBg(badgeW.get().badge_bg_color)
    children = [
      mkBadgeLayerChildren(badgeW.get(), size)
      {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        padding = hdpx(15)
        rendObj = ROBJ_IMAGE
        image = gradRadial
        color = editIconShadeColor
        children = {
          size = editSize
          rendObj = ROBJ_IMAGE
          image = Picture($"{editIconPath}:{editSize}:P")
          color = sf.get() & S_HOVER ? hoverColor : textColor
        }
      }
    ]
    ...mkPressTransitionScale(sf.get())
  }
}

return {
  mkClanBadgeImage
  mkClanBadgePreview
  mkClanBadgeBtn
  mkBadgePartImg
}
