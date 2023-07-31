from "%globalsDarg/darg_library.nut" import *
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let size = [hdpx(325), hdpx(325)]

let tacticalMap = {
  size
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = 0x28000000
    }
    {
      key = "tactical_map"
      size = flex()
      rendObj = ROBJ_TACTICAL_MAP
    }
  ]
}

let tacticalMapEditView = {
  size
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("hotkeys/ID_TACTICAL_MAP")
  }.__update(fontSmall)
}

return {
  tacticalMap
  tacticalMapSize = size
  tacticalMapEditView
}
