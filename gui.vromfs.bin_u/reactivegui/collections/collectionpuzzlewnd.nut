from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import number_of_set_bits
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation, getPuzzleImage
from "%appGlobals/pServer/pServerApi.nut" import collectionInProgress, receive_puzzle_reward
from "%rGui/collections/collectionComps.nut" import mkProgress, mkPuzzlePiece, mkPuzzleImagePiece, getPuzzleGrid,
  mkPuzzleBgExtensions, mkGetRewardButton
from "%rGui/collections/collectionsState.nut" import curCollectionCfg, curCollectionId, curCollection,
  isPuzzleWndOpened, openedPuzzleId, curUnseenPiecesMasks, markPuzzleSeen
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg, headerHeightInSafeArea, headerMargin,
  headerGradientPaddingY
from "%rGui/components/imagePreviewWnd.nut" import openImagePreview
from "%rGui/components/paginator.nut" import mkPaginatorCurPage
from "%rGui/components/timerBlock.nut" import mkTimerBlock
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate, mkRewardReceivedMark
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_SMALL
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const WND_UID = "puzzleWnd"
const pieceHalfGap = hdpxi(6)
const unseenPieceOpenDelay = 0.5
const unseenPieceOpenTime = 0.7

let cardsStyle = REWARD_STYLE_SMALL
let { boxSize, boxGap } = cardsStyle
let leftBlockWidth = hdpx(500)
let progressWidth = 2 * boxSize + boxGap


let bgScene = Computed(@() getCollectionPresentation(curCollectionId.get()))
let close = @() openedPuzzleId.set(null)

let mkPuzzleLock = @(size, styleId, ovr) {
  size
  padding = pieceHalfGap
  children = mkPuzzlePiece(size.map(@(v) v - 2 * pieceHalfGap), styleId)
}.__update(ovr)

let mkPuzzlePaginator = @() mkPaginatorCurPage(openedPuzzleId,
  Computed(@() (curCollectionCfg.get()?.puzzles.len() ?? 0) - 1), { gap = hdpx(60) })

let mkUnseenPieceAnim = @(onFinish) [
  { prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = unseenPieceOpenDelay, play = true }
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, delay = unseenPieceOpenDelay, duration = unseenPieceOpenTime,
    easing = OutQuad, play = true, onFinish }
]

function puzzleMap() {
  let cId = curCollectionId.get()
  let pId = openedPuzzleId.get()
  let { pieces = [], piecesMask = 0 } = curCollectionCfg.get()?.puzzles[pId]

  if (pieces.len() == 0)
    return { watch = [curCollectionId, openedPuzzleId, curCollectionCfg] }

  let { puzzleScreenSize, puzzleScreenOffset, puzzleTexSize, paginatorOffsetY, bg } = getCollectionPresentation(cId)
  let grid = getPuzzleGrid(pieces.len())
  let partSize = puzzleScreenSize.map(@(v, a) hdpxi(v) / grid[a])
  let size = partSize.map(@(v, a) v * grid[a])
  let image = getPuzzleImage(cId, pId)
  let markSeen = @() markPuzzleSeen(cId, pId)
  let unseenPieceAnim = mkUnseenPieceAnim(markSeen)
  let puzzleImage = {
    size
    flow = FLOW_VERTICAL
    children = array(grid[1]).map(@(_, y) {
      size = [FLEX, partSize[1]]
      flow = FLOW_HORIZONTAL
      children = array(grid[0]).map(function(_, x) {
        let idx = y * grid[0] + x
        let bit = 1 << idx
        let has = Computed(@() ((curCollection.get()?.puzzlePiecesMasks[pId] ?? 0) & bit) != 0)
        let isUnseen = Computed(@() ((curUnseenPiecesMasks.get()?[pId] ?? 0) & bit) != 0)
        let watch = [has, isUnseen]
        return @() !has.get() ? mkPuzzleLock(partSize, pieces[idx], { watch })
          : !isUnseen.get() ? mkPuzzleImagePiece(image, idx, grid, puzzleTexSize, { watch })
          : {
              watch
              size = partSize
              children = [
                mkPuzzleLock(partSize, pieces[idx], {})
                mkPuzzleImagePiece(image, idx, grid, puzzleTexSize, { animations = unseenPieceAnim })
              ]
            }
      })
    })
  }
  function onClick(evt) {
    let mask = curCollection.get()?.puzzlePiecesMasks[pId] ?? 0
    if ((mask & piecesMask) == piecesMask)
      openImagePreview(image, evt.targetRect, bg)
  }
  return {
    watch = [curCollectionId, openedPuzzleId, curCollectionCfg]
    size
    pos = puzzleScreenOffset.map(hdpx)
    flow = FLOW_VERTICAL
    children = [
      {
        key = $"puzzleImage_{cId}_{pId}"
        onDetach = markSeen
        behavior = Behaviors.Button
        onClick
        children = puzzleImage
      }
      { size = hdpx(paginatorOffsetY) }
      mkPuzzlePaginator()
    ]
  }
}


function boardWithPuzzle() {
  let presentation = getCollectionPresentation(curCollectionId.get())
  let { puzzleBg, puzzleBgSize } = presentation

  return {
    watch = curCollectionId
    size = puzzleBgSize.map(hdpx)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"{puzzleBg}:0:P")
    keepAspect = true
    stopMouse = true

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkPuzzleBgExtensions(presentation)
      puzzleMap
    ]
  }
}

let wndHeader = headerGradientBg([
  backButton(close),
  @() {
    watch = [curCollectionId, openedPuzzleId]
    rendObj = ROBJ_TEXT
    text = curCollectionId.get() == null ? ""
      : getCollectionPresentation(curCollectionId.get()).getPuzzleName(openedPuzzleId.get())
  }.__update(fontBigShaded)
])

function rewardBlock() {
  let { pieces = [], rewards = [], piecesMask = 0 } = curCollectionCfg.get()?.puzzles[openedPuzzleId.get()]
  if (pieces.len() == 0)
    return { watch = [curCollectionCfg, openedPuzzleId] }

  let vInfo = getRewardsViewInfo(rewards).sort(sortRewardsViewInfo)
  let { puzzleRewardsMask = 0, puzzlePiecesMasks = [] } = curCollection.get()
  let isReceived = (puzzleRewardsMask & (1 << openedPuzzleId.get())) != 0
  return {
    watch = [curCollectionCfg, curCollection, openedPuzzleId]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = boxGap
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("collection/puzzlePrize")
      }.__update(fontSmallShaded)
      {
        flow = FLOW_HORIZONTAL
        gap = boxGap
        children = vInfo.map(@(vi) !isReceived ? mkRewardPlate(vi, cardsStyle)
          : {
              children = [
                mkRewardPlate(vi, cardsStyle)
                mkRewardReceivedMark(cardsStyle)
              ]
            })
      }
      isReceived ? null
        : mkProgress(
            number_of_set_bits((puzzlePiecesMasks?[openedPuzzleId.get()] ?? 0) & piecesMask),
            pieces.len(),
            progressWidth)
    ]
  }
}

let descriptionBlock = {
  size = [leftBlockWidth, FLEX]
  children = {
    pos = [-saBordersRv[1], 0]
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    flipX = true
    color = 0xA0000000
    padding = [headerGradientPaddingY, hdpx(200), headerGradientPaddingY, saBordersRv[1]]
    children = @() {
      watch = [curCollectionId, openedPuzzleId]
      size = [leftBlockWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = curCollectionId.get() == null ? ""
        : getCollectionPresentation(curCollectionId.get()).getPuzzleDesc(openedPuzzleId.get())
    }.__update(fontTinyShaded)
  }
}

function leftBlock() {
  let cId = curCollectionId.get()
  let pId = openedPuzzleId.get()

  let { piecesMask = 0 } = curCollectionCfg.get()?.puzzles[pId]
  let { puzzleRewardsMask = 0, puzzlePiecesMasks = [] } = curCollection.get()
  let isRewardReceived = pId != null && (puzzleRewardsMask & (1 << pId)) != 0
  let isPuzzleCompleted = piecesMask != 0 && (piecesMask & (puzzlePiecesMasks?[pId] ?? 0)) == piecesMask
  return {
    watch = [curCollectionId, openedPuzzleId, curCollectionCfg, curCollection]
    size = [leftBlockWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = headerMargin
    children = [
      mkTimerBlock(Computed(@() curCollectionCfg.get()?.timeRange.end ?? 0))
      rewardBlock
      isRewardReceived ? descriptionBlock
        : isPuzzleCompleted
          ? mkGetRewardButton(Computed(@() collectionInProgress.get() != null), @() receive_puzzle_reward(cId, pId))
        : null
    ]
  }
}

let puzzleWnd = {
  key = WND_UID
  padding = saBordersRv
  size = FLEX
  children = [
    {
      size = FLEX
      padding = [headerHeightInSafeArea + headerMargin, 0, 0, 0]
      flow = FLOW_HORIZONTAL
      gap = headerMargin
      children = [
        leftBlock
        {
          size = FLEX
          children = boardWithPuzzle
        }
      ]
    }
    wndHeader
  ]
  animations = wndSwitchAnim
}

const sceneId = "puzzleScene"
registerScene(sceneId, puzzleWnd, close, isPuzzleWndOpened)
setSceneBg(sceneId, bgScene.get()?.bg, bgScene.get()?.bgColor)
bgScene.subscribe(@(v) setSceneBg(sceneId, v?.bg, v?.bgColor))
