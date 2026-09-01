from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
import "%rGui/attributes/mkAvailAttrMark.nut" as mkAvailAttrMark
from "%rGui/attributes/unitAttr/unitAttrState.nut" import openUnitAttrWnd, availableAttributes
from "%rGui/components/textButton.nut" import iconTextButton, buttonStyles, mergeStyles
from "%rGui/unit/hangarUnit.nut" import setHangarUnit
from "%rGui/unitDetails/unitDetailsState.nut" import baseUnit


function onClick() {
  if (baseUnit.get())
    setHangarUnit(baseUnit.get().name)
  openUnitAttrWnd()
}

let statusUnitAttr = keepref(Computed(@() availableAttributes.get().status))

let statusMark = @(sf) @() {
  watch = [statusUnitAttr, sf]
  size = 0
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkAvailAttrMark(statusUnitAttr.get(), hdpx(62), sf.get())
}

return {
  statusUnitAttr
  mkBtnOpenUnitAttr = function(ovr) {
    let sf = Watched(0)
    return {
      children = [
        iconTextButton("ui/gameuiskin#modify.svg",
          utf8ToUpper(loc("unit/upgrades")),
          onClick,
          mergeStyles(buttonStyles.COMMON,
            {
              stateFlags = sf
              iconOvr = {size = hdpx(60)}
              textOvr = fontBoldTinyAccentedShaded
              childOvr = {gap = hdpx(20)}
            }.__update(ovr)))
        statusMark(sf)
    ]
    }
  }
}
