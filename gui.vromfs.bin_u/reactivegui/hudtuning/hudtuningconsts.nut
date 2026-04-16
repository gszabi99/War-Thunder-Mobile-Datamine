from "%globalsDarg/darg_library.nut" import *

let ALIGN_C = 0
let ALIGN_L = 0x01
let ALIGN_R = 0x02
let ALIGN_T = 0x04
let ALIGN_B = 0x08

let fontsList = [
  { id = "tiny", font = fontVeryVeryTinyShaded }
  { id = "small", font = fontVeryTinyShaded }
  { id = "medium", font = fontTinyShaded, isDefault = true }
  { id = "big", font = fontSmallShaded }
]

let tuningStateDefault = {
  options = {
    scale = 1.0
    textWidth = 1.0
    fontSize = (fontsList.findvalue(@(f) f?.isDefault ?? false) ?? fontsList[0]).id
  }
  customOptions = {
    doublePrimaryGuns = true
    doubleCourseGuns = false
    hasDoubleRepair = false
    bulletsRight = false
  }
}

function alignToDargPlaceImpl(align) {
  let hplace = (align & ALIGN_L) ? ALIGN_LEFT
    : (align & ALIGN_R) ? ALIGN_RIGHT
    : ALIGN_CENTER
  let vplace = (align & ALIGN_T) ? ALIGN_TOP
    : (align & ALIGN_B) ? ALIGN_BOTTOM
    : ALIGN_CENTER
  return {
    hplace
    halign = hplace
    vplace
    valign = vplace
  }
}

let places = {}
function alignToDargPlace(align) {
  if (align not in places)
    places[align] <- alignToDargPlaceImpl(align)
  return places[align]
}

return {
  ALIGN_C
  ALIGN_L
  ALIGN_R
  ALIGN_T
  ALIGN_B

  ALIGN_RT = ALIGN_R | ALIGN_T
  ALIGN_RB = ALIGN_R | ALIGN_B
  ALIGN_LT = ALIGN_L | ALIGN_T
  ALIGN_LB = ALIGN_L | ALIGN_B
  ALIGN_CT = ALIGN_C | ALIGN_T
  ALIGN_CB = ALIGN_C | ALIGN_B

  alignToDargPlace

  fontsList
  tuningStateDefault

  optionWidth = hdpx(870)
}