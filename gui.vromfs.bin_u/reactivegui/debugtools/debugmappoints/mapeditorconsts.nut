from "%globalsDarg/darg_library.nut" import *

const INC_AREA = sh(2)
const START_MOVE_TIME_MSEC = 300
const MOVE_MIN_THRESHOLD = sh(1) 

let optionBtnSize = evenPx(70)
let defaultBgElemSize = evenPx(100)
let imgSize = evenPx(54)

const optionsBtnGap = hdpx(30)

const btnBgColorDefault = 0xFF00DEFF
const btnBgColorPositive = 0xFF1FDA6A
const btnBgColorNegative = 0xFFDA1F22
const btnBgColorDisabled = 0x80202020
const btnImgColor = 0xFFFFFFFF
const btnImgColorDisabled = 0x80808080

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
