from "%globalsDarg/darg_library.nut" import *
from "%globalsDarg/screenMath.nut" import scaleArr


let dasRadarHud = load_das("%rGui/radar/radar.das")

const radarColor = 0xFF00FF00
const radarColorEdit = 0x80008000
let radarSize = [hdpx(325), hdpx(325)]

let radarHudCtor = @(scale) {
  size = scaleArr(radarSize, scale)
  rendObj = ROBJ_DAS_CANVAS
  script = dasRadarHud
  drawFunc = "draw_radar_hud"
  setupFunc = "setup_radar_data"
  color = radarColor
  font = fontVeryTiny.font
  fontSize = fontVeryTiny.fontSize
  hasTxtBlock = true
}

let radarHudWithOverlayCtor = @(scale) {
  size = scaleArr(radarSize, scale)
  rendObj = ROBJ_BOX
  fillColor = 0x40000000
  children = radarHudCtor(scale)
}

let radarHudEditView = {
  size = radarSize
  flow = FLOW_VERTICAL
  padding = const [0, 0, hdpx(115), hdpx(45)]
  children = [
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_LEFT
      color = radarColorEdit
      text = loc("hud/search")
    }.__update(fontTiny)
    {
      size = FLEX
      padding = const [0, hdpx(75), 0, hdpx(30)]
      children = {
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#radar_editor.svg")
        color = radarColorEdit
      }
    }
    {
      size = 0
      hplace = ALIGN_RIGHT
      children = {
        pos = const [-hdpx(45), 0]
        rendObj = ROBJ_TEXT
        color = radarColorEdit
        text = loc("measureUnits/km_dist")
      }.__update(fontTinyAccented)
    }
  ]
}

return {
  radarHudCtor
  radarHudWithOverlayCtor
  radarHudEditView
}
