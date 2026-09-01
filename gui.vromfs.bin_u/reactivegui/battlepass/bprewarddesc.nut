from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/decalsPresentation.nut" import getDecalDescPresentation
from "%appGlobals/config/lootboxPresentation.nut" import getEventLootboxSizeMul
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient, doubleSideGradientPaddingX
from "%rGui/components/infoButton.nut" import infoCommonButton
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonBattle
from "%rGui/decorators/decoratorState.nut" import allDecorators
from "%rGui/rewards/components/lootboxView.nut" import getLootboxPicture, lootboxFallbackPicture
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, REWARD_STYLE_BIG, REWARD_STYLE_SMALL,
  REWARD_STYLE_LARGE
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo
from "%rGui/shop/goodsView/sharedParts.nut" import mkSquareIconBtn
from "%rGui/shop/lootboxPreviewState.nut" import openLootboxPreview
from "%rGui/style/stdColors.nut" import markTextColor
from "%rGui/unit/components/unitPlateComp.nut" import mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitInfo
from "%rGui/unitCustom/unitDecals/unitDecalsComps.nut" import mkDecalIcon
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd


const unitPlateWidth = 2 * REWARD_STYLE_MEDIUM.boxSize + REWARD_STYLE_MEDIUM.boxGap
const unitPlateHeight = REWARD_STYLE_MEDIUM.boxSize
const unitInfoBtnSize = evenPx(50)

let mkUnitPlate = @(unitId, isUpgraded = false) function() {
  let res = { watch = serverConfigs }
  let unit = serverConfigs.get()?.allUnits[unitId].__merge({ isUpgraded })
  if (unit == null)
    return res
  return res.__update({
    padding = const [hdpx(50), 0, hdpx(30),0]
    flow = FLOW_HORIZONTAL
    children = {
      size = [ unitPlateWidth, unitPlateHeight ]
      children = [
        mkUnitBg(unit)
        mkUnitImage(unit)
        mkUnitTexts(unit, getUnitName(unit))
        mkUnitInfo(unit)
        {
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = infoCommonButton(
            @() openUnitDetailsWnd({ name = unitId, isUpgraded }),
            { size = unitInfoBtnSize, hotkeys = [["^J:Y", loc("msgbox/btn_more")]] }
          )
        }
      ]
    }
  })
}


let locByTypesReward = {
  item = @(id) loc($"item/{id}")
  currency = @(id) loc($"battlepass/currency/{id}")
  premium =  @(_) loc($"battlepass/premium/header")
  unit = @(id) getUnitName(id)
  unitUpgrade = @(id) getUnitName(id)
  skin = @(id) loc("reward/skin_for",
    { unitName = colorize(markTextColor, getUnitName(id)) })
  decal = @(id) loc($"decals/{id}")
  blueprint = @(_) loc("blueprints")
  lootbox = @(id) loc($"lootbox/{id}")
  booster = @(_) loc($"debriefing/booster")
}

let mkDecoratorHeader = @(viewInfo) @() {
  watch = allDecorators
  rendObj = ROBJ_TEXT
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = loc($"decorator/{allDecorators.get()?[viewInfo.id].dType}")
}.__update(fontSmallAccented)

let mkDefaultRewardHeader = @(viewInfo) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = locByTypesReward?[viewInfo.rType](viewInfo.id) ?? viewInfo.rType
}.__update(fontSmallAccented)

let specialHeadCtors = {
  decorator = mkDecoratorHeader
}

let receiveBtn = @(receive, isInProgress) mkSpinnerHideBlock(isInProgress,
  textButtonBattle(
    utf8ToUpper(loc("btn/receive")),
    receive))

let rewardDesc = @(reward, curStage, lockText, paidText) @() {
  watch = curStage
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  text = reward.isReceived ? loc("battlepass/receivedRew")
    : reward.canReceive ? ""
    : reward.progress > curStage.get() ? loc(lockText, { level = reward.progress })
    : reward?.isVip ? loc("battlepass/paid/vip")
    : loc(paidText)
}.__update(fontTinyAccented)

let defImageCtor = @(viewInfo, _) mkRewardPlateImage(viewInfo, REWARD_STYLE_BIG)

let infoImageCtors = {
  unit = @(vi, _) mkUnitPlate(vi.id)
  unitUpgrade = @(vi, _) mkUnitPlate(vi.id, true)
  decorator = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_SMALL : REWARD_STYLE_MEDIUM)
  currency = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_MEDIUM : REWARD_STYLE_BIG)
  booster = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_MEDIUM : REWARD_STYLE_BIG)
  function lootbox(viewInfo, _) {
    let sizeMul = getEventLootboxSizeMul(viewInfo.id, null, null)
    return {
      size = (REWARD_STYLE_LARGE.boxSize * sizeMul + 0.5).tointeger()
      rendObj = ROBJ_IMAGE
      image = getLootboxPicture(viewInfo.id, null)
      fallbackImage = lootboxFallbackPicture
      keepAspect = true
      children = mkSquareIconBtn("⌡", @() openLootboxPreview(viewInfo.id), { pos = const [0, ph(60)] })
  }}
  function decal(viewInfo, _) {
    let size = [1.5 * REWARD_STYLE_MEDIUM.boxSize, REWARD_STYLE_MEDIUM.boxSize]
    return {
      size
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/images/decal_preview_bg.avif:{size[0]}:{size[1]}:P")
      keepAspect = true
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkDecalIcon(viewInfo.id,
        round(REWARD_STYLE_MEDIUM.boxSize * getDecalDescPresentation(viewInfo.id).scale).tointeger())
    }
  }
}

let bpRewardDesc = @(reward, texts, curStage, receive, isInProgress) function() {
  let { lockText = "", paidText = "" } = texts
  local viewInfo = reward?.viewInfo
  if (viewInfo == null && "rewards" in reward) {
    let rewInfo = []
    foreach(key, count in reward.rewards) {
      let rew = serverConfigs.get()?.userstatRewards[key]
      rewInfo.extend(getRewardsViewInfo(rew, count))
    }
    viewInfo = rewInfo.sort(sortRewardsViewInfo)?[0]
  }
  return doubleSideGradient.__merge({
    watch = serverConfigs
    size = [hdpx(200) + 4 * doubleSideGradientPaddingX, FLEX]
    padding = const [0, 0, hdpx(10), 0]
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = viewInfo == null ? null
      : [
          (specialHeadCtors?[viewInfo?.rType] ?? mkDefaultRewardHeader)(viewInfo)
          {
            size = FLEX
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            behavior = Behaviors.Button
            onClick = @() viewInfo.rType == "lootbox" ? openLootboxPreview(viewInfo.id) : null
            children = (infoImageCtors?[viewInfo.rType] ?? defImageCtor)(viewInfo, reward.canReceive)
          }
          reward.canReceive ? receiveBtn(receive, isInProgress) : rewardDesc(reward, curStage, lockText, paidText)
        ]
  })
}

return bpRewardDesc
