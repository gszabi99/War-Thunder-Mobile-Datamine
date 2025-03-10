from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { isGamepad, isKeyboard } = require("%appGlobals/activeControls.nut")
let isScriptsLoading = require("%rGui/isScriptsLoading.nut")

let isMoveByKeys = Computed(@() isGamepad.value || isKeyboard.value)

let pannableBase = {
  size = flex()
  behavior = Behaviors.Pannable
  skipDirPadNav = true
  xmbNode = XmbContainer({ scrollToEdge = true })
}

function mkBitmapPictureLazyCached(w, h, errId, fillCb) {
  if (!isScriptsLoading.value && !__static_analysis__) {
    logerr($"Try to create {errId} mask not on scripts load")
    return @() null
  }
  return mkBitmapPictureLazy(w, h, fillCb)
}

/**
 * Creates a constructor function for creating a full-featured VERTICAL pannable area.
 * @param {integer} height - Height in pixels of the whole area with gradients included.
 * @param {[integer,integer]} gradientOffset - Top and bottom gradient offsets in pixels.
 * @param {[integer,integer]|null} scrollOffset - Optional top and bottom scroll offsets.
                                   Pass null to make it equal gradientOffset (usually it should be equal).
 * @return {function} - Pannable area constructor function.
 */
function verticalPannableAreaCtor(height, gradientOffset, scrollOffset = null) {
  scrollOffset = scrollOffset ?? gradientOffset
  let scaleMul = max(0.1, 4.0 / max(4, gradientOffset[0]), 4.0 / max(4, gradientOffset[1]))
  let pageMask = mkBitmapPictureLazyCached(4, (height * scaleMul + 0.5).tointeger(),
    "verticalPannableAreaCtor",
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

  let key = {}
  let pannableBaseExt = pannableBase.__merge({ key = {} })
  return function mkVerticalPannableArea(content, rootOvr = {}, pannableOvr = {}) {
    let root = {
      watch = isMoveByKeys
      size = [flex(), height]
      pos = [0, -scrollOffset[0]]
      rendObj = ROBJ_MASK
      image = pageMask()
      clipChildren = true
    }.__update(rootOvr)
    return @() isMoveByKeys.value
      ? root.__merge({
          children = {
            key
            size = root.size
            padding = [scrollOffset[0], 0, scrollOffset[1], 0]
            children = pannableBaseExt.__merge({
              children = content
            }, pannableOvr)
          }
        })
      : root.__merge({
          children = { //need the same nesting with isMoveByKeys to not reset scroll on change
            key
            size = root.size
            children = pannableBaseExt.__merge({
              flow = FLOW_VERTICAL
              children = [
                { size = [flex(), scrollOffset[0]] }
                content
                { size = [flex(), scrollOffset[1]] }
              ]
            }, pannableOvr)
          }
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
function horizontalPannableAreaCtor(width, gradientOffset, scrollOffset = null) {
  scrollOffset = scrollOffset ?? gradientOffset
  let scaleMul = max(0.1, 4.0 / max(4, gradientOffset[0]), 4.0 / max(4, gradientOffset[1]))
  let pageMask = mkBitmapPictureLazyCached((width * scaleMul + 0.5).tointeger(), 4,
    "horizontalPannableAreaCtor",
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

  let key = {}
  let pannableBaseExt = pannableBase.__merge({ key = {} })
  return function mkHorizontalPannableArea(content, rootOvr = {}, pannableOvr = {}) {
    let root = {
      watch = isMoveByKeys
      size = [width, flex()]
      pos = [-scrollOffset[0], 0]
      rendObj = ROBJ_MASK
      image = pageMask()
      clipChildren = true
    }.__update(rootOvr)
    return @() isMoveByKeys.value
      ? root.__merge({
          children = {
            key
            size = root.size
            padding = [0, scrollOffset[1], 0, scrollOffset[0]] //padding here to correct clipObject by parent
            children = pannableBaseExt.__merge({
              children = content
            }, pannableOvr)
          }
        })
      : root.__merge({
          children = { //need the same nesting with isMoveByKeys to not reset scroll on change
            key
            size = root.size
            children = pannableBaseExt.__merge({
              flow = FLOW_HORIZONTAL
              children = [
                { size = [scrollOffset[0], flex()] }
                content
                { size = [scrollOffset[1], flex()] }
              ]
            }, pannableOvr)
          }
        })
  }
}

/**
 * Creates a constructor function for creating a full-featured HORIZONTAL pannable area.
 * @param {integer} width - Width in pixels of the whole area with gradients included.
  * @param {integer} height - Height in pixels of the whole area with gradients included.
 * @param {[integer,integer]} gradientOffsetX - Left and right gradient offsets in pixels.
  * @param {[integer,integer]} gradientOffsetY - Top and bottom gradient offsets in pixels.
                                   Pass null to make it equal gradientOffset (usually it should be equal).
 * @return {function} - Pannable area constructor function.
 */
function doubleSidePannableAreaCtor(width, height, gradientOffsetX, gradientOffsetY) {
  if (gradientOffsetX[0] < hdpx(3) || gradientOffsetX[1] < hdpx(3) || gradientOffsetY[0] < hdpx(3) || gradientOffsetY[1] < hdpx(3))
    logerr("gradientOffsetX in doubleSidePannableAreaCtor is too small")
  gradientOffsetY = gradientOffsetY ?? gradientOffsetX
  let scaleMulX = 0.1
  let scaleMulY = 0.1
  let pageMask = mkBitmapPictureLazyCached((width * scaleMulX + 0.5).tointeger(), (height * scaleMulY + 0.5).tointeger(),
    "doubleSidePannableAreaCtor",
    function(params, bmp) {
      let { w, h } = params
      let horV = {}
      let gradStartX1 = (gradientOffsetX[0] * w / width + 0.5).tointeger()
      let gradStartX2 = w - (gradientOffsetX[1] * scaleMulX + 0.5).tointeger()
      for (local x = 0; x < w; x++)
        horV[x] <- x < gradStartX1 ? lerpClamped(0, gradStartX1, 0.0, 1.0, x)
          : x > gradStartX2 ? lerpClamped(gradStartX2, w - 1, 1.0, 0.0, x)
          : 1.0
      let gradStartY1 = (gradientOffsetY[1] * h / height + 0.5).tointeger()
      let gradStartY2 = h - (gradientOffsetY[0] * scaleMulY + 0.5).tointeger()
      for (local y = 0; y < h; y++) {
        let v = y < gradStartY1 ? lerpClamped(0, gradStartY1, 0.0, 1.0, y)
          : y > gradStartY2 ? lerpClamped(gradStartY2, h - 1, 1.0, 0.0, y)
          : 1.0
        for (local x = 0; x < w; x++) {
          let part = (v * horV[x] * 0xFF + 0.5).tointeger()
          let color = Color(part, part, part, part)
          bmp.setPixel(x, y, color)
        }
      }
    })

  let key = {}
  let pannableBaseExt = pannableBase.__merge({ key = {} })
  return function mkDoubleSidePannableArea(content, rootOvr = {}, pannableOvr = {}) {
    return {
      size = [width, height]
      rendObj = ROBJ_MASK
      image = pageMask()
      clipChildren = true
      children = {
        key
        size = [width, height]
        children = pannableBaseExt.__merge({
          children = content
        }, pannableOvr)
      }
    }.__update(rootOvr)
  }
}

return {
  verticalPannableAreaCtor
  horizontalPannableAreaCtor
  doubleSidePannableAreaCtor
}