from "%globalsDarg/darg_library.nut" import *

let bulletIconSize = [hdpxi(80), hdpxi(80)]

let function mkBulletIcon(bulletInfo, bInfoFromUnitTags, ovr = {}) {
  if (bulletInfo == null)
    return null
  local { icon = null } = bInfoFromUnitTags
  if (icon != null)
    icon = $"{icon}.svg" //todo: need colored icons not the same with hud.
  else
    icon = (bulletInfo?.isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1.svg"

  return {
    size = bulletIconSize
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{icon}:{bulletIconSize[0]}:{bulletIconSize[1]}")
    keepAspect = KEEP_ASPECT_FIT
  }.__update(ovr)
}

return {
  bulletIconSize
  mkBulletIcon
}