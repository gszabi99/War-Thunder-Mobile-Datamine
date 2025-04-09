from "%globalsDarg/darg_library.nut" import *

let INC_AREA = sh(2)
let START_MOVE_TIME_MSEC = 300
let MOVE_MIN_THRESHOLD = sh(1) //ignore threshold after START_MOVE_TIME

let optionBtnSize = evenPx(70)
let defaultBgElemSize = evenPx(100)
let imgSize = evenPx(54)

let optionsBtnGap = hdpx(30)

let btnBgColorDefault = 0xFF00DEFF
let btnBgColorPositive = 0xFF1FDA6A
let btnBgColorNegative = 0xFFDA1F22
let btnBgColorDisabled = 0x80202020
let btnImgColor = 0xFFFFFFFF
let btnImgColorDisabled = 0x80808080

return {
  INC_AREA
  START_MOVE_TIME_MSEC
  MOVE_MIN_THRESHOLD
  optionBtnSize
  imgSize
  optionsBtnGap
  btnBgColorDefault
  btnBgColorPositive
  btnBgColorNegative
  btnBgColorDisabled
  btnImgColor
  btnImgColorDisabled
  defaultBgElemSize
}
