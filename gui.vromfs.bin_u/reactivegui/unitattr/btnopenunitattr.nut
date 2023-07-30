from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openUnitAttrWnd, availableAttributes } = require("unitAttrState.nut")
let mkAvailAttrMark = require("mkAvailAttrMark.nut")

let status = Computed(@() availableAttributes.value.status)

let statusMark = @(sf) @() {
    watch = status
    size = [0, 0]
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkAvailAttrMark(status.value, hdpx(62), sf)
}

return translucentButton("ui/gameuiskin#modify.svg",
  loc("mainmenu/btnUpgrades"),
  openUnitAttrWnd,
  statusMark)