from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { scoreBoardHeight } = require("%rGui/hud/scoreBoard.nut")
let { unitPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")
let { getBulletBeltImage, TOTAL_VIEW_BULLETS } = require("%appGlobals/config/bulletsPresentation.nut")

let courseMenuKey = "courseMenuKey"
let courseTitleKey = "courseTitleKey"
let turretMenuKey = "turretMenuKey"
let turretTitleKey = "turretTitleKey"
let secondaryMenuKey = "secondaryMenuKey"
let secondaryTitleKey = "secondaryTitleKey"

let textColor = 0xFFD0D0D0
let headerHeight = hdpx(60)
let gap = hdpx(10)
let bulletsBlockWidth = hdpx(520)
let bulletsBlockMargin = hdpx(40)
let bulletsLegendWidth = hdpx(260)
let contentOffset = hdpx(40)
let headerMargin = [0, hdpx(20), 0, bulletsBlockMargin]
let unitListHeight = saSize[1] - scoreBoardHeight - contentOffset - headerHeight - unitPlatesGap

let smallGap = hdpx(8)
let beltImgSize = evenPx(75)
let imgSize = evenPx(100)
let padding = hdpxi(5)
let defPadding = hdpxi(3)
let weaponSize = imgSize + 2 * padding
let weaponGroupWidth = hdpx(600)

let defaultTitle = @(w) format(loc("weapons/counter/right/short"), (w?.count ?? 1) * (w?.weapons[0].totalBullets ?? 1))

function caliberTitle(w) {
  let { caliber = null } = w.bulletSets.findvalue(@(_) true)
  return " ".join([
      caliber != null ? format(loc("caliber/mm"), caliber) : "",
      (w?.count ?? 1) == 1 ? "" : format(loc("weapons/counter/right/short"), w.count)
    ],
    false)
}

let weaponTitles = {
  ["machine gun"] = caliberTitle,
  ["additional gun"] = caliberTitle,
  cannon = caliberTitle,
  gunner = caliberTitle,
}

let getWeaponTitle = @(w) (weaponTitles?[w?.trigger] ?? defaultTitle)(w)

let bg = {
  rendObj = ROBJ_SOLID
  color = 0x99000000
}

let headerText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
  color = textColor
}.__update(fontTinyAccented, ovr)

let header = @(children, ovr = {}) bg.__merge({
  size = [flex(), headerHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children
}, ovr)

let headerMarquee = @(width) {
  size = [width, SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
  delay = defMarqueeDelay
  speed = hdpx(50)
}

let bulletIconHeight = hdpxi(77)
let bulletsLegendBlock = @(text, bulletIcon, width, height) {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  padding = gap
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [ flex(), SIZE_TO_CONTENT ]
      halign = ALIGN_CENTER
      color = textColor
      text
    }.__update(fontVeryTiny),
    {
      size = [ flex(), SIZE_TO_CONTENT ]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_IMAGE
        size = [ width, height ]
        opacity = 0.7
        image = Picture($"ui/gameuiskin#{bulletIcon}.svg:{width}:{height}:P")
      }
    }
  ]
}

let bulletsLegend = {
  key = "bulletsLegend" //for UI tutorial
  rendObj = ROBJ_BOX
  size = [ bulletsLegendWidth, hdpx(300) + gap ]
  pos = [ 0, headerHeight + gap ]
  fillColor = 0x99000000
  borderWidth = hdpx(2)
  borderColor = textColor
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    bulletsLegendBlock(loc("respawn/bullet_armor_penetration"), "hint_ap", hdpxi(155), bulletIconHeight)
    bulletsLegendBlock(loc("respawn/bullet_explosion_power"), "hint_he", hdpxi(200), bulletIconHeight)
  ]
}

let mkSimpleIcon = @(image) {
  size = [imgSize, imgSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  keepAspect = true
}

function commonWeaponIcon(w) {
  let { iconType = "" } = w
  return iconType == "" ? null : mkSimpleIcon($"ui/gameuiskin#{iconType}.avif")
}

function mkBeltImage(bullets, beltSize = weaponSize) {
  if (bullets.len() == 0)
    return null
  let list = array(TOTAL_VIEW_BULLETS).map(@(_, i) bullets[i % bullets.len()])

  return {
    size = [beltSize, beltSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#shadow.avif:{beltSize}:{beltSize}:P")
    keepAspect = true
    padding
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = list.map(@(name, idx) {
      size = [beltImgSize, beltImgSize]
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"{getBulletBeltImage(name, idx)}:{beltImgSize}:{beltImgSize}:P")
      keepAspect = true
    })
  }
}

return {
  bg
  gap
  textColor
  headerText
  header
  headerMargin
  headerHeight
  headerMarquee
  bulletsBlockWidth
  bulletsBlockMargin
  bulletsLegend
  bulletsLegendWidth
  contentOffset
  unitListHeight
  beltImgSize
  imgSize
  padding
  defPadding
  weaponSize
  weaponGroupWidth
  smallGap
  commonWeaponIcon

  getWeaponTitle
  caliberTitle

  courseMenuKey
  courseTitleKey
  turretMenuKey
  turretTitleKey
  secondaryMenuKey
  secondaryTitleKey

  mkBeltImage
}