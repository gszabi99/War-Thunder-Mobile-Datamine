let { round } = require("math")
let { fontsLists } = require("fontsStyle.nut")
let { memoize } = require("%sqstd/functools.nut")


let listByFont = {}
foreach(list in fontsLists)
  foreach(f in list)
    listByFont[f] <- list

let getDecreaseInfo = memoize(function(baseFont) {
  let list = listByFont?[baseFont]
  if (list == null)
    return null
  let idx = list.indexof(baseFont)
  if (idx == null || idx == 0)
    return null
  let font = list[idx - 1]
  let scale = 0.5 * (font.fontSize + baseFont.fontSize) / baseFont.fontSize
  return { font, scale }
})

let getIncreaseInfo = memoize(function(baseFont) {
  let list = listByFont?[baseFont]
  if (list == null)
    return null
  let idx = list.indexof(baseFont)
  if (idx == null || idx == list.len() - 1)
    return null
  let font = list[idx + 1]
  let scale = 0.5 * (font.fontSize + baseFont.fontSize) / baseFont.fontSize
  return { font, scale }
})

function getScaledFont(font, scale) {
  if (scale == 1)
    return font
  if (scale < 1) {
    let dec = getDecreaseInfo(font)
    return dec == null || dec.scale < scale ? font : dec.font
  }
  let inc = getIncreaseInfo(font)
  return inc == null || inc.scale > scale ? font : inc.font
}

function scaleFontWithTransform(font, scale, pivot = [0, 0.5]) {
  if (scale == 1)
    return font
  if (scale < 1)
    return font.__merge({ transform = { pivot, scale = [scale, scale] }})
  let inc = getIncreaseInfo(font)
  return inc == null ? font.__merge({ transform = { pivot, scale = [scale, scale] }})
    : inc.font.__merge({ transform = { pivot, scale = array(2, scale / inc.scale) }})
}

let prettyScaleForSmallNumberCharVariants = @(font, scale)
  font.__merge({ fontSize = round(font.fontSize * scale).tointeger() })

return {
  getScaledFont
  scaleFontWithTransform
  prettyScaleForSmallNumberCharVariants
}