let shipsSort = @(a, b)
       b.damage <=> a.damage
    || b.navalKills <=> a.navalKills
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id

let tanksSort = @(a, b)
       b.score <=> a.score
    || b.groundKills <=> a.groundKills
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id

let sortByCampaign = {
  ships = shipsSort
  ships_new = shipsSort
  tanks = tanksSort
  tanks_new = tanksSort

  air = @(a, b)
       b.score <=> a.score
    || b.kills <=> a.kills
    || (a.isDead && !a.isTemporary) <=> (b.isDead && !b.isTemporary)
    || a.id <=> b.id
}

let battleRoyaleSort = {
  tanks = @(a, b) (b?.missionAliveTime ?? 0) <=> (a?.missionAliveTime ?? 0) || sortByCampaign.tanks(a, b)
}

let raceSort = {
  air = @(a, b)
       (((a?.placeFFA ?? 0) != 0 ? -1 : 1) <=> ((b?.placeFFA ?? 0) != 0 ? -1 : 1))
    || (a?.placeFFA ?? 0) <=> (b?.placeFFA ?? 0)
    || b.score <=> a.score
    || (b?.raceProgress ?? 0) <=> (a?.raceProgress ?? 0)
    || sortByCampaign.air(a, b)
}

let scoreKey = {
  ships = "damage"
  ships_new = "damage"
  tanks = "score"
  tanks_new = "score"
  air   = "score"
}

let scoreKeyRaw = {
  ships = "damage"
  ships_new = "damage"
  tanks = "dmgScoreBonus"
  tanks_new = "dmgScoreBonus"
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

function sortAndFillPlayerPlacesBattleRoyale(campaign, players) {
  players.sort(battleRoyaleSort?[campaign] ?? battleRoyaleSort.tanks)
  foreach(idx, p in players)
    p.place <- idx + 1
  return players
}

function sortAndFillPlayerPlacesRace(campaign, players) {
  players.sort(raceSort?[campaign] ?? raceSort.air)
  foreach(idx, p in players)
    p.place <- idx + 1
  return players
}

let sortAndFillPlayerPlacesByGameType = {
  [GT_RACE] = sortAndFillPlayerPlacesRace,
  [GT_LAST_MAN_STANDING] = sortAndFillPlayerPlacesBattleRoyale
}
let gtCfgMask = sortAndFillPlayerPlacesByGameType.reduce(@(res, _, gt) res | gt, 0)

return {
  getScoreKey
  getScoreKeyRaw
  playersSortFunc
  getSortAndFillPlayerPlacesFunc = @(gt) sortAndFillPlayerPlacesByGameType?[gt & gtCfgMask] ?? sortAndFillPlayerPlaces
}