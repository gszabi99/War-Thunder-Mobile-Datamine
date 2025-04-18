from "%globalsDarg/darg_library.nut" import *
let { getBulletImage } = require("%appGlobals/config/bulletsPresentation.nut")
let { getAmmoTypeShortText, getAmmoNameShortText } = require("%rGui/weaponry/weaponsVisual.nut")
let { chosenBullets, chosenBulletsSec } = require("bulletsChoiceState.nut")

let ICON_SIZE = hdpxi(80)
let headerHeight = hdpxi(108)
let bulletIconSize = [hdpxi(214), headerHeight]

function getSlotNumber(chosenBulletsList, id) {
  let slotNumber = chosenBulletsList.findvalue(@(b) b.name == id)?.idx
  return slotNumber == null ? "" : "".concat(loc("icon/mpstats/rowNo"), (slotNumber + 1))
}

let slotNumber = @(id, isSecBullet) @() {
  watch = isSecBullet ? chosenBulletsSec : chosenBullets
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_TEXT
  padding = hdpx(5)
  text = getSlotNumber(isSecBullet ? chosenBulletsSec.get() : chosenBullets.get(), id)
}.__update(fontTiny)

let nameBullet = @(bulletInfo) {
  size = flex()
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  padding = hdpx(5)
  text = getAmmoNameShortText(bulletInfo)
  maxWidth = pw(100)
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  speed = hdpx(20)
}.__update(fontTiny)

let imageBullet = @(imageBulletName) {
  size = bulletIconSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{imageBulletName}:{bulletIconSize[0]}:{bulletIconSize[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
}

function mkBulletSlot(isSecBullet, bulletInfo, bInfoFromUnitTags, ovrBulletImage = {}, ovrBulletIcon = {}, ovr = {}) {
  if (bulletInfo == null)
    return null
  local { icon = null, image = null } = bInfoFromUnitTags
  if (icon != null)
    icon = $"{icon}.svg"
  else
    icon = (bulletInfo?.isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1_he0.svg"
  let imageBulletName = image != null
    ? $"ui/gameuiskin#{image}.avif"
    : getBulletImage(bulletInfo.bullets)
  let nameText = getAmmoTypeShortText(bulletInfo.bullets?[0] ?? "" )
  return {
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_SOLID
        color = 0xA02C2C2C
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        children = [
          imageBullet(imageBulletName)
          slotNumber(bulletInfo.id, isSecBullet)
          nameBullet(bulletInfo)
        ]
      }.__update(ovrBulletImage)
      {
        rendObj = ROBJ_SOLID
        color = 0x99000000
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        size = [hdpx(130), headerHeight]
        children = [
          {
            size = [ICON_SIZE,ICON_SIZE]
            rendObj = ROBJ_IMAGE
            vplace = ALIGN_CENTER
            image = Picture($"ui/gameuiskin#{icon}:{ICON_SIZE}:{ICON_SIZE}:P")
            keepAspect = KEEP_ASPECT_FIT
          }
          {
            rendObj = ROBJ_TEXT
            text = nameText
          }.__update(fontVeryTinyShaded)
        ]
      }.__update(ovrBulletIcon)
    ]
  }.__update(ovr)
}

return mkBulletSlot
