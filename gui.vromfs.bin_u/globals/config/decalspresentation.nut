from "%globalsDarg/darg_library.nut" import *

let categoryDecalsLoc = {
  china = "country_china"
  france = "country_france"
  germany = "country_germany"
  japan = "country_japan"
  israel = "country_israel"
  italy = "country_italy"
  sweden = "country_sweden"
  usa = "country_usa"
  uk = "country_uk"
  ussr = "country_ussr"
}

let defPresentation = { scale = 0.55 }
let presentations = {
  polar_owl_decal = { scale = 0.8 }
  rook_decal = { scale = 0.7 }
  new_year_26_pinup_decal = { scale = 0.7 }
  new_year_26_lights_decal = { scale = 0.7 }
  april_event_2026_victory_marks = { scale = 0.8 }
}

let defDescPresentation = { scale = 0.8 }
let descPresentation = {
  april_event_2026_victory_marks = { scale = 1.3 }
  counters_16 = { scale = 1.3 }
  counters_25 = { scale = 1.3 }
  uk_deer_335104_rat = { scale = 1.3 }
  uk_deer_rat = { scale = 1.3 }
  new_year_26_lights_decal = { scale = 1.3 }
  germany_numbers_red_11 = { scale = 1.3 }
  germany_numbers_red_13 = { scale = 1.3 }
  germany_numbers_red_33 = { scale = 1.3 }
  jp_3rd_tank_bat = { scale = 1.3 }
  jp_2nd_company_tank_school_fuji = { scale = 1.3 }
  happy_new_year_decal = { scale = 1.3 }
  provence_decal = { scale = 1.3 }
  savoie_decal = { scale = 1.3 }
  ttd_tank_decal = { scale = 1.3 }
  polar_owl_decal = { scale = 1.3 }
  t34_tank_decal = { scale = 1.3 }
  viking_02 = { scale = 1.3 }
  usa_text_destruction = { scale = 1.3 }
  usa_text_foxhunter = { scale = 1.3 }
  usa_text_franche_comte = { scale = 1.3 }
  usa_text_good_luck = { scale = 1.3 }
  text_10 = { scale = 1.3 }
  text_destroyer = { scale = 1.3 }
  text_got_you = { scale = 1.3 }
  text_kliment_voroshilov = { scale = 1.3 }
  text_towards_the_west = { scale = 1.3 }
  text_victory_is_ours = { scale = 1.3 }
  text_war_bride = { scale = 1.3 }
  ussr_text_otvet_stalingrada = { scale = 1.3 }
  ussr_text_za_rodinu = { scale = 1.3 }
  ussr_vdv_1955_white = { scale = 1.3 }
  jp_infantry_school_reg_5th_company = { scale = 1.2 }
  ge_ritter_emblem_v2 = { scale = 1.2 }
  decal_215 = { scale = 1.2 }
  ussr_bmd_4m_decal = { scale = 1.2 }
  ussr_text_smely = { scale = 1.2 }
  decal_402 = { scale = 1.1 }
  rook_decal = { scale = 1.1 }
  leopard_457_decal = { scale = 1.1 }
  halloween_bat_decal = { scale = 1.1 }
  uk_1st_armoured_division = { scale = 1.1 }
  ww_s2_shark = { scale = 1.1 }
  ww_s2_tiger = { scale = 1.1 }
  valentine_kiss = { scale = 1.1 }
  usmc_tank_emblem = { scale = 1.1 }
  ussr_tank_emblem_08 = { scale = 1.1 }
  ussr_tank_emblem_03 = { scale = 1.1 }
  flag_great_britain = { scale = 1.1 }
}

let getDecalCategoryLocName = @(cat) loc(categoryDecalsLoc?[cat] ?? $"decals/category/{cat}")
let getDecalPresentation = @(id) presentations?[id] ?? defPresentation
let getDecalDescPresentation = @(id) descPresentation?[id] ?? defDescPresentation

return {
  getDecalDescPresentation
  getDecalCategoryLocName
  getDecalPresentation
}
