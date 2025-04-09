from "%globalsDarg/darg_library.nut" import *
let regexp2 = require("regexp2")
let { round } = require("math")
let { getRomanNumeral } = require("%sqstd/math.nut")

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

  event_special_tanks_new_year_2025         = "event_special_ships_christmas_2024.avif"
  event_special_ships_new_year_2025         = "event_special_ships_christmas_2024.avif"
  event_special_air_new_year_2025           = "event_special_ships_christmas_2024.avif"

  event_special_gift_tanks_new_year_2025         = "event_christmas_gift_box.avif"
  event_special_gift_ships_new_year_2025         = "event_christmas_gift_box.avif"
  event_special_gift_air_new_year_2025           = "event_christmas_gift_box.avif"

  event_special_tanks_lunar_ny_2025         = "event_special_lunar_ny.avif"
  event_special_ships_lunar_ny_2025         = "event_special_lunar_ny.avif"
  event_special_air_lunar_ny_2025           = "event_special_lunar_ny.avif"

  event_special_tanks_april_fools_2025      = "event_special_ships_april_2025.avif"
  event_special_ships_april_fools_2025      = "event_special_ships_april_2025.avif"
  event_special_air_april_fools_2025        = "event_special_ships_april_2025.avif"

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
  past_events_box_ships_seasons_1_to_11 = "past_events_box_seasons_1_to_11.avif"
  past_events_box_tanks_seasons_1_to_11 = "past_events_box_seasons_1_to_11.avif"
  past_events_box_ships_seasons_1_to_12 = "past_events_box_seasons_1_to_12.avif"
  past_events_box_tanks_seasons_1_to_12 = "past_events_box_seasons_1_to_12.avif"
  past_events_box_ships_seasons_1_to_13 = "past_events_box_seasons_1_to_13.avif"
  past_events_box_tanks_seasons_1_to_13 = "past_events_box_seasons_1_to_13.avif"
  past_events_box_ships_seasons_1_to_14 = "past_events_box_seasons_1_to_14.avif"
  past_events_box_tanks_seasons_1_to_14 = "past_events_box_seasons_1_to_14.avif"
  past_events_box_ships_seasons_1_to_15 = "past_events_box_seasons_1_to_15.avif"
  past_events_box_tanks_seasons_1_to_15 = "past_events_box_seasons_1_to_15.avif"
}

let customRouletteImages = {
  event_special_tanks_new_year_2025 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_ships_new_year_2025 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_air_new_year_2025 = "ui/images/event_bg_roulette_christmas_2024.avif"

  event_special_gift_tanks_new_year_2025 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_gift_ships_new_year_2025 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_gift_air_new_year_2025   = "ui/images/event_bg_roulette_christmas_2024.avif"

  event_special_tanks_april_fools_2025 = "ui/images/event_bg_roulette_event_april_2025.avif"
  event_special_ships_april_fools_2025 = "ui/images/event_bg_roulette_event_april_2025.avif"
  event_special_air_april_fools_2025   = "ui/images/event_bg_roulette_event_april_2025.avif"
}

let imgIdBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let defaultSeasonImages = [
  { re = regexp2(@"^event_tanks_(medium|big)_season_\d+$"), mkImg = @(id) id.replace("tanks", "ships") },
  { re = regexp2(@"^event_air_(medium|big)_season_\d+$"),   mkImg = @(id) id.replace("air", "ships") },
]

let lootboxPreviewBg = { //todo: should merge all presentations to the single table
  event_special_gift_tanks_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_ships_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_air_new_year_2025           = "ui/images/event_bg_christmas_2024.avif"
}

let customEventLootboxScale = {
  event_special_tanks_anniversary_2024 = 1.2
  event_special_ships_anniversary_2024 = 1.2
}

let customGoodsLootboxScale = {
  event_special_gift_tanks_new_year_2025 = 0.7
  event_special_gift_ships_new_year_2025 = 0.7
  event_special_gift_air_new_year_2025   = 0.7
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
  return !size ? Picture($"ui/gameuiskin/{img}:0:P") : Picture($"ui/gameuiskin/{img}:{size}:{size}:P")
}

let getRouletteImage = @(id) customRouletteImages?[id] ?? "ui/images/event_bg.avif"

let mkTagLayersCtor = @(image) function(size) {
  let tagSize = round(0.35 * size).tointeger()
  return {
    size = [tagSize, tagSize]
    pos = [-0.04 * size, 0.2 * size]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin/{image}:{tagSize}:{tagSize}:P")
    keepAspect = true
  }
}

let lootboxLayers = {
  event_special_gift_tanks_new_year_2025 = mkTagLayersCtor("event_christmas_gift_tag_tanks.avif")
  event_special_gift_ships_new_year_2025 = mkTagLayersCtor("event_christmas_gift_tag_ships.avif")
  event_special_gift_air_new_year_2025   = mkTagLayersCtor("event_christmas_gift_tag_planes.avif")
}

function mkLoootboxImage(id, size, scale = 1, ovr = {}) {
  let scaledSize = (size * scale).tointeger()
  return {
    size = [scaledSize, scaledSize]
    rendObj = ROBJ_IMAGE
    image = getLootboxImage(id, null, scaledSize)
    fallbackImage = lootboxFallbackPicture
    keepAspect = true
    children = lootboxLayers?[id](scaledSize)
  }.__update(ovr)
}

let isNum = regexp2(@"^\d+$")

let lootboxPrefixes = ["past_events_box"]

let getLootboxNameById = memoize(function parseString(id) {
  foreach (prefix in lootboxPrefixes) {
    if (id.startswith(prefix)) {
      local parts = id.slice(prefix.len() + 1).split("_")
      if (parts.len() != 0 && isNum.match(parts[0]))
        return loc($"lootbox/{prefix}", {num = getRomanNumeral(parts[0].tointeger())})
    }
  }
  return loc($"lootbox/{id}")
})

let getLootboxName = @(id, slot = "") slot in lootboxLocIdBySlot ? loc(lootboxLocIdBySlot[slot]) : getLootboxNameById(id)

return {
  getLootboxImage
  getRouletteImage
  lootboxFallbackPicture
  mkLoootboxImage
  getLootboxName
  customEventLootboxScale
  customGoodsLootboxScale
  lootboxPreviewBg
}
