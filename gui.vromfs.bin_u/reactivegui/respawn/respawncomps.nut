from "%globalsDarg/darg_library.nut" import *
from "string" import format
from "%appGlobals/config/bulletsPresentation.nut" import getBulletBeltImage, TOTAL_VIEW_BULLETS
from "%rGui/globals/fontUtils.nut" import getFontToFitWidth
from "%rGui/hud/scoreBoard.nut" import scoreBoardHeight
from "%rGui/respawn/respawnSkins.nut" import skinSize
from "%rGui/respawn/respawnState.nut" import hasSkins


const courseMenuKey = "courseMenuKey"
const courseTitleKey = "courseTitleKey"
const turretMenuKey = "turretMenuKey"
const turretTitleKey = "turretTitleKey"
const secondaryMenuKey = "secondaryMenuKey"
const secondaryTitleKey = "secondaryTitleKey"

const textColor = 0xFFD0D0D0
const headerHeight = hdpx(60)
const gap = hdpx(10)
const bulletsBlockWidth = hdpx(500)
const bulletsBlockMargin = hdpx(40)
const bulletsLegendWidth = hdpx(220)
const bulletsLegendTxtWidth = bulletsLegendWidth - gap*2
const contentOffset = hdpx(40)
let headerMargin = [0, hdpx(20), 0, bulletsBlockMargin]
let unitListHeight = saSize[1] - scoreBoardHeight - contentOffset - headerHeight - gap

const smallGap = hdpx(8)
let beltImgSize = evenPx(75)
let imgSize = evenPx(100)
const padding = hdpxi(5)
const defPadding = hdpxi(3)
let weaponSize = imgSize + 2 * padding
const weaponGroupWidth = hdpx(600)

const headerSlotHeight = hdpx(98)
const skinTextHeight = hdpx(29)
const topSkinPadding = hdpx(6)
const skinPadding = hdpx(10)
const skinGap = hdpx(12)
const minBSlotHeight = hdpx(194)
const maxBSlotHeight = hdpx(216)
const minGapHeight = hdpx(8)
const maxGapHeight = gap
let skinsListHeight = skinTextHeight + topSkinPadding + skinPadding + skinSize

let mkBulletHeightInfo = @(primaryBulletSlots, secondaryBulletSlots, specialBulletSlots) Computed(function() {
  let slots = primaryBulletSlots.get() + secondaryBulletSlots.get() + specialBulletSlots.get()
  if (slots == 0)
    return { slotSliderHeight = 0, gapHeight = 0 }
  let gaps = max(1, slots - 1)
  let baseBContentHeight = sh(100) - saBordersRv[0] * 2 - contentOffset - scoreBoardHeight - headerHeight - gap
  let currentBContentHeight = hasSkins.get()
    ? baseBContentHeight - skinsListHeight - skinGap
    : baseBContentHeight
  let slotBHeight = clamp(((currentBContentHeight - minGapHeight * gaps) / slots).tointeger(), minBSlotHeight, maxBSlotHeight)
  return {
    slotSliderHeight = slotBHeight - headerSlotHeight
    gapHeight = clamp(((currentBContentHeight - slotBHeight * slots) / gaps).tointeger(), minGapHeight, maxGapHeight)
  }
})

let defaultTitle = @(w) format(loc("weapons/counter/right/short"),
  w?.weapons.reduce(@(res, v) res + (w?.count ?? 1) * (v?.totalBullets ?? 1), 0) ?? w?.count ?? 1)

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

let headerText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = textColor
}.__update(fontTinyAccented)

let header = @(children, ovr = {}) bg.__merge({
  size = const [FLEX, headerHeight]
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

const bulletIconHeight = hdpxi(77)
function mkBulletsLegendBlock(text, bulletIcon, width, height) {
  let legendTxt = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [bulletsLegendTxtWidth, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    color = textColor
    text
  }.__update(fontVeryTinyAccented)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = gap
    children = [
      legendTxt.__update(getFontToFitWidth(legendTxt, bulletsLegendTxtWidth, [fontVeryVeryTinyAccented, fontVeryTinyAccented])),
      {
        size = FLEX_H
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
}

let bulletsLegend = {
  key = "bulletsLegend" 
  rendObj = ROBJ_BOX
  size = const [bulletsLegendWidth, hdpx(300) + gap]
  pos = const [0, headerHeight + gap]
  fillColor = 0x99000000
  borderWidth = hdpx(2)
  borderColor = textColor
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = hdpx(20)
  children = [
    mkBulletsLegendBlock(loc("respawn/bullet_armor_penetration"), "hint_ap", hdpxi(155), bulletIconHeight)
    mkBulletsLegendBlock(loc("respawn/bullet_explosion_power"), "hint_he", hdpxi(200), bulletIconHeight)
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

  skinTextHeight
  topSkinPadding
  skinPadding
  headerSlotHeight

  mkBulletHeightInfo

  mkBeltImage
}