from "%globalsDarg/darg_library.nut" import *
let { dfAnimBottomRight } = require("%rGui/style/unitDelayAnims.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { isUnitDelayed } = require("%rGui/hudState.nut")
let { bulletToggleButton, bulletHintRightAlign } = require("bullets/bulletToggleButton.nut")

return @() {
  watch = isUnitDelayed
  size = [4.5 * touchButtonSize, 2.5 * touchButtonSize]
  margin = [touchButtonSize, 0]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = isUnitDelayed.value ? null
    : {
        pos = [0, -2.0 * touchButtonSize]
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          bulletHintRightAlign
          bulletToggleButton
        ]
      }
  transform = {}
  animations = dfAnimBottomRight
}