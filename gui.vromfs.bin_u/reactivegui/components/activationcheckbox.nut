from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/spinner.nut" import waitDimmingSpinner
from "%rGui/style/stdColors.nut" import hoverColor, textColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale


const checkBoxSize = hdpx(80)
const checkBoxIconSize = hdpxi(72)
const checkBoxPadding = hdpx(10)

const checkBoxBorderColor = 0xFF9FA7AF
const checkBoxBgColor = 0x88000000

let mkCheckMark = @(sf, isDisabled, hasSpinner) {
  size = checkBoxSize
  rendObj = ROBJ_BOX
  opacity = isDisabled ? 0.5 : 1.0
  borderColor = (sf & S_HOVER) ? hoverColor : checkBoxBorderColor
  borderWidth = hdpx(3)
  fillColor = checkBoxBgColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = hasSpinner ? null : const [0, 0, checkBoxPadding, checkBoxPadding]
  children = hasSpinner ? waitDimmingSpinner
    : {
        size = checkBoxIconSize
        rendObj = ROBJ_IMAGE
        image = isDisabled ? null : Picture($"ui/gameuiskin#daily_mark_claimed.avif:{checkBoxIconSize}:P")
        keepAspect = KEEP_ASPECT_FIT
        color = textColor
      }
}

let mkTitle = @(sf, isDisabled) {
  size = FLEX_H
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  clipChildren = true
  children = {
    size = FLEX_H
    rendObj = ROBJ_TEXT
    padding = const [0, checkBoxPadding]
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    behavior = Behaviors.Marquee
    delay = defMarqueeDelay
    opacity = isDisabled ? 0.5 : 1
    text = isDisabled ? loc("activation/use") : loc("activation/using")
    color = (sf & S_HOVER) ? hoverColor : null
  }.__update(fontTinyAccentedShaded)
}

function mkActivationCheckbox(isDisabledW, hasSpinnerW, onToggle) {
  let stateFlags = Watched(0)

  return @() {
    watch = [stateFlags, isDisabledW, hasSpinnerW]
    behavior = Behaviors.Button
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    margin = const [hdpx(20), 0, 0, 0]
    onElemState = @(sf) stateFlags.set(sf)
    onClick = @() hasSpinnerW.get() ? null : onToggle()
    children = [
      mkCheckMark(stateFlags.get(), isDisabledW.get(), hasSpinnerW.get())
      mkTitle(stateFlags.get(), isDisabledW.get())
    ]
    ...mkPressTransitionScale(stateFlags.get())
  }
}

return { mkActivationCheckbox }
