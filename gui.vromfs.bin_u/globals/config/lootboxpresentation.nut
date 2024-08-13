from "%globalsDarg/darg_library.nut" import *

let lootboxFallbackPicture = Picture("ui/gameuiskin#daily_box_small.avif:0:P")

let customLootboxImages = {
  every_day_award_first = "every_day_award_medium_pack.avif"

  event_small_season_1                 = "event_small.avif"
  event_small_season_11                = "event_small_season_11.avif"

  event_tanks_medium_season_3          = "event_ships_medium_season_3.avif"
  event_tanks_medium_season_4          = "event_ships_medium_season_4.avif"
  event_tanks_medium_season_5          = "event_ships_medium_season_5.avif"
  event_tanks_medium_season_6          = "event_ships_medium_season_6.avif"
  event_tanks_medium_season_7          = "event_ships_medium_season_7.avif"
  event_tanks_medium_season_8          = "event_ships_medium_season_8.avif"
  event_tanks_medium_season_9          = "event_ships_medium_season_9.avif"
  event_tanks_medium_season_10         = "event_ships_medium_season_10.avif"
  event_tanks_medium_season_11         = "event_ships_medium_season_11.avif"

  event_tanks_big_season_3             = "event_ships_big_season_3.avif"
  event_tanks_big_season_4             = "event_ships_big_season_4.avif"
  event_tanks_big_season_5             = "event_ships_big_season_5.avif"
  event_tanks_big_season_6             = "event_ships_big_season_6.avif"
  event_tanks_big_season_7             = "event_ships_big_season_7.avif"
  event_tanks_big_season_8             = "event_ships_big_season_8.avif"
  event_tanks_big_season_9             = "event_ships_big_season_9.avif"
  event_tanks_big_season_10            = "event_ships_big_season_10.avif"
  event_tanks_big_season_11            = "event_ships_big_season_11.avif"

  event_ships_medium_season_10         = "event_ships_medium_season_10.avif"
  event_ships_medium_season_11         = "event_ships_medium_season_11.avif"

  event_ships_big_season_10            = "event_ships_big_season_10.avif"
  event_ships_big_season_11            = "event_ships_big_season_11.avif"

  event_special_tanks_christmas_2023   = "event_special_ships_christmas_2023.avif"
  event_special_tanks_april_2024       = "event_special_ships_april_2024.avif"
  event_special_tanks_anniversary_2024       = "event_special_anniversary_2024.avif"
  event_special_ships_anniversary_2024       = "event_special_anniversary_2024.avif"

  past_events_box_tanks_seasons_1_to_3 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_ships_seasons_1_to_4 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_tanks_seasons_1_to_4 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_tanks_seasons_1_to_5 = "past_events_box_ships_seasons_1_to_5.avif"
  past_events_box_ships_seasons_1_to_6 = "past_events_box.avif"
  past_events_box_tanks_seasons_1_to_6 = "past_events_box.avif"
  past_events_box_ships_seasons_1_to_7 = "past_events_box.avif"
  past_events_box_tanks_seasons_1_to_7 = "past_events_box.avif"
}

let imgIdBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let lootboxLocIdBySlot = {
  ["0"] = "lootbox/every_day_award_small_pack",
  ["1"] = "lootbox/every_day_award_medium_pack",
  ["2"] = "lootbox/every_day_award_big_pack_1",
}

function getLootboxImage(id, season = null, size = null) {
  let finalId = imgIdBySeason?[id](season) ?? id
  let img = customLootboxImages?[finalId] ?? $"{finalId}.avif"
  return !size ? Picture($"ui/gameuiskin#{img}:0:P") : Picture($"ui/gameuiskin#{img}:{size}:{size}:P")
}

let mkLoootboxImage = @(id, size = null, ovr = {}) {
  size = size ? [size, size] : SIZE_TO_CONTENT
  rendObj = ROBJ_IMAGE
  image = getLootboxImage(id, null, size)
  fallbackImage = lootboxFallbackPicture
  keepAspect = true
}.__update(ovr)

let getLootboxName = @(id, slot = "") loc(lootboxLocIdBySlot?[slot] ?? $"lootbox/{id}")

return {
  getLootboxImage
  lootboxFallbackPicture
  mkLoootboxImage
  getLootboxName
}
