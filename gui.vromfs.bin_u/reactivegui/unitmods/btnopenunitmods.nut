from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { openUnitModsWnd, modsCategories } = require("unitModsState.nut")

return @() {
  watch = modsCategories
  children = modsCategories.value.len() == 0 ? null
    : translucentButton("ui/gameuiskin#arsenal.svg",
        loc("mainmenu/btnArsenal"),
        openUnitModsWnd)
}
