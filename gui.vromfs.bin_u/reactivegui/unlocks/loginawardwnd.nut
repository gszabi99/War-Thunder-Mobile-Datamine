from "%globalsDarg/darg_library.nut" import *
from "loginAwardPlaces.nut" import *
let { register_command } = require("console")
let { get_time_msec } = require("dagor.time")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { lerp } = require("%sqstd/math.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { loginAwardUnlock, isLoginAwardOpened, receiveLoginAward, isLoginAwardInProgress,
  hasLoginAwardByAds, showLoginAwardAds
} = require("loginAwardState.nut")
let { getRelativeStageData } = require("unlocks.nut")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let backButton = require("%rGui/components/backButton.nut")
let { mkRewardImage, getRewardName } = require("rewardsView/rewardsPresentation.nut")
let { gradRadialSq, gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { textButtonBattle, textButtonPrimary, textButtonCommon, buttonsHGap
} = require("%rGui/components/textButton.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { canShowAds } = require("%rGui/ads/adsState.nut")
let { isShowUnseenDelayed } = require("%rGui/shop/unseenPurchasesState.nut")
let { playSound } = require("sound_wt")

let itemBlockSize = [ (itemWidth + itemGap) * 4 + itemBigWidth + backItemOffset, itemBigHeight ]
let imageSize = hdpxi(210)
let bigImageSize = hdpxi(330)
let highlightSize = hdpxi(550)
let buttonHeight = evenPx(60)
let checkSize = hdpxi(120)
let debugAnimState = mkWatched(persist, "debugAnimState", null)

local lastPeriodStartStage = null
local lastShowedReceivedStage = null
local lastPeriodStages = -1 //need for correct animation switch on change period especiall when you have several rewards from WT

isAuthorized.subscribe(@(_) {
  lastPeriodStartStage = null
  lastAnimState = -1
  lastShowedReceivedStage = -1
})

let activeTextColor = 0xFFFFFFFF
let commonTextColor = 0xA0A0A0A0

let receiveAnimItemTime = 0.5
let receiveAnimFadeTime = 0.3
let receiveAnimCheckTime = 0.5
let receiveAnimCheckStartShowTime = receiveAnimItemTime - 0.1

local lastAnimState = -1
local animStateStartTime = 0
let close = @() isLoginAwardOpened(false)
let canClose = Computed(@() !loginAwardUnlock.value?.hasReward)

let mkText = @(text, style) {
  text
  rendObj = ROBJ_TEXT
  color = activeTextColor
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(style)

let header = {
  size = [SIZE_TO_CONTENT, hdpx(100)]
  padding = [0, hdpx(100), 0, 0]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0xA0000000

  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap
  children = [
    @() {
      watch = canClose
      size = [hdpx(80), SIZE_TO_CONTENT]
      children = canClose.value ? backButton(close, { animations = wndSwitchAnim }) : null
    }
    mkText(loc("dailyRewards/header"), fontBig)
  ]
}

let function mkFirstRewardComp(stageData) {
  let { rewards = {} } = stageData
  let rewardId = rewards.findindex(@(_) true)
  if (rewardId == null)
    return Watched(null)
  return Computed(@() serverConfigs.value?.userstatRewards[rewardId])
}

let rewardBg = {
  size = flex()
  rendObj = ROBJ_BOX
  fillColor = 0xFFB75114
  borderColor = 0xFFC07B44
  borderWidth = hdpx(4)
  padding = hdpx(4)
}
let canReceiveBgColor = 0xFF2F5086
let hugeRewardBgColor = 0xFFC61EA4
let rewardBgCanReceive = rewardBg.__merge({ fillColor = canReceiveBgColor })
let rewardBgNextReceive = rewardBgCanReceive.__merge({ borderColor = 0xFFC2B152 })
let rewardBgReceived = rewardBg.__merge({
  fillColor = 0xFF514F4E
  borderColor = 0xFF7B7979
})

let highlight = {
  key = {}
  size = [highlightSize, highlightSize]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradRadialSq
  color = rewardBg.fillColor & 0xFFFFFF
}
let highlightReceived = highlight.__merge({ color = rewardBgReceived.fillColor & 0xFFFFFF })
let highlightCanReceive = highlight.__merge({ color = canReceiveBgColor & 0xFFFFFF })
let highlightNextReceive = highlightCanReceive.__merge({
  key = {}
  transform = {}
  animations = [{ prop = AnimProp.color, duration = 2.0,
    play = true, loop = true, easing = CosineFull,
    from = canReceiveBgColor & 0xFFFFFF,
    to = mul_color(canReceiveBgColor, 2.0) & 0xFFFFFF,
  }]
})

let bigSlotImage = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/daily_slot_bg_art.avif")
  keepAspect = KEEP_ASPECT_FILL
}

let checkImg = {
  key = {}
  size = [checkSize, checkSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#daily_mark_claimed.avif:{checkSize}:{checkSize}:P")
}

let checkImgWithAnim = checkImg.__merge({
  key = {}
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.25, 1.25], duration = receiveAnimCheckTime,
      delay = receiveAnimItemTime, play = true, easing = CosineFull, onEnter = @() playSound("daily_reward") }
    { prop = AnimProp.opacity, from = 0.0, to = 0.0,
      duration = receiveAnimCheckStartShowTime, play = true }
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.2,
      delay = receiveAnimCheckStartShowTime, easing = InOutQuad, play = true }
  ]
})

let mkDayText = @(text, isReceived) {
  size = [flex(), hdpx(50)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = 0x60000000
  children = {
    rendObj = ROBJ_TEXT
    text
    color = isReceived ? 0x80808080 : 0xFFFFFFFF
  }.__update(fontTiny)
}

let btnStyle = {
  hotkeys = ["^J:X | Enter"],
  ovr = { size = flex(), minWidth = 0, behavior = null, onElemState = null }
  childOvr = fontTiny
}

let receiveBtn = @(stateFlags) textButtonBattle(
  utf8ToUpper(loc("btn/receive")),
  receiveLoginAward,
  btnStyle.__merge({ stateFlags })
)

let watchAdsBtn = @(stateFlags) textButtonPrimary(
  utf8ToUpper(loc("shop/watchAdvert/short")),
  showLoginAwardAds,
  btnStyle.__merge({ childOvr = fontVeryTiny, stateFlags })
)

let watchAdsNotReadyBtn = @(stateFlags) textButtonCommon(
  utf8ToUpper(loc("shop/watchAdvert/short")),
  showLoginAwardAds,
  btnStyle.__merge({ childOvr = fontVeryTiny, stateFlags })
)

let buttonBlock = function(stateFlags) {
  let targetButtonComponent = @() {
    watch = [loginAwardUnlock, hasLoginAwardByAds, canShowAds, isShowUnseenDelayed]
    size = flex()
    children = isShowUnseenDelayed.value ? null //delay unseen for animation, so no need button at that time also.
      : loginAwardUnlock.value?.hasReward ? receiveBtn(stateFlags)
      : !hasLoginAwardByAds.value ? null
      : canShowAds.value ? watchAdsBtn(stateFlags)
      : watchAdsNotReadyBtn(stateFlags)
  }

  let blockOvr = {
    size = [flex(), buttonHeight]
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  }

  return mkSpinnerHideBlock(isLoginAwardInProgress, targetButtonComponent, blockOvr)
}

let onActivePlateClick = @() isShowUnseenDelayed.value ? null
  : loginAwardUnlock.value?.hasReward ? receiveLoginAward()
  : !hasLoginAwardByAds.value ? null
  : canShowAds.value ? showLoginAwardAds()
  : null

let function mkReward(periodIdx, stageData, stageIdx, curStage, lastRewardedStage, animState) {
  let place = rewardsPlaces?[periodIdx]
  if (place == null) {
    logerr($"Missing place for periodIdx = {periodIdx}")
    return null
  }

  let { size, transformByState, slotType } = place
  let isReceived = stageIdx < lastRewardedStage
  let canReceive = !isReceived && stageIdx < curStage
  let isNextReceive = canReceive && stageIdx == lastRewardedStage
  let reward = mkFirstRewardComp(stageData)
  let dayText = curStage == stageIdx + 1 ? loc("day/today")
    : curStage == stageIdx ? loc("day/tomorrow")
    : loc("enumerated_day", { number = stageIdx + 1 })
  let needReceiveAnim = isReceived && lastShowedReceivedStage < stageIdx

  let { translate = null, opacity = 1.0, animDelay = 0, animTime = 0 } = transformByState?[animState] ?? {}
  let prevTransform = transformByState?[animState - 1]
  let startTime = animStateStartTime + (1000 * animDelay).tointeger()
  let endTime = startTime + (1000 * animTime).tointeger()
  let afterAnimProps = { opacity, transform = { translate } }
  let isCurrentActivePlate = isNextReceive || (curStage == lastRewardedStage && stageIdx == curStage - 1)
  let stateFlags = Watched(0)

  local animData = afterAnimProps
  if (endTime > get_time_msec() && prevTransform != null) {
    let prevOpacity = prevTransform?.opacity ?? 1.0
    let prevTranslate = prevTransform?.translate
    let beforeAnimProps = { opacity = prevOpacity, transform = { translate = prevTranslate } }
    animData = {
      transform = {}
      behavior = [Behaviors.RtPropUpdate, Behaviors.Button]
      function update() {
        let time = get_time_msec()
        if (time <= startTime)
          return beforeAnimProps
        if (time >= endTime)
          return afterAnimProps
        return {
          opacity = lerp(startTime, endTime, prevOpacity, opacity, time)
          transform = {
            translate = translate == null ? null
              : translate.map(@(v, i) lerp(startTime, endTime, prevTranslate?[i] ?? v, v, time))
          }
        }
      }
    }
  }
  let bg = isReceived ? rewardBgReceived
    : isNextReceive ? rewardBgNextReceive
    : canReceive ? rewardBgCanReceive
    : rewardBg
  let children = [
    slotType == SLOT_COMMON ? null
      : bigSlotImage.__merge({ color = !isReceived && slotType == SLOT_HUGE ? hugeRewardBgColor : bg.fillColor })
    slotType == SLOT_HUGE ? null
      : {
          size = flex()
          clipChildren = true
          children = isReceived ? highlightReceived
            : isNextReceive ? highlightNextReceive
            : canReceive ? highlightCanReceive
            : highlight
        }
    @() {
      watch = reward
      key = $"rewardImg_{needReceiveAnim}"
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkRewardImage(reward.value, slotType == SLOT_HUGE ? bigImageSize : imageSize)
      transform = {}
      animations = !needReceiveAnim ? null
        : [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.25, 1.25], duration = receiveAnimItemTime,
             play = true, easing = CosineFull }]
    }
    !isReceived ? null
      : {
          key = needReceiveAnim
          size = flex(),
          rendObj = ROBJ_SOLID,
          color = 0x80000000
          opacity = 1.0
          animations = !needReceiveAnim ? null
            : [
                { prop = AnimProp.opacity, from = 0.0, to = 0.0,
                  duration = receiveAnimItemTime, play = true }
                { prop = AnimProp.opacity, from = 0.0, duration = receiveAnimFadeTime,
                  delay = receiveAnimItemTime, easing = InOutQuad, play = true,
                  onFinish = @() lastShowedReceivedStage = max(lastShowedReceivedStage, stageIdx)
                }
              ]
        }
    mkDayText(dayText, isReceived)
    @() mkText(utf8ToUpper(getRewardName(reward.value)),
      {
        size = [flex(), buttonHeight]
        vplace = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = isReceived ? 0x80808080 : 0xFFFFFFFF
      }.__update(fontVeryTiny))
    isCurrentActivePlate ? buttonBlock(stateFlags) : null
    needReceiveAnim ? checkImgWithAnim
      : isReceived ? checkImg
      : null
  ]

  return @() {
    watch = stateFlags
    key = stageIdx
    size
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    padding = hdpx(2)
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = isCurrentActivePlate ? onActivePlateClick : null
    children = bg.__merge({ children })
  }.__update(animData)
}

let function itemsBlock() {
  let stageOffsetByAds = hasLoginAwardByAds.value ? -1 : 0
  let { lastRewardedStage = 0 } = loginAwardUnlock.value
  let { stages = [], stage = 0 } = getRelativeStageData(
    stageOffsetByAds == 0 || loginAwardUnlock.value == null ? loginAwardUnlock.value
      : loginAwardUnlock.value.__merge({
          stage = loginAwardUnlock.value.stage + stageOffsetByAds
          lastRewardedStage = min(lastRewardedStage, loginAwardUnlock.value.stage + stageOffsetByAds)
        }))
  if (stages.len() == 0)
    return { watch = loginAwardUnlock }
  if ((stages.len() % FULL_DAYS) != 0)
    logerr($"Everyday login unlock stages count should be multiple of 14, but current stages count is {stages.len()}")

  let stageOffset = loginAwardUnlock.value.stage - stage + stageOffsetByAds
  local currentFull = max(loginAwardUnlock.value.current, loginAwardUnlock.value?.stage ?? 0) //for this unlock progress is equal real allowed stage
  let startStage = ((lastRewardedStage - stageOffset + stageOffsetByAds) / FULL_DAYS).tointeger() * FULL_DAYS
  let startStageFull = startStage + stageOffset
  let lastRewardedStageInPeriod = lastRewardedStage - startStageFull

  let curPeriodStages = stages.slice(startStage, startStage + FULL_DAYS)

  if (lastRewardedStageInPeriod > 2 || lastPeriodStartStage == null) { //no more need to store previous stages
    lastPeriodStartStage = startStageFull
    lastPeriodStages = curPeriodStages
  }
  let prevStages = lastPeriodStartStage < startStageFull ? lastPeriodStages : []
  let animState = debugAnimState.value
    ?? (lastRewardedStageInPeriod < 7 ? BEFORE_7_DAY : AFTER_7_DAY)

  if (animState != lastAnimState) {
    let receiveDelay = lastShowedReceivedStage >= lastRewardedStage - 1 ? 0.1 : completeAnimDelay
    animStateStartTime = lastAnimState < 0 ? 0 : get_time_msec() + (1000 * receiveDelay).tointeger()
    lastAnimState = animState
  }

  if (lastShowedReceivedStage < 0)
    lastShowedReceivedStage = lastRewardedStage - 1

  return {
    watch = [loginAwardUnlock, debugAnimState, hasLoginAwardByAds]
    size = itemBlockSize
    key = itemBlockSize
    children =
      prevStages
        .map(@(stageData, idx)
          mkReward(idx, stageData, idx + lastPeriodStartStage, currentFull, lastRewardedStage, AFTER_14_DAY))
        .reverse()
        .extend(curPeriodStages
          .map(@(stageData, idx)
            mkReward(idx, stageData, idx + startStageFull, currentFull, lastRewardedStage, animState))
          .reverse())
  }
}

let content = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    itemsBlock
    mkText(loc("dailyRewards/desc"),
      { vplace = ALIGN_BOTTOM, hplace = ALIGN_CENTER, color = commonTextColor }.__update(fontTiny))
  ]
}

let awardScene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    header
    content
  ]
  animations = wndSwitchAnim
})

registerScene("loginAwardWnd", awardScene, close, isLoginAwardOpened)

register_command(
  function() {
    debugAnimState(((debugAnimState.value ?? -1) + 1) % (AFTER_14_DAY + 1))
    log("debugState set to: ", debugAnimState.value)
  },
  "debug.everydayAwardAnimationTest")
register_command(
  function() {
    debugAnimState(null)
    log("debugState set to: ", debugAnimState.value)
  },
  "debug.everydayAwardAnimationTestOff")
