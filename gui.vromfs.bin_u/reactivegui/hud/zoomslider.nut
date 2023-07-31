from "%globalsDarg/darg_library.nut" import *
let { setZoomMult } = require("controls")
let { isInZoom, zoomMult } = require("%rGui/hudState.nut")


let stepZoom = 0.01

let height = shHud(25)
let scaleWidth = (12.0 / 177.0 * height).tointeger()
let knobSize = 3 * scaleWidth
let knobPadding = scaleWidth
let sliderPadding = 2 * scaleWidth
let fullWidth = knobSize + 2 * sliderPadding
let zoomScaleHeight = height - knobSize

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
  setZoomMult(1.0 - val)
}

let function mkZoomSlider(isDynamic = false) {
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
    watch = zoomMult
    key = zoomMult
    size = [fullWidth, height]
    pos = isDynamic ? null : [-shHud(50), 0]
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
      knob
    ]
    onChange = changeZoomValue
  }
}

let zoomSlider = @() {
  watch = isInZoom
  children = !isInZoom.value ? null : @() mkZoomSlider(true)
}

let zoomSliderEditView = {
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
        zoomScale
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

return {
  zoomSlider
  zoomSliderEditView
}
