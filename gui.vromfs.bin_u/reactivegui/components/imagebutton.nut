from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import hoverColor


let framedBtnSize = [evenPx(100), evenPx(100)]
const borderWidth = hdpx(2)
const imageSizeDecrease = borderWidth * 6
const bgColor = 0x60000000
const borderColor = 0xFFDEDEDE

let mkIconImage = @(image, imageSize, sf) {
  size = imageSize
  rendObj = ROBJ_IMAGE
  color = sf & S_HOVER ? hoverColor : 0xFFFFFFFF
  image = Picture($"{image}:{imageSize?[0] ?? imageSize}:{imageSize?[1] ?? imageSize}:P")
  keepAspect = true
}

function framedImageBtn(image, onClick, ovr = {}, addChild = null) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? framedBtnSize
  let imageSize = ovr?.imageSize
    ?? size?.map(@(v) (v - imageSizeDecrease).tointeger())
    ?? (size - imageSizeDecrease).tointeger()
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_BOX
    borderWidth = hdpx(2)
    borderColor = stateFlags.get() & S_HOVER ? hoverColor : borderColor
    fillColor = bgColor
    onElemState = @(sf) stateFlags.set(sf)
    behavior = Behaviors.Button
    onClick
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkIconImage(image, imageSize, stateFlags.get())
      addChild
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }.__update(ovr)
}

function framedGradientImageBtn(gradImage, image, onClick, ovr = {}, addChild = null) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? framedBtnSize
  let imageSize = ovr?.imageSize
    ?? size?.map(@(v) (v - imageSizeDecrease).tointeger())
    ?? (size - imageSizeDecrease).tointeger()
  let outerKeys = { size = true, color = true, sound = true }
  let outerOvr = ovr.filter(@(_, k) k in outerKeys)
  let innerOvr = ovr.filter(@(_, k) k not in outerKeys)
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{gradImage}:{size[0]}:{size[1]}:P"),
    behavior = Behaviors.Button
    onClick
    onElemState = @(sf) stateFlags.set(sf)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
    children = {
      size = FLEX
      rendObj = ROBJ_BOX
      borderWidth = hdpx(2)
      borderColor = stateFlags.get() & S_HOVER ? hoverColor : borderColor
      fillColor = 0x00000000
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        mkIconImage(image, imageSize, stateFlags.get())
        addChild
      ]
    }.__update(innerOvr)
  }.__update(outerOvr)
}

let hoverBg = {
  vplace = ALIGN_CENTER
  size = FLEX
  color = hoverColor
  opacity =  0.5
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

function imageBtn(image, onClick, ovr = {}, addChild = null) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? framedBtnSize
  return @() {
    watch = stateFlags
    size
    onElemState = @(sf) stateFlags.set(sf)
    behavior = Behaviors.Button
    onClick
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      stateFlags.get() & S_HOVER ? hoverBg : null
      typeof(image) != "string" ? image
        : {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture($"{image}:{size[0]}:{size[1]}:P")
          keepAspect = true
          transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
          transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
        }
      addChild
    ]
  }.__update(ovr)
}

return {
  framedImageBtn
  framedGradientImageBtn
  framedBtnSize
  imageBtn
}
