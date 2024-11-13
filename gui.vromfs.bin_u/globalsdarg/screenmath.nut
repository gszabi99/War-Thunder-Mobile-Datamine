from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

return {
  scaleArr = @(arr, scale) scale == 1 ? arr : arr.map(@(v) round(v * scale).tointeger())
}