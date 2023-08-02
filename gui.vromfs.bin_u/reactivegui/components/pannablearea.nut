from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { isGamepad, isKeyboard } = require("%rGui/activeControls.nut")

let isMoveByKeys = Computed(@() isGamepad.value || isKeyboard.value)

let function verticalPannableAreaCtor(height, gradientOffset, scrollOffset = null) {
  scrollOffset = scrollOffset ?? gradientOffset
  let scaleMul = max(0.1, 4.0 / max(4, gradientOffset[0]), 4.0 / max(4, gradientOffset[1]))
  let pageMask = mkBitmapPicture(2, (height * scaleMul + 0.5).tointeger(),
    function(params, bmp) {
      let { w, h } = params
      let gradStart1 = gradientOffset[1] * h / height
      let gradStart2 = h - (gradientOffset[0] * scaleMul + 0.5).tointeger()
      for (local y = 0; y < h; y++) {
        let v = y < gradStart1 ? lerpClamped(0, gradStart1, 0.0, 1.0, y)
        : y > gradStart2 ? lerpClamped(gradStart2, h - 1, 1.0, 0.0, y)
        : 1.0
        let part = (v * v * 0xFF + 0.5).tointeger()
        let color = Color(part, part, part, part)
        for (local x = 0; x < w; x++)
          bmp.setPixel(x, y, color)
      }
    })

  return function mkVerticalPannableArea(content, override = {}) {
    let root = {
      watch = isMoveByKeys
      size = [flex(), height]
      pos = [0, -scrollOffset[0]]
      rendObj = ROBJ_MASK
      image = pageMask
    }.__update(override)

    let pannable = {
      size = flex()
      behavior = Behaviors.Pannable
      skipDirPadNav = true
      xmbNode = {
        canFocus = @() false
        scrollSpeed = 5.0
        isViewport = true
        scrollToEdge = true
        screenSpaceNav = true
      }
    }

    return @() isMoveByKeys.value
      ? root.__merge({
          padding = [scrollOffset[0], 0, scrollOffset[1], 0]
          children = pannable.__merge({
            children = content
          })
        })
      : root.__merge({
          children = pannable.__merge({
            flow = FLOW_VERTICAL
            children = [
              { size = [flex(), scrollOffset[0]] }
              content
              { size = [flex(), scrollOffset[1]] }
            ]
          })
        })
  }
}

return {
  verticalPannableAreaCtor
}