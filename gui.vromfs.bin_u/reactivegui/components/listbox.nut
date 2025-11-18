from "%globalsDarg/darg_library.nut" import *
let { arrayByRows } = require("%sqstd/underscore.nut")
let listButton = require("%rGui/components/listButton.nut")

let gapH = hdpx(20)
let gapV = hdpx(10)


function listbox(value, list, columns = null, valToString = @(v) v, setValue = null, mkContentCtor = null) {
  setValue = setValue ?? @(v) value.set(v)
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
    size = FLEX_H
    flow = FLOW_VERTICAL
    margin = const [hdpx(20), 0]
    gap = gapV
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = gapH
      children
    })
  }
}

return kwarg(listbox)
