let unknownIcon = "ui/gameuiskin#icon_primary_attention.svg"
let statsImages = {
  battlepass_points            = "ui/gameuiskin#bp_exp_icon.avif"
  eventpass_points             = "ui/gameuiskin#event_pass_exp_icon.avif"
  operation_pass_points        = "ui/gameuiskin#icon_personal_tank_exp.svg"
}

let imagesByMode = {
  operation_pass_points = {
    tanks = "ui/gameuiskin#icon_personal_tank_exp.svg"
    ships = "ui/gameuiskin#icon_personal_ship_exp.svg"
    air = "ui/gameuiskin#icon_personal_air_exp.svg"
  }
}

function getStatsImageImpl(id) {
  if (id.contains("_quests_progress"))
    return "ui/gameuiskin#quest_experience_icon.avif"
  return null
}

function getStatsImageCached(id) {
  if (id not in statsImages)
    statsImages[id] <- getStatsImageImpl(id)
  return statsImages[id]
}

return {
  hasStatsImage = @(id, mode) imagesByMode?[id][mode] != null || getStatsImageCached(id) != null
  getStatsImage = @(id, mode) imagesByMode?[id][mode] ?? getStatsImageCached(id) ?? unknownIcon
}