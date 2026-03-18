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

  operation_pass_infinite_lootbox_tanks           = "battle_pass_infinite_lootbox.avif"
  operation_pass_infinite_lootbox_ships           = "battle_pass_infinite_lootbox.avif"
  operation_pass_infinite_lootbox_air             = "battle_pass_infinite_lootbox.avif"

  event_special_china_tanks_spending_event        = "event_special_lunar_ny.avif"

  valentine_day_candy_lootbox                     = "valentine_day_candy_lootbox.avif"
  valentine_day_extra_reward_lootbox              = "valentine_day_candy_lootbox.avif"

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
  past_events_box_tanks_seasons_1_to_24 = "past_events_box_seasons_1_to_24.avif"
  past_events_box_ships_seasons_1_to_24 = "past_events_box_seasons_1_to_24.avif"
  past_events_box_air_seasons_1_to_24 = "past_events_box_seasons_1_to_24.avif"
  past_events_box_tanks_seasons_1_to_25 = "past_events_box_seasons_1_to_25.avif"
  past_events_box_ships_seasons_1_to_25 = "past_events_box_seasons_1_to_25.avif"
  past_events_box_air_seasons_1_to_25 = "past_events_box_seasons_1_to_25.avif"
  past_events_box_tanks_seasons_1_to_26 = "past_events_box_seasons_1_to_26.avif"
  past_events_box_ships_seasons_1_to_26 = "past_events_box_seasons_1_to_26.avif"
  past_events_box_air_seasons_1_to_26 = "past_events_box_seasons_1_to_26.avif"
  past_events_box_tanks_seasons_1_to_27 = "past_events_box_seasons_1_to_27.avif"
  past_events_box_ships_seasons_1_to_27 = "past_events_box_seasons_1_to_27.avif"
  past_events_box_air_seasons_1_to_27 = "past_events_box_seasons_1_to_27.avif"
  past_events_box_tanks_seasons_1_to_28 = "past_events_box_seasons_1_to_28.avif"
  past_events_box_ships_seasons_1_to_28 = "past_events_box_seasons_1_to_28.avif"
  past_events_box_air_seasons_1_to_28 = "past_events_box_seasons_1_to_28.avif"
  past_events_box_tanks_seasons_1_to_29 = "past_events_box_seasons_1_to_29.avif"
  past_events_box_ships_seasons_1_to_29 = "past_events_box_seasons_1_to_29.avif"
  past_events_box_air_seasons_1_to_29 = "past_events_box_seasons_1_to_29.avif"
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

  event_special_gift_tanks_new_year_2025_26 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_gift_ships_new_year_2025_26 = "ui/images/event_bg_roulette_christmas_2024.avif"
  event_special_gift_air_new_year_2025_26   = "ui/images/event_bg_roulette_christmas_2024.avif"
  new_year_2025_26_tank_box_high_rank_fixed = "ui/images/event_bg_roulette_christmas_2024.avif"
  new_year_2025_26_ship_box_high_rank_fixed = "ui/images/event_bg_roulette_christmas_2024.avif"
  new_year_2025_26_air_box_high_rank_fixed   = "ui/images/event_bg_roulette_christmas_2024.avif"

  event_special_china_tanks_spending_event   = "ui/images/event_bg_lunar.avif"

  valentine_day_candy_lootbox                = "ui/images/event_bg_valentine_day_2026.avif"
  valentine_day_extra_reward_lootbox         = "ui/images/event_bg_valentine_day_2026.avif"

}

let imgIdBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let defaultSeasonImages = [
  { re = regexp2(@"^event_tanks_(medium|big)_season_\d+$"), mkImg = @(id) $"{id.replace("tanks", "ships")}.avif" },
  { re = regexp2(@"^event_air_(medium|big)_season_\d+$"),   mkImg = @(id) $"{id.replace("air", "ships")}.avif" },
]

let defaultBgImage = "ui/images/event_bg.avif"

let lootboxPreviewBg = { 
  event_special_gift_tanks_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_ships_new_year_2025         = "ui/images/event_bg_christmas_2024.avif"
  event_special_gift_air_new_year_2025           = "ui/images/event_bg_christmas_2024.avif"

  event_special_tanks_independence_2025          = "ui/images/event_bg_event_independence_day.avif"
  event_special_ships_independence_2025          = "ui/images/event_bg_event_independence_day.avif"
  event_special_air_independence_2025            = "ui/images/event_bg_event_independence_day.avif"

  event_special_gift_tanks_anniversary_2025         = "ui/images/event_bg_anniversary_2025.avif"
  event_special_gift_ships_anniversary_2025         = "ui/images/event_bg_anniversary_2025.avif"
  event_special_gift_air_anniversary_2025           = "ui/images/event_bg_anniversary_2025.avif"

  event_special_china_tanks_spending_event         = "ui/images/event_bg_lunar.avif"

  valentine_day_candy_lootbox                      = "ui/images/event_bg_valentine_day_2026.avif"
  valentine_day_extra_reward_lootbox               = "ui/images/event_bg_valentine_day_2026.avif"
}

let defEventLootboxScaleBySlot = {
  ["0"] = 0.6,
  ["1"] = 0.9,
  ["2"] = 1.0,
}

let eventLootboxScale = {
  event_special_tanks_anniversary_2024 = 1.2,
  event_special_ships_anniversary_2024 = 1.2,
  ["event_ships_big_season_25.avif"] = 1.2,
  ["event_ships_big_season_31.avif"] = 1.25,
}

let eventLootboxShiftPos = {
  ["event_ships_big_season_25.avif"] = [0, -0.15],
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
  ["_subbox_"] = "lootbox/lucky",
  ["_fixed_"] = "lootbox/guaranteed"
}

let lootboxImageByNamePart = {
  ["_subbox_"] = "lucky_box.avif",
  ["_fixed_"] = "guaranteed_box.avif"
}

function getLootboxPreviewBg(name) {
  if (lootboxPreviewBg?[name])
    return lootboxPreviewBg[name]
  let season = regexp2(@"_season_(\d+)$").multiExtract("\\1", name)?[0]
  lootboxPreviewBg[name] <- season ? $"ui/images/event_bg_season_{season}.avif" : defaultBgImage

  return lootboxPreviewBg[name]
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

    if (fn == null)
      foreach (part, imgName in lootboxImageByNamePart)
        if (id.indexof(part) != null)
          fn = imgName

    defaultImgFilenameCache[id] <- fn ?? $"{id}.avif"
  }
  return defaultImgFilenameCache[id]
}

function getLootboxImageBase(id, season) {
  let finalId = imgIdBySeason?[id](season) ?? id
  return customLootboxImages?[finalId] ?? getDefaultImgFilename(finalId)
}

function getLootboxImage(id, season = null, size = null) {
  let img = getLootboxImageBase(id, season)
  return !size ? Picture($"ui/gameuiskin/{img}:0:P") : Picture($"ui/gameuiskin/{img}:{size}:{size}:P")
}

let getRouletteImage = @(id) customRouletteImages?[id] ?? defaultBgImage

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

let getEventLootboxSizeMul = @(name, season, eventSlot) eventLootboxScale?[name]
  ?? eventLootboxScale?[getLootboxImageBase(name, season)]
  ?? defEventLootboxScaleBySlot?[eventSlot] ?? 1.0

let getEventLootboxShiftPos = @(name, season) eventLootboxShiftPos?[name]
  ?? eventLootboxShiftPos?[getLootboxImageBase(name, season)]
  ?? [0, 0]

return {
  getLootboxImage
  getRouletteImage
  lootboxFallbackPicture
  mkLoootboxImage
  getLootboxName
  customGoodsLootboxScale
  getLootboxPreviewBg

  getEventLootboxSizeMul
  getEventLootboxShiftPos
}
