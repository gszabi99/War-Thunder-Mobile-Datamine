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

  event_special_tanks_independence_2025      = "event_special_independence_2025.avif"
  event_special_ships_independence_2025      = "event_special_independence_2025.avif"
  event_special_air_independence_2025        = "event_special_independence_2025.avif"

  event_special_gift_tanks_anniversary_2025      = "event_anniversary_gift_box.avif"
  event_special_gift_ships_anniversary_2025      = "event_anniversary_gift_box.avif"
  event_special_gift_air_anniversary_2025        = "event_anniversary_gift_box.avif"

  event_special_tanks_april_fools_2025      = "event_special_ships_april_2025.avif"
  event_special_ships_april_fools_2025      = "event_special_ships_april_2025.avif"
  event_special_air_april_fools_2025        = "event_special_ships_april_2025.avif"

  event_ships_medium_subbox_box_season_22   = "lucky_box.avif"
  event_air_medium_subbox_box_season_22     = "lucky_box.avif"
  event_air_big_subbox_box_season_22        = "lucky_box.avif"
  event_ships_big_subbox_box_season_22      = "lucky_box.avif"
  event_ships_medium_subbox_box_season_23   = "lucky_box.avif"
  event_air_medium_subbox_box_season_23     = "lucky_box.avif"
  event_air_big_subbox_box_season_23        = "lucky_box.avif"
  event_ships_big_subbox_box_season_23      = "lucky_box.avif"
  event_ships_medium_subbox_box_season_24   = "lucky_box.avif"
  event_air_medium_subbox_box_season_24     = "lucky_box.avif"
  event_air_big_subbox_box_season_24        = "lucky_box.avif"
  event_ships_big_subbox_box_season_24      = "lucky_box.avif"
  event_tanks_medium_subbox_box_season_25   = "lucky_box.avif"
  event_ships_medium_subbox_box_season_25   = "lucky_box.avif"
  event_air_medium_subbox_box_season_25     = "lucky_box.avif"
  event_tanks_big_subbox_box_season_25      = "lucky_box.avif"
  event_ships_big_subbox_box_season_25      = "lucky_box.avif"
  event_air_big_subbox_box_season_25        = "lucky_box.avif"
  event_tanks_medium_subbox_box_season_26   = "lucky_box.avif"
  event_ships_medium_subbox_box_season_26   = "lucky_box.avif"
  event_air_medium_subbox_box_season_26     = "lucky_box.avif"
  event_tanks_big_subbox_box_season_26      = "lucky_box.avif"
  event_ships_big_subbox_box_season_26      = "lucky_box.avif"
  event_air_big_subbox_box_season_26        = "lucky_box.avif"

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
  past_events_box_tanks_seasons_1_to_16 = "past_events_box_seasons_1_to_16.avif"
  past_events_box_ships_seasons_1_to_16 = "past_events_box_seasons_1_to_16.avif"
  past_events_box_air_seasons_1_to_16 = "past_events_box_seasons_1_to_16.avif"
  past_events_box_tanks_seasons_1_to_17 = "past_events_box_seasons_1_to_17.avif"
  past_events_box_ships_seasons_1_to_17 = "past_events_box_seasons_1_to_17.avif"
  past_events_box_air_seasons_1_to_17 = "past_events_box_seasons_1_to_17.avif"
  past_events_box_tanks_seasons_1_to_18 = "past_events_box_seasons_1_to_18.avif"
  past_events_box_ships_seasons_1_to_18 = "past_events_box_seasons_1_to_18.avif"
  past_events_box_air_seasons_1_to_18 = "past_events_box_seasons_1_to_18.avif"
  past_events_box_tanks_seasons_1_to_19 = "past_events_box_seasons_1_to_19.avif"
  past_events_box_ships_seasons_1_to_19 = "past_events_box_seasons_1_to_19.avif"
  past_events_box_air_seasons_1_to_19 = "past_events_box_seasons_1_to_19.avif"
  past_events_box_tanks_seasons_1_to_20 = "past_events_box_seasons_1_to_20.avif"
  past_events_box_ships_seasons_1_to_20 = "past_events_box_seasons_1_to_20.avif"
  past_events_box_air_seasons_1_to_20 = "past_events_box_seasons_1_to_20.avif"
  past_events_box_tanks_seasons_1_to_21 = "past_events_box_seasons_1_to_21.avif"
  past_events_box_ships_seasons_1_to_21 = "past_events_box_seasons_1_to_21.avif"
  past_events_box_air_seasons_1_to_21 = "past_events_box_seasons_1_to_21.avif"
  past_events_box_tanks_seasons_1_to_22 = "past_events_box_seasons_1_to_22.avif"
  past_events_box_ships_seasons_1_to_22 = "past_events_box_seasons_1_to_22.avif"
  past_events_box_air_seasons_1_to_22 = "past_events_box_seasons_1_to_22.avif"
  past_events_box_tanks_seasons_1_to_23 = "past_events_box_seasons_1_to_23.avif"
  past_events_box_ships_seasons_1_to_23 = "past_events_box_seasons_1_to_23.avif"
  past_events_box_air_seasons_1_to_23 = "past_events_box_seasons_1_to_23.avif"
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

  event_special_gift_tanks_anniversary_2025 = "ui/images/event_bg_roulette_event_anniversary_2025.avif"
  event_special_gift_ships_anniversary_2025 = "ui/images/event_bg_roulette_event_anniversary_2025.avif"
  event_special_gift_air_anniversary_2025   = "ui/images/event_bg_roulette_event_anniversary_2025.avif"
}

let imgIdBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let defaultSeasonImages = [
  { re = regexp2(@"^event_tanks_(medium|big)_season_\d+$"), mkImg = @(id) id.replace("tanks", "ships") },
  { re = regexp2(@"^event_air_(medium|big)_season_\d+$"),   mkImg = @(id) id.replace("air", "ships") },
]

let lootboxPreviewBg = { 
  event_special_gift_tanks_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_ships_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_air_new_year_2025           = "ui/images/event_bg_christmas_2024.avif"

  event_ships_big_subbox_box_season_22           = "ui/images/event_bg_season_22.avif"
  event_ships_medium_subbox_box_season_22        = "ui/images/event_bg_season_22.avif"
  event_air_medium_subbox_box_season_22          = "ui/images/event_bg_season_22.avif"
  event_air_big_subbox_box_season_22             = "ui/images/event_bg_season_22.avif"
  event_ships_big_subbox_box_season_23           = "ui/images/event_bg_season_23.avif"
  event_ships_medium_subbox_box_season_23        = "ui/images/event_bg_season_23.avif"
  event_air_medium_subbox_box_season_23          = "ui/images/event_bg_season_23.avif"
  event_air_big_subbox_box_season_23             = "ui/images/event_bg_season_23.avif"
  event_ships_big_subbox_box_season_24           = "ui/images/event_bg_season_24.avif"
  event_ships_medium_subbox_box_season_24        = "ui/images/event_bg_season_24.avif"
  event_air_medium_subbox_box_season_24          = "ui/images/event_bg_season_24.avif"
  event_air_big_subbox_box_season_24             = "ui/images/event_bg_season_24.avif"
  event_tanks_big_subbox_box_season_25           = "ui/images/event_bg_season_25.avif"
  event_tanks_medium_subbox_box_season_25        = "ui/images/event_bg_season_25.avif"
  event_ships_big_subbox_box_season_25           = "ui/images/event_bg_season_25.avif"
  event_ships_medium_subbox_box_season_25        = "ui/images/event_bg_season_25.avif"
  event_air_medium_subbox_box_season_25          = "ui/images/event_bg_season_25.avif"
  event_air_big_subbox_box_season_25             = "ui/images/event_bg_season_25.avif"
  event_tanks_big_subbox_box_season_26           = "ui/images/event_bg_season_26.avif"
  event_tanks_medium_subbox_box_season_26        = "ui/images/event_bg_season_26.avif"
  event_ships_big_subbox_box_season_26           = "ui/images/event_bg_season_26.avif"
  event_ships_medium_subbox_box_season_26        = "ui/images/event_bg_season_26.avif"
  event_air_medium_subbox_box_season_26          = "ui/images/event_bg_season_26.avif"
  event_air_big_subbox_box_season_26             = "ui/images/event_bg_season_26.avif"

  event_special_tanks_independence_2025          = "ui/images/event_bg_event_independence_day.avif"
  event_special_ships_independence_2025          = "ui/images/event_bg_event_independence_day.avif"
  event_special_air_independence_2025            = "ui/images/event_bg_event_independence_day.avif"

  event_special_gift_tanks_anniversary_2025         = "ui/images/event_bg_anniversary_2025.avif"
  event_special_gift_ships_anniversary_2025         = "ui/images/event_bg_anniversary_2025.avif"
  event_special_gift_air_anniversary_2025           = "ui/images/event_bg_anniversary_2025.avif"
}

let defEventLootboxScaleBySlot = {
  ["0"] = 0.6,
  ["1"] = 0.8,
  ["2"] = 0.9,
}

let customEventLootboxScale = {
  event_special_tanks_anniversary_2024 = 1.2
  event_special_ships_anniversary_2024 = 1.2
  event_tanks_big_season_25 = 1.2
  event_ships_big_season_25 = 1.2
  event_air_big_season_25 = 1.2
}

let customEventLootboxShiftPos = {
  event_tanks_big_season_25 = [0, -0.15]
  event_ships_big_season_25 = [0, -0.15]
  event_air_big_season_25 = [0, -0.15]
}

let customGoodsLootboxScale = {
  event_special_gift_tanks_new_year_2025 = 0.7
  event_special_gift_ships_new_year_2025 = 0.7
  event_special_gift_air_new_year_2025   = 0.7
}

let customLocId = {
  event_small = "lootbox/every_day_award_small_pack"
}

let lootboxLocIdByNamePart = {
  ["_medium_season_"] = "lootbox/every_day_award_medium_pack",
  ["_big_season_"] = "lootbox/every_day_award_big_pack_1",
  ["_subbox_"] = "lootbox/lucky"
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

  event_special_gift_tanks_anniversary_2025 = mkTagLayersCtor("event_christmas_gift_tag_tanks.avif")
  event_special_gift_ships_anniversary_2025 = mkTagLayersCtor("event_christmas_gift_tag_ships.avif")
  event_special_gift_air_anniversary_2025   = mkTagLayersCtor("event_christmas_gift_tag_planes.avif")
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

let getLootboxName = memoize(function parseString(id) {
  if (id in customLocId)
    return loc(customLocId[id])

  foreach (prefix in lootboxPrefixes) {
    if (id.startswith(prefix)) {
      local parts = id.slice(prefix.len() + 1).split("_")
      if (parts.len() != 0 && isNum.match(parts[0]))
        return loc($"lootbox/{prefix}", {num = getRomanNumeral(parts[0].tointeger())})
    }
  }

  foreach (part, locId in lootboxLocIdByNamePart)
    if (id.indexof(part) != null)
      return loc(locId)

  return loc($"lootbox/{id}")
})

let getLootboxSizeMulBySlot = @(name, eventSlot) customEventLootboxScale?[name]
  ?? defEventLootboxScaleBySlot?[eventSlot] ?? 1.0

return {
  getLootboxImage
  getRouletteImage
  lootboxFallbackPicture
  mkLoootboxImage
  getLootboxName
  getLootboxSizeMulBySlot
  customGoodsLootboxScale
  customEventLootboxShiftPos
  lootboxPreviewBg
}
