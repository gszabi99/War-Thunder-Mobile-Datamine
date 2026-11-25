from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/rewardType.nut" import G_PRIZE_TICKET
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/modalWnd.nut" import modalWndHeaderBg, wndHeaderHeight
from "%darg/helpers/bitmap.nut" import mkBitmapPicture
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, rewardTicketDefaultSlots
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, gradTexSize, mkColoredGradientY


const iconSize = hdpx(90)
const arrowImgSize = [hdpxi(50), hdpxi(150)]
const rewardOffset = hdpx(40)

const separatorColor = 0x80777777
const iconColorTop = 0x00FFFFFF
const iconColorBottom = 0xFF999999
const arrowColor = 0xFFFFFFFF
const hintBgColor = 0xBF17181B

let lineGradientHor = mkBitmapPicture(4, gradTexSize, mkGradientCtorDoubleSideX(0, separatorColor, 0.25))
let iconGradient = mkColoredGradientY(iconColorTop, iconColorBottom)

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
  color = arrowColor
  fillColor = arrowColor
  commands = [[VECTOR_POLY,
      0, 0,
      0, 100,
      100, 50
    ]]
}

let mkHintHeader = @(text) {
  ...modalWndHeaderBg
  size = FLEX_H
  minHeight = wndHeaderHeight
  padding = const [hdpx(10), hdpx(20)]
  children = {
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text,
    ...fontSmall
  }
}

let mkHintWnd = @(title, content, hasNextArrow = false) {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = hintBgColor
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        mkHintHeader(title)
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

let mkHelpContent = @(hints, whereToGetTitle) {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = hdpx(80)
      children = hints.map(@(h, idx) mkHintWnd(h.title, h.content, idx < hints.len() - 1))
    }
    {
      size = FLEX
      children = mkHintWnd(whereToGetTitle, howToGet)
    }
  ]
}

function findPrizeTicketId(rewardLists) {
  foreach (rewards in rewardLists) {
    let ticket = rewards.findvalue(@(r) r.gType == G_PRIZE_TICKET)
    if (ticket != null)
      return ticket.id
  }
  return null
}

let mkPrizeTicketVariants = @(ticketId) function() {
  let variants = ticketId == null ? [] : (serverConfigs.get()?.prizeTicketsCfg[ticketId].variants ?? [])
  return {
    watch = serverConfigs
    pos = const [rewardOffset, -rewardOffset]
    children = variants.map(function(variant, idx) {
      let reward = variant.top()
      return mkRewardPlate({ slots = rewardTicketDefaultSlots, rType = reward.gType, ...reward },
        REWARD_STYLE_MEDIUM, { pos = [-rewardOffset * idx, rewardOffset * idx] })
    })
  }
}

return {
  mkHelpContent
  findPrizeTicketId
  mkPrizeTicketVariants
}
