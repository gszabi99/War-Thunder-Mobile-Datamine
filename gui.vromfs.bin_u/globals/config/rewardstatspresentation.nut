let unknownIcon = "ui/gameuiskin#icon_primary_attention.svg"
let statsImages = {
  battlepass_points            = "ui/gameuiskin#bp_exp_icon.avif"
}

function getStatsImageImpl(id) {
  if (id.endswith("_quests_progress"))
    return "ui/gameuiskin#quest_experience_icon.avif"
  return null
}

function getStatsImageCached(id) {
  if (id not in statsImages)
    statsImages[id] <- getStatsImageImpl(id)
  return statsImages[id]
}

return {
  hasStatsImage = @(id) getStatsImageCached(id) != null
  getStatsImage = @(id) getStatsImageCached(id) ?? unknownIcon
}