let bulletsImages = {
  ap_tank                             = "shell_apbc_tank"
  apbc_tank                           = "shell_apbc_tank"
  apbc_usa_tank                       = "shell_apbc_tank"
  ap_large_caliber_tank               = "shell_apbc_tank"
  apcbc_solid_medium_caliber_tank     = "shell_apbc_tank"
  apc_solid_medium_caliber_tank       = "shell_apbc_tank"
  aphe_tank                           = "shell_apbc_tank"
  aphebc_tank                         = "shell_apbc_tank"
  apc_tank                            = "shell_apbc_tank"
  apcbc_tank                          = "shell_apbc_tank"
  sap_tank                            = "shell_apbc_tank"
  sapbc_tank                          = "shell_apbc_tank"
  sapcbc_tank                         = "shell_apbc_tank"
  sap_hei                             = "shell_apbc_tank"
  ac_shell_tank                       = "shell_apbc_tank"
  apds_tank                           = "shell_apds_tank"
  apds_early_tank                     = "shell_apds_tank"
  apds_l15_tank                       = "shell_apds_tank"
  he_frag_tank                        = "shell_he_frag_tank"
  he_frag_i_tank                      = "shell_he_frag_tank"
  sap_hei_tank                        = "shell_he_frag_tank"
  he_grenade_tank                     = "shell_he_frag_tank"
  he_frag_fs_tank                     = "shell_he_frag_fs_tank"
  heat_tank                           = "shell_heat_tank"
  heat_fs_tank                        = "shell_heat_fs_tank"
  heat_grenade_tank                   = "shell_heat_grenade_tank"
  hesh_tank                           = "shell_hesh_tank"
  apcr_tank                           = "shell_apcr_tank"
  apds_fs_tank                        = "shell_apdsfs_tank"
  apds_fs_full_body_steel_tank        = "shell_apdsfs_tank"
  apds_autocannon                     = "shell_apdsfs_tank"
  smoke_tank                          = "shell_smoke_tank"
  apds_fs_long_l30_tank               = "shell_apds_fs_long_l30_tank"
  apds_fs_long_tank                   = "shell_apds_fs_long_tank"
  apds_fs_tungsten_caliber_fins_tank  = "shell_apds_fs_tungsten_caliber_fins_tank"
  apds_fs_tungsten_l10_l15_tank       = "shell_apds_fs_tungsten_l10_l15_tank"
  apds_fs_tungsten_small_core_tank    = "shell_apds_fs_tungsten_small_core_tank"
  atgm_tank                           = "shell_atgm_tank"
  atgm_tandem_tank                    = "shell_atgm_tandem_tank"
  atgm_he_tank                        = "shell_atgm_he_tank"
  atgm_vt_fuze_tank                   = "shell_atgm_vt_fuze_tank"
  shell_bullet_belt_tank              = "shell_bullet_belt_tank"

  aam                                 = "air_to_air_missile"
}

let defaultBeltImage                  = "bullet_gun_brown"
let bulletsBeltImages = {
  ball                                = "bullet_gun_brown"
  t_ball                              = "bullet_gun_green"
  i_ball                              = "bullet_gun_blue"
  ap_ball                             = "bullet_gun_red"
  ap_t_ball                           = "bullet_gun_red_green"
  ap_i_ball                           = "bullet_gun_red_blue"
  ap_i_t_ball                         = "bullet_gun_red_blue_green"
  apcr_i_ball                         = "bullet_gun_black_blue"
  apcr_i_ball_bs41                    = "bullet_gun_black_blue"
  he_ball                             = "bullet_gun_yellow"
  he_i_ball                           = "bullet_gun_yellow"
  he_i_fuse_ball                      = "bullet_gun_yellow"
  he_frag_t_ball                      = "bullet_gun_yellow_green"
  i_t_ball                            = "bullet_gun_blue_green"
  i_ball_M1                           = "bullet_gun_blue"
  t_ball_M1                           = "bullet_gun_green"
  ap_ball_M2                          = "bullet_gun_red"
  ball_M2                             = "bullet_gun_brown"
  ap_i_t_ball_M20                     = "bullet_gun_red_blue_green"
  i_ball_M23                          = "bullet_gun_blue"
  ap_i_ball_M8                        = "bullet_gun_red_blue"
}

let bulletsLocIdByCaliber = [
  "air_target", "air_targets", "all_tracers", "antibomber", "antitank", "apit", "apt",
  "armor_target", "armor_targets", "fighter", "ground_targets", "mix", "night", "stealth",
  "tracer", "tracers", "turret_ap", "turret_ap_he", "turret_ap_t", "turret_api", "turret_apit",
  "turret_apt", "turret_he", "turret_het", "universal"
]

function getBulletImage(bullets){
  if(bullets.len() > 1)
    return "ui/gameuiskin#shell_bullet_belt_tank.avif"
  return bulletsImages?[bullets[0]] ? $"ui/gameuiskin#{bulletsImages?[bullets[0]]}.avif"
   : "ui/unitskin#image_in_progress.avif"
}

function getLocIdPrefixByCaliber(name) {
  foreach(id in bulletsLocIdByCaliber)
    if (name.endswith(id))
      return id
  return null
}

return {
  getBulletImage
  getBulletBeltImage = @(id) $"ui/gameuiskin#{bulletsBeltImages?[id] ?? defaultBeltImage}.avif"
  getLocIdPrefixByCaliber
}