let newbieGameModesConfig = {
  tanks = [
    {
      gmName = "tank_new_players_battle_single"
      isFit = @(s) !s.hasPkg || s.battles < 1 || (s.battles < 2 && s.kills < 5)
    }
    {
      gmName = "tank_new_players_battle_coop"
      isFit = @(s) s.battles < 3 || (s.battles < 6 && s.kills < 10)
    }
  ]
  ships = [
    {
      gmName = "ship_new_players_battle_single"
      isFit = @(s) !s.hasPkg || s.battles < 1 || (s.battles < 2 && s.kills < 3)
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
    newbieModes[m.gmName] <- true

return {
  newbieGameModesConfig
  prepareStatsForNewbieConfig = @(stats) { kills = 0, battles = 0, hasPkg = false }.__update(stats)
  isNewbieMode = @(gmName) newbieModes?[gmName] ?? false
}

