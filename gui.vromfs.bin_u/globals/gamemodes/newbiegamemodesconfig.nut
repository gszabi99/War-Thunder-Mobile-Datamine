let newbieGameModesConfig = {
  tanks = [
    {
      gmName = "tank_new_players_battle_single"
      isFit = @(s) s.battles < 1 || (s.battles < 2 && (s.kills < 5 || !s.hasPkg))
      isSingle = true
    }
    {
      gmName = "tank_new_players_battle_coop"
      isFit = @(s) s.battles < 3 || (s.battles < 6 && s.kills < 10)
    }
  ]
  ships = [
    {
      gmName = "ship_new_players_battle_single"
      isFit = @(s) s.battles < 1 || (s.battles < 2 && (s.kills < 3 || !s.hasPkg))
      isSingle = true
    }
    {
      gmName = "ship_new_players_battle_coop"
      isFit = @(s) s.battles < 4 || (s.battles < 7 && s.kills < 9)
    }
  ]
}

let newbieModes = {}
foreach(c in newbieGameModesConfig)
  foreach(m in c)
    newbieModes[m.gmName] <- m

return {
  newbieGameModesConfig
  prepareStatsForNewbieConfig = @(stats) { kills = 0, battles = 0, hasPkg = false }.__update(stats)
  isNewbieMode = @(gmName) gmName in newbieModes
  isNewbieModeSingle = @(gmName) newbieModes?[gmName].isSingle ?? false
}

