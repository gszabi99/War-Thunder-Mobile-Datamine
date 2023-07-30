from "%globalsDarg/darg_library.nut" import *

return {
  size = [hdpx(325), hdpx(325)]
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = 0x28000000
    }
    {
      key = "tactical_map"
      size = flex()
      rendObj = ROBJ_TACTICAL_MAP
    }
  ]
}