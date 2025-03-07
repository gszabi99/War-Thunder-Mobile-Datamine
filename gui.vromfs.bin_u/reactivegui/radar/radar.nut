from "%globalsDarg/darg_library.nut" import *
let dasRadarHud = load_das("%rGui/radar/radar.das")
let { scaleArr } = require("%globalsDarg/screenMath.nut")

let radarColor = 0xFF00FF00
let radarColorEdit = 0x80008000
let radarSize = [hdpxi(300), hdpxi(300)]

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

let radarHudEditView = {
  size = radarSize
  flow = FLOW_VERTICAL
  padding = [0, 0, hdpx(115), hdpx(45)]
  children = [
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_LEFT
      color = radarColorEdit
      text = loc("hud/search")
    }.__update(fontTiny)
    {
      size = flex()
      padding = [0, hdpx(75), 0, hdpx(30)]
      children = {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#radar_editor.svg")
        color = radarColorEdit
      }
    }
    {
      size = [0, 0]
      hplace = ALIGN_RIGHT
      children = {
        pos = [-hdpx(45), 0]
        rendObj = ROBJ_TEXT
        color = radarColorEdit
        text = loc("measureUnits/km_dist")
      }.__update(fontTinyAccented)
    }
  ]
}

return {
  radarHudCtor
  radarHudEditView
}
