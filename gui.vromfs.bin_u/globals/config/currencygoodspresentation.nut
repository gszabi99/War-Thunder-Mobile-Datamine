let { max } = require("math")
let { getBaseCurrency, getSeasonStr, getCurrencyBigIcon } = require("currencyPresentation.nut")
let { WP, GOLD, WARBOND, EVENT_KEY, NYBOND, PLATINUM, APRILBOND, APRILMAPPIECE, APRILDOUBLON,
  BLACK_FRIDAY_BOND, HOTMAYBOND, INDEPENDENCEBOND, ANNIVERSARYBOND, HALLOWEENBOND
} = require("%appGlobals/currenciesState.nut")

let presentations = {
  [WP] = [
    { img = "shop_lions_01.avif", amountAtLeast = 0 }
    { img = "shop_lions_02.avif", amountAtLeast = 40000 }
    { img = "shop_lions_03.avif", amountAtLeast = 90000 }
    { img = "shop_lions_04.avif", amountAtLeast = 200000 }
    { img = "shop_lions_05.avif", amountAtLeast = 300000 }
    { img = "shop_lions_06.avif", amountAtLeast = 500000 }
    { img = "shop_lions_07.avif", amountAtLeast = 1000000 }
  ],
  [GOLD] = [
    { img = "shop_eagles_01.avif", amountAtLeast = 0 }
    { img = "shop_eagles_02.avif", amountAtLeast = 400 }
    { img = "shop_eagles_03.avif", amountAtLeast = 1200 }
    { img = "shop_eagles_04.avif", amountAtLeast = 2400 }
    { img = "shop_eagles_05.avif", amountAtLeast = 4000 }
    { img = "shop_eagles_06.avif", amountAtLeast = 8000 }
  ],
  [PLATINUM] = [
    { img = "shop_wolves_01.avif", amountAtLeast = 200 }
    { img = "shop_wolves_02.avif", amountAtLeast = 500 }
    { img = "shop_wolves_03.avif", amountAtLeast = 1000 }
    { img = "shop_wolves_04.avif", amountAtLeast = 5000 }
    { img = "shop_wolves_05.avif", amountAtLeast = 10000 }
  ],
  [NYBOND] = [
    { img = "warbond_goods_christmas_01.avif", amountAtLeast = 0 }
    { img = "warbond_goods_christmas_02.avif", amountAtLeast = 600 }
    { img = "warbond_goods_christmas_03.avif", amountAtLeast = 3000 }
  ],
  [APRILBOND] = [
    { img = "warbond_april_01.avif", amountAtLeast = 0 }
    { img = "warbond_april_02.avif", amountAtLeast = 600 }
    { img = "warbond_april_03.avif", amountAtLeast = 3000 }
  ],
  [APRILMAPPIECE] = [
    { img = "aprilmappiece_goods_01.avif", amountAtLeast = 0 }
    { img = "aprilmappiece_goods_02.avif", amountAtLeast = 10 }
  ],
  [APRILDOUBLON] = [
    { img = "aprildoublon_goods_01.avif", amountAtLeast = 0 }
    { img = "aprildoublon_goods_02.avif", amountAtLeast = 1001 }
    { img = "aprildoublon_goods_03.avif", amountAtLeast = 3000 }
  ],
  [WARBOND] = [
    { img = "warbond_goods_01.avif", amountAtLeast = 0 }
    { img = "warbond_goods_02.avif", amountAtLeast = 2000 }
    { img = "warbond_goods_03.avif", amountAtLeast = 10000 }
  ],
  [EVENT_KEY] = [
    { img = $"event_keys_01.avif", amountAtLeast = 0 }
    { img = $"event_keys_02.avif", amountAtLeast = 2 }
    { img = $"event_keys_03.avif", amountAtLeast = 10 }
  ],
  [BLACK_FRIDAY_BOND] = [
    { img = "blackfridaybond_goods_01.avif", amountAtLeast = 0 }
    { img = "blackfridaybond_goods_02.avif", amountAtLeast = 500 }
    { img = "blackfridaybond_goods_03.avif", amountAtLeast = 1000 }
  ],
  [HOTMAYBOND] = [
    { img = "hotmaybond_goods_01.avif", amountAtLeast = 0 }
    { img = "hotmaybond_goods_01.avif", amountAtLeast = 500 }
    { img = "hotmaybond_goods_01.avif", amountAtLeast = 1000 }
  ],
  [INDEPENDENCEBOND] = [
    { img = "independencebond_goods_01.avif", amountAtLeast = 0 }
    { img = "independencebond_goods_02.avif", amountAtLeast = 600 }
    { img = "independencebond_goods_03.avif", amountAtLeast = 3000 }
  ],
  [ANNIVERSARYBOND] = [
    { img = "anniversarybond_goods_2025_01.avif", amountAtLeast = 0 }
    { img = "anniversarybond_goods_2025_02.avif", amountAtLeast = 500 }
    { img = "anniversarybond_goods_2025_03.avif", amountAtLeast = 1500 }
  ],
  [HALLOWEENBOND] = [
    { img = "halloweenbond_goods_2025_01.avif", amountAtLeast = 0 }
    { img = "halloweenbond_goods_2025_02.avif", amountAtLeast = 500 }
    { img = "halloweenbond_goods_2025_03.avif", amountAtLeast = 1500 }
  ],
}

let ctors = {
  [WARBOND] = @(season) [
    {
      img = season != ""
        ? $"warbond_goods_season_{season}_01.avif"
        : "warbond_goods_01.avif"
      fallbackImg = "warbond_goods_01.avif"
      amountAtLeast = 0
    }
    {
      img = season != ""
        ? $"warbond_goods_season_{season}_02.avif"
        : "warbond_goods_02.avif"
      fallbackImg = "warbond_goods_02.avif"
      amountAtLeast = 2000
    }
    {
      img = season != ""
        ? $"warbond_goods_season_{season}_03.avif"
        : "warbond_goods_03.avif"
      fallbackImg = "warbond_goods_03.avif"
      amountAtLeast = 10000
    }
  ],
  [EVENT_KEY] = @(season) [
    {
      img = season != ""
        ? $"event_keys_season_{season}_01.avif"
        : "event_keys_01.avif"
      fallbackImg = "event_keys_01.avif"
      amountAtLeast = 0
    }
    {
      img = season != ""
        ? $"event_keys_season_{season}_02.avif"
        : "event_keys_02.avif"
      fallbackImg = "event_keys_02.avif"
      amountAtLeast = 2
    }
    {
      img = season != ""
        ? $"event_keys_season_{season}_03.avif"
        : "event_keys_03.avif"
      fallbackImg = "event_keys_03.avif"
      amountAtLeast = 10
    }
  ],
}

let defaultCtor = @(curId) [
  {
    img = getCurrencyBigIcon(curId).slice(14), 
    amountAtLeast = 0
  }
]

function mkPresentation(id) {
  let baseId = getBaseCurrency(id)
  let seasonCtor = ctors?[baseId]
  if (seasonCtor != null)
    return seasonCtor(getSeasonStr(id))
  return presentations?[baseId] ?? defaultCtor(id)
}

function getPresentationFull(id) {
  if (id not in presentations)
    presentations[id] <- mkPresentation(id)
  return presentations[id]
}

function getCurrencyGoodsPresentation(id, amount = null) {
  let full = getPresentationFull(id)
  if (amount == null)
    return full[0]
  let nextIdx = full.findindex(@(v) v.amountAtLeast > amount) ?? full.len()
  return full[max(0, nextIdx - 1)]
}

return getCurrencyGoodsPresentation
