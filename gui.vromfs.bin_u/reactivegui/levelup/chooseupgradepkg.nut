from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("%sqstd/math.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")

let offerCardWidth = hdpx(480)
let gapCards = isWidescreen ? hdpx(480) : hdpx(240)
let offerCardHeight = sh(70)

let wpCardPatternSize = [hdpx(140), hdpx(140)]
let premCardPatternSize = [hdpx(200), hdpx(200)]

let bgSlotColor = 0xFFe38e15

let offerCardBaseStyle = {
  rendObj = ROBJ_FRAME
  borderWidth = [hdpx(2), hdpx(2), 0, hdpx(2)]
  size = [ offerCardWidth, sh(80) ]
}

let mkBgGradient = @(height, ovr = {}) {
  size = [flex(), height]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#gradient_button.svg:{50}:{50}")
  color = 0xDC000000
}.__merge(ovr)

let topGradient = mkBgGradient((offerCardHeight / 4).tointeger())
let bottomGradient = mkBgGradient((offerCardHeight / 2).tointeger(),
  { transform = { rotate = 180 }, vplace = ALIGN_BOTTOM, color = 0xFF000000 })
let cardBgGradient = {
  size = flex()
  padding = [hdpx(1), 0, 0, 0]
  children = [
    topGradient
    bottomGradient
  ]
}

let mkOfferCardBgPatternChunk = @(patternSize) {
  size = patternSize
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#button_pattern.svg:{patternSize[0]}:{patternSize[1]}")
  keepAspect = KEEP_ASPECT_NONE
  color = 0x23000000
}

function mkOfferCardBgPattern(isUpgraded) {
  let patternSize = isUpgraded ? premCardPatternSize : wpCardPatternSize
  let patternChunk = mkOfferCardBgPatternChunk(patternSize)
  return {
    size = flex()
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

let battleRewardsTitle = @(unit){
  rendObj = ROBJ_TEXT
  hplace = ALIGN_LEFT
  text = "".concat(loc("attrib_section/battleRewards"), colon)
  color = unit?.isUpgraded ? premiumTextColor : 0xFFFFFFFF
  padding = [hdpx(10), hdpx(30)]
}.__update(fontTiny)

let premDesc = {
  flow = FLOW_VERTICAL
  pos = [offerCardWidth - hdpx(30), hdpx(30)]
  children =[
    {
      size = [hdpx(389), hdpx(144)]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      rendObj = ROBJ_IMAGE
      flipX = true
      image = simpleHorGrad
      color = bgSlotColor
      children = {
        size = flex()
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc("buyUnitAndExp/premDesc"))
        valign = ALIGN_CENTER
        margin = [hdpx(20), hdpx(30)]
      }.__update(fontVeryTiny)
    }
    {
      size = [hdpx(30), hdpx(30)]
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = 0x90000000
      color = 0
      commands = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 0]]
    }
  ]
}

let wpOfferCard = @(unit, contentCtor) {
  children = [
    { rendObj = ROBJ_SOLID, size = flex(), color = 0xC8212C3C }
    mkOfferCardBgPattern(unit?.isUpgraded)
    cardBgGradient
    contentCtor
  ]
}.__merge(offerCardBaseStyle)

let premOfferCard = @(unit, contentCtor) {
  children = [
    { rendObj = ROBJ_SOLID, size = flex(), color = 0xC8760302 }
    mkOfferCardBgPattern(unit?.isUpgraded)
    cardBgGradient
    contentCtor
    premDesc
  ]
}.__merge(offerCardBaseStyle)

return {
  gapCards

  wpOfferCard
  premOfferCard
  battleRewardsTitle
}