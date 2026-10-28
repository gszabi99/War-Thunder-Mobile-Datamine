from "%globalsDarg/darg_library.nut" import *
from "%sqstd/underscore.nut" import arrayByRows
from "%appGlobals/config/passPresentation.nut" import getBpHelpWndPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_PRIZE_TICKET
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/battlePass/battlePassState.nut" import curBpId, curBpPages, isBpHelpWndOpened, closeBpHelpWnd
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/components/modalWnd.nut" import modalWndHeader
from "%darg/helpers/bitmap.nut" import mkBitmapPicture
from "%rGui/navState.nut" import registerScene, setSceneBg
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage, mkRewardPlate
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_LARGE, REWARD_STYLE_MEDIUM, rewardTicketDefaultSlots, REWARD_STYLE_VERY_TINY
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, gradTexSize, mkColoredGradientY
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const sceneId = "bpHelpWnd"
const iconSize = hdpx(90)
const boardRatio = 1.125
let boardHeight = hdpxi(300)
let boardWidth = (boardHeight / boardRatio).tointeger()
let pagePadding = [boardHeight * 0.065, boardWidth * 0.15]
const arrowImgSize = [hdpxi(50), hdpxi(150)]
const rewardOffset = hdpx(40)

let bgScene = Computed(@() getBpHelpWndPresentation(curBpId.get()))

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
  backButton(closeBpHelpWnd)
  {
    rendObj = ROBJ_TEXT
    text = loc("HowToPlay")
    ...fontBig
  }
])

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

function getReward(pages) {
  foreach( page in pages) {
    foreach(slot in page.slots) {
      let reward = slot.rewards.findvalue(@(r) r.gType == G_PRIZE_TICKET)
      if (reward != null)
        return reward
    }
  }
  return null
}

function bpRewards() {
  let rewards = Computed(function() {
    let r = getReward(curBpPages.get())

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
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
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

let howToGet = @() {
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
        mkHintWnd(loc("battlePass/getWarCredits"), bpCurrency, true)
        mkHintWnd(loc("battlePass/openCatalogPages"), bpPages, true)
        mkHintWnd(loc("collection/claimRewards"), bpRewards)
      ]
    }
    {
      size = FLEX
      children = mkHintWnd(loc("battlePass/whereToGetWarCredits"), howToGet)
    }
  ]
}

function sceneWnd() {
  return {
    key = sceneId
    size = FLEX
    padding = saBordersRv
    flow = FLOW_VERTICAL
    onDetach = closeBpHelpWnd
    children = [
      header
      mkContent
    ]
    animations = wndSwitchAnim
  }
}

registerScene(sceneId, sceneWnd, closeBpHelpWnd, isBpHelpWndOpened)
setSceneBg(sceneId, bgScene.get()?.bg, bgScene.get()?.bgColor, bgScene.get()?.dimColor)
bgScene.subscribe(@(v) setSceneBg(sceneId, v?.bg, v?.bgColor, v?.dimColor))
