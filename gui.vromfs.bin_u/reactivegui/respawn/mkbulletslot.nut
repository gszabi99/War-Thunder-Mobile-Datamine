from "%globalsDarg/darg_library.nut" import *
let getBulletImage = require("%appGlobals/config/bulletsPresentation.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { getAmmoTypeShortText } = require("%rGui/weaponry/weaponsVisual.nut")
let { touchButtonSize } = require("%rGui/hud/hudTouchButtonStyle.nut")

let bgSlotColor = 0xFF51C1D1
let slotBGImage = mkBitmapPicture(gradTexSize, gradTexSize,
  mkGradientCtorRadial(bgSlotColor, 0 , 20, 55, 35, 0))
let ICON_SIZE = hdpxi(80)

let function mkBulletSlot(bulletInfo, bInfoFromUnitTags, ovr = {}) {
  if (bulletInfo == null)
    return null
  local { icon = null } = bInfoFromUnitTags
  if (icon != null)
    icon = $"{icon}.svg"
  else
    icon = (bulletInfo?.isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1_he0.svg"
  let imageBulletName = getBulletImage(bulletInfo.bullets)
  let nameText = getAmmoTypeShortText(bulletInfo.bullets?[0] ?? "" )
  return {
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_IMAGE
    image = slotBGImage
    children = [
      {
        size = [hdpxi(214), hdpxi(105)]
        rendObj = ROBJ_IMAGE
        image = Picture($"{imageBulletName}:{hdpxi(214)}:{hdpxi(105)}:P")
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        size = [touchButtonSize, flex()]
        halign = ALIGN_CENTER
        children = [
          {
            size = [ICON_SIZE, ICON_SIZE]
            rendObj = ROBJ_IMAGE
            vplace = ALIGN_TOP
            image = Picture($"ui/gameuiskin#{icon}:{ICON_SIZE}:{ICON_SIZE}:P")
            keepAspect = KEEP_ASPECT_FIT
          }
          {
            rendObj = ROBJ_TEXT
            vplace = ALIGN_BOTTOM
            text = nameText
          }.__update(fontVeryTinyShaded)
        ]
      }
    ]
  }.__update(ovr)
}

return mkBulletSlot
