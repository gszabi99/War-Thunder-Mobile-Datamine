from "%globalsDarg/darg_library.nut" import *
let { translucentButton, translucentIconButton } = require("%rGui/components/translucentButton.nut")
let { openUnitAttrWnd, availableAttributes } = require("unitAttrState.nut")
let mkAvailAttrMark = require("%rGui/attributes/mkAvailAttrMark.nut")
let { unseenModsByCategory } = require("%rGui/unitMods/unitModsState.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { baseUnit } = require("%rGui/unitDetails/unitDetailsState.nut")

let function onClick() {
  if (baseUnit.get())
    setHangarUnit(baseUnit.get().name)
  openUnitAttrWnd()
}

let statusUnitAttr = keepref(Computed(function() {
  local res = availableAttributes.get().status
  if (res == -1 && unseenModsByCategory.get().len() > 0)
    res = 0
  return res
}))

let statusMark = @(sf) @() {
  watch = statusUnitAttr
  size = [0, 0]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkAvailAttrMark(statusUnitAttr.get(), hdpx(62), sf)
}

return {
  statusUnitAttr
  btnOpenUnitAttr = translucentButton("ui/gameuiskin#modify.svg", "", onClick, statusMark)
  btnOpenUnitAttrBig = translucentIconButton("ui/gameuiskin#modify.svg", onClick, hdpxi(75), [hdpx(150), hdpx(110)], statusMark)
  btnOpenUnitAttrCustom = @(imageSize, bgSize)
    translucentIconButton("ui/gameuiskin#modify.svg", onClick, imageSize, bgSize, statusMark)
}
