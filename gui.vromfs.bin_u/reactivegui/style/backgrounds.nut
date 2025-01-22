from "%globalsDarg/darg_library.nut" import *

let bgShaded = {
  rendObj = ROBJ_SOLID
  color = 0x80001521
}

let bgShadedLight = {
  rendObj = ROBJ_SOLID
  color = 0x60000F18
}

let bgShadedDark = {
  rendObj = ROBJ_SOLID
  color = 0xB0001A29
}

return freeze({
  bgShaded
  bgShadedLight
  bgShadedDark
})
