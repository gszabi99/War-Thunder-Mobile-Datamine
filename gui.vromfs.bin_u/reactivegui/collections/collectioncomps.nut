from "%globalsDarg/darg_library.nut" import *
from "math" import sqrt
from "types" import Array
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation, getPuzzleImage
from "%rGui/collections/rewardProgressConsts.nut" import progressHeight, progressBorder
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_SMALL
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/style/gradients.nut" import mkColoredGradientY


let progressBgColor = 0xFF303030
let progressBorderColor = 0xFFBBBBBB
let progressFgColor = 0xFF5AA0E9
const pieceBorder = hdpx(3)

const infoGap = hdpx(40)
const infoDupeWidth = hdpxi(250)
const infoDupeOffset = pieceBorder * 2
const infoDupesCount = 3

let infoCardStyle = REWARD_STYLE_SMALL

let defPuzzleStyle = {
  bgImage = mkColoredGradientY(0xFF7C7E88, 0xFF3A3B41)
  borderColor = 0xFFAEAEAE
}

let puzzleStyles = {
  uncommon = {
    bgImage = mkColoredGradientY(0xFF2B43A6, 0xFF132365)
    borderColor = 0xFF6F88EB
  }
  rare = {
    bgImage = mkColoredGradientY(0xFF6A1B9E, 0xFF3E1659)
    borderColor = 0xFFB16FEB
  }
  classified = {
    bgImage = mkColoredGradientY(0xFFA3410C, 0xFF632C0E)
    borderColor = 0xFFEBA36F
  }
}

let rewardUnseenMark = priorityUnseenMark.__merge({
  hplace = ALIGN_RIGHT
  pos = const [hdpx(6), hdpx(-6)]
})

let getPuzzleStyle = @(styleId) puzzleStyles?[styleId] ?? defPuzzleStyle

let getPuzzleGrid = memoize(function(total) {
  for (local rows = sqrt(total).tointeger(); rows > 1; rows--)
    if (total / rows * rows == total)
      return [total / rows, rows]
  return [total, 1]
})

let mkProgress = @(cur, total, width, ovr = {}) {
  size = [width, progressHeight]
  padding = progressBorder
  rendObj = ROBJ_BOX
  fillColor = progressBgColor
  borderColor = progressBorderColor
  borderWidth = progressBorder
  children = [
    {
      size = [pw(total == 0 ? 100 : clamp(100.0 * cur / total, 0, 100)), FLEX]
      rendObj = ROBJ_SOLID
      color = progressFgColor
    }
    {
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = $"{cur}/{total}"
    }.__update(fontVeryTinyShaded)
  ]
}.__update(ovr)

function unknownPieceMark(pieceHeght) {
  let size = pieceHeght.tointeger() / 2
  return {
    size
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#unknown_puzzle_piece.svg:{size}:P")
    keepAspect = true
  }
}

function mkPuzzlePiece(size, styleId, ovr = {}) {
  let { bgImage, borderColor } = getPuzzleStyle(styleId)
  let cleanOvr = ovr.filter(@(_, key) key != "watch" && key != "animations" && key != "transform")
  return {
    watch = ovr?.watch
    animations = ovr?.animations
    transform = ovr?.transform
    children = [
      {
        size
        rendObj = ROBJ_SOLID
        pos = const [hdpx(7), hdpx(7)]
        color = 0x70000000
      }
      {
        size
        rendObj = ROBJ_BOX
        image = bgImage
        fillColor = 0xFFFFFFFF
        borderColor
        borderWidth = pieceBorder
        children = unknownPieceMark(size instanceof Array ? size[1] : size)
      }.__update(cleanOvr)
    ]
  }
}

function mkPuzzleImagePiece(image, pieceIdx, grid, texSize, ovr = {}) {
  let x = pieceIdx % grid[0]
  let y = pieceIdx / grid[0]
  let texOffs = [
    texSize[1].tofloat() * y / grid[1],
    texSize[0].tofloat() * (grid[0] - x - 1) / grid[0],
    texSize[1].tofloat() * (grid[1] - y - 1) / grid[1],
    texSize[0].tofloat() * x / grid[0]
  ]
  return {
    key = image 
    size = FLEX
    rendObj = ROBJ_9RECT
    image = Picture(image)
    texOffs
    screenOffs = [0, 0, 0, 0]
  }.__update(ovr)
}

function mkPuzzleBgExtensions(presentation) {
  let { puzzleBg, puzzleBgSize, puzzleBgExtensions = [] } = presentation
  if (puzzleBgExtensions.len() == 0)
    return null

  let texW = puzzleBgSize[0]
  let texH = puzzleBgSize[1]

  return {
    size = FLEX
    children = puzzleBgExtensions.map(@(e) {
      size = [pw(100.0 * e.width / texW), sh(100)]
      pos = [pw(100.0 * e.x / texW), ph(100)]
      rendObj = ROBJ_9RECT
      texOffs = [texH - 1, texW - e.x - e.width, 0, e.x]
      image = Picture($"{puzzleBg}:0:P")
    })
  }
}

function mkViewCollectionPiece(cId, cfg) {
  let res = {
    rendObj = ROBJ_SOLID
    color = defPuzzleStyle.borderColor
    padding = pieceBorder
  }
  let { puzzleScreenSize, puzzleTexSize, dupesInfoPiece } = getCollectionPresentation(cId)
  let { pieces = [] } = cfg?.puzzles[dupesInfoPiece[0]]
  if (pieces.len() == 0)
    return res

  let grid = getPuzzleGrid(pieces.len())
  let partSizeBase = puzzleScreenSize.map(@(v, a) v.tofloat() / grid[a])
  let imgWidth = infoDupeWidth - 2 * pieceBorder
  let imgHeight = (partSizeBase[1] / partSizeBase[0] * imgWidth + 0.5).tointeger()
  let image = getPuzzleImage(cId, dupesInfoPiece[0])
  res.children <- mkPuzzleImagePiece(image, dupesInfoPiece[1], grid, puzzleTexSize,
    { size = [imgWidth, imgHeight] })
  return res
}

function mkConvertionInfoBlock(cId, cfg, curDblProgress, ovr = {}) {
  let { dblRewardProgress = 0, dblRewards = [] } = cfg
  if (dblRewardProgress == 0 || dblRewards.len() == 0)
    return ovr

  let piece = mkViewCollectionPiece(cId, cfg)
  let dupesBlockAddSize = (infoDupesCount - 1) * infoDupeOffset
  let dupesBlockWidth = infoDupeWidth + dupesBlockAddSize
  let rewardMul = curDblProgress / dblRewardProgress
  local vInfo = getRewardsViewInfo(dblRewards).sort(sortRewardsViewInfo)
  if (rewardMul > 1)
    vInfo = vInfo.map(@(g) g.__merge({ count = g.count * rewardMul }))

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = infoGap
    children = [
      {
        flow = FLOW_VERTICAL
        gap = infoCardStyle.boxGap
        children = [
          {
            size = [dupesBlockWidth, SIZE_TO_CONTENT]
            padding = [dupesBlockAddSize, 0, 0, dupesBlockAddSize]
            children = array(infoDupesCount).map(@(_, i) piece.__merge({ pos = [-infoDupeOffset * i, -infoDupeOffset * i] }))
          }
          mkProgress(curDblProgress, dblRewardProgress, dupesBlockWidth)
        ]
      }
      {
        rendObj = ROBJ_IMAGE
        size = const [hdpx(100), hdpx(70)]
        vplace = ALIGN_CENTER
        image = Picture($"ui/gameuiskin#arrow_icon.svg:{hdpx(100)}:{hdpx(70)}:P")
      }
      {
        flow = FLOW_HORIZONTAL
        gap = infoCardStyle.boxGap
        children = vInfo.map(@(vi) mkRewardPlate(vi, infoCardStyle))
      }
    ]
  }.__update(ovr)
}

let mkGetRewardButton = @(isInProgress, onClick) mkSpinnerHideBlock(isInProgress,
  {
    children = [
      textButtonPrimary(utf8ToUpper(loc("shop/vip/get_rewards")), onClick, { hotkeys = ["^J:X"] })
      rewardUnseenMark
    ]
  },
  {
    size = [ FLEX, defButtonHeight ]
  })

return {
  pieceBorder
  infoGap

  getPuzzleStyle
  getPuzzleGrid
  defPuzzleStyle

  mkProgress
  mkPuzzlePiece
  mkPuzzleImagePiece
  mkPuzzleBgExtensions
  mkConvertionInfoBlock
  mkGetRewardButton
}