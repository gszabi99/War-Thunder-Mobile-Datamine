let eventBgFallback = "ui/images/event_bg.avif"

let presentations = {
  season_5 = { color = 0xA500A556 }
  season_6 = { imageOffset = [0, -0.06] }
  season_7 = { color = 0xA584C827, imageOffset = [0, -0.08] }
  season_8 = { color = 0xA50A65B1 }
  season_9 = { color = 0XA57E34FF }
  season_11 = { color = 0xFFFFBB10 }
  season_12 = { color = 0xFFFF8000 }
  season_13 = { color = 0xFF2E87D9 }
  season_14 = { color = 0xFF00A556 }
  season_15 = { color = 0xFF5C67FB, imageSizeMul = 2}
  season_16 = { color = 0xFF85C523 }

  blackfridaybond              = { bg = "ui/images/event_bg_season_14.avif" }
  event_black_friday_season    = { bg = "ui/images/event_bg_season_14.avif" }
  event_new_year               = { icon = "ui/gameuiskin#icon_event_christmas.svg", bg = "ui/images/event_bg_christmas_2024.avif" }
  event_lunar_ny_season        = { icon = "ui/gameuiskin#icon_event_event_lunar_ny_season.svg", bg = "ui/images/event_bg_lunar.avif" }
}

let genParams = {
  name = @(name) name
  icon = @(name) $"ui/gameuiskin#icon_event_{name}.svg"
  image = @(name) $"ui/gameuiskin#banner_event_{name}.avif"
  color = @(_) 0xA5FF2B00
  imageOffset = @(_) [0, 0]
  imageSizeMul = @(_) 1.2
  bg = @(name) (name ?? "") == "" ? eventBgFallback : $"ui/images/event_bg_{name}.avif"
}

function mkEventPresentation(name) {
  let res = presentations?[name] ?? {}
  foreach (id, gen in genParams)
    if (id not in res)
      res[id] <- gen(name)
  return res
}

let cache = {}

function getEventPresentation(name) {
  if (name not in cache)
    cache[name ?? ""] <- mkEventPresentation(name)
  return cache[name ?? ""]
}

return {
  getEventPresentation
  eventBgFallback
}