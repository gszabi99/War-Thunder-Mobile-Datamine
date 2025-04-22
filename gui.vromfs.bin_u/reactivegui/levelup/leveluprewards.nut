from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { rewardsToReceive, failedRewardsLevelStr, maxRewardLevelInfo, isRewardsModalOpen,
  openLvlUpAfterDelay, startLvlUpAnimation, closeRewardsModal, skipLevelUpUnitPurchase
} = require("levelUpState.nut")
let { rewardInProgress, get_player_level_rewards, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { mkPlayerLevel, mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateSmall, mkUnitInfo } = require("%rGui/unit/components/unitPlateComp.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { levelUpFlag } = require("levelUpFlag.nut")
let { resetTimeout } = require("dagor.workcycle")
let { playerLevelInfo, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { mkRewardPlate, REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardPlateComp.nut")
let { receivedGoodsToViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { boughtUnit } = require("%rGui/unit/selectNewUnitWnd.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")


let WND_UID = "levelup_rewards_wnd"
let sceneAppearDelay = 0.6
let sceneAppearTime = 0.5
let eachRewardsAnimDuration = 0.2
let wndOpacityAnimDuration = 0.2


let flagStartDelay = 0.3

function afterReceiveRewards() {
  closeRewardsModal()
  resetTimeout(0.1, function() {
    if (playerLevelInfo.get().isReadyForLevelUp) {
      if (isCampaignWithUnitsResearch.get()) {
        skipLevelUpUnitPurchase()
      }
      else {
        startLvlUpAnimation()
        openLvlUpAfterDelay()
      }
    }
  })
}

function receiveRewards() {
  let level = rewardsToReceive.value.findindex(@(_) true)
  if (level == null) {
    afterReceiveRewards()
    return
  }
  if (rewardInProgress.value)
    return
  get_player_level_rewards(curCampaign.value, level,
    { id = "playerLevelRewards.receiveNext", level })
  afterReceiveRewards()
}

registerHandler("playerLevelRewards.receiveNext",
  function(res, context) {
    if ("error" in res)
      failedRewardsLevelStr.mutate(@(v) v[context.level.tostring()] <- true)
    receiveRewards()
  })

let receiveBtn = mkSpinnerHideBlock(Computed(@() rewardInProgress.value != null),
  textButtonPrimary(utf8ToUpper(loc("btn/receive")), receiveRewards, { hotkeys = [btnAUp] }),
  {
    margin = [hdpx(20),0,0,0]
    size = [SIZE_TO_CONTENT, defButtonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  })


function rewardsList() {
  let rewards = rewardsToReceive.get().values()?[0].map(receivedGoodsToViewInfo) ?? 0
  return rewardsToReceive.get().len() > 0 ? {
    watch = rewardsToReceive
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(35)
    children = rewards?.map(@(r, idx) {
      children = mkRewardPlate(r, REWARD_STYLE_SMALL)
      transform = {}
      animations = appearAnim(sceneAppearDelay, sceneAppearTime)
        .append(
          { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], duration = eachRewardsAnimDuration,
            delay = eachRewardsAnimDuration * idx + sceneAppearDelay , play = true, easing = Linear }
          { prop = AnimProp.scale, from = [1.2, 1.2], to = [1, 1], duration = eachRewardsAnimDuration,
            delay = eachRewardsAnimDuration * idx + sceneAppearDelay + eachRewardsAnimDuration, play = true, easing = Linear,
            onFinish = (idx + 1) == rewardsToReceive.get().len() ? @() anim_start("unitRAnim") : null
          }
        )
    })
  } : null
}

let levelUpText = @() {
  padding = [0, hdpx(150)]
  watch = maxRewardLevelInfo
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = mkTextRow(
    loc("levelUp/newLevel"),
    @(text) { rendObj = ROBJ_TEXT, text }.__update(fontMedium),
    {
      ["{level}"] = mkPlayerLevel(maxRewardLevelInfo.value.level, maxRewardLevelInfo.value.starLevel), 
    }
  )
}

function mkUnitPlate(){
  let unit = Computed(@() campMyUnits.get()?[boughtUnit.get()])
  return @() !unit.get() ? { watch = unit } : {
    watch = [unit, boughtUnit, rewardsToReceive]
    size = unitPlateSmall
    children = [
      mkUnitBg(unit.get())
      mkUnitImage(unit.get())
      mkUnitTexts(unit.get(), loc(getUnitLocId(boughtUnit.get())))
      mkUnitInfo(unit.get())
    ]
    transform = {}
    animations = appearAnim(sceneAppearDelay, sceneAppearTime)
      .append(
        { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], duration = eachRewardsAnimDuration,
          delay = eachRewardsAnimDuration * rewardsToReceive.get().len(), trigger = "unitRAnim", easing = Linear }
        { prop = AnimProp.scale, from = [1.2, 1.2], to = [1, 1], duration = eachRewardsAnimDuration,
          delay = eachRewardsAnimDuration * rewardsToReceive.get().len() + eachRewardsAnimDuration, trigger = "unitRAnim", easing = Linear }
      )
  }
}

let content = modalWndBg.__merge({
  padding = [0,0,hdpx(50), 0]
  onClick = receiveRewards
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    flow = FLOW_VERTICAL
    gap = hdpx(50)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      @() modalWndHeaderBg.__merge({
        margin = [0, 0, hdpx(20), 0]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        watch = maxRewardLevelInfo
        children = levelUpFlag(hdpx(150), maxRewardLevelInfo.get().level, maxRewardLevelInfo.get().starLevel, flagStartDelay)
      })
      levelUpText
      rewardsList
      mkUnitPlate()
      receiveBtn
    ]
    animations = appearAnim(sceneAppearDelay, sceneAppearTime)
      .append({ prop = AnimProp.opacity, from = 1, to = 0, duration = wndOpacityAnimDuration, easing = OutQuad, playFadeOut = true })
  }
})

let levelUpRewards = bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = receiveRewards
  children = content
  animations = wndSwitchAnim
})

if (isRewardsModalOpen.get() && rewardsToReceive.get().len() > 0)
  addModalWindow(levelUpRewards)
isRewardsModalOpen.subscribe(@(v) v ? addModalWindow(levelUpRewards) : removeModalWindow(WND_UID))
