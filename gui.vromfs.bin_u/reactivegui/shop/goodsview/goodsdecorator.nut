from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/goodsPresentation.nut" import getGoodsIcon
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/rewardType.nut" import G_DECORATOR
from "%rGui/decorators/decoratorState.nut" import allDecorators, myDecorators
from "%rGui/shop/goodsStates.nut" import ALL_PURCHASED
from "%rGui/shop/goodsView/sharedParts.nut" import mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsWrap,
  goodsH, goodsSmallSize, goodsBgH, mkSlotBgImg, mkBgParticles, borderBg, goodsW, limitFontGrad, mkGradeTitle,
  mkEndTime


let bgSize = [goodsSmallSize[0], goodsBgH]
const avatarBorderWidth = hdpx(2)
let avatarFrameSize = (goodsBgH * 0.6 + 0.5).tointeger()
let avatarSize = avatarFrameSize - avatarBorderWidth * 2
let emptyIconSize = [goodsSmallSize[0] - hdpxi(40), (goodsBgH * 0.9 + 0.5).tointeger()]

let mkAvatarImg = @(decoratorId) {
  size = [avatarFrameSize, avatarFrameSize]
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = const [0, hdpx(80)]
  rendObj = ROBJ_BOX
  borderColor = 0xFFA0A0A0
  borderWidth = avatarBorderWidth
  children = {
    size = [avatarSize, avatarSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(decoratorId)}:{avatarSize}:{avatarSize}:P")
    keepAspect = true
  }
}

let mkTitleImg = @(decoratorId) {
  behavior = Behaviors.TextArea
  size = FLEX_H
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  maxWidth = goodsW
  rendObj = ROBJ_TEXTAREA
  text = loc($"title/{decoratorId}")
}.__update(fontMediumShaded)

let mkNickFrameImg = @(decoratorId) {
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = frameNick("", decoratorId)
}.__update(fontVeryLarge)

let mkEmptyDecoratorImg = @(decoratorId) {
  size = emptyIconSize
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{getGoodsIcon(decoratorId)}:{emptyIconSize[0]}:{emptyIconSize[1]}:P")
  keepAspect = true
}

let viewCfg = {
  avatar = {
    mkImage = mkAvatarImg
    getTitle = @(_) loc("decorator/avatar")
  }
  nickFrame = {
    mkImage = mkNickFrameImg
    getTitle = @(decoratorId) frameNick("", decoratorId)
  }
  title = {
    mkImage = mkTitleImg
    getTitle = @(decoratorId) loc($"title/{decoratorId}")
  }
}

let mkDecoratorContent = @(decoratorId) function() {
  let { dType = "" } = allDecorators.get()?[decoratorId]
  let { mkImage = null } = viewCfg?[dType]
  let image = mkImage != null ? mkImage(decoratorId) : mkEmptyDecoratorImg(decoratorId)
  let title = mkImage != null ? loc($"decorator/{dType}") : decoratorId
  return {
    watch = allDecorators
    size = FLEX
    children = [
      image
      mkGradeTitle(title, limitFontGrad)
    ]
  }
}

function mkGoodsDecorator(goods, onClick, state, animParams, addChildren) {
  let decoratorId = goods.rewards.findvalue(@(r) r.gType == G_DECORATOR)?.id
  let ovrState = Computed(@() state.get() | (myDecorators.get()?[decoratorId] != null ? ALL_PURCHASED : 0))
  let onDecoratorClick = (ovrState.get() & ALL_PURCHASED) == 0 ? onClick : null
  return mkGoodsWrap(
    goods,
    onDecoratorClick,
    @(_, _) [
      mkSlotBgImg()
      goods?.isShowDebugOnly ? underConstructionBg : null
      mkBgParticles(bgSize)
      borderBg
      mkDecoratorContent(decoratorId)
      mkEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, ovrState), addChildren),
    mkPricePlate(goods, ovrState, animParams)
    { size = [goodsSmallSize[0], goodsH] })
}

function getLocNameDecorator(goods) {
  let decoratorId = goods.rewards.findvalue(@(r) r.gType == G_DECORATOR)?.id ?? ""
  let cfg = viewCfg?[allDecorators.get()?[decoratorId].dType]
  return cfg?.getTitle(decoratorId) ?? decoratorId
}

return {
  mkGoodsDecorator
  getLocNameDecorator
}
