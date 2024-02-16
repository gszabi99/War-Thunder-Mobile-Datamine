let unknownBooster = "ui/gameuiskin#icon_primary_attention.svg"

let icons = {
  wp =        "ui/gameuiskin#wp_booster.avif"
  unitExp =   "ui/gameuiskin#unitExp_booster.avif"
  playerExp = "ui/gameuiskin#playerExp_booster.avif"
}

let getBoosterIcon = @(id) icons?[id] ?? unknownBooster

return {
  getBoosterIcon
}