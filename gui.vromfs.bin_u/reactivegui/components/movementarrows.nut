from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { TouchScreenButton } = require("wt.behaviors")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { hudLightBlackColor, hudDarkGrayColor, hudRedColor, hudWhiteColor, hudAshGrayColor } = require("%rGui/style/hudColors.nut")
let { mkContinuousButtonParams, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isPieMenuActive } = require("%rGui/hud/pieMenu.nut")

let toInt = @(list) list.map(@(v) v.tointeger())

let horSize = toInt([shHud(12.5), shHud(17)])
let horAnimSizeMul = [0.175, 0.17]
let verSize = toInt([shHud(16), shHud(12.8)])
let verCornerSizeMul = [0.61, 0.24]
let ver2stepSizeMul = [0.85, 0.34]
let stopSizeMul = [0.581, 0.726]
let horSizeAir = toInt([shHud(9), shHud(12)])
let verSizeAir = toInt([shHud(12), shHud(10)])

let animTime = 0.3
let bgColor = hudLightBlackColor
let bgColorPushed = hudDarkGrayColor
let fillMoveColorDef = hudWhiteColor
let fillMoveColorBlocked = hudRedColor

let outlineColorDef = Watched(hudAshGrayColor)
let fillColorDef = Watched(fillMoveColorDef)
let isActiveWithPieMenu = Computed(@() !isGamepad.get() || !isPieMenuActive.get())

let mkMoveHorCtor = @(flipX) kwarg(function mkMoveHor(onTouchBegin, onTouchEnd, shortcutId = null,
  ovr = {}, outlineColor = outlineColorDef, isDisabled = Watched(false), scale = 1
) {
  let stateFlags = Watched(0)
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)

  let size = scaleArr(ovr?.size ?? horSize, scale)
  let ovrExt = clone ovr
  if ("size" in ovrExt)
    ovrExt.$rawdelete("size")
  let horAnimSize = horAnimSizeMul.map(@(v, i) round(v * size[i]).tointeger())
  let cornerOffset = (0.72 * horAnimSize[0]).tointeger()

  return @() res.__update({
    watch = isDisabled
    size
    vplace = ALIGN_CENTER
    behavior = Behaviors.Button
    cameraControl = false
    children = [
      @() {
        watch = [stateFlags, isActiveWithPieMenu]
        rendObj = ROBJ_IMAGE
        size
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{size[0]}:{size[1]}")
        color = (stateFlags.get() & S_ACTIVE) != 0 && isActiveWithPieMenu.get() ? bgColorPushed : bgColor
        flipX
      }
    ].extend(isDisabled.get() ? []
      : [
          @() {
            watch = [stateFlags, isActiveWithPieMenu]
            size = horAnimSize
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#hud_movement_left_animated_marker.svg:{horAnimSize[0]}:{horAnimSize[1]}")
            vplace = ALIGN_CENTER
            opacity = (stateFlags.get() & S_ACTIVE) != 0 && isActiveWithPieMenu.get() ? 100 : 0
            transform = {
              translate = (stateFlags.get() & S_ACTIVE) != 0
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
            color = outlineColor.get()
            flipX
          }
          @() {
            watch = [outlineColor, stateFlags]
            rendObj = ROBJ_IMAGE
            size = horAnimSize
            image = Picture($"ui/gameuiskin#hud_movement_arrow_left_corner.svg:{horAnimSize[0]}:{horAnimSize[1]}")
            hplace = flipX ? ALIGN_RIGHT : ALIGN_LEFT
            vplace = ALIGN_CENTER
            color = (stateFlags.get() & S_ACTIVE) != 0 ? fillColorDef.get() : outlineColor.get()
            margin = [0, cornerOffset]
            flipX
          }
          mkGamepadShortcutImage(shortcutId,
            flipX ? { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(-20), 0] }
              : { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(20), 0] },
            scale)
        ])
  }, ovrExt)
})

let mkStopBtn = kwarg(function mkMoveHor(onTouchBegin, onTouchEnd, shortcutId = null, ovr = {},
  outlineColor = outlineColorDef
) {
  let stateFlags = Watched(0)
  let { size = verSize } = ovr
  let stopSize = stopSizeMul.map(@(v, i) (v * size[i]).tointeger())
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
  let scale = size[0].tofloat() / verSize[0]
  return res.__update({
    size
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = TouchScreenButton
    cameraControl = false
    children = [
      @() {
        watch = stateFlags
        rendObj = ROBJ_IMAGE
        keepAspect = true
        size = stopSize
        image = Picture($"ui/gameuiskin#hud_movement_stop2_bg.svg:{stopSize[0]}:{stopSize[1]}")
        color = (stateFlags.get() & S_ACTIVE) != 0 ? bgColorPushed : bgColor
        children = {
          rendObj = ROBJ_TEXT
          vplace = ALIGN_CENTER
          hplace = ALIGN_CENTER
          text =loc("hud/movementArrows/stopBtn")
          transform = scale == 1 ? null : { pivot = [0.5, 0.5], scale = [scale, scale] }
        }.__update(fontTiny)
      }
      @() {
        watch = outlineColor
        rendObj = ROBJ_IMAGE
        keepAspect = true
        size = stopSize
        image = Picture($"ui/gameuiskin#hud_movement_stop2_outline.svg:{stopSize[0]}:{stopSize[1]}")
        color = outlineColor.get()
      }
    ]
  }, ovr)
})

let mkMoveVertBtnAnimBg = @(flipY, calcPart = @() 1.0, size = verSize, fillColor = fillColorDef) {
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
    color = fillColor.get()
    update = @() { transform = { scale = [1, calcPart()] } }
  }
}

let mkMoveVertBtnOutline = @(flipY, size = verSize, outlineColor = outlineColorDef) @() {
  watch = outlineColor
  rendObj = ROBJ_IMAGE
  size
  image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_outline.svg:{size[0]}:{size[1]}")
  color = outlineColor.get()
  flipY
}

function mkMoveVertBtnCorner(flipY, cornerColor = Watched(hudAshGrayColor), btnSize = verSize) {
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
    color = cornerColor.get()
    transitions = [{ prop = AnimProp.color, duration = animTime }]
    flipY
  }
}

function mkMoveVertBtn(onTouchBegin, onTouchEnd, shortcutId, ovr = {}) {
  let stateFlags = Watched(0)
  let { size = verSize } = ovr
  let res = mkContinuousButtonParams(onTouchBegin, onTouchEnd, shortcutId, stateFlags)
  return @() res.__merge({
    watch = [stateFlags, isActiveWithPieMenu]
    size
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{size[0]}:{size[1]}")
    color = (stateFlags.get() & S_ACTIVE) != 0 && isActiveWithPieMenu.get() ? bgColorPushed : bgColor
    cameraControl = false
  }, ovr)
}

function mkMoveVertBtn2step(calcPart = @() 1.0, cornerColor = Watched(hudAshGrayColor),
  btnSize = verSize, fillColor = fillColorDef
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
        color = cornerColor.get()
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
          color = fillColor.get()
          update = @() { transform = { scale = [1, calcPart()] } }
        }
      }
    ]
  }
}

function mkMoveHorView(flipX, viewSize = horSize) {
  let horAnimSize = horAnimSizeMul.map(@(v, i) (v * viewSize[i]).tointeger())
  let cornerOffset = (0.72 * horAnimSize[0]).tointeger()
  return {
    size = viewSize
    children = [
      {
        size = viewSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_bg.svg:{viewSize[0]}:{viewSize[1]}")
        color = bgColor
        flipX
      }
      {
        size = viewSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_outline.svg:{viewSize[0]}:{viewSize[1]}")
        flipX
      }
      {
        size = horAnimSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_left_corner.svg:{horAnimSize[0]}:{horAnimSize[1]}")
        hplace = flipX ? ALIGN_RIGHT : ALIGN_LEFT
        vplace = ALIGN_CENTER
        color = hudAshGrayColor
        margin = [0, cornerOffset]
        flipX
      }
    ]
  }
}

function mkMoveVertView(flipY, viewSize = verSize) {
  let verCornerSize = verCornerSizeMul.map(@(v, i) (v * viewSize[i]).tointeger())
  let cornerOffset = (0.3 * verCornerSize[1]).tointeger()
  return {
    size = viewSize
    children = [
      {
        size = viewSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_bg.svg:{viewSize[0]}:{viewSize[1]}")
        color = bgColor
        flipY
      }
      {
        size = viewSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_outline.svg:{viewSize[0]}:{viewSize[1]}")
        flipY
      }
      {
        size = verCornerSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_movement_arrow_forward_corner.svg:{verCornerSize[0]}:{verCornerSize[1]}")
        vplace = flipY ? ALIGN_BOTTOM : ALIGN_TOP
        hplace = ALIGN_CENTER
        color = hudAshGrayColor
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
    size = const [flex(), hdpx(30)]
    rendObj = ROBJ_TEXT
    halign = ALIGN_CENTER
    text = loc("HUD/ENGINE_REV_STOP_SHORT")
  }.__update(fontTiny))

let mkMoveArrowsAirView = @() {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    mkMoveHorView(false, horSizeAir)
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        mkMoveVertView(false, verSizeAir)
        mkMoveVertView(true, verSizeAir)
      ]
    }
    mkMoveHorView(true, horSizeAir)
  ]
}

let moveArrowsAirView = mkMoveArrowsAirView()

return {
  arrowsVerSize = verSize

  mkMoveLeftBtn = mkMoveHorCtor(false)
  mkMoveRightBtn = mkMoveHorCtor(true)
  mkMoveVertBtn
  mkMoveVertBtnAnimBg
  mkMoveVertBtnOutline
  mkMoveVertBtnCorner
  mkMoveVertBtn2step
  mkStopBtn

  outlineColorDef
  fillMoveColorDef
  fillMoveColorBlocked

  moveArrowsView
  moveArrowsViewWithMode
  moveArrowsAirView
}