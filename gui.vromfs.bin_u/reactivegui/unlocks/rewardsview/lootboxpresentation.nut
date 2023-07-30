from "%globalsDarg/darg_library.nut" import *

let defaultLootbox = "ui/gameuiskin#crate_small_1.avif"
let lootboxImage = {
  every_day_award_small_pack = "ui/gameuiskin#daily_box_small.avif"
  every_day_award_big_pack_1 = "ui/gameuiskin#daily_box_big.avif"
  every_day_award_big_pack_2 = "ui/gameuiskin#daily_box_very_big.avif"
}.map(@(v) ":".concat(v, "{0}", "{0}", "P"))

let lootboxCustomLocId = {}

return {
  getLootboxImage = @(id, size) Picture((lootboxImage?[id] ?? defaultLootbox).subst(size))
  getLootboxName = @(id) loc(lootboxCustomLocId?[id] ?? $"lootbox/{id}")
}
