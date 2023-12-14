from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")

let framedBtnSize = [evenPx(100), evenPx(100)]
let borderWidth = hdpx(2)
let imageSizeDecrease = borderWidth * 6
let bgColor = 0x60000000
let borderColor = 0xFFA0A0A0

let function framedImageBtn(image, onClick, ovr = {}, addChild = null) {
  let stateFlags = Watched(0)
  let size = ovr?.size ?? framedBtnSize
  let imageSize = ovr?.imageSize ?? size.map(@(v) (v - imageSizeDecrease).tointeger())
  return @() {
    watch = stateFlags
    size
    rendObj = ROBJ_BOX
    borderWidth = hdpx(2)
    borderColor = stateFlags.value & S_HOVER ? hoverColor : borderColor
    fillColor = bgColor

    onElemState = @(sf) stateFlags(sf)
    behavior = Behaviors.Button
    onClick

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER

    children = [
      {
        size = imageSize
        rendObj = ROBJ_IMAGE
        color = stateFlags.value & S_HOVER ? hoverColor : 0xFFFFFFFF
        image = Picture($"{image}:{imageSize[0]}:{imageSize[1]}:P")
        keepAspect = true
      }
      addChild
    ]

    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
  }.__update(ovr)
}

return {
  framedImageBtn
  framedBtnSize
}