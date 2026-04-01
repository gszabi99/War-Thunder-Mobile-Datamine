from "%globalsDarg/darg_library.nut" import *
from "math" import round, min
from "%rGui/unit/components/unitPlateComp.nut" import mkFlagImageWithoutGrad

let bgImage = "ui/images/help/help_event_walkers.avif"
let bgTexSize = [3282, 1041]

let bgImgRatio = 1.0 * bgTexSize[0] / bgTexSize[1]
let scrRatio = sw(100) / sh(100)
let minScrRatioForFullImage = 2340.0 / 1080
let minFitImgRatio = 2.0
let bgImgW = scrRatio >= minScrRatioForFullImage ? sw(100)
  : min(sh(100) * minScrRatioForFullImage, sw(100) / minFitImgRatio * bgImgRatio)

let bgImgSize = [bgImgW, round(1.0 * bgImgW / bgTexSize[0] * bgTexSize[1]).tointeger()]
let bgSizeMul = 1.0 * bgImgW / bgTexSize[0]

let bgTexPx = @(s) round(bgSizeMul * s).tointeger()
let sizeByBgTexSize = @(size) size.map(bgTexPx)

let uPosL = 1190
let uPosR = 2090
let uPosT = 30
let uPosB = 520

let units = [
  { pos = [uPosL, uPosT], unitName = "ussr_sht_1", country = "country_ussr", weapons = 2 }
  { pos = [uPosR, uPosT], unitName = "cn_victor", country = "country_china", weapons = 2 }
  { pos = [uPosL, uPosB], unitName = "germ_trixter", country = "country_germany", weapons = 2 }
  { pos = [uPosR, uPosB], unitName = "us_bulldog", country = "country_usa", weapons = 3 }
]

let getSmallestFontSize = @(listId) fontsLists[listId].map(@(v) v.fontSize).reduce(@(a, b) min(a, b))

function getNearestSmallerFont(listId, lessThanFontSize) {
  local selSize = 0
  local res = null
  foreach (f in fontsLists[listId])
    if (selSize == 0 || (f.fontSize > selSize && f.fontSize < lessThanFontSize)) {
      selSize = f.fontSize
      res = f
    }
  return res
}

let cornerLineWidth = bgTexPx(4)
let cornerLineLen = bgTexPx(50)

let lineH = {
  size = [cornerLineLen, cornerLineWidth]
  rendObj = ROBJ_SOLID
  color = 0xFFFFFFFF
}
let lineV = lineH.__merge({ size = [cornerLineWidth, cornerLineLen] })

let posRT = { hplace = ALIGN_RIGHT }
let posLB = { vplace = ALIGN_BOTTOM }
let posRB = posRT.__merge(posLB)

let frameCorners = {
  size = flex()
  children = [
    lineH
    lineH.__merge(posRT)
    lineH.__merge(posLB)
    lineH.__merge(posRB)
    lineV
    lineV.__merge(posRT)
    lineV.__merge(posLB)
    lineV.__merge(posRB)
  ]
}

let barrelShading = {
  size = sizeByBgTexSize([100, 40])
  pos = sizeByBgTexSize([uPosR, 100])
  rendObj = ROBJ_SOLID
  color = 0xFF488BA6
  opacity = 0.6
}

let mkTextFrame = @(pos, children) {
  pos
  rendObj = ROBJ_SOLID
  color = 0x1F1F1F1F
  children = [
    frameCorners
    {
      padding = bgTexPx(25)
      children
    }
  ]
}

let mkTextarea = @(text, maxWidth, ovr = {}) {
  size = [maxWidth, SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontVeryVeryTiny, ovr)

let textMaxW = bgTexPx(376)
let flagW = bgTexPx(68)
let flagGap = bgTexPx(9)
let bullet = loc("ui/bullet")

function mkUnitDescComp(cfg, fontDefault, fontTitle) {
  let { pos, unitName, country, weapons, ovr = {} } = cfg
  let weapNums = array(weapons).map(@(_, i) i + 1)
  let sep = { size = [1, 0.35 * fontDefault.fontSize] }
  return mkTextFrame(sizeByBgTexSize(pos), {
    flow = FLOW_VERTICAL
    children = [
      {
        size = [textMaxW, SIZE_TO_CONTENT]
        children = [
          mkFlagImageWithoutGrad(country, flagW, { hplace = ALIGN_RIGHT })
          mkTextarea(loc(unitName), textMaxW - flagW - flagGap, fontTitle)
        ]
      }
      mkTextarea(loc($"help/event/walkers/u/{unitName}"), textMaxW, fontDefault)
      sep
      mkTextarea("".concat(loc("help/event/walkers/armament"), colon), textMaxW, fontDefault)
    ].extend(weapNums.map(@(v) mkTextarea("".concat(bullet, loc($"help/event/walkers/{unitName}/w{v}")), textMaxW, fontDefault)))
  }.__update(ovr))
}

let maxTextFrameH = bgTexPx(549)
let maxFontSizeDefault = bgTexPx(43)
let maxFontSizeTitle = bgTexPx(43)

function mkCompsInternal() {
  let fontTitle = getNearestSmallerFont("accented", maxFontSizeTitle)
  let smallestFontSize = getSmallestFontSize("common")
  local prevFontSz = maxFontSizeDefault
  local fontDefault
  local res
  local heights
  while (true) {
    fontDefault = getNearestSmallerFont("common", prevFontSz)
    res = units.map(@(u) mkUnitDescComp(u, fontDefault, fontTitle))
    heights = res.map(@(c) calc_comp_size(c)[1])
    if (fontDefault.fontSize == smallestFontSize || heights.findvalue(@(h) h > maxTextFrameH) == null)
      break
    prevFontSz = fontDefault.fontSize
  }
  for (local i = 0; i < units.len(); i++) {
    let c = res[i]
    let h = heights[i]
    if (i == 1) {
      if (h > bgTexPx(445))
        c.pos[1] = bgTexPx(10)
    }
    else if (i >= units.len() / 2)
      c.pos[1] = bgTexPx(1025) - h
  }
  return res.insert(0, barrelShading)
}

local comps = null
function mkComps() {
  if (comps == null)
    comps = mkCompsInternal()
  return comps
}

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = bgImgSize
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = mkComps()
    }
  }
}

return makeScreen