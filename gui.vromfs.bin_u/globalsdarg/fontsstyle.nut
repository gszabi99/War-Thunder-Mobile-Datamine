let { Fonts } = require("daRg")
let { hdpxi } = require("screenUnits.nut")
let { getLocalLanguage = @() "" } = require_optional("language")
let { getCurrentLanguage = @() "" } = require_optional("dagor.localize")

let language = getLocalLanguage() == "" ? getCurrentLanguage() : getLocalLanguage()
let isJp = language == "Japanese"
let muller_regular = isJp ? Fonts.muller_regular_jp : Fonts.muller_regular
let muller_medium = isJp ? Fonts.muller_medium_jp : Fonts.muller_medium
let muller_mono_regular = Fonts.muller_mono_regular // Only chars "0123456789.,:-+% "
let muller_mono_medium = Fonts.muller_mono_medium // Only chars "0123456789.,:-+% "
let wtfont = Fonts.wtfont

let shadeTiny = {
  fontFx = FFT_GLOW
  fontFxColor = 0xB3000000
  fontFxFactor = hdpxi(32)
}
let shade = {
  fontFx = FFT_GLOW
  fontFxColor = 0xFF000000
  fontFxFactor = hdpxi(64)
}

let fontVeryVeryTiny = {
  font = muller_regular
  fontSize = hdpxi(17)
}
let fontVeryVeryTinyAccented = {
  font = muller_regular
  fontSize = hdpxi(20)
}
let fontVeryTiny = {
  font = muller_regular
  fontSize = hdpxi(22)
}
let fontVeryTinyAccented = {
  font = muller_medium
  fontSize = hdpxi(23)
}
let fontTiny = {
  font = muller_regular
  fontSize = hdpxi(27)
}
let fontTinyAccented = {
  font = muller_medium
  fontSize = hdpxi(29)
}
let fontSmall = {
  font = muller_medium
  fontSize = hdpxi(35)
}
let fontSmallAccented = {
  font = muller_medium
  fontSize = hdpxi(37)
}
let fontMedium = {
  font = muller_medium
  fontSize = hdpxi(42)
}
let fontBig = {
  font = muller_medium
  fontSize = hdpxi(57)
}
let fontLarge = {
  font = muller_medium
  fontSize = hdpxi(77)
}
let fontVeryLarge = {
  font = muller_medium
  fontSize = hdpxi(97)
}

let fontWtSmall = {
  font = wtfont
  fontSize = hdpxi(35)
}
let fontWtMedium = {
  font = wtfont
  fontSize = hdpxi(42)
}
let fontWtBig = {
  font = wtfont
  fontSize = hdpxi(58)
}
let fontWtLarge = {
  font = wtfont
  fontSize = hdpxi(70)
}
let fontWtVeryLarge = {
  font = wtfont
  fontSize = hdpxi(100)
}
let fontWtExtraLarge = {
  font = wtfont
  fontSize = hdpxi(150)
}

let fontVeryVeryTinyShaded = fontVeryVeryTiny.__merge(shadeTiny)
let fontVeryVeryTinyAccentedShaded = fontVeryVeryTinyAccented.__merge(shadeTiny)
let fontVeryTinyShaded = fontVeryTiny.__merge(shadeTiny)
let fontVeryTinyAccentedShaded = fontVeryTinyAccented.__merge(shadeTiny)
let fontTinyShaded = fontTiny.__merge(shadeTiny)
let fontTinyAccentedShaded = fontTinyAccented.__merge(shadeTiny)
let fontSmallShaded = fontSmall.__merge(shade)
let fontSmallAccentedShaded = fontSmallAccented.__merge(shade)
let fontMediumShaded = fontMedium.__merge(shade)
let fontBigShaded = fontBig.__merge(shade)
let fontVeryLargeShaded = fontVeryLarge.__merge(shade)

let fontMonoVeryTiny = fontVeryTiny.__merge({ font = muller_mono_regular })
let fontMonoTiny = fontTiny.__merge({ font = muller_mono_regular })
let fontMonoMedium = fontMedium.__merge({ font = muller_mono_medium })

let fontMonoVeryTinyShaded = fontVeryTiny.__merge({ font = muller_mono_regular }, shadeTiny)
let fontMonoTinyShaded = fontTiny.__merge({ font = muller_mono_regular }, shadeTiny)
let fontMonoTinyAccentedShaded = fontTinyAccented.__merge({ font = muller_mono_medium }, shadeTiny)

let fontsSets = {
  common = {
    fontVeryVeryTiny
    fontVeryTiny
    fontTiny
    fontSmall
    fontMedium
    fontBig
    fontLarge
    fontVeryLarge
  }
  commonShaded = {
    fontVeryVeryTinyShaded
    fontVeryTinyShaded
    fontTinyShaded
    fontSmallShaded
    fontMediumShaded
    fontBigShaded
    fontVeryLargeShaded
  }
  accented = {
    fontVeryVeryTinyAccented
    fontVeryTinyAccented
    fontTinyAccented
    fontSmallAccented
  }
  accentedShaded = {
    fontVeryVeryTinyAccentedShaded
    fontVeryTinyAccentedShaded
    fontTinyAccentedShaded
    fontSmallAccentedShaded
  }
  monospace = {
    fontMonoVeryTiny
    fontMonoTiny
    fontMonoMedium
  }
  monospaceShaded = {
    fontMonoVeryTinyShaded
    fontMonoTinyShaded
    fontMonoTinyAccentedShaded
  }
  fontWt = {
    fontWtSmall
    fontWtMedium
    fontWtBig
    fontWtLarge
    fontWtVeryLarge
    fontWtExtraLarge
  }
}

let sortFunc = @(a, b) a.fontSize <=> b.fontSize
let fontsLists = fontsSets.map(@(v) v.values().sort(sortFunc))

let res = { fontsLists, shadeTiny }
fontsSets.each(@(set) res.__update(set))

return freeze(res)
