from "%globalsDarg/darg_library.nut" import *
let { getBulletImage, getBulletTypeIcon } = require("%appGlobals/config/bulletsPresentation.nut")
let { getAmmoTypeShortText, getAmmoNameShortText } = require("%rGui/weaponry/weaponsVisual.nut")

let ICON_SIZE = hdpxi(80)
let headerHeight = hdpxi(108)
let bulletIconSize = [hdpxi(214), headerHeight]

function getSlotNumber(chosenBulletsList, id) {
  let slotNumber = chosenBulletsList.findvalue(@(b) b.name == id)?.idx
  return slotNumber == null ? "" : "".concat(loc("icon/mpstats/rowNo"), (slotNumber + 1))
}

let mkSlotNumber = @(id, chosenBullets) @() {
  watch = chosenBullets
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_TEXT
  padding = hdpx(5)
  text = getSlotNumber(chosenBullets.get(), id)
}.__update(fontTiny)

let nameBullet = @(bSet) {
  size = flex()
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  padding = hdpx(5)
  text = getAmmoNameShortText(bSet)
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

function mkBulletSlot(chosenBullets, bSet, bInfoFromUnitTags, ovrBulletImage = {}, ovrBulletIcon = {}, ovr = {}) {
  if (bSet == null)
    return null
  let icon = getBulletTypeIcon(bInfoFromUnitTags?.icon, bSet)
  let imageBulletName = getBulletImage(bInfoFromUnitTags?.image, bSet?.bullets ?? [])
  let nameText = getAmmoTypeShortText(bSet.bullets?[0] ?? "")
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
          mkSlotNumber(bSet.id, chosenBullets)
          nameBullet(bSet)
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
            image = Picture($"{icon}:{ICON_SIZE}:{ICON_SIZE}:P")
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
