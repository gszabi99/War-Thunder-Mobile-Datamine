from "%globalsDarg/darg_library.nut" import *
let { chosenTitle } = require("%rGui/decorators/decoratorState.nut")

let defMarkSize = hdpxi(30)

let mkTitle = @(ovr = {}) @() chosenTitle.value
  ? {
    watch = chosenTitle
    rendObj = ROBJ_TEXT
    text = loc($"title/{chosenTitle.value.name}")
    color = 0xFFFFB70B
  }.__update(ovr)
  : { watch = chosenTitle }

let choosenMark = @(size = defMarkSize, ovr = {}) {
  size = [size, size]
  margin = const [hdpxi(10), hdpxi(15)]
  rendObj = ROBJ_IMAGE
  color = 0xFF78FA78
  image = Picture($"ui/gameuiskin#check.svg:{size}:{size}:P")
  keepAspect = KEEP_ASPECT_FIT
}.__update(ovr)

return {
  mkTitle
  choosenMark
}
