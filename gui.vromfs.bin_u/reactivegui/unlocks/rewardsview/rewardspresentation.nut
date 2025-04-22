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
  
  foreach(g in reward)
    if (g.gType == G_LOOTBOX)
      return mkLoootboxImage(g.id, size)
    else if (g.gType == G_CURRENCY)
      return mkCurrencyImage(g.count, size, g.id)

  return null
}

function getRewardName(reward) {
  foreach(g in reward)
    if (g.gType == G_LOOTBOX)
      return getLootboxName(g.id)
  return ""
}

return {
  mkRewardImage
  getRewardName
}
