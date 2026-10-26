from "%globalsDarg/darg_library.nut" import *
from "types" import Float
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/activeControls.nut" import isGamepad
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/textButton.nut" import iconTextButton, mergeStyles


const propertyBtnDefWidth = hdpx(300)
const propertyBtnDefHeight = hdpx(80)
const propertyIconSize = hdpx(50)
const childGap = hdpx(20)
let propertyBtnDefSize = [propertyBtnDefWidth, propertyBtnDefHeight]
const arrowsIcon = "ui/gameuiskin#decor_change_icon.svg"

let mkClanChangeBtn = @(btnTxt, action, size = propertyBtnDefSize, styleOvr = {})
  function() {
    let gamepadWidth = isGamepad.get() ? hdpx(70) : 0
    let textMaxWidth = !(size[0] instanceof Float) ? null
      : size[0] - propertyIconSize - childGap - gamepadWidth
    let style = mergeStyles({
      iconOvr = {
        size = propertyIconSize
        transform = { rotate = 90 }
      }
      ovr = {
        minWidth = 0,
        size
        padding = isGamepad.get() ? null : 0
      }
      childOvr = { gap = childGap, halign = ALIGN_LEFT }
      textOvr = {
        maxWidth = textMaxWidth,
        halign = ALIGN_CENTER,
        valign = ALIGN_CENTER,
        behavior = Behaviors.Marquee
      }.__update(fontTinyAccentedShaded)
      useFlexText = true,
    }, styleOvr)

    return {
    watch = isGamepad
    children = iconTextButton(arrowsIcon,
      btnTxt,
      action,
      mergeStyles(buttonStyles.COMMON, style))
    }
  }



let mkClanPropertyBtnWithTitle = @(cfg, btnTxt, action, size = propertyBtnDefSize) {
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(cfg.locTitle))
    }.__update(fontTinyAccentedShaded)
    mkClanChangeBtn(btnTxt, action, size)
  ]
}

return {
  mkClanChangeBtn
  propertyBtnDefHeight
  mkClanPropertyBtnWithTitle
}
