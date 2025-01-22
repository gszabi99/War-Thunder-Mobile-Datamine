from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let { allPermissions, dbgPermissions } = require("%appGlobals/permissions.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { textButtonCommon, textButtonBright } = require("%rGui/components/textButton.nut")


let wndWidth = sh(130)
let gap = hdpx(10)

let wndUid = "permissionsWnd"
let close = @() removeModalWindow(wndUid)

let mkBtn = @(label, isActive, func) (isActive ? textButtonBright : textButtonCommon)(
  label, func, { ovr = { size = [flex(), hdpx(100)] } })

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
    rows.top().resize(2, { size = flex() })

  return {
    watch = allPermissions
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = [0, gap]
    gap
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

return @() addModalWindow(bgShaded.__merge({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = modalWndBg.__merge({
    size = [wndWidth + 2 * gap, sh(90)]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderWithClose("Permissions", close)
      { size = [flex(), gap] }
      makeVertScroll(permissionsList)
      { size = [flex(), gap] }
    ]
  })
}))
