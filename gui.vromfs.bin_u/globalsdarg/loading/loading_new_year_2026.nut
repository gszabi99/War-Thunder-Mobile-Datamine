from "%globalsDarg/darg_library.nut" import *
let { mkBgImageByPx, mkBgImageWithFallback } = require("%globalsDarg/components/mkAnimBg.nut")

return @() [
  {
    moveX = sh(-6)
    children = mkBgImageWithFallback("ui/bkg/login_layer_loading_new_year_2026_layer_1.avif")
  }
  {
    moveX = sh(-1)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_new_year_2026_layer_2?x1ac", [1012, 560], [809, 0])
  }
    {
    moveX = sh(4)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_new_year_2026_layer_3?x1ac", [1856, 620], [303, 0])
  }
    {
    moveX = sh(5)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_new_year_2026_layer_4?x1ac", [596, 236], [1725, 0])
  }
    {
    moveX = sh(2)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_new_year_2026_layer_5?x1ac", [536, 424], [594, 0])
  }
  {
    moveX = sh(8)
    children = mkBgImageByPx("ui/bkg/login_layer_loading_new_year_2026_layer_6?x1ac", [2700, 1080], [0, 0])
  }
  { 
    children = mkBgImageByPx("ui/bkg/login_layer_4", [pw(1.3), ph(1.8)], [pw(-0.15), ph(-0.4)])
  }
]