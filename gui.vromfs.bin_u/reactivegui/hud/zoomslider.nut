from "%globalsDarg/darg_library.nut" import *
let { setZoomMult } = require("controls")
let { isInZoom, zoomMult } = require("%rGui/hudState.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { allShortcutsUp } = require("%rGui/controls/shortcutsMap.nut")
let { defShortcutOvr} = require("%rGui/hud/buttons/hudButtonsPkg.nut")
let { mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")


let stepZoom = 0.01

function calcSizes(scale) {
  let height = hdpxi(270 * scale)
  let scaleWidth = (12.0 / 177.0 * height).tointeger()
  let knobSize = 3 * scaleWidth
  let sliderPadding = 2 * scaleWidth
  return {
    height
    scaleWidth
    knobSize
    knobPadding = scaleWidth
    sliderPadding
    fullWidth = knobSize + 2 * sliderPadding
    zoomScaleHeight = height - knobSize
    lineWidth = hdpx(5 * scale)
  }
}

let knobColor = Color(230, 230, 230, 230)

let mkZoomScale = @(scaleWidth, lineWidth) {
  size = [scaleWidth * 2, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth
  commands = [
    [VECTOR_LINE, 0, 10, 100, 10],
    [VECTOR_LINE, 0, 20, 70, 20],
    [VECTOR_LINE, 0, 30, 60, 30],
    [VECTOR_LINE, 0, 40, 50, 40],
    [VECTOR_LINE, 0, 50, 70, 50],
    [VECTOR_LINE, 0, 60, 40, 60],
    [VECTOR_LINE, 0, 70, 30, 70],
    [VECTOR_LINE, 0, 80, 20, 80],
    [VECTOR_LINE, 0, 90, 50, 90],
  ]
}

let zoomShortcutId = "ID_CHANGE_ZOOM"
let zoomBgrImage = Picture("!ui/gameuiskin#hud_plane_slider.avif")

function changeZoomValue(val) {
  val = clamp(val, 0, 1.0)
  setZoomMult(1.0 - val)
}

function mkGamepadZoomHotkeyButton(scale) {
  let imageComp = mkGamepadShortcutImage(zoomShortcutId, defShortcutOvr, scale)
  let sf = Watched(0)
  let isActive = Computed(@() (sf.get() & S_ACTIVE) != 0)
  let btn = {
    key = zoomShortcutId
    behavior = Behaviors.Button
    onElemState = @(v) sf.set(v)
    onClick = @() setZoomMult(zoomMult.get() == 1 ? 0 : 1)
    hotkeys = [allShortcutsUp[zoomShortcutId]]
  }

  return @() {
    watch = [isGamepad, isActive]
    key = imageComp
    hplace = ALIGN_RIGHT
    pos = [pw(90), 0]
    children = [isGamepad.get() ? imageComp : null, btn]
    transform = { scale = isActive.get() ? [0.8, 0.8] : [1.0, 1.0] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
  }
}

function mkZoomSliderImpl(scale) {
  let { height, scaleWidth, knobSize, knobPadding, sliderPadding, fullWidth, zoomScaleHeight, lineWidth
  } = calcSizes(scale)
  let knob = {
    size  = [knobSize + 2 * knobPadding, knobSize + 2 * knobPadding]
    hplace = ALIGN_CENTER
    padding = knobPadding
    children = {
      size  = [knobSize, knobSize]
      fillColor = knobColor
      color = knobColor
      rendObj = ROBJ_VECTOR_CANVAS
      commands = [
        [VECTOR_ELLIPSE, 50, 50, 50, 50]
      ]
    }
  }

  let zoomScale = mkZoomScale(scaleWidth, lineWidth)

  return @() {
    watch = zoomMult
    key = zoomMult
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    behavior = Behaviors.Slider
    fValue = zoomMult.value
    knob = knob
    max = 1.0
    unit = stepZoom
    orientation = O_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_CENTER
        pos =  [scaleWidth, 0]
        children = [
          {
            size = [scaleWidth, zoomScaleHeight]
            rendObj = ROBJ_IMAGE
            image = zoomBgrImage
          }
          zoomScale
        ]
      }
      knob.__merge({ pos = [0, ((1.0 - zoomMult.value) * zoomScaleHeight).tointeger() - knobPadding] })
      mkGamepadZoomHotkeyButton(scale)
    ]
    onChange = changeZoomValue
  }
}

let mkZoomSlider = @(scale) @() {
  watch = isInZoom
  children = !isInZoom.get() ? null : mkZoomSliderImpl(scale)
}

function mkEditView() {
  let { height, scaleWidth, knobSize, sliderPadding, fullWidth, zoomScaleHeight, lineWidth
  } = calcSizes(1)
  return {
    size = [fullWidth, height]
    padding = [0, sliderPadding]
    children = [
      {
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_CENTER
        pos =  [scaleWidth, 0]
        children = [
          {
            size = [scaleWidth, zoomScaleHeight]
            rendObj = ROBJ_IMAGE
            image = zoomBgrImage
          }
          mkZoomScale(scaleWidth, lineWidth)
        ]
      }
      {
        size  = [knobSize, knobSize]
        pos = [- knobSize * 0.6, knobSize * 0.5]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/gameuiskin#hud_binoculars_zoom.svg")
      }
    ]
  }
}

let zoomSliderEditView = mkEditView()

return {
  mkZoomSlider
  zoomSliderEditView
}
