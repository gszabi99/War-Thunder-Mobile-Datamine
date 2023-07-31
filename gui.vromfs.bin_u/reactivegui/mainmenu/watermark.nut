from "%globalsDarg/darg_library.nut" import *
let { is_android } = require("%sqstd/platform.nut")

return !is_android ? null : {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  padding = [ 0, saBorders[0], hdpxi(8), 0 ]
  rendObj = ROBJ_TEXT
  text = "Open Beta"
}.__update(fontSmall)
