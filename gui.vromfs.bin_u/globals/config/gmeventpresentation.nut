let defCfg = {
  id = "unknown"
  image = "ui/gameuiskin#icon_primary_attention.svg"
  bgImage = "ui/images/event_bg.avif"
  accessStat = ""
  hasConsumablePlate = false
}

let allPresentations = {
  event_cbt = {
    image = "ui/gameuiskin#unit_air.svg"
    bgImage = "ui/images/air_beta_access_bg.avif"
    accessStat = "air_beta_access"
  }

  event_ny_ctf = {
    image = "ui/gameuiskin#icon_event_christmas.svg"
  }

  event_april_2025 = {
    image = "ui/gameuiskin#icon_event_april_2025.svg"
    bgImage = "ui/images/pirates/map_border_table.avif"
    bgMapImage = "ui/images/pirates/map_border_2.avif"
  }

  anniversary_2025 = {
    image = "ui/gameuiskin#icon_event_anniversary_2025.svg"
    bgImage = "ui/images/event_bg_anniversary_2025.avif"
  }

  halloween_2025 = {
    image = "ui/gameuiskin#icon_event_halloween_2025.svg"
    bgImage = "ui/images/event_bg_halloween_2025.avif"
  }
}
  .map(@(cfg, id) defCfg.__merge(cfg, { id }))

return @(id) allPresentations?[id] ?? defCfg