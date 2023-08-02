from "%globalsDarg/darg_library.nut" import *
let getBulletImage = require("%appGlobals/config/bulletsPresentation.nut")
let { simpleVerGrad } = require("%rGui/style/gradients.nut")

let function mkBulletSlot(bulletInfo, bInfoFromUnitTags, ovr = {}) {
  if (bulletInfo == null)
    return null
  local { icon = null } = bInfoFromUnitTags
  if (icon != null)
    icon = $"{icon}.svg"
  else
    icon = (bulletInfo?.isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1_he0.svg"
  let imageBulletName = getBulletImage(bulletInfo.bullets)
  return {
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_IMAGE
    image = simpleVerGrad
    color = 0xFF264A4E
    flipY = true
    children = [
      {
        size = [hdpxi(214), hdpxi(105)]
        rendObj = ROBJ_IMAGE
        image = Picture($"{imageBulletName}:{hdpxi(214)}:{hdpxi(105)}:P")
        keepAspect = KEEP_ASPECT_FIT
      }
      {
        size = [hdpxi(80), hdpxi(80)]
        rendObj = ROBJ_IMAGE
        hplace = ALIGN_RIGHT
        vplace = ALIGN_CENTER
        image = Picture($"ui/gameuiskin#{icon}:{hdpxi(80)}:{hdpxi(80)}:P")
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }.__update(ovr)
}

return mkBulletSlot
