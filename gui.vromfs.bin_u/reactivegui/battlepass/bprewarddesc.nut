from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { REWARD_STYLE_BIG, REWARD_STYLE_LARGE } = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateImage } = require("%rGui/rewards/rewardPlateComp.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getPlatoonName, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateRatio, mkUnitRank
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkGradRankLarge } = require("%rGui/components/gradTexts.nut")
let { receiveBpRewards, isBpRewardsInProgress, curStage } = require("battlePassState.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { doubleSideGradient, doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")


let unitPlateWidth = hdpx(480)
let unitPlateHeight = unitPlateWidth * unitPlateRatio

let mkUnitPlate = @(unitId) function() {
  let res = { watch = serverConfigs }
  let unit = serverConfigs.get()?.allUnits[unitId]
  if (unit == null)
    return res
  return res.__update({
    padding = [hdpx(50), 0, hdpx(30),0]
    flow = FLOW_HORIZONTAL
    children = {
      size = [ unitPlateWidth, unitPlateHeight ]
      children = [
        mkUnitBg(unit)
        mkUnitImage(unit)
        mkUnitRank(unit)
        mkUnitTexts(unit, getPlatoonOrUnitName(unit, loc))
        mkGradRankLarge(unit.mRank, {
         padding = hdpx(10)
         hplace = ALIGN_RIGHT
         vplace = ALIGN_BOTTOM
        })
        {
          hplace = ALIGN_LEFT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = infoBlueButton(
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
  unit = @(id) getPlatoonName(id, loc)
  unitUpgrade = @(id) getPlatoonName(id, loc)
}

let mkDecoratorHeader = @(viewInfo) @(){
  watch = allDecorators
  rendObj = ROBJ_TEXT
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = loc($"decorator/{allDecorators.value?[viewInfo.id].dType}")
}.__update(fontSmallAccented)

let mkDefaultRewardHeader = @(viewInfo){
  rendObj = ROBJ_TEXT
  vplace = ALIGN_TOP
  halign = ALIGN_CENTER
  text = locByTypesReward[viewInfo.rType](viewInfo.id)
}.__update(fontSmallAccented)

let specialHeadCtors = {
  decorator = mkDecoratorHeader
}

let receiveBtn = @(reward) mkSpinnerHideBlock(isBpRewardsInProgress,
  textButtonBattle(
    utf8ToUpper(loc("btn/receive")),
    @() receiveBpRewards(reward.progress)))

let rewardDesc = @(reward) @() {
  watch = curStage
  size = [flex(), hdpx(40)]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  text = reward.isReceived ? loc("battlepass/receivedRew")
    : reward.canReceive ? ""
    : reward.progress <= curStage.get() ? loc("battlepass/paid")
    : loc("battlepass/lock", { level = reward.progress })
}.__update(fontTinyAccented)

let defImageCtor = @(viewInfo) mkRewardPlateImage(viewInfo, REWARD_STYLE_LARGE)
let unitImageCtor = @(viewInfo) mkUnitPlate(viewInfo.id)

let infoImageCtors = {
  unit = unitImageCtor
  unitUpgrade = unitImageCtor
  decorator = @(viewInfo) mkRewardPlateImage(viewInfo, REWARD_STYLE_BIG)
}

let bpRewardDesc = @(reward) function() {
  let rewInfo = []
  foreach(key, count in reward.rewards) {
    let rew = serverConfigs.value.userstatRewards?[key]
    rewInfo.extend(getRewardsViewInfo(rew, count))
  }
  let viewInfo = rewInfo.sort(sortRewardsViewInfo)?[0]
  return doubleSideGradient.__merge({
    watch = serverConfigs
    size = [hdpx(600) + 4 * doubleSideGradientPaddingX, flex()]
    padding = [hdpx(10), doubleSideGradientPaddingX, hdpx(20), doubleSideGradientPaddingX]
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(5)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      (specialHeadCtors?[viewInfo?.rType] ?? mkDefaultRewardHeader)(viewInfo)
      {
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = viewInfo == null ? null
          : (infoImageCtors?[viewInfo.rType] ?? defImageCtor)(viewInfo)
      }
      reward.canReceive ? receiveBtn(reward) : rewardDesc(reward)
    ]
  })
}

return bpRewardDesc