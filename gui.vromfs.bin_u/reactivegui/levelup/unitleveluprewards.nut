from "%globalsDarg/darg_library.nut" import *

let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")

let { rewardsToReceive, rewardUnitLevelInfo, isUnitRewardsModalOpen, closeUnitRewardsModal,
  currentUnit, receiveUnitRewards } = require("%rGui/levelUp/unitLevelUpState.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkRewardPlate, REWARD_STYLE_SMALL } = require("%rGui/rewards/rewardPlateComp.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { modalWndBg, modalWndHeaderBg } = require("%rGui/components/modalWnd.nut")
let { receivedGoodsToViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { mkUnitLevel } = require("%rGui/unit/components/unitPlateComp.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { wndSwitchAnim }= require("%rGui/style/stdAnimations.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { levelUpUnitFlag } = require("%rGui/levelUp/levelUpFlag.nut")


let WND_UID = "unit_levelup_rewards_wnd"
let sceneAppearDelay = 0.6
let sceneAppearTime = 0.5
let rewardsAnimDelay = sceneAppearDelay * 1.5
let eachRewardsAnimDelay  = sceneAppearTime  + 0.2
let eachRewardsAnimDuration = 0.3
let wndOpacityAnimDuration = 0.2
let flagStartDelay = 0.3

function receiveRewards() {
  if (unitInProgress.get())
    return
  let { name, campaign } = currentUnit.get()
  if(!name || !campaign)
    return
  receiveUnitRewards(name, campaign)
  closeUnitRewardsModal()
}

let receiveBtn = mkSpinnerHideBlock(Computed(@() unitInProgress.get() != null),
  textButtonPrimary(utf8ToUpper(loc("btn/receive")), receiveRewards, { hotkeys = [btnAUp] }),
  {
    margin = const [hdpx(20), 0, 0, 0]
    size = [SIZE_TO_CONTENT, defButtonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  })

function rewardsList() {
  let rewards = rewardsToReceive.get().map(receivedGoodsToViewInfo) ?? 0
  return rewardsToReceive.get().len() == 0
    ? null
    : {
        watch = rewardsToReceive
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(35)
        children = rewards?.map(@(r, idx) {
          children = mkRewardPlate(r, REWARD_STYLE_SMALL)
          transform = {}
          animations = appearAnim(rewardsAnimDelay, sceneAppearTime)
            .append(
              { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], duration = eachRewardsAnimDuration, delay = eachRewardsAnimDelay * (idx + 1),
                play = true, easing = InOutQuad }
            )
        })
      }
}

let levelUpText = @() {
  padding = const [0, hdpx(150)]
  watch = rewardUnitLevelInfo
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = mkTextRow(
        loc("unitlevelUp/rewardLevels"),
        @(text) {
          rendObj = ROBJ_TEXT
          text
        }.__update(fontSmall),
        {
          ["{minLevel}"] = mkUnitLevel(rewardUnitLevelInfo.get().minLevel), 
          ["{maxLevel}"] = mkUnitLevel(rewardUnitLevelInfo.get().maxLevel) 
        }
      )
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("unitlevelUp/rewardsForUnit", { unitName = getPlatoonOrUnitName(currentUnit.get(), loc) })
    }.__update(fontSmall)
  ]
}

let content = modalWndBg.__merge({
  padding = const [0, 0, hdpx(50), 0]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    flow = FLOW_VERTICAL
    gap = hdpx(50)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      @() modalWndHeaderBg.__merge({
        margin = const [0, 0, hdpx(20), 0]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        watch = rewardUnitLevelInfo
        children = levelUpUnitFlag(hdpx(150), rewardUnitLevelInfo.get().maxLevel, 0, flagStartDelay)
      })
      levelUpText
      rewardsList
      receiveBtn
    ]
    animations = appearAnim(sceneAppearDelay, sceneAppearTime)
      .append({ prop = AnimProp.opacity, from = 1, to = 0, duration = wndOpacityAnimDuration, easing = OutQuad, playFadeOut = true })
  }
})

let unitLevelUpRewards = bgShaded.__merge({
  key = WND_UID
  size = flex()
  onClick = receiveRewards
  children = content
  animations = wndSwitchAnim
})

if (isUnitRewardsModalOpen.get() && rewardsToReceive.get().len() > 0)
  addModalWindow(unitLevelUpRewards)
isUnitRewardsModalOpen.subscribe(@(v) v ? addModalWindow(unitLevelUpRewards) : removeModalWindow(WND_UID))
