from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import ceil
from "%sqstd/string.nut" import utf8ToUpper
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/style/gradients.nut" import simpleHorGrad, simpleVerGrad
from "%rGui/style/stdColors.nut" import premiumTextColor


const fontIconPreview = "⌡"

const offerCardWidth = hdpx(550)
const offerCardHeight = hdpx(630)
const cardHPadding = hdpx(80)
const buyBtnMinWidth = hdpx(300)

let gapCards = isWidescreen ? hdpx(240) : hdpx(120)

let patternSize = [hdpx(200), hdpx(200)]
const bgSlotColor = 0xFFe38e15

let offerCardBaseStyle = {
  rendObj = ROBJ_FRAME
  borderWidth = const [hdpx(2), hdpx(2), 0, hdpx(2)]
  size = const [ offerCardWidth, offerCardHeight ]
}

let mkBgGradient = @(height, ovr = {}) {
  size = [FLEX, height]
  rendObj = ROBJ_IMAGE
  image = simpleVerGrad
  color = 0xDC000000
}.__merge(ovr)

let topGradient = mkBgGradient((offerCardHeight / 4).tointeger())
let bottomGradient = mkBgGradient((offerCardHeight / 2).tointeger(),
  { transform = { rotate = 180 }, vplace = ALIGN_BOTTOM, color = 0xFF000000 })
let cardBgGradient = {
  size = FLEX
  padding = const [hdpx(1), 0, 0, 0]
  children = [
    topGradient
    bottomGradient
  ]
}

let mkOfferCardBgPatternChunk = {
  size = patternSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{patternSize[0]}:{patternSize[1]}:P")
  color = 0x23000000
}

function mkOfferCardBgPattern() {
  let patternChunk = mkOfferCardBgPatternChunk
  return {
    size = FLEX
    clipChildren = true
    flow = FLOW_HORIZONTAL
    children = array(ceil(offerCardWidth.tofloat() / patternSize[0]).tointeger(),
      {
        flow = FLOW_VERTICAL
        children = array(ceil(offerCardHeight.tofloat() / patternSize[1]).tointeger(),
          patternChunk)
      })
  }
}

let battleRewardsTitle = @(unit, ovr = {}){
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = "".concat(loc("attrib_section/battleRewards"), colon)
  color = unit?.isUpgraded ? premiumTextColor : 0xFFFFFFFF
  padding = const [hdpx(10), hdpx(30)]
}.__update(fontTiny, ovr)


let premDesc = {
  flow = FLOW_VERTICAL
  pos = const [offerCardWidth - hdpx(30), hdpx(30)]
  children =[
    {
      size = const [hdpx(389), hdpx(144)]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      rendObj = ROBJ_IMAGE
      image = simpleHorGrad
      color = bgSlotColor
      flipX = true
      children = {
        margin = const [hdpx(20), hdpx(30)]
        size = FLEX
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc("buyUnitAndExp/premDesc"))
        valign = ALIGN_CENTER
      }.__update(fontVeryTiny)
    }
    {
      size = hdpx(30)
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = 0x90000000
      color = 0
      commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 0]]
    }
  ]
}

let wpOfferCard = @(content) {
  children = [
    { rendObj = ROBJ_SOLID, size = FLEX, color = 0xC8212C3C }
    mkOfferCardBgPattern()
    cardBgGradient
    content
  ]
}.__merge(offerCardBaseStyle)

let premOfferCard = @(content) {
  children = [
    { rendObj = ROBJ_SOLID, size = FLEX, color = 0xC8760302 }
    mkOfferCardBgPattern()
    cardBgGradient
    content
    premDesc
  ]
}.__merge(offerCardBaseStyle)

let ovrBuyBtn = {
  size = [SIZE_TO_CONTENT, buttonStyles.defButtonHeight]
  minWidth = buyBtnMinWidth
}

return {
  offerCardWidth
  offerCardHeight
  cardHPadding

  gapCards
  ovrBuyBtn
  fontIconPreview

  wpOfferCard
  premOfferCard
  battleRewardsTitle
}