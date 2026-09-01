from "%globalsDarg/darg_library.nut" import *
from "math" import round


return {
  scaleArr = @(arr, scale) scale == 1 ? arr : arr.map(@(v) round(v * scale).tointeger())
}