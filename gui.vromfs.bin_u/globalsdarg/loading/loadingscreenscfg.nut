from "%globalsDarg/darg_library.nut" import *
let { mkBgImageByPx } = require("%globalsDarg/components/mkAnimBg.nut")

let fallbackLoadingImage = "ui/bkg/login_bkg_s_1.avif"

let mkSingleImageLayers = @(image) [{
  moveX = sh(10)
  children = mkBgImageByPx(image)
}]

let screensList = {
  simple_ship_1 = {
    camp = [ "ships" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_s_1.avif")
  }
  simple_ship_2 = {
    camp = [ "ships" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_s_2.avif")
  }
  simple_ship_3 = {
    camp = [ "ships" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_s_3.avif")
  }
  simple_ship_4 = {
    camp = [ "ships" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_s_4.avif")
  }
  complex_ship_1 = {
    camp = [ "ships" ]
    weight = 2.0
    layers = require("complex_ship_1.nut")
  }
  simple_tank_1 = {
    camp = [ "tanks" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_t_1.avif")
  }
  simple_tank_2 = {
    camp = [ "tanks" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_t_2.avif")
  }
  simple_tank_3 = {
    camp = [ "tanks" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_t_3.avif")
  }
  simple_tank_4 = {
    camp = [ "tanks" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_t_4.avif")
  }
  simple_tank_5 = {
    camp = [ "tanks" ]
    weight = 1.0
    layers = mkSingleImageLayers("ui/bkg/login_bkg_t_5.avif")
  }
}

return {
  fallbackLoadingImage
  screensList
}