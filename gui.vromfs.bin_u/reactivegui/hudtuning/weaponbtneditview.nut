from "%globalsDarg/darg_library.nut" import *
let { borderColor, borderWidth, touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { defImageSize } = require("%rGui/hud/weaponsButtonsView.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { hudWhiteColor, hudBlackColor, hudTransparentColor } = require("%rGui/style/hudColors.nut")

let weaponNumberSize = (0.3 * touchButtonSize).tointeger()
let weaponNumberColor = hudBlackColor

let mkWeaponNumber = @(weaponNumber, isRoman = true) weaponNumber == 0 ? null : {
  pos = [pw(30), 0]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      size = [weaponNumberSize, weaponNumberSize]
      rendObj = ROBJ_BOX
      fillColor = hudWhiteColor
      transform = { rotate = 45 }
    }
    {
      rendObj = ROBJ_TEXT
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      color = weaponNumberColor
      text = isRoman ? getRomanNumeral(weaponNumber) : weaponNumber
    }.__update(fontVeryTiny)
  ]
}

let weaponBtnEditViewCtor = @(size, imgSize) function(image, relImageSize = 1, ovr = {}) {
  let imageSize = (imgSize * relImageSize + 0.5).tointeger()

  return {
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [size, size]
        color = hudTransparentColor
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_BOX
        size = [size, size]
        borderColor
        borderWidth
        transform = { rotate = 45 }
      }
      {
        rendObj = ROBJ_IMAGE
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        size = [imageSize, imageSize]
        image = Picture($"{image}:{imageSize}:{imageSize}")
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }.__update(ovr)
}
let mkWeaponBtnEditView = weaponBtnEditViewCtor(touchButtonSize, defImageSize)
let mkNumberedWeaponEditView = @(image, weaponNumber, isRoman = true) {
  children = [
    mkWeaponBtnEditView(image)
    mkWeaponNumber(weaponNumber, isRoman)
  ]
}

return {
  mkWeaponBtnEditView
  mkNumberedWeaponEditView
}
