from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { rewardsToReceive, failedRewardsLevelStr } = require("levelUpState.nut")
let { rewardInProgress, get_player_level_rewards } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { addCompToCompAnim } = require("%darg/helpers/compToCompAnim.nut")
let { itemsOrderFull } = require("%appGlobals/itemsState.nut")


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

let iconSize = hdpx(80).tointeger()
let hideCurrencyTrigger = {}

let rewardsSum = Computed(@() rewardsToReceive.value.reduce(
  function(res, rew) {
    let result = {
      wp = (res?.wp ?? 0) + (rew?.wp ?? 0)
      gold = (res?.gold ?? 0) + (rew?.gold ?? 0)
    }
    foreach (id, count in (rew?.items ?? {}))
      result[id] <- (res?[id] ?? 0) + count
    return result
  },
  {}))

let currencyAnims = {
  wp = { from = "received_wp", to = "levelUpWp" }
  gold = { from = "received_gold", to = "levelUpGold" }
}


let function startCurrencyAnims() {
  currencyAnims.each(@(cfg, id) (rewardsSum.value?[id] ?? 0) <= 0 ? null
    : addCompToCompAnim(cfg.__merge({ component = mkCurrencyImage(id, iconSize, { size = flex() }) })))
  anim_start(hideCurrencyTrigger)
}

let function receiveRewards() {
  if (rewardInProgress.value)
    return
  let levels = rewardsToReceive.value.keys()
  local level = null
  let function receiveNext(res) {
    if ("error" in res)
      failedRewardsLevelStr.mutate(@(v) v[level.tostring()] <- true)
    if (levels.len() == 0)
      return
    startCurrencyAnims()
    level = levels.pop()
    get_player_level_rewards(curCampaign.value, level, receiveNext)
  }
  receiveNext(null)
}

let receiveBtn = mkSpinnerHideBlock(Computed(@() rewardInProgress.value != null),
  textButtonCommon(utf8ToUpper(loc("btn/receive")), receiveRewards),
  {
    size = [flex(), defButtonHeight]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    animations = appearAnim(buttonAppearDelay, buttonAppearTime)
  })

let startTimes = {} //outside to not break after parent recalc.
let countTextStyle = { halign = ALIGN_CENTER, monoWidth = "0" }.__merge(fontMedium)
let function mkCurrencyReward(id, amount, countDelay) {
  let countTimeMsec = (1000 * min(amount.tofloat() / (rewardCountPerSec?[id] ?? amount), maxRewardCountTime)).tointeger()
  return {
    key = id
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    halign = ALIGN_CENTER
    children = [
      mkCurrencyImage(id, iconSize, {
        key = $"received_{id}"
        animations = [{
          prop = AnimProp.opacity, duration = 10000, trigger = hideCurrencyTrigger, from = 0, to = 0
        }]
      })
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
            delete startTimes[id]
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
let function rewardsList() {
  let rewards = rewardsSum.value
  let children = []
  foreach (id in allRewardsOrder)
    if ((rewards?[id] ?? 0) > 0)
      children.append(
        mkCurrencyReward(id, rewards[id], rewardStartCount + rewardStartCountOffset * children.len()))

  return {
    watch = rewardsSum
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(200)
    children
    animations = appearAnim(rewardAppearDelay, rewardAppearTime)
  }
}

let levelUpText = @() {
  watch = playerLevelInfo
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text = loc("levelUp/newLevel", { level = playerLevelInfo.value.level + 1 })
}.__update(fontMedium)

return {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    levelUpText
    rewardsList
    receiveBtn
  ]
  animations = appearAnim(sceneAppearDelay, sceneAppearTime)
    .append({ prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, easing = OutQuad, playFadeOut = true })
}