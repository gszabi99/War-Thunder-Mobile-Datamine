from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let listButton = require("listButton.nut")

let gapH = hdpx(20)
let gapV = hdpx(10)


function listbox(value, list, columns = null, valToString = @(v) v, setValue = null, mkContentCtor = null) {
  setValue = setValue ?? @(v) value(v)
  let colCount = columns ?? list.len()
  let rows = arrayByRows(
    list.map(@(v)
      listButton(mkContentCtor ? @(sf, isSelected) mkContentCtor(v, sf, isSelected) : valToString(v),
        Computed(@() v == value.get()),
        @() setValue(v))),
    colCount
  )
  if (rows.len() > 0 && rows.top().len() < colCount)
    rows.top().resize(colCount, { size = flex() })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = [hdpx(20), 0]
    gap = gapV
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = gapH
      children
    })
  }
}

return kwarg(listbox)
