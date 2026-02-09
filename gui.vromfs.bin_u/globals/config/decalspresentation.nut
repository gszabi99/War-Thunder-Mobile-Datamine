from "%globalsDarg/darg_library.nut" import *

let categoryDecalsLoc = {
  china = "country_china"
  france = "country_france"
  germany = "country_germany"
  japan = "country_japan"
  israel = "country_israel"
  italy = "country_italy"
  sweden = "country_sweden"
  usa = "country_usa"
  uk = "country_uk"
  ussr = "country_ussr"
}

let defPresentation = { scale = 0.55 }
let presentations = {
  polar_owl_decal = { scale = 0.8 }
  rook_decal = { scale = 0.7 }
  new_year_26_pinup_decal = { scale = 0.7 }
  new_year_26_lights_decal = { scale = 0.7 }
}

let getDecalCategoryLocName = @(cat) loc(categoryDecalsLoc?[cat] ?? $"decals/category/{cat}")
let getDecalPresentation = @(id) presentations?[id] ?? defPresentation

return {
  getDecalCategoryLocName
  getDecalPresentation
}
