from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let hasDoubleCourseGuns = @(options) !!options?.doubleCourseGuns
let optDoubleCourseGuns = {
  locId = "options/courseGun"
  ctrlType = OCT_LIST
  has = hasDoubleCourseGuns
  list = [false, true]
  getValue = hasDoubleCourseGuns
  function setValue(options, value) {
    options.doubleCourseGuns <- value
  }
  valToString = @(v) loc("options/buttonCount", { count = v ? 2 : 1 })
}

return {
  optDoubleCourseGuns
}