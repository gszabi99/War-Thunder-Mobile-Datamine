from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_CURRENCY, G_PRIZE_TICKET
from "%rGui/event/treeEvent/treeEventState.nut" import openedTreeEventId, curEventMapCurrencies, curEventUnlocks
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_LARGE
from "%rGui/rewards/rewardViewInfo.nut" import mkViewInfo, getUnlockRewardsViewInfo
from "%rGui/seasonScene/seasonHelpWndComps.nut" import mkHelpContent, mkPrizeTicketVariants
from "%rGui/seasonScene/seasonSceneState.nut" import bgScene


const routeImgSize = [hdpxi(440), hdpxi(250)]
const biggestTokensImgAmount = 1000000

function tokensBlock() {
  let currencyId = curEventMapCurrencies.get()?[0]
  return {
    watch = curEventMapCurrencies
    children = currencyId == null ? null
      : mkRewardPlateImage(mkViewInfo(currencyId, G_CURRENCY, biggestTokensImgAmount), REWARD_STYLE_LARGE)
  }
}

function routeBlock() {
  let image = getEventPresentation(openedTreeEventId.get()).mapHelpRouteImage
  return {
    watch = openedTreeEventId
    size = routeImgSize
    children = image == null ? null
      : {
          size = FLEX
          rendObj = ROBJ_IMAGE
          image = Picture($"{image}:0:P")
          keepAspect = true
        }
  }
}

function getPrizeTicketId(unlocks, sConfigs) {
  foreach (name in unlocks.keys().sort())
    foreach (stage in unlocks[name]?.stages ?? []) {
      let reward = getUnlockRewardsViewInfo(stage, sConfigs).findvalue(@(v) v.rType == G_PRIZE_TICKET)
      if (reward != null)
        return reward.id
    }
  return null
}

let rewardsBlock = @() {
  watch = [curEventUnlocks, serverConfigs]
  children = mkPrizeTicketVariants(getPrizeTicketId(curEventUnlocks.get(), serverConfigs.get()))
}

return {
  isAvailable = Computed(@() openedTreeEventId.get() != null)
  bg = bgScene
  function content() {
    let { mapHelpTokensLocId } = getEventPresentation(openedTreeEventId.get())
    return {
      ...mkHelpContent([
          { title = loc(mapHelpTokensLocId), content = tokensBlock }
          { title = loc("treeEvent/help/followRoute"), content = routeBlock }
          { title = loc("treeEvent/help/getRewards"), content = rewardsBlock }
        ],
        loc("treeEvent/help/whereToGet"))
      watch = openedTreeEventId
    }
  }
}
