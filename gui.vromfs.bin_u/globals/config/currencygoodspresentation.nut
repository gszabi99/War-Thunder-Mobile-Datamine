let { WP, GOLD, WARBOND, EVENT_KEY, NYBOND } = require("%appGlobals/currenciesState.nut")

let imgCfgByCurrency = {
  [WP] = [
    { img = "ui/gameuiskin/shop_lions_01.avif", amountAtLeast = 0 }
    { img = "ui/gameuiskin/shop_lions_02.avif", amountAtLeast = 40000 }
    { img = "ui/gameuiskin/shop_lions_03.avif", amountAtLeast = 100000 }
    { img = "ui/gameuiskin/shop_lions_04.avif", amountAtLeast = 300000 }
    { img = "ui/gameuiskin/shop_lions_05.avif", amountAtLeast = 500000 }
    { img = "ui/gameuiskin/shop_lions_06.avif", amountAtLeast = 1000000 }
  ],
  [GOLD] = [
    { img = "ui/gameuiskin/shop_eagles_01.avif", amountAtLeast = 0 }
    { img = "ui/gameuiskin/shop_eagles_02.avif", amountAtLeast = 400 }
    { img = "ui/gameuiskin/shop_eagles_03.avif", amountAtLeast = 600 }
    { img = "ui/gameuiskin/shop_eagles_04.avif", amountAtLeast = 1200 }
    { img = "ui/gameuiskin/shop_eagles_05.avif", amountAtLeast = 2400 }
    { img = "ui/gameuiskin/shop_eagles_06.avif", amountAtLeast = 4000 }
    { img = "ui/gameuiskin/shop_eagles_07.avif", amountAtLeast = 8000 }
  ],
  [WARBOND] = [
    { img = "ui/gameuiskin/warbond_goods_01.avif", amountAtLeast = 0 }
    { img = "ui/gameuiskin/warbond_goods_02.avif", amountAtLeast = 2000 }
    { img = "ui/gameuiskin/warbond_goods_03.avif", amountAtLeast = 10000 }
  ],
  [EVENT_KEY] = [
    { img =  "ui/gameuiskin/event_keys_01.avif", amountAtLeast = 0 }
    { img =  "ui/gameuiskin/event_keys_02.avif", amountAtLeast = 2 }
    { img =  "ui/gameuiskin/event_keys_03.avif", amountAtLeast = 10 }
  ],
  [NYBOND] = [
    { img =  "ui/gameuiskin/warbond_goods_christmas_01.avif", amountAtLeast = 0 }
    { img =  "ui/gameuiskin/warbond_goods_christmas_02.avif", amountAtLeast = 600 }
    { img =  "ui/gameuiskin/warbond_goods_christmas_03.avif", amountAtLeast = 3000 }
  ],
}

let getCurrencyGoodsPresentation = @(curId) imgCfgByCurrency?[curId] ?? [
  { img = $"ui/gameuiskin/{curId}_goods_01.avif", amountAtLeast = 0 }
  { img = $"ui/gameuiskin/{curId}_goods_02.avif", amountAtLeast = 20 }
  { img = $"ui/gameuiskin/{curId}_goods_03.avif", amountAtLeast = 100 }
]

return getCurrencyGoodsPresentation
