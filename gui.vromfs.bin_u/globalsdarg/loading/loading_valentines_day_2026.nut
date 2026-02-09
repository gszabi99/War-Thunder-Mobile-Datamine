from "%globalsDarg/darg_library.nut" import *
let { mkBgImageByPx, mkBgImageWithFallback } = require("%globalsDarg/components/mkAnimBg.nut")

return @() [
  {
    moveX = sh(-6)
    children = mkBgImageWithFallback("ui/bkg/login_layer_loading_valentines_day_2026.avif")
  }
  {
    moveX = sh(2)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_1?x1ac", [2700, 1080], [0, 0])
  }
  {
    moveX = sh(3)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_7?x1ac", [964, 472], [1736, 0])
  }
  {
    moveX = sh(4)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_2?x1ac", [2700, 812], [0, 269])
  }
  {
    moveX = sh(4)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_3?x1ac", [2448, 860], [212, 0])
  }
  {
    moveX = sh(8)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_4?x1ac", [1904, 1028], [726, 53])
  }
  {
    moveX = sh(8)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_5?x1ac", [2680, 936], [20, 0])
  }
  {
    moveX = sh(10)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_6?x1ac", [2700, 1080], [0, 0])
  }
  {
    moveX = sh(12)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_8?x1ac", [2700, 1080], [0, 0])
  }
  {
    moveX = sh(10)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_valentines_day_2026_9?x1ac", [2700, 1080], [0, 0])
  }
  { 
    children = mkBgImageByPx("ui/bkg/login_layer_4", [pw(1.3), ph(1.8)], [pw(-0.15), ph(-0.4)])
  }
]