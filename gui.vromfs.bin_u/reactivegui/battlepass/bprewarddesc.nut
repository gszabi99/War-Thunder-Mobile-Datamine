from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { REWARD_STYLE_BIG, REWARD_STYLE_LARGE, REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateImage } = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getPlatoonOrUnitName, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { infoCommonButton } = require("%rGui/components/infoButton.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateRatio, mkUnitInfo
} = require("%rGui/unit/components/unitPlateComp.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { doubleSideGradient, doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let { markTextColor } = require("%rGui/style/stdColors.nut")
let { openLootboxPreview } = require("%rGui/shop/lootboxPreviewState.nut")


let unitPlateWidth = hdpx(480)
let unitPlateHeight = unitPlateWidth * unitPlateRatio

let mkUnitPlate = @(unitId) function() {
  let res = { watch = serverConfigs }
  let unit = serverConfigs.get()?.allUnits[unitId]
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
        mkUnitTexts(unit, getPlatoonOrUnitName(unit, loc))
        mkUnitInfo(unit)
        {
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = infoCommonButton(
            @() unitDetailsWnd({ name = unit.name }),
            { hotkeys = [["^J:Y", loc("msgbox/btn_more")]] }
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
  unit = @(id) getPlatoonOrUnitName({ name = id }, loc)
  unitUpgrade = @(id) getPlatoonOrUnitName({ name = id }, loc)
  skin = @(id) loc("reward/skin_for",
    { unitName = colorize(markTextColor, loc(getUnitLocId(id))) })
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

let defImageCtor = @(viewInfo, _) mkRewardPlateImage(viewInfo, REWARD_STYLE_LARGE)
let unitImageCtor = @(viewInfo, _) mkUnitPlate(viewInfo.id)

let infoImageCtors = {
  unit = unitImageCtor
  unitUpgrade = unitImageCtor
  decorator = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_MEDIUM : REWARD_STYLE_BIG)
  currency = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_BIG : REWARD_STYLE_LARGE)
  booster = @(viewInfo, canReceive) mkRewardPlateImage(viewInfo, canReceive ? REWARD_STYLE_BIG : REWARD_STYLE_LARGE)
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
    size = [hdpx(600) + 4 * doubleSideGradientPaddingX, flex()]
    padding = [hdpx(10), doubleSideGradientPaddingX, hdpx(20), doubleSideGradientPaddingX]
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = viewInfo == null ? null
      : [
          (specialHeadCtors?[viewInfo?.rType] ?? mkDefaultRewardHeader)(viewInfo)
          {
            size = flex()
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            behavior = Behaviors.Button
            onClick = @() viewInfo.rType == "lootbox" ? openLootboxPreview(viewInfo.id) : null
            children = viewInfo == null ? null
              : (infoImageCtors?[viewInfo.rType] ?? defImageCtor)(viewInfo, reward.canReceive)
          }
          reward.canReceive ? receiveBtn(receive, isInProgress) : rewardDesc(reward, curStage, lockText, paidText)
        ]
  })
}

return bpRewardDesc