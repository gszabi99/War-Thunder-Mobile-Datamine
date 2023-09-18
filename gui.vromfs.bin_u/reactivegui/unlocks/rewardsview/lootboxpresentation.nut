from "%globalsDarg/darg_library.nut" import *

let defaultLootbox = "ui/gameuiskin#daily_box_small.avif"
let lootboxImage = {
  every_day_award_small_pack = "ui/gameuiskin#daily_box_small.avif"
  every_day_award_big_pack_1 = "ui/gameuiskin#daily_box_big.avif"
  every_day_award_big_pack_2 = "ui/gameuiskin#daily_box_very_big.avif"
  event_small = "ui/gameuiskin#event_chest_01.avif"
  event_medium = "ui/gameuiskin#event_chest_02.avif"
  event_big = "ui/gameuiskin#event_chest_03.avif"
}.map(@(v) ":".concat(v, "{0}", "{0}", "P"))

let lootboxCustomLocId = {
  event_small = "lootbox/every_day_award_small_pack"
  event_medium = "lootbox/every_day_award_medium_pack"
  event_big = "lootbox/every_day_award_big_pack_1"
}

return {
  getLootboxImage = @(id, size) Picture((lootboxImage?[id] ?? defaultLootbox).subst(size))
  getLootboxName = @(id) loc(lootboxCustomLocId?[id] ?? $"lootbox/{id}")
}
