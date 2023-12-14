let statsImages = {
  event_quests_progress        = "ui/gameuiskin#quest_experience_icon.avif"
  daily_quests_progress        = "ui/gameuiskin#quest_experience_icon.avif"
  weekly_quests_progress       = "ui/gameuiskin#quest_experience_icon.avif"
  battlepass_points            = "ui/gameuiskin#bp_exp_icon.avif"
}

return {
  statsImages
  getStatsImage = @(id) statsImages?[id] ?? "ui/gameuiskin#icon_primary_attention.svg"
}