from "%globalsDarg/darg_library.nut" import *
let { eventSeason } = require("%rGui/event/eventState.nut")

let defaultLootbox = "ui/gameuiskin#daily_box_small.avif"

let lootboxLocIdBySlot = {
  ["0"] = "lootbox/every_day_award_small_pack",
  ["1"] = "lootbox/every_day_award_medium_pack",
  ["2"] = "lootbox/every_day_award_big_pack_1",
}

let sizeMulBySlot = {
  ["0"] = 0.6,
  ["1"] = 0.8,
  ["2"] = 0.9,
}

let getImgBySeason = {
  event_small = @(season) $"event_small_{season}",
}

let getLootboxName = @(id, slot = "") loc(lootboxLocIdBySlot?[slot] ?? $"lootbox/{id}")

let getLootboxSizeMul = @(slot = "") sizeMulBySlot?[slot] ?? 1.0

let function getLootboxImage(id, season, size = null) {
  let img = id in getImgBySeason ? getImgBySeason[id](season) : id
  return !size ? Picture($"ui/gameuiskin#{img}.avif:0:P") : Picture($"ui/gameuiskin#{img}.avif:{size}:{size}:P")
}

let getLootboxFallbackImage = @(size = null)
  !size ? Picture($"{defaultLootbox}:0:P") : Picture($"{defaultLootbox}:{size}:{size}:P")

let mkLoootboxImage = @(id, size = null, ovr = {}) @() {
  watch = eventSeason
  size = size ? [size, size] : SIZE_TO_CONTENT
  rendObj = ROBJ_IMAGE
  image = getLootboxImage(id, eventSeason.value, size)
  fallbackImage = getLootboxFallbackImage(size)
  keepAspect = true
}.__update(ovr)

return {
  getLootboxImage
  getLootboxFallbackImage
  getLootboxName
  getLootboxSizeMul
  mkLoootboxImage
}
