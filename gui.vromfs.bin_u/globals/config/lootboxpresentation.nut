from "%globalsDarg/darg_library.nut" import *
let regexp2 = require("regexp2")

let lootboxFallbackPicture = Picture("ui/gameuiskin#daily_box_small.avif:0:P")

let customLootboxImages = {
  every_day_award_first = "every_day_award_medium_pack.avif"

  event_small_season_1                 = "event_small.avif"

  event_special_tanks_christmas_2023   = "event_special_ships_christmas_2023.avif"
  event_special_tanks_april_2024       = "event_special_ships_april_2024.avif"
  event_special_tanks_anniversary_2024       = "event_special_anniversary_2024.avif"
  event_special_ships_anniversary_2024       = "event_special_anniversary_2024.avif"

  event_special_tanks_halloween_2024         = "event_special_halloween_2024.avif"
  event_special_ships_halloween_2024         = "event_special_halloween_2024.avif"
  event_special_air_halloween_2024           = "event_special_halloween_2024.avif"

  past_events_box_tanks_seasons_1_to_3 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_ships_seasons_1_to_4 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_tanks_seasons_1_to_4 = "past_events_box_ships_seasons_1_to_3.avif"
  past_events_box_tanks_seasons_1_to_5 = "past_events_box_ships_seasons_1_to_5.avif"
  past_events_box_ships_seasons_1_to_6 = "past_events_box.avif"
  past_events_box_tanks_seasons_1_to_6 = "past_events_box.avif"
  past_events_box_ships_seasons_1_to_7 = "past_events_box.avif"
  past_events_box_tanks_seasons_1_to_7 = "past_events_box.avif"
  past_events_box_ships_seasons_1_to_8 = "past_events_box_seasons_1_to_8.avif"
  past_events_box_tanks_seasons_1_to_8 = "past_events_box_seasons_1_to_8.avif"
  past_events_box_ships_seasons_1_to_9 = "past_events_box_seasons_1_to_9.avif"
  past_events_box_tanks_seasons_1_to_9 = "past_events_box_seasons_1_to_9.avif"
  past_events_box_ships_seasons_1_to_10 = "past_events_box_seasons_1_to_10.avif"
  past_events_box_tanks_seasons_1_to_10 = "past_events_box_seasons_1_to_10.avif"
}

let imgIdBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let defaultSeasonImages = [
  { re = regexp2(@"^event_tanks_(medium|big)_season_\d+$"), mkImg = @(id) id.replace("tanks", "ships") },
  { re = regexp2(@"^event_air_(medium|big)_season_\d+$"),   mkImg = @(id) id.replace("air", "ships") },
]

let customEventLootboxScale = {
  event_special_tanks_anniversary_2024 = 1.2
  event_special_ships_anniversary_2024 = 1.2
}

let lootboxLocIdBySlot = {
  ["0"] = "lootbox/every_day_award_small_pack",
  ["1"] = "lootbox/every_day_award_medium_pack",
  ["2"] = "lootbox/every_day_award_big_pack_1",
}

let defaultImgFilenameCache = {}
function getDefaultImgFilename(id) {
  if (id not in defaultImgFilenameCache) {
    local fn = null
    foreach (v in defaultSeasonImages)
      if (v.re.match(id)) {
        fn = v.mkImg(id)
        break
      }
    fn = fn ?? id
    defaultImgFilenameCache[id] <- $"{fn}.avif"
  }
  return defaultImgFilenameCache[id]
}

function getLootboxImage(id, season = null, size = null) {
  let finalId = imgIdBySeason?[id](season) ?? id
  let img = customLootboxImages?[finalId] ?? getDefaultImgFilename(finalId)
  return !size ? Picture($"ui/gameuiskin/{img}:0:P") : Picture($"ui/gameuiskin#{img}:{size}:{size}:P")
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
  customEventLootboxScale
}
