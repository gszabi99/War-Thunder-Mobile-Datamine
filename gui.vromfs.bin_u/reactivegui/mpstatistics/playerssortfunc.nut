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

return @(campaign) sortByCampaign?[campaign] ?? sortByCampaign.tanks