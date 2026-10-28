from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/config/decalsPresentation.nut" import getDecalDescPresentation
from "%appGlobals/config/lootboxPresentation.nut" import getEventLootboxSizeMul
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/pServer/bqClient.nut" import sendUnitBqEventOnce, BQ_DETAILS_BP
from "%rGui/components/gradientDefComps.nut" import doubleSideGradient, doubleSideGradientPaddingX
from "%rGui/components/infoButton.nut" import infoCommonButton
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonBattle
from "%rGui/components/currencyComp.nut" import mkCurrencyImage
from "%rGui/decorators/decoratorState.nut" import allDecorators
from "%rGui/rewards/components/lootboxView.nut" import getLootboxPicture, lootboxFallbackPicture
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateImage
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM, REWARD_STYLE_BIG, REWARD_STYLE_SMALL,
  REWARD_STYLE_LARGE, REWARD_STYLE_BP_DESC
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

function mkUnitPlate(unitId, isUpgraded = false) {
  let moreInfoHotkeys = [["^J:Y", loc("msgbox/btn_more")]]
  return function() {
    let res = { watch = serverConfigs }
    let unit = serverConfigs.get()?.allUnits[unitId].__merge({ isUpgraded })
    function onClick() {
      sendUnitBqEventOnce(BQ_DETAILS_BP, unitId)
      openUnitDetailsWnd({ name = unitId, isUpgraded })
    }
    if (unit == null)
      return res
    return res.__update({
      padding = const [hdpx(50), 0, hdpx(30),0]
      flow = FLOW_HORIZONTAL
      children = {
        size = const [ unitPlateWidth, unitPlateHeight ]
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
              onClick,
              { size = unitInfoBtnSize, hotkeys = moreInfoHotkeys }
            )
          }
        ]
      }
    })
  }
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

let decoratorNameByType = {
  avatar =  @(_) loc("decorator/avatar")
  nickFrame = @(decoratorId) frameNick("", decoratorId)
  title = @(decoratorId) loc($"title/{decoratorId}")
}

let locByTypesRewardNonUpdatable = {
  function decorator(id) {
    let { dType = null } = allDecorators.get()?[id]
    return dType == null ? id : (decoratorNameByType?[dType](id) ?? loc($"decorator/{dType}"))
  }
}

let getLocByRTypeNonUpdatable = @(rType, id)
  locByTypesRewardNonUpdatable?[rType](id) ?? locByTypesReward?[rType](id) ?? rType

let mkDecoratorHeader = @(viewInfo, ovr = {}) @() {
  watch = allDecorators
  rendObj = ROBJ_TEXT
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = loc($"decorator/{allDecorators.get()?[viewInfo.id].dType}")
}.__update(fontSmallAccented, ovr)

let mkDefaultRewardHeader = @(viewInfo, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = getLocByRTypeNonUpdatable(viewInfo.rType, viewInfo.id)
}.__update(fontSmallAccented, ovr)

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

let defImageCtor = @(viewInfo, _, style = null) mkRewardPlateImage(viewInfo, style ?? REWARD_STYLE_BIG)

let infoImageCtors = {
  unit = @(vi, _, __ = null) mkUnitPlate(vi.id)
  unitUpgrade = @(vi, _, __ = null) mkUnitPlate(vi.id, true)
  decorator = @(viewInfo, canReceive, style = null)
    mkRewardPlateImage(viewInfo, style ?? (canReceive ? REWARD_STYLE_SMALL : REWARD_STYLE_MEDIUM))
  currency = @(viewInfo, canReceive, style = null)
    mkRewardPlateImage(viewInfo, style ?? (canReceive ? REWARD_STYLE_MEDIUM : REWARD_STYLE_BIG))
  booster = @(viewInfo, canReceive, style = null)
    mkRewardPlateImage(viewInfo, style ?? (canReceive ? REWARD_STYLE_MEDIUM : REWARD_STYLE_BIG))
  function lootbox(viewInfo, _, style = null) {
    let sizeMul = getEventLootboxSizeMul(viewInfo.id, null, null)
    let { boxSize } = style ?? REWARD_STYLE_LARGE
    return {
      size = (boxSize * sizeMul + 0.5).tointeger()
      rendObj = ROBJ_IMAGE
      image = getLootboxPicture(viewInfo.id, null)
      fallbackImage = lootboxFallbackPicture
      keepAspect = true
      children = mkSquareIconBtn("⌡", @() openLootboxPreview(viewInfo.id), { pos = const [0, ph(60)] })
  }}
  function decal(viewInfo, _, style = null) {
    let { boxSize } = style ?? REWARD_STYLE_MEDIUM
    let size = [1.5 * boxSize, boxSize]
    return {
      size
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/images/decal_preview_bg.avif:{size[0]}:{size[1]}:P")
      keepAspect = true
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkDecalIcon(viewInfo.id,
        round(boxSize * getDecalDescPresentation(viewInfo.id).scale).tointeger())
    }
  }
}

let bpObsoleteRewardDesc = @(reward, texts, curStage, receive, isInProgress) function() {
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

function bpRewardDesc(slot, bpId) {
  let viewInfo = getRewardsViewInfo(slot.rewards).sort(sortRewardsViewInfo)?[0]
  let mkText = specialHeadCtors?[viewInfo?.rType] ?? mkDefaultRewardHeader
  let bpPointsIcon = mkCurrencyImage(bpId,
    get_font_metrics(fontTinyAccented.font, fontTinyAccented.fontSize).ascent * 0.75,
    { imageValign = ALIGN_BOTTOM })
  return {
    size = FLEX
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = viewInfo == null ? null
      : [
          {
            size = FLEX
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = (infoImageCtors?[viewInfo.rType] ?? defImageCtor)(viewInfo, slot?.canReceive,
              viewInfo.slots > 1 ? REWARD_STYLE_BIG : REWARD_STYLE_BP_DESC)
          }
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              {
                size = [ FLEX, evenPx(60) ]
                halign = ALIGN_CENTER
                valign = ALIGN_BOTTOM

                rendObj = ROBJ_SOLID
                color = 0x80304453
                children = mkText(viewInfo, { ...fontTinyAccented, vplace = ALIGN_CENTER })
              }
              {
                size = [ FLEX, evenPx(200) ]
                halign = ALIGN_CENTER
                padding = hdpx(16)

                rendObj = ROBJ_SOLID
                color = 0x80000000
                children = {
                  size = FLEX
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  vplace = ALIGN_TOP
                  halign = ALIGN_CENTER

                  embed = { icon = bpPointsIcon }
                  text = slot.descLoc
                }.__update(fontTinyAccented)
              }
            ]
          }
        ]
  }
}

return {
  bpRewardDesc
  bpObsoleteRewardDesc
  getLocByRTypeNonUpdatable
}
