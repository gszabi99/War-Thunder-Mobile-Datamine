from "%globalsDarg/darg_library.nut" import *
let { mkSimpleCircleTouchBtn } = require("buttons/circleTouchHudButtons.nut")
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")({
  onClick = @() toggleShortcut("ID_FREECAM_TOGGLE")
})

let gap = hdpx(40)

let movementBlock = {
  flow = FLOW_VERTICAL
  gap
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = mkSimpleCircleTouchBtn("ui/gameuiskin#circle.svg", "ID_FREECAM_FORWARD")
    }
    {
      flow = FLOW_HORIZONTAL
      gap
      children = [
        mkSimpleCircleTouchBtn("ui/gameuiskin#circle.svg", "ID_FREECAM_LEFT")
        mkSimpleCircleTouchBtn("ui/gameuiskin#circle.svg", "ID_FREECAM_BACK")
        mkSimpleCircleTouchBtn("ui/gameuiskin#circle.svg", "ID_FREECAM_RIGHT")
      ]
    }
  ]
}

let zoomBlock = {
  flow = FLOW_HORIZONTAL
  gap
  children = [
    mkSimpleCircleTouchBtn("ui/gameuiskin#hud_movement_arrow_forward_bg.svg", "ID_FREECAM_ZOOM_IN")
    mkSimpleCircleTouchBtn("ui/gameuiskin#hud_movement_arrow_forward_bg.svg", "ID_FREECAM_ZOOM_OUT",
      { transform = { rotate = 180 } })
  ]
}

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "free-cam-hud"
  children = [
    menuButton
    {
      flow = FLOW_VERTICAL
      gap
      children = [
        movementBlock
        zoomBlock
      ]
    }
  ]
}
