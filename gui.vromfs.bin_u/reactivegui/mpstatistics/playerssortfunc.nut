let sortByCampaign = {
  ships = @(a, b)
       b.damage <=> a.damage
    || b.navalKills <=> a.navalKills
    || b.kills <=> a.kills
    || a.isDead <=> b.isDead
    || a.name <=> b.name

  tanks = @(a, b)
       b.score <=> a.score
    || b.groundKills <=> a.groundKills
    || b.kills <=> a.kills
    || a.isDead <=> b.isDead
    || a.name <=> b.name
}

let scoreKey = {
  ships = "damage"
  tanks = "score"
}

let scoreKeyRaw = {
  ships = "damage"
  tanks = "dmgScoreBonus"
}

let getScoreKey = @(campaign) scoreKey?[campaign] ?? scoreKey.tanks
let getScoreKeyRaw = @(campaign) scoreKeyRaw?[campaign] ?? scoreKeyRaw.tanks
let playersSortFunc = @(campaign) sortByCampaign?[campaign] ?? sortByCampaign.tanks

let function sortAndFillPlayerPlaces(campaign, players) {
  players.sort(playersSortFunc(campaign))

  let key = getScoreKey(campaign)
  local prevPlace = 1
  local prevScore = null
  foreach(idx, p in players) {
    let score = p?[key] ?? 0
    if (score <= 0)
      p.place <- 0
    else if (prevScore == score)
      p.place <- prevPlace
    else {
      prevPlace = idx + 1
      prevScore = score
      p.place <- prevPlace
    }
  }
  return players
}

return {
  getScoreKey
  getScoreKeyRaw
  playersSortFunc
  sortAndFillPlayerPlaces
}