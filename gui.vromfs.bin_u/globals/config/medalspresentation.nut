
let mkPresentation = @(id, ovr = {}) {
  id
  descLocId = $"medal/{id}/desc"
  image = null
}.__update(ovr)

let medalsPresentation = {
  lb_wp_top_10             = { ctor = "lbTop10", image = "leaderboard_trophy_01.avif" }
  lb_tanks_top_10          = { ctor = "lbTop10", image = "leaderboard_trophy_01.avif", campaign = "tanks" }
  lb_ships_top_10          = { ctor = "lbTop10", image = "leaderboard_trophy_01.avif", campaign = "ships" }
  lb_air_top_10            = { ctor = "lbTop10", image = "leaderboard_trophy_01.avif", campaign = "air" }
  cbt_air_medal            = { image = "leaderboard_trophy_06.avif", campaign = "air" }
  japan_air_early_access   = { image = "medal_air_early_access_japan.avif", campaign = "air" }
}
  .map(@(p, id) mkPresentation(id, p))

function getMedalPresentation(name) {
  if (name not in medalsPresentation)
    medalsPresentation[name] <- mkPresentation(name)
  return medalsPresentation[name]
}

return {
  getMedalPresentation
}
