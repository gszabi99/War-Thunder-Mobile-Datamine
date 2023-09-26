from "%globalsDarg/darg_library.nut" import *

let playerPlaceIconSize = evenPx(90)
let playerPlaceIconBigSize = evenPx(130)
let defaultBadge = "ui/gameuiskin#player_rank_badge_grey.avif"
let placeBadges = {
  [1] = "ui/gameuiskin#player_rank_badge_gold.avif",
  [2] = "ui/gameuiskin#player_rank_badge_silver.avif",
  [3] = "ui/gameuiskin#player_rank_badge_bronze.avif",
}

let mkPlaceIcon = @(place, size = playerPlaceIconSize, fontStyle = fontTiny) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"{placeBadges?[place] ?? defaultBadge}:{size}:{size}:P")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    pos = [0, -0.03 * size]
    rendObj = ROBJ_TEXT
    text = place < 1 ? "-" : place
  }.__update(fontStyle)
}

return {
  playerPlaceIconSize
  playerPlaceIconBigSize
  mkPlaceIcon
  mkPlaceIconBig = @(place) mkPlaceIcon(place, playerPlaceIconBigSize, fontSmallAccented)
}
