from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let modalPopupWnd = require("%rGui/components/modalPopupWnd.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")

let wndUid = "chooseByName"
let close = @() modalPopupWnd.remove(wndUid)
let minWidth = hdpx(700)
let maxWidth = saSize[0]
let maxListHeight = saSize[1] - hdpx(300)
let gap = hdpx(20)
let vGap = 0
let font = fontSmall

let function valuesList(list, curValue, setValue) {
  if (list.len() == 0)
    return null

  let width = list.reduce(@(res, v) max(res, calc_str_box(v.text, font)[0]), 0)
  let height = calc_str_box("A", font)[1]
  local rowCount = (maxListHeight / (height + vGap)).tointeger()
  local columnCount = (maxWidth / (width + gap)).tointeger()
  let isFit = list.len() <= rowCount * columnCount
  if (!isFit)
    rowCount = ceil(list.len().tofloat() / columnCount).tointeger()
  else
    columnCount = ceil(list.len().tofloat() / rowCount).tointeger()

  let buttons = list.map(function(v) {
    let stateFlags = Watched(0)
    let { text, value } = v
    return @() {
      watch = stateFlags
      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags(sf)
      function onClick() {
        close()
        setValue(value)
      }
      rendObj = ROBJ_TEXT
      text
      color = curValue == value ? 0xFFFFFF00
        : stateFlags.get() & S_ACTIVE ? 0xFF8080FF
        : stateFlags.get() & S_HOVER ? 0xFFFFFFFF
        : 0xFFA0A0A0
    }.__update(font)
  })

  let res = {
    minWidth
    flow = FLOW_HORIZONTAL
    gap
    children = arrayByRows(buttons, rowCount).map(@(column) {
      flow = FLOW_VERTICAL
      gap = vGap
      children = column
    })
  }

  return isFit ? res
    : makeVertScroll(res, { size = SIZE_TO_CONTENT, maxHeight = maxListHeight })
}

return @(targetRect, header, list, curValue, setValue) modalPopupWnd.add(targetRect, {
  uid = wndUid
  popupOffset = hdpx(20)
  hotkeys = [[btnBEscUp, close]]
  popupBg = bgShaded
  children = {
    padding = gap
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = 0xF01E1E1E
    flow = FLOW_VERTICAL
    gap
    children = [
      {
        rendObj = ROBJ_TEXT
        text = header
        color = 0xFFA0A0A0
      }.__update(fontTiny)
      valuesList(list, curValue, setValue)
    ]
  }
})