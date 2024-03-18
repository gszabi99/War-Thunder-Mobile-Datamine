from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

let mkImage = @(path, w, h) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{w}:{h}:P")
  color = 0xFFFFFFFF
}

function mkArrowImageComp(lengthPx) {
  let h = round(lengthPx).tointeger()
  let w = round(h / 2.0 / 24 * 40).tointeger() * 2
  return mkImage("ui/gameuiskin#scroll_arrow.svg", w, h)
}

let scrollArrowImageBig = mkArrowImageComp(evenPx(88))
let scrollArrowImageSmall = mkArrowImageComp(evenPx(50))

let mkIsShow = {
  [MR_T] = @(scrollHandler) Computed(@() (scrollHandler.elem?.getScrollOffsY() ?? 0) > 0),
  [MR_B] = @(scrollHandler) Computed(@() (scrollHandler.elem?.getScrollOffsY() ?? 0) <
    (scrollHandler.elem?.getContentHeight() ?? 0) - (scrollHandler.elem?.getHeight() ?? 0)),
  [MR_L] = @(scrollHandler) Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0) > 0),
  [MR_R] = @(scrollHandler) Computed(@() (scrollHandler.elem?.getScrollOffsX() ?? 0) <
    (scrollHandler.elem?.getContentWidth() ?? 0) - (scrollHandler.elem?.getWidth() ?? 0)),
}

let posParams = {
  [MR_T] = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_TOP
    transform = { rotate = 180 }
  },
  [MR_B] = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
  },
  [MR_L] = {
    hplace = ALIGN_LEFT
    vplace = ALIGN_CENTER
    transform = { rotate = 90 }
  },
  [MR_R] = {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    transform = { rotate = 270 }
  },
}

// IMPORTANT: Pannable MUST have Behaviors.ScrollEvent behavior, and scrollHandler attached.
function mkScrollArrow(scrollHandler, align, arrowImageComp = scrollArrowImageBig, ovr = {}) {
  let isShow = mkIsShow[align](scrollHandler)
  return @() arrowImageComp.__merge(posParams[align],
    {
      watch = isShow
      opacity = isShow.value ? 0.7 : 0
      transitions = [{ prop = AnimProp.opacity, duration = 0.5, easing = OutCubic }]
    },
    ovr)
}

return {
  mkScrollArrow
  scrollArrowImageSmall
}
