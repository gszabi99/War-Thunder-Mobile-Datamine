from "%globalsDarg/darg_library.nut" import *
let { mkLoootboxImage, getLootboxName } = require("lootboxPresentation.nut")
let { mkCurrencyComp, CS_SMALL } = require("%rGui/components/currencyComp.nut")

let mkCurrencyImage = @(amount, size, currencyId) {
  size = [size, 2 * size]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkCurrencyComp(amount, currencyId, CS_SMALL)
}

let function mkRewardImage(reward, size) {
  if (reward == null)
    return null
  let { lootboxes = {}, wp = 0, gold = 0 } = reward
  if (lootboxes.len() > 0)
    return mkLoootboxImage(lootboxes.findindex(@(_) true), size)
  if (gold > 0)
    return mkCurrencyImage(gold, size, "gold")
  if (wp > 0)
    return mkCurrencyImage(wp, size, "wp")

  //push here other fields if need
  return null
}

let function getRewardName(reward) {
  let { lootboxes = {} } = reward
  if (lootboxes.len() > 0)
    return getLootboxName(lootboxes.findindex(@(_) true))
  return ""
}

return {
  mkRewardImage
  getRewardName
}
