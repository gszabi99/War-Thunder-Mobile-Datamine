from "%globalsDarg/darg_library.nut" import *
let { mkBgImageByPx } = require("%globalsDarg/components/mkAnimBg.nut")

return @() [
  {
    moveX = sh(6)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_0.avif")
  }
  {
    moveX = sh(-3)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_1?x1ac", [912, 112], [1790, 567])
  }
  {
    moveX = sh(-3)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_2?x1ac", [1500, 480], [0, 445])
  }
  {
    moveX = sh(-3.3)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_3?x1ac", [496, 104], [806, 576])
  }
  {
    moveX = sh(-3.5)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_4?x1ac", [436, 336], [1293, 312])
  }
  {
    moveX = sh(-5)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_5?x1ac", [flex(), 496], [0, 586])
  }
  {
    moveX = sh(-5)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_6?x1ac", [1088, 732], [1193, 85])
  }
  {
    moveX = sh(-5.5)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_7?x1ac", [444, 260], [1544, 346])
  }
  {
    moveX = sh(-6)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_8?x1ac", [448, 256], [1456, 376])
  }
  {
    moveX = sh(-5.3)
    children = mkBgImageByPx("ui/bkg/login_layer_testloading_9?x1ac", [292, 224], [1851, 462])
  }
  { 
    children = mkBgImageByPx("ui/bkg/login_layer_4", [pw(1.3), ph(1.8)], [pw(-0.15), ph(-0.4)])
  }
]