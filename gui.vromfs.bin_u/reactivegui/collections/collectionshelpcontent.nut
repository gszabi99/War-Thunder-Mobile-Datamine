from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation, getPuzzleImage
from "%rGui/collections/collectionComps.nut" import mkPieceDupes, mkPuzzlePiece, mkPuzzleImagePiece, getPuzzleGrid
from "%rGui/collections/collectionsState.nut" import curCollectionCfg, curCollectionId
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_LARGE
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/seasonScene/seasonHelpWndComps.nut" import mkHelpContent, findPrizeTicketId, mkPrizeTicketVariants


const puzzleImgSize = [hdpxi(440), hdpxi(250)]

function fragmentBlock() {
  let {dblRewards = []} = curCollectionCfg.get()
  let vInfo = getRewardsViewInfo(dblRewards).sort(sortRewardsViewInfo)?[0]
  return {
    watch = [curCollectionId, curCollectionCfg]
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      !curCollectionId.get() ? null
        : {
          ...mkPieceDupes(curCollectionId.get(), curCollectionCfg.get())
          pos = const [hdpx(80), -hdpx(30)], transform = const { scale = 0.8, rotate = 20}
        }
      !vInfo ? null
        : {
          pos = const [-hdpx(70), 0]
          children = mkRewardPlateImage(vInfo, REWARD_STYLE_LARGE)
        }
    ]
  }
}


let mkPuzzleLock = @(size, styleId) {
  size
  children = mkPuzzlePiece(size, styleId)
}

function collectionBlock() {
  let cId = curCollectionId.get()
  let { puzzleTexSize, helpWndConfig } = getCollectionPresentation(cId)
  let { pId, pieces } = helpWndConfig
  if (pieces.len() == 0)
    return { watch = curCollectionId }
  let grid = getPuzzleGrid(pieces.len())

  let partSize = puzzleImgSize.map(@(v, a) v / grid[a])
  let size = partSize.map(@(v, a) v * grid[a])
  let image = getPuzzleImage(cId, pId)

  return {
    watch = curCollectionId
    size
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = array(grid[1]).map(@(_, y) {
      size = [FLEX, partSize[1]]
      flow = FLOW_HORIZONTAL
      children = array(grid[0]).map(function(_, x) {
        let idx = y * grid[0] + x
        let hasPiece = pieces[idx] == ""
        return @() !hasPiece ? mkPuzzleLock(partSize, pieces[idx])
          : mkPuzzleImagePiece(image, idx, grid, puzzleTexSize)
      })
    })
  }
}

let rewardsBlock = @() {
  watch = curCollectionCfg
  children = mkPrizeTicketVariants(findPrizeTicketId((curCollectionCfg.get()?.puzzles ?? []).map(@(p) p?.rewards ?? [])))
}

return {
  isAvailable = Computed(@() curCollectionId.get() != null)
  bg = Computed(@() getCollectionPresentation(curCollectionId.get()))
  content = @() mkHelpContent([
      { title = loc("collection/getFragments"), content = fragmentBlock }
      { title = loc("collection/completeCollections"), content = collectionBlock }
      { title = loc("collection/claimRewards"), content = rewardsBlock }
    ],
    loc("collection/whereToGetFragments"))
}
