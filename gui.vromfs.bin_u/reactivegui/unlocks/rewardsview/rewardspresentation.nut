from "%globalsDarg/darg_library.nut" import *
let { mkLoootboxImage, getLootboxName } = require("lootboxPresentation.nut")
let { mkCurrencyComp, CS_SMALL } = require("%rGui/components/currencyComp.nut")

let mkCurrencyImage = @(amount, size, currencyId) {
  size = [size, 2 * size]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkCurrencyComp(amount, currencyId, CS_SMALL)
}

function mkRewardImage(reward, size) {
  if (reward == null)
    return null
  let { lootboxes = {}, currencies = {} } = reward
  if (lootboxes.len() > 0)
    return mkLoootboxImage(lootboxes.findindex(@(_) true), size)

  let cId = currencies?.findindex(@(_) true)
  let cVal = currencies?[cId] ?? 0
  if (cVal > 0)
    return mkCurrencyImage(cVal, size, cId)

  //push here other fields if need
  return null
}

function getRewardName(reward) {
  let { lootboxes = {} } = reward
  if (lootboxes.len() > 0)
    return getLootboxName(lootboxes.findindex(@(_) true))
  return ""
}

return {
  mkRewardImage
  getRewardName
}
