from "%globalsDarg/darg_library.nut" import *

let size = evenPx(70)
let imgSize = evenPx(54)

let btnBgColorDefault = 0xFF00DEFF
let btnBgColorPositive = 0xFF1FDA6A
let btnBgColorNegative = 0xFFDA1F22
let btnBgColorDisabled = 0x80202020
let btnImgColor = 0xFFFFFFFF
let btnImgColorDisabled = 0x80808080

let tuningBtnImg = @(image, ovr = {}) {
  size = [imgSize, imgSize]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  color = btnImgColor
}.__update(ovr)

let function tuningBtn(image, onClick, ovr = {}) {
  let stateFlags = Watched(0)
  let children = type(image) == "string" ? tuningBtnImg(image) : image
  return @() {
    watch = stateFlags
    size = [size, size]
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    onElemState = @(sf) stateFlags(sf)
    behavior = Behaviors.Button
    onClick
    sound = { click  = "click" }
    children
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let tuningBtnInactive = @(image, onClick)
  tuningBtn(tuningBtnImg(image, { color = btnImgColorDisabled }),
    onClick,
    { color = btnBgColorDisabled })

let tuningBtnWithActivity = @(isActive, image, onClick) @() {
  watch = isActive
  children = (isActive.value ? tuningBtn : tuningBtnInactive)(image, onClick)
}

return {
  tuningBtn
  tuningBtnInactive
  tuningBtnWithActivity
  tuningBtnImg
  btnBgColorDefault
  btnBgColorPositive
  btnBgColorNegative
  btnBgColorDisabled
  btnImgColor
  btnImgColorDisabled
}