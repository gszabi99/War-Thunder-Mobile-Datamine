from "%globalsDarg/darg_library.nut" import *
let { hudIndicatorsState, indicatorTypes } = require("hudIndicatorsState.nut")

let indicatorsKey = {}
return @() {
  watch = hudIndicatorsState
  key = indicatorsKey
  size = flex()
  children = hudIndicatorsState.get().values().map(@(data) indicatorTypes[data.indicatorType].ctor(data))
}
