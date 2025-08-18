from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")

let framedBtnSize = [evenPx(100), evenPx(100)]
let borderWidth = hdpx(2)
let imageSizeDecrease = borderWidth * 6
let bgColor = 0x60000000
let borderColor = 0xFFA0A0A0
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")

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
      {
        size = imageSize
        rendObj = ROBJ_IMAGE
        color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
        image = Picture($"{image}:{imageSize?[0] ?? imageSize}:{imageSize?[1] ?? imageSize}:P")
        keepAspect = true
      }
      addChild
    ]

    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }.__update(ovr)
}

let hoverBg = {
  vplace = ALIGN_CENTER
  size = flex()
  color = 0x8052C4E4
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
          size = flex()
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
  framedBtnSize
  imageBtn
}