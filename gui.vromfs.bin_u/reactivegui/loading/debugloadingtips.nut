from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "console" import register_command
from "%appGlobals/unitPresentation.nut" import unitTypeFontIcons, unitTypeColors
from "%globalsDarg/loading/loadingTips.nut" import getAllTips, GLOBAL_LOADING_TIP_BIT
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp


const wndUid = "debugLoadingTips"
const iconColorDefault = 0xFF808080
const textColor = 0xFFE0E0E0

function getTipsList() {
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
  size = FLEX_H
  color = textColor
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "\n".join(tips)
}.__update(fontTiny)

let tipsWnd = @(tips) {
  size = const [min(sw(95), hdpx(1600)), sh(95)]
  padding = hdpx(20)
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  children = makeVertScroll(
    tipsText(tips),
    { rootBase = { behavior = Behaviors.Pannable } })
}

let open = @() addModalWindow({
  key = wndUid
  size = FLEX
  hotkeys = [[btnBEscUp, @() removeModalWindow(wndUid)]]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = tipsWnd(getTipsList())
})

register_command(open, "debug.loading_tips")