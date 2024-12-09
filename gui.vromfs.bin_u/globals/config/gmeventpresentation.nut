let defCfg = {
  id = "unknown"
  image = "ui/gameuiskin#icon_primary_attention.svg"
  bgImage = "ui/images/event_bg.avif"
  accessStat = ""
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
}
  .map(@(cfg, id) defCfg.__merge(cfg, { id }))

return @(id) allPresentations?[id] ?? defCfg