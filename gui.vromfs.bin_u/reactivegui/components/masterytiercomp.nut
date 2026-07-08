from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitPresentation.nut" import getMasteryPresentation

let mkMasteryTierIconCtor = @(pathKey) function(baseSize, masteryTier) {
  let presentation = getMasteryPresentation(masteryTier)
  let image = presentation?[pathKey] ?? presentation.icon
  let size = (baseSize * (presentation?.scale ?? 1)).tointeger()
  return {
    size
    rendObj = ROBJ_IMAGE
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_CENTER
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{image}:{size}:P")
  }
}


return {
  mkMasteryTierIcon = mkMasteryTierIconCtor("icon")
  mkMasteryTierColorIcon = mkMasteryTierIconCtor("colorIcon")
}
