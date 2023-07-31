let { Fonts } = require("daRg")
let { hdpxi } = require("screenUnits.nut")

let shade = {
  fontFx = FFT_GLOW
  fontFxColor = 0xFF000000
  fontFxFactor = hdpxi(64)
}

let fontVeryVeryTiny = {
  font = Fonts.muller_regular
  fontSize = hdpxi(15)
}
let fontVeryTiny = {
  font = Fonts.muller_regular
  fontSize = hdpxi(22)
}
let fontTiny = {
  font = Fonts.muller_regular
  fontSize = hdpxi(27)
}
let fontTinyAccented = {
  font = Fonts.muller_medium
  fontSize = hdpxi(29)
}
let fontSmall = {
  font = Fonts.muller_medium
  fontSize = hdpxi(35)
}
let fontSmallAccented = {
  font = Fonts.muller_medium
  fontSize = hdpxi(37)
}
let fontMedium = {
  font = Fonts.muller_medium
  fontSize = hdpxi(42)
}
let fontBig = {
  font = Fonts.muller_medium
  fontSize = hdpxi(57)
}
let fontVeryLarge = {
  font = Fonts.muller_medium
  fontSize = hdpxi(97)
}

let fontVeryTinyShaded = fontVeryTiny.__merge(shade)
let fontTinyAccentedShaded = fontTinyAccented.__merge(shade)
let fontMediumShaded = fontMedium.__merge(shade)
let fontBigShaded = fontBig.__merge(shade)
let fontVeryLargeShaded = fontVeryLarge.__merge(shade)

let fontsSets = {
  common = {
    fontVeryVeryTiny
    fontVeryTiny
    fontTiny
    fontTinyAccented
    fontSmall
    fontSmallAccented
    fontMedium
    fontBig
    fontVeryLarge
  }
  commonShaded = {
    fontVeryTinyShaded
    fontTinyAccentedShaded
    fontMediumShaded
    fontBigShaded
    fontVeryLargeShaded
  }
}

let sortFunc = @(a, b) a.fontSize <=> b.fontSize
let fontsLists = fontsSets.map(@(v) v.values().sort(sortFunc))

let res = { fontsLists }
fontsSets.each(@(set) res.__update(set))

return freeze(res)
