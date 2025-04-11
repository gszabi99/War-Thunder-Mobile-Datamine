let shipsSort = @(a, b)
       b.damage <=> a.damage
    || b.navalKills <=> a.navalKills
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id

let sortByCampaign = {
  ships = shipsSort
  ships_new = shipsSort

  tanks = @(a, b)
       b.score <=> a.score
    || b.groundKills <=> a.groundKills
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id

  air = @(a, b)
       b.score <=> a.score
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id
}

let scoreKey = {
  ships = "damage"
  ships_new = "damage"
  tanks = "score"
  air   = "score"
}

let scoreKeyRaw = {
  ships = "damage"
  ships_new = "damage"
  tanks = "dmgScoreBonus"
  air   = "dmgScoreBonus"
}

let getScoreKey = @(campaign) scoreKey?[campaign] ?? scoreKey.tanks
let getScoreKeyRaw = @(campaign) scoreKeyRaw?[campaign] ?? scoreKeyRaw.tanks
let playersSortFunc = @(campaign) sortByCampaign?[campaign] ?? sortByCampaign.tanks

function sortAndFillPlayerPlaces(campaign, players) {
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