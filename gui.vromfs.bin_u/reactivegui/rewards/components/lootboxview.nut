from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxImage, lootboxLayers,
  getEventLootboxSizeMul, getEventLootboxShiftPos


let lootboxFallbackPicture = Picture("ui/gameuiskin#daily_box_small.avif:0:P")

function mkLootboxLayers(id, size) {
  let layers = lootboxLayers?[id]
  if (layers == null)
    return null

  return layers.map(function(l) {
    let lSize = l.size.map(@(v) round(v * size).tointeger())
    return {
      size = lSize
      pos = l.pos.map(@(v) round(v * size).tointeger())
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin/{l.image}:{lSize[0]}:{lSize[1]}:P")
      keepAspect = true
    }
  })
}

function getLootboxPicture(id, season = null, size = null) {
  let img = getLootboxImage(id, season)
  return !size ? Picture($"ui/gameuiskin/{img}:0:P") : Picture($"ui/gameuiskin/{img}:{size}:{size}:P")
}

function mkLootboxImage(id, size, scale = 1, ovr = {}) {
  let scaledSize = (size * scale).tointeger()
  return {
    size = [scaledSize, scaledSize]
    rendObj = ROBJ_IMAGE
    image = getLootboxPicture(id, null, scaledSize)
    fallbackImage = lootboxFallbackPicture
    keepAspect = true
    children = mkLootboxLayers(id, scaledSize)
  }.__update(ovr)
}

let mkLootboxImageWithSlotScale = @(lootbox, boxSize, season, isActive, children) function() {
  let { name } = lootbox
  let sizeMul = getEventLootboxSizeMul(name, season.get(), lootbox.meta?.event_slot ?? "")
  let size = boxSize.map(@(v) (v * sizeMul + 0.5).tointeger())
  return {
    watch = [season, isActive]
    size
    pos = getEventLootboxShiftPos(name, season.get()).map(@(v, a) size[a] * v)
    rendObj = ROBJ_IMAGE
    image = getLootboxPicture(name, season.get())
    fallbackImage = lootboxFallbackPicture
    keepAspect = true
    picSaturate = isActive.get() ? 1.0 : 0.2
    brightness = isActive.get() ? 1.0 : 0.5
    children
  }
}

return {
  lootboxFallbackPicture
  getLootboxPicture
  mkLootboxImage
  mkLootboxImageWithSlotScale
}
