from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/collectionPresentation.nut" import getCollectionPresentation, getPuzzleImage
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_PRIZE_TICKET
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/collections/collectionComps.nut" import mkPieceDupes, mkPuzzlePiece, mkPuzzleImagePiece, getPuzzleGrid
from "%rGui/collections/collectionsState.nut" import isCollectionsHelpWndOpened, closeCollectionsHelpWnd,
  curCollectionCfg, curCollectionId
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/modalWnd.nut" import modalWndHeader
from "%darg/helpers/bitmap.nut" import mkBitmapPicture
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage, mkRewardPlate
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_LARGE, REWARD_STYLE_MEDIUM, rewardTicketDefaultSlots
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, gradTexSize, mkColoredGradientY
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const sceneId = "collectionsHelpWnd"
const iconSize = hdpx(90)
const puzzleImgSize = [hdpxi(440), hdpxi(250)]
const arrowImgSize = [hdpxi(50), hdpxi(150)]
const rewardOffset = hdpx(40)

let bgScene = Computed(@() getCollectionPresentation(curCollectionId.get()))

let lineGradientHor = mkBitmapPicture(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80777777, 0.25))
let iconGradient = mkColoredGradientY(0x00FFFFFF, 0xFF999999)

let separator = {
  size = const [FLEX, hdpx(4)]
  rendObj = ROBJ_IMAGE
  image = lineGradientHor
}

let nextArrowImg = {
  size = arrowImgSize
  pos = const [arrowImgSize[0], 0]
  vplace = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_VECTOR_CANVAS
  color = 0xFFFFFFFF
  fillColor = 0xFFFFFFFF
  commands = [[VECTOR_POLY,
      0, 0,
      0, 100,
      100, 50
    ]]
}

let header = headerGradientBg([
  backButton(closeCollectionsHelpWnd)
  {
    rendObj = ROBJ_TEXT
    text = loc("HowToPlay")
    ...fontBig
  }
])

let mkHintWnd = @(title, content, hasNextArrow = false) {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0xBF17181B
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        modalWndHeader(title)
        {
          size = FLEX
          children = content
        }
      ]
    }
    !hasNextArrow ? null : nextArrowImg
  ]
}

let mkHowToGetVariant = @(icon, text) {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  pos = const [0, -hdpx(30)]
  children = [
    {
      size = iconSize
      rendObj = ROBJ_MASK
      image = Picture($"{icon}:{iconSize}:{iconSize}:P")
      children = {
        size = iconSize
        rendObj = ROBJ_IMAGE
        image = iconGradient
      }
    }
    {
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(text)
      ...fontVeryTinyAccentedShaded
    }
  ]
}

let howToGet = {
  size = FLEX
  valign = ALIGN_CENTER
  padding = const [hdpx(50), hdpx(10)]
  children = [
    separator
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      children = [
        mkHowToGetVariant("ui/gameuiskin#battles_icon.svg", loc("collection/dailyWins"))
        mkHowToGetVariant("ui/gameuiskin#quests.svg", loc("collection/seasonQuests"))
        mkHowToGetVariant("ui/gameuiskin#icon_shop.svg", loc("collection/eventShop"))
      ]
    }
  ]
}

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

function mkRewardsBlock() {
  let rewards = Computed(function() {
    let { puzzles = []} = curCollectionCfg.get()
    local r = null
    foreach (p in puzzles) {
      r = (p?.rewards ?? []).findvalue(@(v) v.gType == G_PRIZE_TICKET)
      if (r)
        break
    }
    let { prizeTicketsCfg = {} } = serverConfigs.get()
    if (!r?.id || r.id not in prizeTicketsCfg)
      return []
    let rewards = []
    foreach(variant in (prizeTicketsCfg?[r.id].variants ?? [])) {
      let reward = variant.top()
      rewards.append({ slots = rewardTicketDefaultSlots, rType = reward.gType }.__merge(reward))
    }

    return rewards
  })

  return {
    watch = rewards
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    pos = const [rewardOffset, -rewardOffset]
    children = rewards.get().map(@(r, idx) mkRewardPlate(r, REWARD_STYLE_MEDIUM, { pos = [(-rewardOffset * idx), (rewardOffset * idx)]}))
  }
}

let mkContent = @() {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = hdpx(80)
      children = [
        mkHintWnd(loc("collection/getFragments"), fragmentBlock, true)
        mkHintWnd(loc("collection/completeCollections"), collectionBlock, true)
        mkHintWnd(loc("collection/claimRewards"), mkRewardsBlock)
      ]
    }
    {
      size = FLEX
      children = mkHintWnd(loc("collection/whereToGetFragments"), howToGet)
    }
  ]
}

function sceneWnd() {
  return {
    key = sceneId
    size = FLEX
    padding = saBordersRv
    flow = FLOW_VERTICAL
    onDetach = closeCollectionsHelpWnd
    children = [
      header
      mkContent
    ]
    animations = wndSwitchAnim
  }
}

registerScene(sceneId, sceneWnd, closeCollectionsHelpWnd, isCollectionsHelpWndOpened)
setSceneBg(sceneId, bgScene.get()?.bg, bgScene.get()?.bgColor, bgScene.get()?.dimColor)
bgScene.subscribe(@(v) setSceneBg(sceneId, v?.bg, v?.bgColor, v?.dimColor))
