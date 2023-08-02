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
let fontLarge = {
  font = Fonts.muller_medium
  fontSize = hdpxi(77)
}
let fontVeryLarge = {
  font = Fonts.muller_medium
  fontSize = hdpxi(97)
}

let fontWtSmall = {
  font = Fonts.wtfont
  fontSize = hdpxi(35)
}
let fontWtMedium = {
  font = Fonts.wtfont
  fontSize = hdpxi(42)
}
let fontWtBig = {
  font = Fonts.wtfont
  fontSize = hdpxi(58)
}
let fontWtLarge = {
  font = Fonts.wtfont
  fontSize = hdpxi(70)
}
let fontWtVeryLarge = {
  font = Fonts.wtfont
  fontSize = hdpxi(100)
}
let fontWtExtraLarge = {
  font = Fonts.wtfont
  fontSize = hdpxi(150)
}

let fontVeryTinyShaded = fontVeryTiny.__merge(shade)
let fontTinyShaded = fontTiny.__merge(shade)
let fontTinyAccentedShaded = fontTinyAccented.__merge(shade)
let fontSmallShaded = fontSmall.__merge(shade)
let fontSmallAccentedShaded = fontSmallAccented.__merge(shade)
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
    fontLarge
    fontVeryLarge
    fontWtSmall
    fontWtMedium
    fontWtBig
    fontWtLarge
    fontWtVeryLarge
    fontWtExtraLarge
  }
  commonShaded = {
    fontVeryTinyShaded
    fontTinyShaded
    fontTinyAccentedShaded
    fontSmallShaded
    fontSmallAccentedShaded
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
