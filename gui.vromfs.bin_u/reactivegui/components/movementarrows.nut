from "%globalsDarg/darg_library.nut" import *
let { mkContinuousButtonParams, mkGamepadShortcutImage
} = require("%rGui/controls/shortcutSimpleComps.nut")

let toInt = @(list) list.map(@(v) v.tointeger())

let horSize = toInt([shHud(12.5), shHud(17)])
let horAnimSizeMul = [0.175, 0.17]
let verSize = toInt([shHud(16), shHud(12.8)])
let verCornerSizeMul = [0.61, 0.24]
let ver2stepSizeMul = [0.85, 0.34]
let stopSize = toInt([shHud(9.3), shHud(9.3)])

let animTime = 0.3
let bgColor = 0x28000000
let bgColorPushed = 0x28282828
let fillMoveColorDef = 0xFF00DEFF
let fillMoveColorBlocked = 0xFFFF4338

let outlineColorDef = Watched(0xFFFFFFFF)
let fillColorDef = Watched(fillMoveColorDef)

let mkMoveHorCtor = @(flipX) kwarg(function mkMoveHor(onTouchBegin, onTouchEnd, shortcutId = null, ovr = {}, outlineColor = outlineColorDef) {
  let stateFlags = Watched(0)
  let { size = horSize } = ovr
  let horAnimSize = horAnimSizeMul.map(@(v, i) (v * size[i]).tointeger())
  let cornerOffset = (0.72 * horAnimSize[0]).tointeger()
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
  return res.__update({
    size
    vplace = ALIGN_CENTER
    behavior = Behaviors.Button
    children = [
      @() {
        watch = stateFlags
        rendObj = ROBJ_IMAGE
        size
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{size[0]}:{size[1]}")
        color = (stateFlags.value & S_ACTIVE) != 0 ? bgColorPushed : bgColor
        flipX
      }
      @() {
        watch = stateFlags
        size = horAnimSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_left_animated_marker.svg:{horAnimSize[0]}:{horAnimSize[1]}")
        vplace = ALIGN_CENTER
        opacity = (stateFlags.value & S_ACTIVE) != 0 ? 100 : 0
        transform = {
          translate = (stateFlags.value & S_ACTIVE) != 0
            ? [flipX ? 0.6 * size[0] : 0.4 * size[0] - horAnimSize[0], 0]
            : [flipX ? 0.5 * size[0] : 0.5 * size[0] - horAnimSize[0], 0]
        }
        transitions = [{ prop = AnimProp.translate, duration = animTime, easing = Linear }]
        flipX
      }
      @() {
        watch = outlineColor
        rendObj = ROBJ_IMAGE
        size
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_outline.svg:{size[0]}:{size[1]}")
        color = outlineColor.value
        flipX
      }
      {
        rendObj = ROBJ_IMAGE
        size = horAnimSize
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_corner.svg:{horAnimSize[0]}:{horAnimSize[1]}")
        hplace = flipX ? ALIGN_RIGHT : ALIGN_LEFT
        vplace = ALIGN_CENTER
        margin = [0, cornerOffset]
        flipX
      }
      mkGamepadShortcutImage(shortcutId,
        flipX ? { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(-20), 0] }
          : { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(20), 0] })
    ]
  }, ovr)
})

let mkStopBtn = kwarg(function mkMoveHor(onTouchBegin, onTouchEnd, shortcutId = null, ovr = {}, outlineColor = outlineColorDef) {
  let stateFlags = Watched(0)
  let { size = verSize } = ovr
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
  return res.__update({
    size
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.TouchScreenButton
    children = [
      @() {
        watch = stateFlags
        rendObj = ROBJ_IMAGE
        keepAspect = true
        size = stopSize
        image = Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{stopSize[0]}:{stopSize[1]}")
        color = (stateFlags.value & S_ACTIVE) != 0 ? bgColorPushed : bgColor
        children =
        {
          rendObj = ROBJ_TEXT
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          text =loc("hud/movementArrows/stopBtn")
        }.__update(fontTiny)
      }
      @() {
        watch = outlineColor
        rendObj = ROBJ_IMAGE
        keepAspect = true
        size = stopSize
        image = Picture($"ui/gameuiskin#hud_movement_stop2_outline.svg:{stopSize[0]}:{stopSize[1]}")
        color = outlineColor.value
      }
    ]
  }, ovr)
})

let mkMoveVertBtnAnimBg = @(flipY, calcPart = @() 1.0, fillColor = fillColorDef, size = verSize) {
  rendObj = ROBJ_MASK
  size
  image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_selection.svg:{size[0]}:{size[1]}")
  transform = { rotate = flipY ? 180 : 0 }
  children = @() {
    watch = fillColor
    rendObj = ROBJ_SOLID
    size = flex()
    transform = { pivot = [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = animTime, easing = Linear }]
    behavior = Behaviors.RtPropUpdate
    color = fillColor.value
    update = @() { transform = { scale = [1, calcPart()] } }
  }
}

let mkMoveVertBtnOutline = @(flipY, outlineColor = outlineColorDef, size = verSize) @() {
  watch = outlineColor
  rendObj = ROBJ_IMAGE
  size
  image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_outline.svg:{size[0]}:{size[1]}")
  color = outlineColor.value
  flipY
}

let function mkMoveVertBtnCorner(flipY, cornerColor = Watched(0xFFFFFFFF), btnSize = verSize) {
  let verCornerSize = verCornerSizeMul.map(@(v, i) (v * btnSize[i]).tointeger())
  let cornerOffset = (0.3 * verCornerSize[1]).tointeger()
  return @() {
    watch = cornerColor
    rendObj = ROBJ_IMAGE
    size = verCornerSize
    image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_corner.svg:{verCornerSize[0]}:{verCornerSize[1]}")
    vplace = flipY ? ALIGN_BOTTOM : ALIGN_TOP
    hplace = ALIGN_CENTER
    margin = [flipY ? 0 : cornerOffset, 0, flipY ? cornerOffset : 0, 0]
    color = cornerColor.value
    transitions = [{ prop = AnimProp.color, duration = animTime }]
    flipY
  }
}

let function mkMoveVertBtn(onTouchBegin, onTouchEnd, shortcutId, ovr = {}) {
  let stateFlags = Watched(0)
  let { size = verSize } = ovr
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
  return @() res.__merge({
    watch = stateFlags
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{size[0]}:{size[1]}")
    color = (stateFlags.value & S_ACTIVE) != 0 ? bgColorPushed : bgColor
  }, ovr)
}

let function mkMoveVertBtnNoHotkey(ovr = {}) {
  let stateFlags = Watched(0)
  let { size = verSize } = ovr
  return @() {
    watch = stateFlags
    behavior = Behaviors.TouchScreenButton
    size
    onElemState = @(sf) stateFlags(sf)
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{size[0]}:{size[1]}")
    color = (stateFlags.value & S_ACTIVE) != 0 ? bgColorPushed : bgColor
  }.__update(ovr)
}

let function mkMoveVertBtn2step(calcPart = @() 1.0, cornerColor = Watched(0xFFFFFFFF),
  fillColor = fillColorDef, btnSize = verSize
) {
  let size = ver2stepSizeMul.map(@(v, i) (v * btnSize[i]).tointeger())
  let verCornerSize = verCornerSizeMul.map(@(v, i) (v * btnSize[i]).tointeger())
  let offset = -(0.42 * verCornerSize[1]).tointeger()
  return {
    hplace = ALIGN_CENTER
    pos = [0, offset]
    size
    children = [
      @() {
        watch = cornerColor
        size = verCornerSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_corner.svg:{verCornerSize[0]}:{verCornerSize[1]}")
        vplace = ALIGN_TOP
        hplace = ALIGN_CENTER
        color = cornerColor.value
        transitions = [{ prop = AnimProp.color, duration = animTime }]
      }
      {
        size
        rendObj = ROBJ_MASK
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_x2_selection.svg:{size[0]}:{size[1]}")
        children = @() {
          watch = fillColor
          rendObj = ROBJ_SOLID
          size = flex()
          transform = { pivot = [1, 1] }
          transitions = [{ prop = AnimProp.scale, duration = animTime, easing = Linear }]
          behavior = Behaviors.RtPropUpdate
          color = fillColor.value
          update = @() { transform = { scale = [1, calcPart()] } }
        }
      }
    ]
  }
}

let function mkMoveHorView(flipX) {
  let horAnimSize = horAnimSizeMul.map(@(v, i) (v * horSize[i]).tointeger())
  let cornerOffset = (0.72 * horAnimSize[0]).tointeger()
  return {
    size = horSize
    children = [
      {
        size = horSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{horSize[0]}:{horSize[1]}")
        color = bgColor
        flipX
      }
      {
        size = horSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_outline.svg:{horSize[0]}:{horSize[1]}")
        flipX
      }
      {
        size = horAnimSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_corner.svg:{horAnimSize[0]}:{horAnimSize[1]}")
        hplace = flipX ? ALIGN_RIGHT : ALIGN_LEFT
        vplace = ALIGN_CENTER
        margin = [0, cornerOffset]
        flipX
      }
    ]
  }
}

let function mkMoveVertView(flipY) {
  let verCornerSize = verCornerSizeMul.map(@(v, i) (v * verSize[i]).tointeger())
  let cornerOffset = (0.3 * verCornerSize[1]).tointeger()
  return {
    size = verSize
    children = [
      {
        size = verSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{verSize[0]}:{verSize[1]}")
        color = bgColor
        flipY
      }
      {
        size = verSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_outline.svg:{verSize[0]}:{verSize[1]}")
        flipY
      }
      {
        size = verCornerSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_corner.svg:{verCornerSize[0]}:{verCornerSize[1]}")
        vplace = flipY ? ALIGN_BOTTOM : ALIGN_TOP
        hplace = ALIGN_CENTER
        margin = [flipY ? 0 : cornerOffset, 0, flipY ? cornerOffset : 0, 0]
        transitions = [{ prop = AnimProp.color, duration = animTime }]
        flipY
      }
    ]
  }
}

let mkMoveArrowsView = @(midGap, midComp = null) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    mkMoveHorView(false)
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = midGap
      children = [
        mkMoveVertView(false)
        midComp
        mkMoveVertView(true)
      ]
    }
    mkMoveHorView(true)
  ]
}

let moveArrowsView = mkMoveArrowsView(shHud(2), null)
let moveArrowsViewWithMode = mkMoveArrowsView(0,
  {
    size = [flex(), hdpx(30)]
    rendObj = ROBJ_TEXT
    halign = ALIGN_CENTER
    text = loc("HUD/ENGINE_REV_STOP_SHORT")
  }.__update(fontTiny))

return {
  mkMoveLeftBtn = mkMoveHorCtor(false)
  mkMoveRightBtn = mkMoveHorCtor(true)
  mkMoveVertBtn
  mkMoveVertBtnNoHotkey
  mkMoveVertBtnAnimBg
  mkMoveVertBtnOutline
  mkMoveVertBtnCorner
  mkMoveVertBtn2step
  mkStopBtn

  fillMoveColorDef
  fillMoveColorBlocked

  moveArrowsView
  moveArrowsViewWithMode
}