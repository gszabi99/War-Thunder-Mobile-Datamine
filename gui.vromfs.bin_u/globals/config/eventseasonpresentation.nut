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
  season_15 = { color = 0xFF5C67FB, imageSizeMul = 2 }
  season_16 = { color = 0xFF85C523 }
  season_17 = { color = 0xB3E50606 }
  season_18 = { color = 0xFFFFBB10 }
  season_19 = { color = 0xFF9CB3Df }
  season_20 = { color = 0xFF2F48EC }
  season_21 = { color = 0xFFFE6F71 }
  season_22 = { color = 0xFFE9AB11, imageSizeMul = 1.8 }
  season_23 = { color = 0xFFBC0022 }
  season_24 = { color = 0xFFFC7724 }
  season_25 = { color = 0xFFADDB76 }
  season_26 = { color = 0xFFC3EBFF }
  season_27 = { color = 0xFFE9AB10 }
  season_28 = { color = 0xFF397EE6 }
  season_29 = { color = 0xFF36B388 }
  season_30 = { color = 0xFFBC0022 }
  season_31 = { color = 0xFF8FDE16 }
  nybond                       = { bg = "ui/images/event_bg_christmas_2024.avif" }
  blackfridaybond              = { bg = "ui/images/event_bg_season_14.avif" }
  event_black_friday_season    = { bg = "ui/images/event_bg_season_14.avif" }
  black_friday_2025            = {
    image = $"ui/gameuiskin/icon_event_event_black_friday_shop.avif",
    bg = "ui/images/event_bg_season_27.avif"
  }
  event_new_year               = {
    icon = "ui/gameuiskin#icon_event_christmas.svg",
    bg = "ui/images/event_bg_christmas_2024.avif",
    gamercardItems = [ "firework_kit" ]
  }
  china_tanks_early_access        = {
    bg = "ui/images/event_bg_lunar.avif"
  }
  event_lunar_ny_season        = {
    icon = "ui/gameuiskin#icon_event_event_lunar_ny_season.svg",
    bg = "ui/images/event_bg_lunar.avif",
    gamercardItems = [ "firework_kit" ]
  }
  event_patrick_day            = { icon = "ui/gameuiskin#icon_event_patrick_day2.svg" }
  event_patrick_daily          = { icon = "ui/gameuiskin#icon_event_patrick_day.svg" }
  event_april_2025             = {
    icon = "ui/gameuiskin#icon_event_april_2025.svg",
    bg = "ui/images/event_bg_event_april_2025.avif"
  }
  hot_may                      = {
    icon = "ui/gameuiskin#icon_event_hot_may.svg",
    bg = "ui/images/event_bg_season_20.avif"
  }
  hotmaybond                   = { bg = "ui/images/event_bg_season_20.avif" }
  independencebond             = { bg = "ui/images/event_bg_event_independence_day.avif" }
  anniversary_2025             = { bg = "ui/images/event_bg_anniversary_2025.avif", gamercardItems = [ "firework_kit" ] }
  anniversarybond              = { bg = "ui/images/event_bg_anniversary_2025.avif" }
  halloween_2025               = { bg = "ui/images/event_bg_halloween_2025.avif", gamercardItems = [ "firework_kit" ] }
  new_year_2026                = {
    image = $"ui/gameuiskin/icon_event_christmas_shop.avif",
    icon = "ui/gameuiskin#icon_event_christmas.svg",
    bg = "new_year_2026",
    gamercardItems = [ "firework_kit" ]
  }
  valentine_day_2026                = {
    image = $"ui/gameuiskin/icon_event_valentine_day_shop.avif",
    icon = "ui/gameuiskin#icon_event_event_valentine_day.svg",
    bg = "ui/images/event_bg_valentine_day_2026.avif"
  }
  lunar_ny_2026                = {
    image = $"ui/gameuiskin/icon_event_lunar_ny_shop.avif",
    icon = "ui/gameuiskin#icon_event_event_lunar_ny_season.svg",
    bg = "ui/images/event_bg_lunar_ny_2026.avif",
    gamercardItems = [ "firework_kit" ]
  }
  halloweenbond                = { bg = "ui/images/event_bg_halloween_2025.avif" }
  valentinebond                = { bg = "ui/images/event_bg_valentine_day_2026.avif" }
  candybond                    = { bg = "ui/images/event_bg_valentine_day_2026.avif" }
  lollipopbond                 = { bg = "ui/images/event_bg_valentine_day_2026.avif" }
  chocolatebond                = { bg = "ui/images/event_bg_valentine_day_2026.avif" }
  lunarbond                    = { bg = "ui/images/event_bg_lunar.avif" }
  event_leyte_battle           = { imageSizeMul = 1.4 }
  tank_constructor_birthday    = { image = $"ui/gameuiskin/icon_event_event_black_friday_shop.avif" }
  offers_event                 = { locId = "events/name/challenge" }
  premiere_challenge_first     = { locId = "events/name/challenge" }
  premiere_challenge_second    = { locId = "events/name/challenge" }
  rerun_offers_event           = { locId = "events/name/challenge" }
}

let genParams = {
  name = @(name) name
  locId = @(name) $"events/name/{name}"
  icon = @(name) $"ui/gameuiskin#icon_event_{name}.svg"
  image = @(name) $"ui/gameuiskin#banner_event_{name}.avif"
  color = @(_) 0xA5FF2B00
  imageOffset = @(_) [0, 0]
  imageSizeMul = @(_) 1.0
  imageTabOffset = @(_) [0, 0]
  bg = @(name) (name ?? "") == "" ? eventBgFallback : $"ui/images/event_bg_{name}.avif"
  gamercardItems = @(_) []
}

let seasonFlagsRotation = {
  ship = ["major_banner_buoy_even", "major_banner_buoy_odd"],
  tank = ["major_banner_even", "major_banner_odd"],
  air = ["major_banner_wall_even", "major_banner_wall_odd"],
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
  seasonFlagsRotation
}