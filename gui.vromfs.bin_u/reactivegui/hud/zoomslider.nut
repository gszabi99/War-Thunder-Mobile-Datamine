from "%globalsDarg/darg_library.nut" import *
let { dfAnimBottomCenter } = require("%rGui/style/unitDelayAnims.nut")
let { resetTimeout } = require("dagor.workcycle")
let { setZoomMult } = require("controls")
let { isUnitDelayed, isInZoom, zoomMult } = require("%rGui/hudState.nut")


let stepZoom = 0.01

let height = shHud(25)
let scaleWidth = (12.0 / 177.0 * height).tointeger()
let knobSize = 3 * scaleWidth
let knobPadding = scaleWidth
let sliderPadding = 2 * scaleWidth
let fullWidth = knobSize + 2 * sliderPadding
let zoomScaleHeight = height - knobSize

let idleTimeForZoomOpacity = 5
let needOpacityZoom = Watched(false)
let makeOpacityZoom = @() needOpacityZoom(true)

let knobColor = Color(230, 230, 230, 230)

let zoomScale = {
  size = [scaleWidth * 2, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(5)
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

let zoomBgrImage = Picture("!ui/gameuiskin#hud_plane_slider.avif")

let function changeZoomValue(val) {
  val = clamp(val, 0, 1.0)
  needOpacityZoom(false)
  resetTimeout(idleTimeForZoomOpacity, makeOpacityZoom)
  setZoomMult(1.0 - val)
}

let function zoomSlider() {
  let knob = {
    size  = [knobSize + 2 * knobPadding, knobSize + 2 * knobPadding]
    pos = [0, ((1.0 - zoomMult.value) * zoomScaleHeight).tointeger() - knobPadding]
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

  return {
    watch = [ zoomMult, needOpacityZoom ]
    key = zoomMult
    size = [fullWidth, height]
    pos = [-shHud(50), 0]
    padding = [0, sliderPadding]
    behavior = Behaviors.Slider
    fValue = zoomMult.value
    knob = knob
    max = 1.0
    unit = stepZoom
    orientation = O_VERTICAL
    opacity = needOpacityZoom.value ? 0.5 : 1.0
    transitions = [{ prop = AnimProp.opacity, duration = 0.5, easing = Linear }]
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
      knob
    ]
    onAttach = @() needOpacityZoom(true)
    onChange = changeZoomValue
  }
}

let viewSlider = @() {
  watch = [isInZoom, isUnitDelayed]
  size = [fullWidth, height]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = !isInZoom.value || isUnitDelayed.value ? null : zoomSlider
  transform = {}
  animations = dfAnimBottomCenter
}

return viewSlider
