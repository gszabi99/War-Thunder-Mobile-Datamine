let newbieGameModesConfig = {
  tanks = [
    {
      gmName = "tank_new_players_battle_single"
      isFit = @(s) s.anyBattles < 1 || (s.anyBattles < 2 && (s.anyKills < 5 || !s.hasPkg))
      isSingle = true
      offlineMissions = [
        "abandoned_factory_single_Conq1"
        "abandoned_factory_single_Conq2"
        "abandoned_factory_single_Conq3"
      ]
    }
    {
      gmName = "tank_new_players_battle_coop"
      isFit = @(s) s.anyBattles < 3 || (s.anyBattles < 6 && s.kills < 7)
    }
  ]
  ships = [
    {
      gmName = "ship_new_players_battle_single"
      isFit = @(s) s.anyBattles < 1 || (s.anyBattles < 2 && (s.anyKills < 3 || !s.hasPkg))
      isSingle = true
      offlineMissions = [
        "pacific_island_small_single_NTdm"
      ]
    }
    {
      gmName = "ship_new_players_battle_coop"
      isFit = @(s) s.anyBattles < 4 || (s.anyBattles < 7 && s.kills < 6)
    }
  ]
}

let newbieModes = {}
foreach(c in newbieGameModesConfig)
  foreach(m in c)
    newbieModes[m.gmName] <- m

let function prepareStatsForNewbieConfig(stats) {
  let res = { kills = 0, offlineKills = 0, battles = 0, offlineBattles = 0, hasPkg = false }.__update(stats)
  res.anyBattles <- res.battles + res.offlineBattles
  res.anyKills <- res.kills + res.offlineKills
  return res
}

return {
  newbieGameModesConfig
  prepareStatsForNewbieConfig
  isNewbieMode = @(gmName) gmName in newbieModes
  isNewbieModeSingle = @(gmName) newbieModes?[gmName].isSingle ?? false
}

