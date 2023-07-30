from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { getAllTips, GLOBAL_LOADING_TIP_BIT } = require("%globalsDarg/loading/loadingTips.nut")
let { unitTypeFontIcons, unitTypeColors } = require("%appGlobals/unitPresentation.nut")
let { register_command } = require("console")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let wndUid = "debugLoadingTips"
let iconColorDefault = 0xFF808080
let textColor = 0xFFE0E0E0

let function getTipsList() {
  let tipsLocId = getAllTips()

  let res = (tipsLocId?[GLOBAL_LOADING_TIP_BIT] ?? []).map(@(v) loc(v))
  foreach (unitType in unitTypeOrder) {
    let locIds = tipsLocId?[unitTypeToBit(unitType)]
    if (locIds == null)
      continue
    let iconColor = unitTypeColors?[unitType] ?? iconColorDefault
    let icon = colorize(iconColor, unitTypeFontIcons?[unitType] ?? "")
    foreach (locId in locIds)
      res.append(" ".concat(icon, loc(locId)))
  }
  return res
}

let tipsText = @(tips) {
  size = [flex(), SIZE_TO_CONTENT]
  color = textColor
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "\n".join(tips)
}.__update(fontTiny)

let tipsWnd = @(tips) {
  size = [min(sw(95), hdpx(1600)), sh(95)]
  padding = hdpx(20)
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  children = makeVertScroll(
    tipsText(tips),
    { rootBase = class { behavior = Behaviors.Pannable } })
}

let open = @() addModalWindow({
  key = wndUid
  size = flex()
  hotkeys = [["Esc", @() removeModalWindow(wndUid)]]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = tipsWnd(getTipsList())
})

register_command(open, "debug.loading_tips")