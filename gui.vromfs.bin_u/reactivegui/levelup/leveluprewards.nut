from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { btnAUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { rewardsToReceive, failedRewardsLevelStr, maxRewardLevelInfo, isRewardsModalOpen,
  openLvlUpAfterDelay, startLvlUpAnimation, closeRewardsModal, skipLevelUpUnitPurchase
} = require("levelUpState.nut")
let { rewardInProgress, get_player_level_rewards, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyImage, maxIconsCoef } = require("%rGui/components/currencyComp.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { mkPlayerLevel } = require("%rGui/unit/components/unitPlateComp.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { gradTranspDoubleSideX, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { bgMW } = require("%rGui/style/stdColors.nut")
let { levelUpFlag, flagHeight } = require("levelUpFlag.nut")
let { resetTimeout } = require("dagor.workcycle")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let openSelectUnitResearchIfCan = require("%rGui/unitsTree/selectUnitResearchWnd.nut")


let WND_UID = "levelup_rewards_wnd"
let sceneAppearDelay = 0.6
let sceneAppearTime = 0.5
let rewardAppearDelay = sceneAppearDelay + sceneAppearTime
let rewardAppearTime = 0.3
let rewardStartCount = rewardAppearDelay + rewardAppearTime
let rewardStartCountOffset = 0.3
let rewardCountPerSec = { wp = 40000, gold = 200 }
let maxRewardCountTime = 1.0
let buttonAppearDelay = rewardStartCount + maxRewardCountTime
let buttonAppearTime = 1.0
let flagStartDelay = 0.3

let iconSize = hdpxi(160)
let hideCurrencyTrigger = {}

let rewardsSum = Computed(@() rewardsToReceive.value.reduce(
  function(res, rew) {
    if (type(rew) == "table") { //compatibility with 2024.04.14
      let result = {
        wp = (res?.wp ?? 0) + (rew?.currencies.wp ?? 0) + (rew?.wp ?? 0)
        gold = (res?.gold ?? 0) + (rew?.currencies.gold ?? 0) + (rew?.gold ?? 0)
      }
      foreach (id, count in (rew?.items ?? {}))
        result[id] <- (res?[id] ?? 0) + count
      return result
    }
    let result = {}
    foreach(g in rew)
      if (g.gType == "currency" || g.gType == "item") //does not support to show other rewards yet
        result[g.id] <- (result?[g.id] ?? 0) + g.count
    return result
  },
  {}))

function afterReceiveRewards() {
  closeRewardsModal()
  resetTimeout(0.1, function() {
    if (playerLevelInfo.get().isReadyForLevelUp) {
      if (curCampaign.get() in serverConfigs.get()?.unitTreeNodes) {
        skipLevelUpUnitPurchase()
        openSelectUnitResearchIfCan()
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
    size = [flex(), defButtonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    animations = appearAnim(buttonAppearDelay, buttonAppearTime)
  })

let startTimes = {} //outside to not break after parent recalc.
let countTextStyle = { halign = ALIGN_CENTER, monoWidth = "0" }.__merge(fontMedium)
function mkCurrencyReward(id, amount, countDelay) {
  let countTimeMsec = (1000 * min(amount.tofloat() / (rewardCountPerSec?[id] ?? amount), maxRewardCountTime)).tointeger()
  return {
    key = id
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    halign = ALIGN_CENTER
    children = [
      {
        size = [iconSize * maxIconsCoef, iconSize * maxIconsCoef]
        halign = ALIGN_CENTER
        children = mkCurrencyImage(id, iconSize, {
          key = $"received_{id}"
          animations = [{
            prop = AnimProp.opacity, duration = 10000, trigger = hideCurrencyTrigger, from = 0, to = 0
          }]
        })
      }
      {
        size = calc_str_box({ text = decimalFormat(amount) }.__update(countTextStyle))
        rendObj = ROBJ_TEXT
        text = ""
        onAttach = @() startTimes[id] <- get_time_msec() + (1000 * countDelay).tointeger()
        behavior = Behaviors.RtPropUpdate
        function update() {
          if (id not in startTimes)
            return null
          let curTime = get_time_msec()
          if (curTime < startTimes[id])
            return null
          let startTime = startTimes[id]
          let endTime = startTime + countTimeMsec
          if (curTime >= endTime)
            startTimes.$rawdelete(id)
          return {
            text = curTime >= endTime ? decimalFormat(amount)
              : decimalFormat(lerpClamped(startTime, endTime, 0, amount, curTime).tointeger())
          }
        }
        animations = [
          { prop = AnimProp.opacity, duration = 0.15, trigger = hideCurrencyTrigger, from = 1, to = 0 }
          { prop = AnimProp.opacity, delay = 0.15, duration = 10000, trigger = hideCurrencyTrigger, from = 0, to = 0 }
        ]
      }.__update(countTextStyle)
    ]
  }
}

let allRewardsOrder = ["wp", "gold"].extend(itemsOrderFull)
function rewardsList() {
  let rewards = rewardsSum.value
  let children = []
  foreach (id in allRewardsOrder)
    if ((rewards?[id] ?? 0) > 0)
      children.append(
        mkCurrencyReward(id, rewards[id], rewardStartCount + rewardStartCountOffset * children.len()))

  return {
    watch = rewardsSum
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(100)
    children
    animations = appearAnim(rewardAppearDelay, rewardAppearTime)
  }
}

let levelUpText = @() {
  watch = maxRewardLevelInfo
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = mkTextRow(
    loc("levelUp/newLevel"),
    @(text) { rendObj = ROBJ_TEXT, text }.__update(fontMedium),
    {
      ["{level}"] = mkPlayerLevel(maxRewardLevelInfo.value.level, maxRewardLevelInfo.value.starLevel), //warning disable: -forgot-subst
    }
  )
}

let levelUpRewards = {
  key = WND_UID
  size = flex()
  padding = saBordersRv
  onClick = receiveRewards
  children = {
    size = flex()
    rendObj = ROBJ_9RECT
    color = bgMW
    image = gradTranspDoubleSideX
    texOffs = [0, gradCircCornerOffset]
    screenOffs = [0, hdpx(150)]
    children = {
      size = flex()
      flow = FLOW_VERTICAL
      gap = hdpx(50)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        @() {
          watch = maxRewardLevelInfo
          children = levelUpFlag(flagHeight, maxRewardLevelInfo.value.level, maxRewardLevelInfo.value.starLevel, flagStartDelay)
        }
        levelUpText
        rewardsList
        receiveBtn
      ]
      animations = appearAnim(sceneAppearDelay, sceneAppearTime)
        .append({ prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, easing = OutQuad, playFadeOut = true })
    }
  }
}

if (isRewardsModalOpen.get() && rewardsToReceive.get().len() > 0)
  addModalWindow(levelUpRewards)
isRewardsModalOpen.subscribe(@(v) v ? addModalWindow(levelUpRewards) : removeModalWindow(WND_UID))
