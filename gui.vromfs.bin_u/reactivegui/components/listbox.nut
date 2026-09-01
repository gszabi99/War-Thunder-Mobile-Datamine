from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
import "%rGui/components/listButton.nut" as listButton


const gapH = hdpx(20)
const gapV = hdpx(10)


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
    rows.top().resize(colCount, { size = FLEX })
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
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
