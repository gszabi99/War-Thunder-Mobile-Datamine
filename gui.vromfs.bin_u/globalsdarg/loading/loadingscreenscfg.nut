from "%globalsDarg/darg_library.nut" import *
let { mkBgImageByPx } = require("%globalsDarg/components/mkAnimBg.nut")
let mkLayersComplexShip1 = require("complex_ship_1.nut")

/*
For fallbackLoadingImage please use only image from screen ID, which is listed in "screensList" below,
AND listed in "loadingScreensWhitelist" (skyquake/prog/scripts/wtm/updater/updaterScene.nut),
because Android Updated uses this loadingScreensCfg.nut module too, but in its VROMs there are ONLY
those few images, which are listed in its "loadingScreensWhitelist".
*/
let fallbackLoadingImage = "ui/bkg/login_bkg_t_7.avif"

let mkSingleImageLayers = @(image) [{
  moveX = sh(10)
  children = mkBgImageByPx(image)
}]

/*
Here, layers are described as functions (not daRG elems) so that Picture elems in it (loading screen image
takes 11 MB in memory) do not take up memory when they are not used. Because global Picture objects exported
from the module prevent textures from storing texture references and prevent them from being deallocated.
You can use a console command "app.tex" and then filter its output by "ui/" to see all UI textures currently
loaded in memory, and how much memory each one takes up.
*/

let screensList = {
  simple_ship_1 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_1.avif")
  }
  simple_ship_2 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_2.avif")
  }
  simple_ship_3 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_3.avif")
  }
  simple_ship_4 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_4.avif")
  }
  simple_ship_5 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_5.avif")
  }
  simple_ship_6 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_6.avif")
  }
  simple_ship_7 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_7.avif")
  }
  complex_ship_1 = {
    camp = [ "ships" ]
    weight = 1.0
    mkLayers = mkLayersComplexShip1
  }
  simple_tank_1 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_1.avif")
  }
  simple_tank_2 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_2.avif")
  }
  simple_tank_3 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_3.avif")
  }
  simple_tank_4 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_4.avif")
  }
  simple_tank_5 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_5.avif")
  }
  simple_tank_6 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_6.avif")
  }
  simple_tank_7 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_7.avif")
  }
  simple_tank_8 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_8.avif")
  }
  simple_tank_9 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_9.avif")
  }
  simple_tank_10 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_10.avif")
  }
  event_pony = {
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_11.avif")
  }
  simple_tank_12 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_12.avif")
  }
  simple_tank_13 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_13.avif")
  }
  simple_tank_14 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_14.avif")
  }
  event_anniversary = {
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_15.avif")
  }
  simple_tank_16 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_16.avif")
  }
  event_halloween = {
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_17.avif")
  }
  simple_tank_18 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_18.avif")
  }
  simple_tank_19 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_19.avif")
  }
  event_christmas = {
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_20.avif")
  }
  event_lunar_ny = {
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_21.avif")
  }
  event_april_fools = {
    camp = [ "ships" ]
    weight = 0.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_s_8.avif")
  }
  simple_tank_20 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_22.avif")
  }
  simple_tank_21 = {
    camp = [ "tanks" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_24.avif")
  }
  simple_tank_22 = {
    camp = [ "tanks" ]
    weight = 2.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_t_25.avif")
  }
  simple_airplane_1 = {
    camp = [ "air" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_a_1.avif")
  }
  simple_airplane_3 = {
    camp = [ "air" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_a_3.avif")
  }
  simple_airplane_4 = {
    camp = [ "air" ]
    weight = 1.0
    mkLayers = @() mkSingleImageLayers("ui/bkg/login_bkg_a_4.avif")
  }

}

return {
  fallbackLoadingImage
  screensList
}