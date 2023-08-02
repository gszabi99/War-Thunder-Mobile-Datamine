from "%globalsDarg/darg_library.nut" import *
let { chosenTitle } = require("%rGui/decorators/decoratorState.nut")

let mkTitle = @(ovr = {}) @() chosenTitle.value
  ? {
    watch = chosenTitle
    rendObj = ROBJ_TEXT
    text = loc($"title/{chosenTitle.value.name}")
    color = 0xFFFFB70B
  }.__update(ovr)
  : { watch = chosenTitle }


return {
  mkTitle
}