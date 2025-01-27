let { WP, GOLD, WARBOND, EVENT_KEY, NYBOND, PLATINUM, APRILBOND, BLACK_FRIDAY_BOND } = require("%appGlobals/currenciesState.nut")

let SEASON_EMPTY = "season_0"

let imgCfgByCurrency = {
  [WP] = {
    def = [
      { img = "shop_lions_01.avif", amountAtLeast = 0 }
      { img = "shop_lions_02.avif", amountAtLeast = 40000 }
      { img = "shop_lions_03.avif", amountAtLeast = 90000 }
      { img = "shop_lions_04.avif", amountAtLeast = 200000 }
      { img = "shop_lions_05.avif", amountAtLeast = 300000 }
      { img = "shop_lions_06.avif", amountAtLeast = 500000 }
      { img = "shop_lions_07.avif", amountAtLeast = 1000000 }
    ]
   },
  [GOLD] = {
    def = [
      { img = "shop_eagles_01.avif", amountAtLeast = 0 }
      { img = "shop_eagles_02.avif", amountAtLeast = 400 }
      { img = "shop_eagles_03.avif", amountAtLeast = 1200 }
      { img = "shop_eagles_04.avif", amountAtLeast = 2400 }
      { img = "shop_eagles_05.avif", amountAtLeast = 4000 }
      { img = "shop_eagles_06.avif", amountAtLeast = 8000 }
    ]
  },
  [PLATINUM] = {
    def = [
      { img = "shop_wolves_01.avif", amountAtLeast = 200 }
      { img = "shop_wolves_02.avif", amountAtLeast = 500 }
      { img = "shop_wolves_03.avif", amountAtLeast = 1000 }
      { img = "shop_wolves_04.avif", amountAtLeast = 5000 }
      { img = "shop_wolves_05.avif", amountAtLeast = 10000 }
    ]
  },
  [NYBOND] = {
    def = [
      { img = "warbond_goods_christmas_01.avif", amountAtLeast = 0 }
      { img = "warbond_goods_christmas_02.avif", amountAtLeast = 600 }
      { img = "warbond_goods_christmas_03.avif", amountAtLeast = 3000 }
    ]
  },
  [APRILBOND] = {
    def = [
      { img = "warbond_april_01.avif", amountAtLeast = 0 }
      { img = "warbond_april_02.avif", amountAtLeast = 600 }
      { img = "warbond_april_03.avif", amountAtLeast = 3000 }
    ]
  },
  [WARBOND] = {
    season_3 = [
      { img = "warbond_goods_01.avif", amountAtLeast = 0 }
      { img = "warbond_goods_02.avif", amountAtLeast = 2000 }
      { img = "warbond_goods_03.avif", amountAtLeast = 10000 }
    ]
  },
  [EVENT_KEY] = {
    season_3 = [
      { img = $"event_keys_01.avif", amountAtLeast = 0 }
      { img = $"event_keys_02.avif", amountAtLeast = 2 }
      { img = $"event_keys_03.avif", amountAtLeast = 10 }
    ],
  },
  [BLACK_FRIDAY_BOND] = {
    def = [
      { img = "blackfridaybond_goods_01.avif", amountAtLeast = 0 }
      { img = "blackfridaybond_goods_02.avif", amountAtLeast = 500 }
      { img = "blackfridaybond_goods_03.avif", amountAtLeast = 1000 }
    ]
  },
}

let cfgCtors = {
  [WARBOND] = @(season) [
    {
      img = season != SEASON_EMPTY
        ? $"warbond_goods_{season}_01.avif"
        : "warbond_goods_01.avif"
      fallbackImg = "warbond_goods_01.avif"
      amountAtLeast = 0
    }
    {
      img = season != SEASON_EMPTY
        ? $"warbond_goods_{season}_02.avif"
        : "warbond_goods_02.avif"
      fallbackImg = "warbond_goods_02.avif"
      amountAtLeast = 2000
    }
    {
      img = season != SEASON_EMPTY
        ? $"warbond_goods_{season}_03.avif"
        : "warbond_goods_03.avif"
      fallbackImg = "warbond_goods_03.avif"
      amountAtLeast = 10000
    }
  ],
  [EVENT_KEY] = @(season) [
    {
      img = season != SEASON_EMPTY
        ? $"event_keys_{season}_01.avif"
        : "event_keys_01.avif"
      fallbackImg = "event_keys_01.avif"
      amountAtLeast = 0
    }
    {
      img = season != SEASON_EMPTY
        ? $"event_keys_{season}_02.avif"
        : "event_keys_02.avif"
      fallbackImg = "event_keys_02.avif"
      amountAtLeast = 2
    }
    {
      img = season != SEASON_EMPTY
        ? $"event_keys_{season}_03.avif"
        : "event_keys_03.avif"
      fallbackImg = "event_keys_03.avif"
      amountAtLeast = 10
    }
  ],
}

let unknownCurrencyCtor = @(curId) [
  { img = $"{curId}_goods_01.avif", amountAtLeast = 0 }
  { img = $"{curId}_goods_02.avif", amountAtLeast = 2000 }
  { img = $"{curId}_goods_03.avif", amountAtLeast = 10000 }
]

foreach(id, _ in cfgCtors)
  if (id not in imgCfgByCurrency)
    imgCfgByCurrency[id] <- {}

function getCurrencyGoodsPresentation(curId, season = SEASON_EMPTY) {
  if (curId not in cfgCtors) {
    if (curId not in imgCfgByCurrency)
      imgCfgByCurrency[curId] <- { def = unknownCurrencyCtor(curId) }
    return imgCfgByCurrency[curId].def
  }
  if (season not in imgCfgByCurrency?[curId])
    imgCfgByCurrency[curId][season] <- cfgCtors[curId](season)
  return imgCfgByCurrency[curId][season]
}

return getCurrencyGoodsPresentation
