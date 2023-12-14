from "%globalsDarg/darg_library.nut" import *
let { translucentButton, translucentIconButton } = require("%rGui/components/translucentButton.nut")
let { openUnitAttrWnd, availableAttributes } = require("unitAttrState.nut")
let mkAvailAttrMark = require("mkAvailAttrMark.nut")
let { unseenModsByCategory } = require("%rGui/unitMods/unitModsState.nut")

let status = keepref(Computed(function() {
  local res = availableAttributes.value.status
  if (res == -1 && unseenModsByCategory.value.len() > 0)
    res = 0
  return res
}))

let statusMark = @(sf) @() {
    watch = status
    size = [0, 0]
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkAvailAttrMark(status.value, hdpx(62), sf)
}

return {
  btnOpenUnitAttr = translucentButton("ui/gameuiskin#modify.svg", "", openUnitAttrWnd, statusMark)
  btnOpenUnitAttrBig = translucentIconButton("ui/gameuiskin#modify.svg", openUnitAttrWnd, hdpxi(75), [hdpx(150), hdpx(110)], statusMark)
}