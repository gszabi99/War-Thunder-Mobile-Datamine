from "%globalsDarg/darg_library.nut" import *
let { G_LOOTBOX, G_CURRENCY } = require("%appGlobals/rewardType.nut")
let { getLootboxName, mkLoootboxImage } = require("%appGlobals/config/lootboxPresentation.nut")
let { mkCurrencyComp, CS_SMALL } = require("%rGui/components/currencyComp.nut")

let mkCurrencyImage = @(amount, size, currencyId) {
  size = [size, 2 * size]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkCurrencyComp(amount, currencyId, CS_SMALL)
}

function mkRewardImage(reward, size) {
  if (type(reward) == "table") { //compatibility with 2024.04.14
    let { lootboxes = {}, currencies = {} } = reward
    if (lootboxes.len() > 0)
      return mkLoootboxImage(lootboxes.findindex(@(_) true), size)

    let cId = currencies?.findindex(@(_) true)
    let cVal = currencies?[cId] ?? 0
    if (cVal > 0)
      return mkCurrencyImage(cVal, size, cId)
    return null
  }

  //todo: use icons from the othe rewards
  foreach(g in reward)
    if (g.gType == G_LOOTBOX)
      return mkLoootboxImage(g.id, size)
    else if (g.gType == G_CURRENCY)
      return mkCurrencyImage(g.count, size, g.id)

  return null
}

function getRewardName(reward) {
  if (type(reward) == "table") { //compatibility with 2024.04.14
    let { lootboxes = {} } = reward
    if (lootboxes.len() > 0)
      return getLootboxName(lootboxes.findindex(@(_) true))
    return ""
  }
  foreach(g in reward)
    if (g.gType == G_LOOTBOX)
      return getLootboxName(g.id)
  return ""
}

return {
  mkRewardImage
  getRewardName
}
