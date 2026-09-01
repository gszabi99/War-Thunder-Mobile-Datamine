from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe, eventbus_unsubscribe
from "%rGui/unit/components/unitInfoPanel.nut" import statsWidth


const hintMaxWidth = hdpx(600)
const hintShiftX = hdpx(150)
const hintShiftY = hdpx(-100)
const hintPad = hdpx(20)
const hitTitleGap = hdpx(7)
let hintRightAlignedMaxX = sw(100) - hintShiftX - hintMaxWidth - statsWidth
const unitStatusTextMaxWidth = hdpx(600)

const accentColor = 0xFFFFFF80
const hintBgColor = 0xC0181818

const hitProbPossibleColor = 0xFFFFE000
const hitProbMinorColor = 0xFF808080

function toggleSubscription(event, func, isEnable) {
  let toggleFunc = isEnable ? eventbus_subscribe : eventbus_unsubscribe
  toggleFunc(event, func)
}

let mkDmViewerHint = @(isVisible, x, y, children) @() !isVisible.get() ? { watch = isVisible } : {
  watch = isVisible
  size = 0
  children = @() {
    watch = [x, y]
    size = 0
    pos = [x.get() + (hintShiftX * (x.get() < hintRightAlignedMaxX ? 1 : -1)), y.get() + hintShiftY]
    halign = x.get() < hintRightAlignedMaxX ? ALIGN_LEFT : ALIGN_RIGHT
    children = {
      padding = const [hintPad - hitTitleGap, hintPad, hintPad, hintPad]
      rendObj = ROBJ_SOLID
      color = hintBgColor
      children
    }
  }
}

let txtBase = {
  maxWidth = hintMaxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}

let mkHintTitle = @(textW) @() textW.get() == "" ? { watch = textW } : {
  watch = textW
  text = textW.get()
  color = accentColor
}.__update(txtBase, fontSmall)

let mkHintDescText = @(textW) @() textW.get() == "" ? { watch = textW } : {
  watch = textW
  margin = const [hitTitleGap, 0, 0, 0]
  text = textW.get()
}.__update(txtBase, fontVeryTiny)

let mkUnitStatusText = @(text) {
  maxWidth = unitStatusTextMaxWidth
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  text
}.__update(txtBase, fontMedium)

return {
  toggleSubscription
  mkDmViewerHint
  mkHintTitle
  mkHintDescText
  mkUnitStatusText
  accentColor
  hitProbPossibleColor
  hitProbMinorColor
}
