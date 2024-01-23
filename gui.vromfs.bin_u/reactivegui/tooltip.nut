from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { locColorTable } = require("%rGui/style/stdColors.nut")

const REPAY_TIME = 0.3
let state = Watched(null)
local curContent = null
local delayedTooltip = null

let TOOLTIP_PARAMS = {
  flow = FLOW_VERTICAL //how popup need to flow against target point
  flowOffset = hdpx(20) //popup offset from coords in popup flow direction
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  content = null
  bgOvr = null
}

let tooltipBg = {
  rendObj = ROBJ_BOX
  fillColor = 0xDD000000
  borderColor = 0xFF808080
  borderWidth = hdpxi(4)
  padding = [hdpx(20), hdpx(30)]
}

let mkTooltipText = @(text, ovr = {}) {
  maxWidth = hdpx(800)
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFE0E0E0
  colorTable = locColorTable
  text
}.__update(fontSmall, ovr)

let function calcPosition(rectOrPos, flow, flowOffset, halign, valign) {
  let isArray = type(rectOrPos) == "array"
  assert(isArray || (("l" in rectOrPos) && ("b" in rectOrPos)))
  let res = {
    pos = isArray ? rectOrPos : [rectOrPos.l, rectOrPos.t]
    halign = halign == ALIGN_CENTER ? ALIGN_CENTER
      : halign == ALIGN_LEFT ? ALIGN_RIGHT //when we set popup halign = left, we want it to link to the left object side, but it mean ALIGN_RIGHT
      : ALIGN_LEFT
    valign = valign == ALIGN_CENTER ? ALIGN_CENTER
      : valign == ALIGN_TOP ? ALIGN_BOTTOM //when we set popup halign = top, we want it to link to the top object side, but it mean ALIGN_BOTTOM
      : ALIGN_TOP
  }

  let size = isArray ? [0, 0] : [rectOrPos.r - rectOrPos.l, rectOrPos.b - rectOrPos.t]

  if (flow == FLOW_VERTICAL) {
    if (res.valign == ALIGN_CENTER)
      res.valign = (2.0 * res.pos[1] > sh(100) - res.pos[1] - size[1]) ? ALIGN_BOTTOM : ALIGN_TOP
    res.pos[1] += res.valign == ALIGN_BOTTOM ? -flowOffset : flowOffset + size[1]

    res.pos[0] += res.halign == ALIGN_CENTER ? size[0] / 2
      : res.halign == ALIGN_RIGHT ? size[0]
      : 0
  }
  else {
    if (res.halign == ALIGN_CENTER)
      res.halign = (res.pos[0] > sw(100) - res.pos[0] - size[0]) ? ALIGN_RIGHT : ALIGN_LEFT
    res.pos[0] += res.halign == ALIGN_RIGHT ? -flowOffset : flowOffset + size[0]

    res.pos[1] += res.valign == ALIGN_CENTER ? size[1] / 2
      : res.valign == ALIGN_BOTTOM ? size[1]
      : 0
  }

  return res
}

let function hideTooltip() {
  state(null)
  curContent = null
  delayedTooltip = null
}

let function showTooltip(rectOrPos, params) {
  delayedTooltip = null
  if (params == null) {
    hideTooltip()
    return
  }
  let content = type(params) == "string" ? params : params?.content
  if (content == null || content == "") {
    logerr("try to show tooltip with empty content")
    hideTooltip()
    return
  }

  let newState = TOOLTIP_PARAMS.__merge(type(params) == "string" ? { content } : params)
  if (type(content) != "string") {
    curContent = content
    newState.content = null
  }

  let { flow, flowOffset, halign, valign } = newState
  newState.position <- calcPosition(rectOrPos, flow, flowOffset, halign, valign)
  state(newState)
}

let function showDelayedTooltipImpl() {
  if (delayedTooltip == null)
    return
  let { rectOrPos, params } = delayedTooltip
  showTooltip(rectOrPos, params)
}

let function showDelayedTooltip(rectOrPos, params, repayTime = REPAY_TIME) {
  hideTooltip()
  delayedTooltip = { rectOrPos, params }
  resetTimeout(repayTime, showDelayedTooltipImpl)
}

let withTooltipImpl = @(stateFlags, showFunc) function(sf) {
  let hasHint = (stateFlags.value & S_ACTIVE) != 0
  let needHint = (sf & S_ACTIVE) != 0
  stateFlags(sf)
  if (hasHint == needHint)
    return
  if (needHint)
    showFunc()
  else
    hideTooltip()
}

let tooltipDetach = @(stateFlags) @() (stateFlags.value & S_ACTIVE) != 0 ? hideTooltip() : null

let withHoldTooltip = @(stateFlags, key, tooltipCtor)
  withTooltipImpl(stateFlags, @() showDelayedTooltip(gui_scene.getCompAABBbyKey(key), tooltipCtor()))

let withTooltip = @(stateFlags, key, tooltipCtor)
  withTooltipImpl(stateFlags, @() showTooltip(gui_scene.getCompAABBbyKey(key), tooltipCtor()))


let translateAnimation = @(flow, halign, valign, duration)
  { prop = AnimProp.translate, duration = duration, play = true, easing = OutCubic
    from = (flow == FLOW_VERTICAL && valign == ALIGN_BOTTOM) ? [0, hdpx(50)]
      : (flow == FLOW_VERTICAL && valign == ALIGN_TOP) ? [0, -hdpx(50)]
      : (flow == FLOW_HORIZONTAL && halign == ALIGN_RIGHT) ? [hdpx(50), 0]
      : (flow == FLOW_HORIZONTAL && halign == ALIGN_LEFT) ? [-hdpx(50), 0]
      : [0, 0]
  }

let fadeOutAnim = { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.15,
  easing = OutQuad, playFadeOut = true }

let function tooltipComp() {
  if (state.value == null)
    return { watch = state }

  let { flow, position, content, bgOvr } = state.value
  let { halign, valign } = position

  let visibleChild = tooltipBg.__merge(
    bgOvr ?? {},
    {
      key = state.value
      children = curContent ?? mkTooltipText(content)
      transform = {}
      animations = [
        translateAnimation(flow, halign, valign, 0.15)
        fadeOutAnim
      ]
    })

  return position.__merge({
    watch = state
    size = [0, 0]
    halign
    valign
    children = {
      size = SIZE_TO_CONTENT
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children = visibleChild
    }
  })
}

return {
  calcPosition
  tooltipComp
  showTooltip
  showDelayedTooltip
  hideTooltip
  withHoldTooltip
  withTooltip
  tooltipDetach

  tooltipBg
  mkTooltipText
}