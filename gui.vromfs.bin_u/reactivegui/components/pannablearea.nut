from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { isGamepad, isKeyboard } = require("%rGui/activeControls.nut")

let isMoveByKeys = Computed(@() isGamepad.value || isKeyboard.value)

let pannableBase = {
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

/**
 * Creates a constructor function for creating a full-featured VERTICAL pannable area.
 * @param {integer} height - Height in pixels of the whole area with gradients included.
 * @param {[integer,integer]} gradientOffset - Top and bottom gradient offsets in pixels.
 * @param {[integer,integer]|null} scrollOffset - Optional top and bottom scroll offsets.
                                   Pass null to make it equal gradientOffset (usually it should be equal).
 * @return {function} - Pannable area constructor function.
 */
let function verticalPannableAreaCtor(height, gradientOffset, scrollOffset = null) {
  scrollOffset = scrollOffset ?? gradientOffset
  let scaleMul = max(0.1, 4.0 / max(4, gradientOffset[0]), 4.0 / max(4, gradientOffset[1]))
  let pageMask = mkBitmapPictureLazy(4, (height * scaleMul + 0.5).tointeger(),
    function(params, bmp) {
      let { w, h } = params
      let gradStart1 = (gradientOffset[1] * h / height + 0.5).tointeger()
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

  return function mkVerticalPannableArea(content, rootOvr = {}, pannableOvr = {}) {
    let root = {
      watch = isMoveByKeys
      size = [flex(), height]
      pos = [0, -scrollOffset[0]]
      rendObj = ROBJ_MASK
      image = pageMask()
    }.__update(rootOvr)

    return @() isMoveByKeys.value
      ? root.__merge({
          padding = [scrollOffset[0], 0, scrollOffset[1], 0]
          children = pannableBase.__merge({
            children = content
          }, pannableOvr)
        })
      : root.__merge({
          clipChildren = true
          children = pannableBase.__merge({
            flow = FLOW_VERTICAL
            children = [
              { size = [flex(), scrollOffset[0]] }
              content
              { size = [flex(), scrollOffset[1]] }
            ]
          }, pannableOvr)
        })
  }
}

/**
 * Creates a constructor function for creating a full-featured HORIZONTAL pannable area.
 * @param {integer} width - Width in pixels of the whole area with gradients included.
 * @param {[integer,integer]} gradientOffset - Left and right gradient offsets in pixels.
 * @param {[integer,integer]|null} scrollOffset - Optional left and right scroll offsets.
                                   Pass null to make it equal gradientOffset (usually it should be equal).
 * @return {function} - Pannable area constructor function.
 */
let function horizontalPannableAreaCtor(width, gradientOffset, scrollOffset = null) {
  scrollOffset = scrollOffset ?? gradientOffset
  let scaleMul = max(0.1, 4.0 / max(4, gradientOffset[0]), 4.0 / max(4, gradientOffset[1]))
  let pageMask = mkBitmapPictureLazy((width * scaleMul + 0.5).tointeger(), 4,
    function(params, bmp) {
      let { w, h } = params
      let gradStart1 = (gradientOffset[0] * w / width + 0.5).tointeger()
      let gradStart2 = w - (gradientOffset[1] * scaleMul + 0.5).tointeger()
      for (local x = 0; x < w; x++) {
        let v = x < gradStart1 ? lerpClamped(0, gradStart1, 0.0, 1.0, x)
          : x > gradStart2 ? lerpClamped(gradStart2, w - 1, 1.0, 0.0, x)
          : 1.0
        let part = (v * v * 0xFF + 0.5).tointeger()
        let color = Color(part, part, part, part)
        for (local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    })

  return function mkHorizontalPannableArea(content, rootOvr = {}, pannableOvr = {}) {
    let root = {
      watch = isMoveByKeys
      size = [width, flex()]
      pos = [-scrollOffset[0], 0]
      rendObj = ROBJ_MASK
      image = pageMask()
    }.__update(rootOvr)

    return @() isMoveByKeys.value
      ? root.__merge({
          padding = [0, scrollOffset[1], 0, scrollOffset[0]]
          children = pannableBase.__merge({
            children = content
          }, pannableOvr)
        })
      : root.__merge({
          clipChildren = true
          children = pannableBase.__merge({
            flow = FLOW_HORIZONTAL
            children = [
              { size = [scrollOffset[0], flex()] }
              content
              { size = [scrollOffset[1], flex()] }
            ]
          }, pannableOvr)
        })
  }
}

return {
  verticalPannableAreaCtor
  horizontalPannableAreaCtor
}