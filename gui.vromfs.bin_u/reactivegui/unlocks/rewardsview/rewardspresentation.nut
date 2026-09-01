from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/lootboxPresentation.nut" import getLootboxName
from "%appGlobals/rewardType.nut" import G_LOOTBOX, G_CURRENCY
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_SMALL
from "%rGui/rewards/components/lootboxView.nut" import mkLootboxImage


let mkCurrencyImage = @(amount, size, currencyId) {
  size = [size, 2 * size]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkCurrencyComp(amount, currencyId, CS_SMALL)
}

function mkRewardImage(reward, size) {
  
  foreach(g in reward)
    if (g.gType == G_LOOTBOX)
      return mkLootboxImage(g.id, size)
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
