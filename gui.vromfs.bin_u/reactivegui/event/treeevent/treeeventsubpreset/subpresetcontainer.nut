from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { closeSubPreset, currentSubPresetState, selectedElemId, presetBgElems
} = require("%rGui/event/treeEvent/treeEventState.nut")
let { subMapContainer } = require("%rGui/event/treeEvent/treeEventSubPreset/subMapContainer.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")

let shadowTexOffs = [300, 520, 310, 570]
let shadowScreenOffs = shadowTexOffs.map(hdpxi)
let scrollTexOffs = [180, 395, 195, 355]
let scrollScreenOffs = scrollTexOffs.map(hdpxi)

let OPEN_TIME = 0.5

let isOpeningFinished = Watched(false)
let contentWidthAnimLimit = Watched(0)
let contentHeight = Computed(@() currentSubPresetState.get() == null ? null : hdpxi(currentSubPresetState.get().mapSize[1]))
let contentWidthFinal = Computed(@() hdpxi(currentSubPresetState.get()?.mapSize[0] ?? 0))
let contentWidth = Computed(@() isOpeningFinished.get() ? contentWidthFinal.get()
  : min(contentWidthFinal.get(), contentWidthAnimLimit.get()).tointeger())

local animEndMsec = 0

function updateAnim() {
  let t = get_time_msec()
  if (t >= animEndMsec) {
    isOpeningFinished.set(true)
    return
  }

  let v = clamp(0.001 * (animEndMsec - t) / OPEN_TIME, 0, 1)
  contentWidthAnimLimit.set(contentWidthFinal.get() * (1.0 - v * v * v))
  resetTimeout(0.01, updateAnim)
}

function startAnim() {
  isOpeningFinished.set(false)
  animEndMsec = get_time_msec() + (1000 * (OPEN_TIME - 0.01)).tointeger()
  updateAnim() 
}

function wndHeader() {
  let res = { watch = [presetBgElems, selectedElemId], key = "scroll_header" }
  let bgElem = presetBgElems.get().findvalue(@(v) v?.isOnTop && v?.required == selectedElemId.get())
  if (bgElem == null)
    return res
  let { img, size } = bgElem
  let sizeExt = size.map(hdpxi)
  return res.__update({
    size = sizeExt
    pos = [0, -0.5 * sizeExt[1]]
    hplace = ALIGN_CENTER
    vplace = ALIGN_TOP
    rendObj = ROBJ_IMAGE
    image = Picture($"{img}:{sizeExt[0]}:{sizeExt[1]}:P")
    keepAspect = true
    transform = {}
    animations = [{
      prop = AnimProp.scale, from = [1,1], to = [1.1, 1.1], easing = CosineFull,
      duration = 0.3, play = true
    }]
  })
}

let get9RectSize = @(contentSize, screenOffs)
  [contentSize[0] + screenOffs[1] + screenOffs[3], contentSize[1] + screenOffs[0] + screenOffs[2]]

function subPresetContent() {
  if (contentHeight.get() == null)
    return { watch = contentHeight }
  let contentSize = [contentWidth.get(), contentHeight.get()]
  return {
    watch = [contentWidth, contentHeight, isOpeningFinished]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        key = isOpeningFinished
        size = get9RectSize(contentSize, shadowScreenOffs)
        onAttach = startAnim
        function onDetach() {
          isOpeningFinished.set(false)
          contentWidthAnimLimit.set(0)
        }
        pos = [-hdpx(50), 0]
        padding = shadowScreenOffs
        rendObj = ROBJ_9RECT
        texOffs = shadowTexOffs
        screenOffs = shadowScreenOffs
        image = Picture("ui/images/pirates/map_scroll_shadow.avif:0:P")
        opacity = 0.8
      }
      {
        key = "subPresetContainer" 
        size = get9RectSize(contentSize, scrollScreenOffs)
        padding = scrollScreenOffs
        rendObj = ROBJ_9RECT
        texOffs = scrollTexOffs
        screenOffs = scrollScreenOffs
        image = Picture("ui/images/pirates/map_scroll.avif:0:P")
        children = {
          key = isOpeningFinished.get()
          size = flex()
          clipChildren = !isOpeningFinished.get()
          halign = ALIGN_CENTER
          children = [
            subMapContainer
            !isOpeningFinished.get() ? null : wndHeader
          ]
        }
      }
    ]
  }
}

let subPresetContainer = {
  size = flex()
  stopMouse = true
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  touchMarginPriority = TOUCH_BACKGROUND
  onClick = closeSubPreset
  children = subPresetContent
  animatons = wndSwitchAnim
}

return { subPresetContainer }
