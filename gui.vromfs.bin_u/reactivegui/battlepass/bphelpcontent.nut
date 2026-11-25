from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/config/passPresentation.nut" import getBpHelpWndPresentation
from "%rGui/battlePass/battlePassState.nut" import curBpId, curBpPages
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage, mkRewardPlate
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_LARGE, REWARD_STYLE_VERY_TINY
from "%rGui/seasonScene/seasonHelpWndComps.nut" import mkHelpContent, findPrizeTicketId, mkPrizeTicketVariants


const boardRatio = 1.125
let boardHeight = hdpxi(300)
let boardWidth = (boardHeight / boardRatio).tointeger()
let pagePadding = [boardHeight * 0.065, boardWidth * 0.15]

let bpCurrency = @() {
  watch = curBpId
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkRewardPlateImage(getRewardsViewInfo([getBpHelpWndPresentation(curBpId.get()).currency])[0], REWARD_STYLE_LARGE)
}

function bpPages() {
  let { rewards, boardImg } = getBpHelpWndPresentation(curBpId.get())
  return {
    watch = curBpId
    size = [boardWidth, boardHeight]
    rendObj = ROBJ_IMAGE
    image = Picture($"{boardImg}:{boardWidth}:{boardHeight}:P")
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = pagePadding
    children = {
      flow = FLOW_VERTICAL
      transform = const { scale = 0.5 }
      children = arrayByRows(getRewardsViewInfo(rewards), 4).map(@(row) {
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = row.map(@(ch) mkRewardPlate(ch, { ...REWARD_STYLE_VERY_TINY, needShowPreview = false }))
      })
    }
  }
}

let bpRewards = @() {
  watch = curBpPages
  children = mkPrizeTicketVariants(findPrizeTicketId(
    curBpPages.get().reduce(@(res, page) res.extend(page.slots.map(@(s) s.rewards)), [])))
}

return {
  isAvailable = Computed(@() curBpId.get() != null)
  bg = Computed(@() getBpHelpWndPresentation(curBpId.get()))
  content = @() mkHelpContent([
      { title = loc("battlePass/getWarCredits"), content = bpCurrency }
      { title = loc("battlePass/openCatalogPages"), content = bpPages }
      { title = loc("collection/claimRewards"), content = bpRewards }
    ],
    loc("battlePass/whereToGetWarCredits"))
}
