from "%globalsDarg/darg_library.nut" import *

let textColor = 0xFFD0D0D0
let headerHeight = hdpx(60)
let gap = hdpx(10)
let bulletsBlockWidth = hdpx(520)
let bulletsBlockMargin = hdpx(40)

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
  size = [flex(), headerHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children
}, ovr)

let headerMarquee = @(width) {
  size = [width, SIZE_TO_CONTENT]
  behavior = Behaviors.Marquee
  delay = 1
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
  rendObj = ROBJ_BOX
  size = [ hdpx(220), hdpx(300) + gap ]
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

return {
  bg
  gap
  headerText
  header
  headerHeight
  headerMarquee
  bulletsBlockWidth
  bulletsBlockMargin
  bulletsLegend
}