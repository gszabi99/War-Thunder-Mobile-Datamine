from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/permissions.nut" import allPermissions, dbgPermissions
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/textButton.nut" import textButtonCommon, textButtonPrimary
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/backgrounds.nut" import bgShaded


const wndWidth = hdpx(1500)
const gap = hdpx(10)

const wndUid = "permissionsWnd"
let close = @() removeModalWindow(wndUid)

let mkBtn = @(label, isActive, func) (isActive ? textButtonPrimary : textButtonCommon)(
  label, func, { ovr = { size = const [FLEX, hdpx(100)] } })

function permissionsList() {
  let list = allPermissions.get()
    .keys()
    .sort()
    .map(function(name) {
      let isActive = allPermissions.get()[name]
      return mkBtn($"{name} = {isActive}", isActive, @() dbgPermissions.mutate(@(v) v[name] <- !v?[name]))
    })
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = FLEX })

  return {
    watch = allPermissions
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = const [0, gap]
    gap
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

return @() addModalWindow(bgShaded.__merge({
  key = wndUid
  size = FLEX
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = modalWndBg.__merge({
    size = const [wndWidth + 2 * gap, sh(90)]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderWithClose("Permissions", close)
      { size = [FLEX, gap] }
      makeVertScroll(permissionsList)
      { size = [FLEX, gap] }
    ]
  })
}))
