from "%globalsDarg/darg_library.nut" import *

let STREAK_SIZE = 90

let mkSizeByParent = @(size) [
  pw(100.0 * size[0] / STREAK_SIZE),
  ph(100.0 * size[1] / STREAK_SIZE)
]

let mkImageParams = @(pxSize, pxOffset = [0,0]) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = mkSizeByParent(pxSize)
  pos = mkSizeByParent(pxOffset)
}

let mkStackImage = @(img, pxSize, pxOffset = [0, 0]) {
  img = $"ui/gameuiskin#{img}"
  params = mkImageParams(pxSize, pxOffset)
}
let mkNumberCtor = @(pxSize, pxOffset = [0, 0])
  @(val) {
    img = $"ui/gameuiskin#multi_kill_{min(9, val)}.avif"
    params = mkImageParams(pxSize, pxOffset)
  }

let streaksPresentation = {
  unknown = {
    name = "streaks/unknown"
    bgImage = "ui/gameuiskin#streaks_event_bg.avif"
    stackImages = [
      {
        params = mkImageParams([140, 70], [12, -13])
        img = "ui/unitskin#image_in_progress"
      }
    ]
  }
  first_blood = {
    name = "streaks/first_blood"
    bgImage = "ui/gameuiskin#streaks_event_bg.avif"
    stackImages = [
      mkStackImage("first_kill.avif", [55, 55])
    ]
  }
  final_blow = {
    name = "streaks/final_blow"
    bgImage = "ui/gameuiskin#streaks_event_bg.avif"
    stackImages = [
      mkStackImage("last_kill.avif", [55, 55])
    ]
  }
  last_man_standing = {
    name = "streaks/last_man_standing"
    bgImage = "ui/gameuiskin#streaks_event_bg.avif"
    stackImages = [
      mkStackImage("last_alive.avif", [60, 60])
    ]
  }

  heroic_mission_maker = {
    name = "streaks/heroic_mission_maker"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("first_and_last_kill.avif", [62, 62])
    ]
  }

  heroic_tankman = {
    name = "streaks/heroic_tankman"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("tank_top_killer_hero.avif", [62, 62])
    ]
  }

  heroic_ship = {
    name = "streaks/heroic_ship"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("top_killer_hero.avif", [62, 62])
    ]
  }

  heroic_survivor = {
    name = "streaks/heroic_survivor"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("top_survivor_hero.avif", [62, 62])
    ]
  }

  heroic_punisher = {
    name = "streaks/heroic_punisher"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("top_uprank_killer_hero.avif", [62, 62])
    ]
  }

  heroic_wingman = {
    name = "streaks/heroic_wingman"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("top_assists_hero.avif", [62, 62])
    ]
  }

  defender_fighter = {
    name = "streaks/defender_fighter"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("fighter_air_saver.avif", [62, 62])
    ]
  }

  defender_bomber = {
    name = "streaks/defender_bomber"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("bomber_air_saver.avif", [62, 62])
    ]
  }

  defender_ground = {
    name = "streaks/defender_ground"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("ground_saver.avif", [62, 62])
    ]
  }

  defender_water = {
    name = "streaks/defender_water"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("water_saver.avif", [62, 62])
    ]
  }

  defender_ship = {
    name = "streaks/defender_ship"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("water_saver.avif", [62, 62])
    ]
  }

  defender_tank = {
    name = "streaks/defender_tank"
    bgImage = "ui/gameuiskin#streaks_defender_bg.avif"
    stackImages = [
      mkStackImage("saver.avif", [62, 62])
    ]
  }

  trophy_near_tankman = {
    name = "streaks/trophy_near_tankman"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("tank_top_killer_hero.avif", [62, 62])
    ]
  }

  trophy_near_ship = {
    name = "streaks/trophy_near_ship"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("top_killer_hero.avif", [62, 62])
    ]
  }

  ship_healer = {
    name = "streaks/ship_healer"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("thirst_for_life.avif", [62, 62])
    ]
  }

  ship_sniper_shot = {
    name = "streaks/ship_sniper_shot"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("naval_sniper.avif", [62, 62])
    ]
  }

  ship_artillery_master = {
    name = "streaks/ship_artillery_master"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("large_caliber.avif", [62, 62])
    ]
  }

  ship_torpedo_master = {
    name = "streaks/ship_torpedo_master"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("torpedo_master.avif", [62, 62])
    ]
  }

  ship_bomberman = {
    name = "streaks/ship_bomberman"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("demolition.avif", [62, 62])
    ]
  }

  ship_anti_main_caliber = {
    name = "streaks/ship_anti_main_caliber"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("disarm.avif", [62, 62])
    ]
  }

  ship_anti_steering = {
    name = "streaks/ship_anti_steering"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("lost_control.avif", [62, 62])
    ]
  }

  ship_air_recon = {
    name = "streaks/ship_air_recon"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("air_reconnaissance.avif", [62, 62])
    ]
  }

  trophy_near_survivor = {
    name = "streaks/trophy_near_survivor"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("top_survivor_hero.avif", [62, 62])
    ]
  }
  trophy_near_punisher = {
    name = "streaks/trophy_near_punisher"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("top_uprank_killer_hero.avif", [62, 62])
    ]
  }

  trophy_near_wingman = {
    name = "streaks/trophy_near_wingman"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("top_assists_hero.avif", [62, 62])
    ]
  }

  global_avenge_self = {
    name = "streaks/global_avenge_self"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("revenge.avif", [63, 63])
    ]
  }

  global_base_capturer = {
    name = "streaks/global_base_capturer"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("capture_streak.avif", [62, 62])
    ]
  }

  global_avenge_friendly = {
    name = "streaks/global_avenge_friendly"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("avenge.avif", [62, 62])
    ]
  }

  global_shadow_assassin = {
    name = "streaks/global_shadow_assassin"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("hitless_kill_streak.avif", [62, 62])
    ]
  }

  global_kills_without_death = {
    name = "streaks/global_kills_without_death"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("single_life_killstreak.avif", [62, 62])
    ]
  }

  global_base_defender = {
    name = "streaks/global_base_defender"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("capture_defend_streak.avif", [62, 62])
    ]
  }

  marks_killed_plane_10_ranks_higher = {
    name = "streaks/marks_killed_plane_10_ranks_higher"
    bgImage = "ui/gameuiskin#streaks_marks_bg.avif"
    stackImages = [
      mkStackImage("uprank_kill.avif", [62, 62])
    ]
  }

  row_air_assist = {
    name = "streaks/row_air_assist"
    bgImage = "ui/gameuiskin#streaks_row_bg.avif"
    stackImages = [
      mkStackImage("assist_streak.avif", [92, 92], [-1, 0])
    ]
  }

  killStreak_fighter_survived = {
    name = "streaks/killStreak_fighter_survived"
    bgImage = "ui/gameuiskin#streaks_survivance_bg.avif"
    stackImages = [
      mkStackImage("fighter_survived.avif", [62, 62])
    ]
  }

  killStreak_attacker_survived = {
    name = "streaks/killStreak_attacker_survived"
    bgImage = "ui/gameuiskin#streaks_survivance_bg.avif"
    stackImages = [
      mkStackImage("attacker_survived.avif", [62, 62])
    ]
  }

  killStreak_bomber_survived = {
    name = "streaks/killStreak_bomber_survived"
    bgImage = "ui/gameuiskin#streaks_survivance_bg.avif"
    stackImages = [
      mkStackImage("bomber_survived.avif", [62, 62])
    ]
  }

  tank_kill_without_fail = {
    name = "streaks/tank_kill_without_fail"
    bgImage = "ui/gameuiskin#streaks_tank_bg.avif"
    stackImages = [
      mkStackImage("accurate_kill_streak.avif", [62, 62])
    ]
  }

  tank_sniper_shot = {
    name = "streaks/tank_sniper_shot"
    bgImage = "ui/gameuiskin#streaks_tank_bg.avif"
    stackImages = [
      mkStackImage("single_life_killstreak.avif", [62, 62])
    ]
  }

  tank_die_hard = {
    name = "streaks/tank_die_hard"
    bgImage = "ui/gameuiskin#streaks_tank_bg.avif"
    stackImages = [
      mkStackImage("take_hit.avif", [62, 62])
    ]
  }

  tank_best_antiAircraft = {
    name = "streaks/tank_best_antiAircraft"
    bgImage = "ui/gameuiskin#streaks_tank_bg.avif"
    stackImages = [
      mkStackImage("tank_best_antiaircraft.avif", [62, 62])
    ]
  }

  squad_best = {
    name = "streaks/squad_best"
    bgImage = "ui/gameuiskin#streaks_event_bg.avif"
    stackImages = [
      mkStackImage("squad_best.avif", [62, 62])
    ]
  }

  squad_assist = {
    name = "streaks/squad_assist"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("top_assists_hero.avif", [62, 62])
    ]
  }

  squad_kill = {
    name = "streaks/squad_kill"
    bgImage = "ui/gameuiskin#streaks_global_bg.avif"
    stackImages = [
      mkStackImage("squad_kill.avif", [62, 62])
    ]
  }

  multi_kill_air = {
    name = "streaks/multi_kill_air"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_air.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  double_kill_air = {
    name = "streaks/double_kill_air"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_air.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  triple_kill_air = {
    name = "streaks/triple_kill_air"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_air.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  multi_kill_ship = {
    name = "streaks/multi_kill_ship"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ship.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  double_kill_ship = {
    name = "streaks/double_kill_ship"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ship.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  triple_kill_ship = {
    name = "streaks/triple_kill_ship"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ship.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  multi_kill_ground = {
    name = "streaks/multi_kill_ground"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ground.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  double_kill_ground = {
    name = "streaks/double_kill_ground"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ground.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  triple_kill_ground = {
    name = "streaks/triple_kill_ground"
    bgImage = "ui/gameuiskin#streaks_multi_kill_bg.avif"
    stackImages = [
      mkStackImage("multi_kill_ground.avif", [62, 62])
      mkStackImage("multi_kill_x.avif", [12, 18], [-5, 20])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  streak_firework_new_year = {
    name = "streaks/streak_firework_new_year"
    bgImage = "ui/gameuiskin#streak_christmas.avif"
  }

  heroic_fighter = {
    name = "streaks/heroic_fighter"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("tank_best_antiaircraft.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  trophy_near_fighter = {
    name = "streaks/trophy_near_fighter"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("tank_best_antiaircraft.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  heroic_bomber = {
    name = "streaks/heroic_bomber"
    bgImage = "ui/gameuiskin#streaks_heroic_bg.avif"
    stackImages = [
      mkStackImage("streaks_tank_two_kills_at_one_blow.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  trophy_near_bomber = {
    name = "streaks/trophy_near_bomber"
    bgImage = "ui/gameuiskin#streaks_event_bg2.avif"
    stackImages = [
      mkStackImage("streaks_tank_two_kills_at_one_blow.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  marks_5_bombers = {
    name = "streaks/marks_5_bombers"
    bgImage = "ui/gameuiskin#streaks_marks_bg.avif"
    stackImages = [
      mkStackImage("bomber_or_attacker_killer.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  marks_5_fighters = {
    name = "streaks/marks_5_fighters"
    bgImage = "ui/gameuiskin#streaks_marks_bg.avif"
    stackImages = [
      mkStackImage("fighter_killer.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

  marks_landing_after_critical_hit = {
    name = "streaks/marks_landing_after_critical_hit"
    bgImage = "ui/gameuiskin#streaks_marks_bg.avif"
    stackImages = [
      mkStackImage("streaks_marks_landing_after_critical_hit.avif", [62, 62])
    ]
    numberCtor = mkNumberCtor([12, 18], [5, 20])
  }

}
function streakPresentation(unlockId) {
  return streaksPresentation?[unlockId] ?? streaksPresentation.unknown
}

return {
  streakPresentation
}
