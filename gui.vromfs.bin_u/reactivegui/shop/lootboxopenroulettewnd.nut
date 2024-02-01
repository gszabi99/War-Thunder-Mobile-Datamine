from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[Roulette] ")
let { resetTimeout, defer, deferOnce, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { rnd_int } = require("dagor.random")
let { playSound, startSound, stopSound } = require("sound_wt")
let { lerpClamped, cos, sin, PI, pow } = require("%sqstd/math.nut")
let ln = require("math").log
let { registerScene, scenesOrder } = require("%rGui/navState.nut")
let { rouletteOpenId, rouletteOpenType, rouletteOpenResult, nextOpenCount, curJackpotInfo,
  rouletteRewardsList, receivedRewardsCur, receivedRewardsAll, rouletteOpenIdx, nextFixedReward,
  isCurRewardFixed, requestOpenCurLootbox, closeRoulette, lastJackpotIdx, logOpenConfig,
  rouletteLastReward, isRouletteDebugMode
} = require("lootboxOpenRouletteState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { delayUnseedPurchaseShow, skipUnseenMessageAnimOnce } = require("%rGui/shop/unseenPurchasesState.nut")
let { REWARD_STYLE_MEDIUM, mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { addCompToCompAnim } = require("%darg/helpers/compToCompAnim.nut")
let { mkLensFlareLootbox } = require("%rGui/effects/mkLensFlare.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { opacityAnim, lightAnim } = require("lootboxOpenRouletteAnims.nut")
let lootboxOpenRouletteConfig = require("lootboxOpenRouletteConfig.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")

let markSize = evenPx(40)
let markMaxOffset = hdpx(20)
let slotsGap = evenPx(10)
let slotPadding = hdpxi(30)
let progressbarWidth = hdpx(550)
let progressbarHeight = hdpx(14)
let openCountIconSize = hdpxi(30)

let RS_IDLE_ROLL = "RS_IDLE_ROLL"
let RS_ROLL = "RS_ROLL" //roll to start slowdown
let RS_SLOWDOWN = "RS_SLOWDOWN"
let RS_SLOW = "RS_SLOW"
let RS_PRECISE_REVERSE = "RS_PRECISE_REVERSE" //only for move back for presize
let RS_PRECISE = "RS_PRECISE"
let RS_STOP = "RS_STOP"
let RS_REWARD_NO_ROLL = "RS_REWARD_NO_ROLL"

let aTimeRewardScale = 0.6
let aTimeRewardMove = 0.3
let delayBeforeClose = 0.5
let aTimeFixedRewardScale = 1.0

let aTimeHighlight = 0.9
let aTimeDelayJackpotProgress = 0.1

let rewardBoxSize = REWARD_STYLE_MEDIUM.boxSize
let rewardBoxGap = REWARD_STYLE_MEDIUM.boxGap

let REWARD_RESULT_ANIM_KEY = {}
let FIXED_REWARD_ANIM_KEY = {}
let getRewardResultKey = @(idx) $"reward_result_{idx}"

let resultVisibleIdx = Watched(-1)
let recevedRewardAnimIdx = Watched(-1)
let isReceivedAnimFixed = Watched(false)
let isReceivedAnimLast = Watched(false)
let resultOffsetIdx = Watched(-1)
let curRewardViewInfo = Computed(@() receivedRewardsCur.value?.viewInfo ?? [])
let receiveRewardsAnimViewInfo = Computed(@() receivedRewardsAll.value?[recevedRewardAnimIdx.value].viewInfo?[0])
let needHighlight = Watched(receiveRewardsAnimViewInfo.value != null)
let openConfig = Computed(@() lootboxOpenRouletteConfig?[rouletteOpenType.value]
  ?? lootboxOpenRouletteConfig.roulette_short)

function isReceivedSame(received, rewardInfo) {
  foreach(rec in received)
    foreach(info in rewardInfo)
      if (info.id == rec.id && info.rType == rec.rType && info.count == rec.count)
        return true //support only single reward drop from lootboxes atm.
  return false
}

let allowedResultIndexes = Computed(function() {
  if (rouletteOpenResult.value == null)
    return null
  let res = {}
  let isFit = {}
  let received = curRewardViewInfo.value
  foreach(idx, rew in rouletteRewardsList.value) {
    if (rew not in isFit)
      isFit[rew] <- isReceivedSame(received, rew)
    if (isFit[rew])
      res[idx] <- true
  }
  return res
})

let isResultLastReward = Computed(function() {
  if (rouletteOpenResult.value == null || (allowedResultIndexes.value?.len() ?? 0) > 0
      || rouletteLastReward.value == null)
    return false
  return isReceivedSame(curRewardViewInfo.value, rouletteLastReward.value)
})

receiveRewardsAnimViewInfo.subscribe(function(v) {
  if (v != null)
    needHighlight(true)
})
resultVisibleIdx.subscribe(function(v) {
  if (v != recevedRewardAnimIdx.value)
    needHighlight(false)
  resultOffsetIdx(max(resultOffsetIdx.value, v))
})
recevedRewardAnimIdx.subscribe(function(v) {
  if (v >= 0) {
    isReceivedAnimFixed(isCurRewardFixed.value)
    isReceivedAnimLast(isResultLastReward.value)
  }
  resultOffsetIdx(max(resultOffsetIdx.value, v))
})

let WND_UID = "lootboxOpenRouletteWindow"
rouletteOpenId.subscribe(function(v) {
  if (v != null)
    return
  resultVisibleIdx(-1)
  recevedRewardAnimIdx(-1)
  resultOffsetIdx(-1)
})

allowedResultIndexes.subscribe(function(v) {
  if (rouletteOpenId.value == null || v == null || v.len() > 0 || isResultLastReward.value)
    return
  log($"Not found received reward to show in the roulette '{rouletteOpenId.value}': ", curRewardViewInfo.value)
  logOpenConfig()
  logerr("Not found received reward to show in the roulette")
  defer(closeRoulette)
})

rouletteOpenResult.subscribe(function(v) {
  if (v == null)
    return
  resetTimeout(openConfig.value.BACKUP_CLOSE_TIME * max(1, receivedRewardsAll.value.len()), closeRoulette)  // in case of broken animation events
  skipUnseenMessageAnimOnce(true)
})

let calcSlowdown = @(t, a, b) a - a * pow(2.71828, b * t)

function fillSlowdownPoints(state, allowedIndexes) {
  if (allowedIndexes.len() == 0) {
    if (!isResultLastReward.value)
      state.status <- RS_STOP
    return
  }

  local { speed = 1.0, offset = 0.0, fullSize, sizes, SLOWDOWN_TIME, MIN_SLOW_MOVE_SPEED,
    MAX_STOP_BORDER_OFFSET_PART, SLOWEST_COUNT_MIN, SLOWEST_COUNT_MAX
  } = state
  let total = sizes.len()
  let slowdownB = ln(MIN_SLOW_MOVE_SPEED / speed) / SLOWDOWN_TIME
  let slowdownA = - speed / slowdownB
  let slowdownDist = calcSlowdown(SLOWDOWN_TIME, slowdownA, slowdownB)
  local slowStartOffset = offset + slowdownDist
  local curIndex = 0
  local slowStartIndex = 0
  local tgtIndex = -1
  let isMoveBack = !rnd_int(0, 1).tointeger()
  let slowestCount = rnd_int(SLOWEST_COUNT_MIN, SLOWEST_COUNT_MAX).tointeger()

  //search slowStartIndex for slowdown target
  let minOffset = slowStartOffset % fullSize
  let circles = ((slowStartOffset - minOffset) / fullSize).tointeger()
  local offsetSum = 0.0
  foreach(idx, s in sizes) {
    offsetSum += s
    if (offsetSum < offset)
      curIndex++
    if (offsetSum < minOffset)
      continue
    slowStartOffset = offsetSum + fullSize * circles
    slowStartIndex = idx + total * circles
    break
  }

  let endIndex = slowStartIndex + slowestCount + total + 1
  for(local i = slowStartIndex + slowestCount + 1; i < endIndex; i++)
    if (allowedIndexes?[i % total]) {
      tgtIndex = i
      break
    }
  if (tgtIndex < 0) {
    log($"Roulette cant find cur index: slowStartIndex = {slowStartIndex} + {slowestCount}, endIndex = {endIndex}, total = {total}, allowedIndexes = ",
      allowedIndexes)
    logerr("Not found target index for roulette animation")
    tgtIndex = slowStartIndex + slowestCount
  }

  let newSlowStartIndex = tgtIndex - slowestCount
  for(local i = slowStartIndex; i < newSlowStartIndex; i++)
    slowStartOffset += sizes[i % total]

  local sum = 0
  let sizesSum = array(tgtIndex + 2).map(function(_, idx) {
    sum += sizes[idx % total]
    return sum
  })

  local finalOffset = sizesSum[tgtIndex - 1]
  local stopOffset = finalOffset + (isMoveBack ? sizes[tgtIndex % total] : 0)
  finalOffset += 0.5 * sizes[tgtIndex % total]

  if (isMoveBack)
    stopOffset -= rnd_int(0, MAX_STOP_BORDER_OFFSET_PART * sizes[(tgtIndex - 1) % total])

  let sizeOccurs = sizes
    .reduce(function(res, s) {
      res[s] <- (res?[s] ?? 0) + 1
      return res
    }, {})
  local commonSize = null
  local commonSizeOccur = null
  foreach(size, occur in sizeOccurs)
    if (commonSize == null || commonSizeOccur < occur) {
      commonSize = size
      commonSizeOccur = occur
    }

  let curTime = get_time_msec()
  let rollDist = slowStartOffset - offset - slowdownDist
  let rollTime = rollDist / speed
  let slowTime = (stopOffset - slowStartOffset) / MIN_SLOW_MOVE_SPEED

  state.__update({
    curIndex
    tgtIndex

    rollStartTime = curTime
    rollStartOffset = offset

    slowdownStartTime = curTime + (1000 * rollTime).tointeger()
    slowdownStartOffset = offset + rollDist
    slowdownA
    slowdownB

    slowStartTime = curTime + (1000 * (rollTime + SLOWDOWN_TIME)).tointeger()
    slowStartOffset

    precizeStartTime = curTime + (1000 * (rollTime + SLOWDOWN_TIME + slowTime)).tointeger()
    precizeStartOffset = stopOffset
    finalOffset

    sizesSum
    slowestCount
    commonSize

    isLastReward = (receivedRewardsAll.value.len() - 1) == rouletteOpenIdx.value
    openIdx = rouletteOpenIdx.value
  })
}

function updateCurIndex(state) {
  let { curIndex, offset, sizesSum } = state
  local idx = curIndex
  for(local i = curIndex; i < sizesSum.len(); i++) {
    idx = i
    if (sizesSum[idx] >= offset)
      break
  }
  let next = sizesSum[idx]
  let slotOffset = sizesSum?[idx - 1] ?? 0
  let slotSize = next - slotOffset
  state.curIndex <- idx
  state.slotOffset <- slotOffset
  state.slotSize <- slotSize
  return { slotOffset, slotSize }
}

function getSlotAddOffset(slotOffset, slotSize, state) {
  let a = 2.0 * PI / slotSize
  let { MIN_FINAL_BORDER_SPEED, MIN_SLOW_MOVE_SPEED } = state
  return (MIN_FINAL_BORDER_SPEED - MIN_SLOW_MOVE_SPEED) / MIN_SLOW_MOVE_SPEED / a * sin(a * slotOffset)
}

function switchStatusToPrecise(state, precizeStartTime, slotSize) {
  let { isLastReward } = state
  state.status <- RS_PRECISE
  state.slotPrecisePeriod <- slotSize / state.MIN_SLOW_MOVE_SPEED
  state.precizeStartTime <- precizeStartTime
  state.precizeTime <- state.PRECIZE_PERIODS * state.slotPrecisePeriod
  state.rewardAnimTime <- isLastReward ? state.precizeTime : 0.25 * state.slotPrecisePeriod
  state.nextRewardTime <- isLastReward ? -1 : 0.5 * state.slotPrecisePeriod
}

function switchStatusToPreciseReverse(state, precizeRevStartTime, slotOffset, slotSize) {
  let a = 2.0 * PI / slotSize
  let { MIN_FINAL_BORDER_SPEED, MIN_SLOW_MOVE_SPEED } = state
  let speed = (MIN_FINAL_BORDER_SPEED - MIN_SLOW_MOVE_SPEED) / MIN_SLOW_MOVE_SPEED * cos(a * slotOffset)
  let maxOffset = slotSize - slotOffset
  local stopTime = 0.05
  local amplitude = 0.0
  if (speed > 0 && maxOffset > 0) {
    stopTime = 2 * PI * maxOffset / speed
    amplitude = maxOffset
  }

  state.status <- RS_PRECISE_REVERSE
  state.precizeRevStartTime <- precizeRevStartTime
  state.precizeStartTime <- precizeRevStartTime + (2000 * stopTime).tointeger()
  state.preciseRevAmplitude <- amplitude
  state.preciseRevAngle <- 2 * PI / stopTime
}

let startReceivedRewardAnim = @(openIdx) defer(function() {
  recevedRewardAnimIdx(openIdx)
  playSound("meta_roulette_cell_up")
})

let updAnimByStatus = {
  [RS_IDLE_ROLL] = function(dt, state) {
    local { speed = 0.0, offset = 0.0, fullSize, halfViewSize, startTime,
      MAX_SPEED, ACCELERATION, MIN_ROLL_TIME
    } = state
    state.speed <- min(MAX_SPEED, speed + dt * ACCELERATION)
    offset += dt * state.speed
    state.offset <- offset > fullSize + halfViewSize ? (offset % fullSize) : offset

    if (isCurRewardFixed.value || isResultLastReward.value) {
      if (rouletteOpenIdx.value == state?.lastFixedIdx || recevedRewardAnimIdx.value >= 0)
        return
      if (rouletteOpenIdx.value != state?.waitFixedIdx) {
        state.startTime = get_time_msec()
        state.waitFixedIdx <- rouletteOpenIdx.value
        return
      }

      if (get_time_msec() - startTime < 1000 * state.MIN_ROLL_TIME_NEXT_FIXED_REWARD)
        return
      startReceivedRewardAnim(rouletteOpenIdx.value)
      state.lastFixedIdx <- rouletteOpenIdx.value
      state.startTime = get_time_msec()
      return
    }

    if (!allowedResultIndexes.value || (get_time_msec() - startTime) < 1000 * MIN_ROLL_TIME)
      return

    state.status <- RS_ROLL
    fillSlowdownPoints(state, allowedResultIndexes.value)
    if (isRouletteDebugMode.get())
      logR("State after fillSlowdownPoints: ", state)
  },

  [RS_ROLL] = function(_, state) {
    let { time, rollStartOffset, slowdownStartOffset, rollStartTime, slowdownStartTime } = state
    state.offset <- lerpClamped(rollStartTime, slowdownStartTime, rollStartOffset, slowdownStartOffset, time)

    if (time < slowdownStartTime)
      return 0

    state.status <- RS_SLOWDOWN
    stopSound("meta_roulette_spin")
    state.rollSoundFinishTime <- time + (1000 * state.STOP_ROLL_SOUND_TIME).tointeger()
    return 0.001 * (time - slowdownStartTime)
  },

  [RS_SLOWDOWN] = function(dt, state) {
    let { time, slowdownStartOffset, slowdownA, slowdownB,
      slowdownStartTime, slowStartTime, prevBaseOffset = 0,
      MIN_SLOW_MOVE_SPEED
    } = state
    let t = 0.001 * (time - slowdownStartTime)
    let baseOffset = slowdownStartOffset + calcSlowdown(t, slowdownA, slowdownB)
    state.offset <- baseOffset
    state.prevBaseOffset <- baseOffset
    if (dt > 0 && prevBaseOffset > 0) {
      let speed = (baseOffset - prevBaseOffset) / dt
      let { slotOffset, slotSize } = updateCurIndex(state)
      let slotAddOffset = getSlotAddOffset(baseOffset - slotOffset, slotSize, state)
      state.offset += slotAddOffset * MIN_SLOW_MOVE_SPEED / speed
    }

    if (time < slowStartTime)
      return 0

    state.status <- RS_SLOW
    state.speed <- state.MIN_FINAL_BORDER_SPEED
    return 0.001 * (time - slowStartTime)
  },

  [RS_SLOW] = function(_, state) {
    let { time, slowStartOffset, precizeStartOffset, slowStartTime, precizeStartTime } = state
    state.offset <- lerpClamped(slowStartTime, precizeStartTime, slowStartOffset, precizeStartOffset, time)
    let { slotOffset, slotSize } = updateCurIndex(state)
    let slotAddOffset = getSlotAddOffset(state.offset - slotOffset, slotSize, state)
    state.offset += slotAddOffset

    if (time < precizeStartTime)
      return 0

    if (state.finalOffset > precizeStartOffset)
      switchStatusToPrecise(state, precizeStartTime, slotSize)
    else
      switchStatusToPreciseReverse(state, precizeStartTime, slotOffset, slotSize)
    return 0.001 * (time - precizeStartTime)
  },

  [RS_PRECISE_REVERSE] = function(_, state) {
    let { time, precizeStartOffset, precizeRevStartTime, precizeStartTime, preciseRevAngle, preciseRevAmplitude } = state
    let timeSec = 0.001 * (time - precizeRevStartTime)
    state.offset <- precizeStartOffset + max(0.0, preciseRevAmplitude * sin(preciseRevAngle * timeSec))

    if (time < precizeStartTime)
      return 0

    switchStatusToPrecise(state, precizeStartTime, updateCurIndex(state).slotSize)
    return 0.001 * (time - precizeStartTime)
  },

  [RS_PRECISE] = function(_, state) {
    let { time, precizeStartOffset, finalOffset, precizeStartTime, precizeTime, slotPrecisePeriod,
      rewardAnimTime, nextRewardTime, openIdx
    } = state
    updateCurIndex(state) //need for correct arrow update
    let timeSec = 0.001 * (time - precizeStartTime)
    let timeMul = timeSec > precizeTime ? 0.0 : 1.0 - timeSec / precizeTime
    let amplitude = timeMul * timeMul * (precizeStartOffset - finalOffset)
    state.offset <- finalOffset + amplitude * cos(2 * PI * timeSec / slotPrecisePeriod)

    if (rewardAnimTime != null && timeSec >= rewardAnimTime) {
      startReceivedRewardAnim(openIdx)
      state.rewardAnimTime <- null
    }

    if (nextRewardTime > 0 && timeSec >= nextRewardTime) {
      let { MIN_ROLL_TIME, MIN_ROLL_TIME_NEXT } = state
      state.status = RS_IDLE_ROLL
      state.speed = 0.0
      state.startTime = get_time_msec() + (1000 * (MIN_ROLL_TIME_NEXT - MIN_ROLL_TIME)).tointeger()
      rouletteOpenIdx(openIdx + 1)
    } else if (timeSec >= precizeTime)
      state.status <- RS_STOP
  },

  [RS_REWARD_NO_ROLL] = function(_, state) {
    let { time, rewardNoRollTime = null, nextRewardTime = null } = state
    if (rewardNoRollTime != null && time >= rewardNoRollTime) {
      let isLastReward = (receivedRewardsAll.value.len() - 1) == rouletteOpenIdx.value
      state.rewardNoRollTime <- null
      state.openIdx <- rouletteOpenIdx.value
      startReceivedRewardAnim(rouletteOpenIdx.value)
      if (isLastReward)
        state.status = RS_STOP
      else
        state.nextRewardTime <- time + (1000 * state.WAIT_ANIM_NO_ROOL_REWARD).tointeger()
    }

    if (rewardNoRollTime == null && nextRewardTime != null && time >= nextRewardTime) {
      let { MIN_ROLL_TIME, MIN_ROLL_TIME_NEXT } = state
      state.status = RS_IDLE_ROLL
      state.speed = 0.0
      state.startTime = get_time_msec() + (1000 * (MIN_ROLL_TIME_NEXT - MIN_ROLL_TIME)).tointeger()
      rouletteOpenIdx((state?.openIdx ?? rouletteOpenIdx.value) + 1)
    }
  },
}

function updateArrowDeviation(dt, state) {
  let { slotSize, slotOffset = 0.0, offset = 0.0, curIndex = 0, prevIndex = 0, arrowDev = 1.0,
    ARROW_DROP_SPEED
  } = state
  state.prevIndex <- curIndex
  if (prevIndex != curIndex) {
    state.arrowDev <- 1.0
    let { time, rollSoundFinishTime = null } = state
    if (rollSoundFinishTime != null && rollSoundFinishTime < time)
      playSound("meta_roulette_cell_click")
    return
  }
  let rel = (offset - slotOffset) / slotSize
  let dev = rel <= 0 ? 1.0
    : rel < 0.05 ? 1.0 - 20.0 * rel
    : rel < 0.85 ? 0.0
    : rel < 1 ? (rel - 0.85) / 0.15
    : 1.0

  state.arrowDev <- arrowDev <= dev ? dev
    : max(dev, arrowDev - ARROW_DROP_SPEED * dt * (state.arrowDev - dev))
}

function updateAnimState(state) {
  let curTime = get_time_msec()
  local { time = curTime, status = RS_IDLE_ROLL } = state
  state.time <- curTime
  let dt = 0.001 * (curTime - time)
  if (dt == 0) {
    state.startTime <- curTime
    return
  }

  let dtLeft = updAnimByStatus?[status](dt, state)
  if ((dtLeft ?? 0) > 0) {
    if (isRouletteDebugMode.get())
      logR($"dtLeft = {dtLeft} on status {state.status} (curTime = {curTime}, dt = {dt})")
    let dtLeft2 = updAnimByStatus?[state.status](dtLeft, state)
    if ((dtLeft2 ?? 0) > 0 && isRouletteDebugMode.get())
      logR($"dtLeft2 = {dtLeft2} on status {state.status} (curTime = {curTime}, dt = {dt})")
  }
  else if (isRouletteDebugMode.get() && status != (state?.status ?? RS_IDLE_ROLL))
    logR($"status changed to {state.status} without dtLeft (curTime = {curTime}, dt = {dt})")

  if ("slotSize" in state)
    updateArrowDeviation(dt, state)
}

let slotBgImgSize = hdpxi(20)
let slotOfs = [hdpxi(9), hdpxi(9)]
let slotBg = {
  padding = slotPadding
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#roulette_slot_bg.svg:{slotBgImgSize}:{slotBgImgSize}:P")
  texOffs = slotOfs
  screenOffs = slotOfs
}

let mkSlot = @(children) {
  padding = [0, slotsGap / 2]
  children = slotBg.__merge({ children })
}

let emptySlot = { size = array(2, rewardBoxSize) }
let markTop = {
  size = [markSize, markSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#roulette_pointer.svg:{markSize}:{markSize}:P")
  keepAspect = true
}
let markBottom = markTop.__merge({ flipY = true })

let highlightH = 9 * rewardBoxSize
let highlightW = 2 * highlightH
let highlight = @() {
  key = {}
  size = [highlightW, highlightH]
  rendObj = ROBJ_IMAGE
  color = 0x00FFC040
  image = Picture("ui/images/effects/searchlight_earth_flare.avif:0:P")
  opacity = 0
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, easing = CosineFull,
      duration = aTimeHighlight, play = true }
    { prop = AnimProp.scale, from = [0.1, 0.1], to = [1.0, 1.0],
      duration = aTimeHighlight, play = true }
  ]
}

function onRewardScaleFinish(viewInfo, rewardIdx) {
  addCompToCompAnim({
    component = mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM)
    from = isReceivedAnimFixed.value ? FIXED_REWARD_ANIM_KEY : REWARD_RESULT_ANIM_KEY
    to = getRewardResultKey(rewardIdx)
    easing = InOutQuad
    duration = aTimeRewardMove
  })

  resetTimeout(aTimeRewardMove, @() resultVisibleIdx(max(rewardIdx, resultVisibleIdx.value)))
  if (rewardIdx >= receivedRewardsAll.value.len() - 1)
    resetTimeout(aTimeRewardMove + delayBeforeClose, closeRoulette)
  else if (rouletteOpenIdx.value == rewardIdx && (isReceivedAnimFixed.value || isReceivedAnimLast.value))
    rouletteOpenIdx(rewardIdx + 1)
  recevedRewardAnimIdx(-1)
}

let receiveRewardAnimBlock = @(viewInfo, rewardIdx, key, duration)
  mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM,
    {
      key
      transform = {}
      animations = [{ prop = AnimProp.scale, to = [1.3, 1.3], easing = CosineFull,
        duration, play = true,
        onFinish = @() onRewardScaleFinish(viewInfo, rewardIdx)
      }]
    })

function rouletteRewardsBlock() {
  if (rouletteRewardsList.value.len() < 2)
    return { watch = rouletteRewardsList }

  let midIdx = rouletteRewardsList.value.len() / 2
  let children = []
  let sizes = []
  local fullSize = 0
  local halfSize = 0
  let sizesTbl = {}
  let compsTbl = {}
  foreach(idx, rew in rouletteRewardsList.value) {
    if (rew not in compsTbl)
      compsTbl[rew] <- mkSlot(rew.len() == 0 ? emptySlot : mkRewardPlate(rew[0], REWARD_STYLE_MEDIUM))
    let comp = compsTbl[rew]
    if (rew not in sizesTbl)
      sizesTbl[rew] <- calc_comp_size(comp)[0]
    children.append(comp)
    sizes.append(sizesTbl[rew])
    fullSize += sizesTbl[rew]
    if (idx == midIdx - 1)
      halfSize = fullSize
  }

  let halfViewSize = sw(50)
  let openCount = rouletteOpenResult.value ? receivedRewardsAll.value.len() : nextOpenCount.value
  local state = openConfig.value.__merge(
    openCount <= 1 ? {} : (openConfig.value?.multiOpenOvr ?? {}),
    { //no need to subscribe on openConfig due to itnot should be change on the full roulette anim
      fullSize
      halfViewSize
      offset = sizes[0] / 2
      speed = 0.0
      sizes
    })

  if (compsTbl.len() == 1) //only single reward
    state.__update({
      status = RS_REWARD_NO_ROLL
      rewardNoRollTime = get_time_msec() + (1000 * state.MIN_WAIT_NO_ROOL_REWARD).tointeger()
    })

  local recalcCounter = 0
  function recalcOnce() {
    if (recalcCounter == 0)
      updateAnimState(state)
    recalcCounter = (recalcCounter + 1) % 4
  }

  return {
    watch = rouletteRewardsList
    key = rouletteRewardsList
    size = [sw(100), rewardBoxSize + 2 * slotPadding + 2 * slotsGap]
    function onAttach() {
      if (isRouletteDebugMode.get())
        logR($"Roulette attached")
      startSound("meta_roulette_spin")
    }
    onDetach = @() stopSound("meta_roulette_spin")
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    animations = opacityAnim
    children = [
      {
        hplace = ALIGN_LEFT
        flow = FLOW_HORIZONTAL
        children = children.slice(0, midIdx)
        transform = {}
        behavior = Behaviors.RtPropUpdate
        function update() {
          recalcOnce()
          let offset = state.offset % fullSize
          let pos = -offset + halfSize >= -halfViewSize ? 0 : fullSize
          return { transform = { translate = [-offset + pos + halfViewSize, 0] } }
        }
      }
      {
        hplace = ALIGN_LEFT
        flow = FLOW_HORIZONTAL
        children = children.slice(midIdx)
        transform = {}
        behavior = Behaviors.RtPropUpdate
        function update() {
          recalcOnce()
          let offset = state.offset % fullSize
          let pos = -offset >= -halfViewSize ? -fullSize : 0
          return { transform = { translate = [-offset + halfSize + pos + halfViewSize, 0] } }
        }
      }
      {
        vplace = ALIGN_BOTTOM
        pos = [0, ph(-100)]
        children = markTop
        transform = {}
        behavior = Behaviors.RtPropUpdate
        function update() {
          recalcOnce()
          let { arrowDev = 1.0 } = state
          return { transform = { translate = [0, -markMaxOffset * arrowDev] } }
        }
      }
      {
        vplace = ALIGN_TOP
        pos = [0, ph(100)]
        children = markBottom
        transform = {}
        behavior = Behaviors.RtPropUpdate
        function update() {
          recalcOnce()
          let { arrowDev = 1.0 } = state
          return { transform = { translate = [0, markMaxOffset * arrowDev] } }
        }
      }
      @() {
        watch = [needHighlight, isReceivedAnimFixed]
        children = needHighlight.value && !isReceivedAnimFixed.value ? highlight : null
      }
      @() {
        watch = [recevedRewardAnimIdx, receiveRewardsAnimViewInfo, isReceivedAnimFixed]
        children = receiveRewardsAnimViewInfo.value == null || isReceivedAnimFixed.value ? null
          : receiveRewardAnimBlock(receiveRewardsAnimViewInfo.value, recevedRewardAnimIdx.value,
              REWARD_RESULT_ANIM_KEY, aTimeRewardScale)
      }
    ]
  }
}

function receivedRewardsBlock() {
  let viewInfos = receivedRewardsAll.value.map(@(r) r.viewInfo[0])
  let widthSum = []
  local visibleWidth = 0
  for(local i = 0; i <= resultOffsetIdx.value; i++) {
    widthSum.append(visibleWidth)
    let { slots = 0 } = viewInfos?[i]
    visibleWidth += slotsGap + slots * rewardBoxSize + (slots - 1) * rewardBoxGap
  }

  let offsetVisible = - visibleWidth / 2 + slotsGap / 2
  let posInvisible = - offsetVisible + slotsGap
    - 0.5 * (rewardBoxSize + rewardBoxGap) * (viewInfos?[resultOffsetIdx.value + 1].slots ?? 0)
    + 0.5 * rewardBoxGap

  return {
    watch = [receivedRewardsAll, rouletteOpenResult, resultVisibleIdx, resultOffsetIdx]
    size = [0, rewardBoxSize]
    hplace = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = !rouletteOpenResult.value || receivedRewardsAll.value.len() == 0 ? null
      : viewInfos.map(@(viewInfo, idx)
          mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM,
            {
              key = getRewardResultKey(idx)
              opacity = idx <= resultVisibleIdx.value ? 1 : 0
              transform = {
                translate = [idx <= resultOffsetIdx.value ? offsetVisible + widthSum[idx] : posInvisible, 0]
              }
              transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = InOutQuad }]
            }))
  }
}

let progressTrigger = {}
let progressAnimations = [{
  prop = AnimProp.scale, from = [1.0, 1.0], to = [1.6, 1.6],
  duration = 0.5, trigger = progressTrigger, easing = Blink
}]

let mkOpenCountText = @(text, count) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
    }.__update(fontTiny)
    {
      size = [openCountIconSize, openCountIconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#events_chest_icon.svg:{openCountIconSize}:{openCountIconSize}:P")
      keepAspect = true
      transform = { pivot = [1.0, 0.5] }
      animations = progressAnimations
    }
    {
      rendObj = ROBJ_TEXT
      text = count
      minWidth = hdpx(50)
      transform = { pivot = [0.0, 0.5] }
      animations = progressAnimations
    }.__update(fontTiny)
  ]
}

let progressbar = @(value) {
  rendObj = ROBJ_BOX
  size = [progressbarWidth, progressbarHeight]
  margin = [hdpx(12), 0]
  fillColor = 0x80000000
  borderWidth = hdpx(2)
  padding = hdpx(2)
  borderColor = premiumTextColor
  children = [
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = 0xFFFFFFFF
      transform = {
        scale = [value, 1.0]
        pivot = [0, 0]
      }
      transitions = [{ prop = AnimProp.scale, duration = 0.1, easing = InOutQuad }]
    }
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = premiumTextColor
      transform = {
        scale = [value, 1.0]
        pivot = [0, 0]
      }
      transitions = [{ prop = AnimProp.scale, duration = 1.3, easing = InOutQuad }]
    }
  ]
}

let fixedRewardCurrent = Computed(@()
  max(lastJackpotIdx.value,
    (nextFixedReward.value?.current ?? -1) + (rouletteOpenIdx.value == resultOffsetIdx.value ? 0 : -1)))
let fixedRewardTotal = Computed(@() (nextFixedReward.value?.total ?? 1))

local lastFixedRewardCurrent = fixedRewardCurrent.value
function startOpenCountAnim() {
  if (lastFixedRewardCurrent == fixedRewardCurrent.value)
    return
  if (lastFixedRewardCurrent >= 0)
    anim_start(progressTrigger)
  lastFixedRewardCurrent = fixedRewardCurrent.value
}
fixedRewardCurrent.subscribe(@(_) deferOnce(startOpenCountAnim))

let fixedProgressInfo = @() {
  watch = [fixedRewardCurrent, fixedRewardTotal]
  size = [progressbarWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    mkOpenCountText(loc("lootbox/totalOpened"), fixedRewardCurrent.value)
    mkOpenCountText(loc("events/jackpot"), fixedRewardTotal.value - fixedRewardCurrent.value)
    progressbar(fixedRewardCurrent.value.tofloat() / fixedRewardTotal.value)
  ]
}

let isJackpotFinalProgress = Watched(false)
let showJackpotFinalProgress = @() isJackpotFinalProgress(true)
function onJackpotInfoChange(v) {
  isJackpotFinalProgress(false)
  if (v != null)
    resetTimeout(aTimeDelayJackpotProgress, showJackpotFinalProgress)
  else
    clearTimer(showJackpotFinalProgress)
}
onJackpotInfoChange(curJackpotInfo.value)
curJackpotInfo.subscribe(onJackpotInfoChange)
let jackpotProgressInfo = @(startIdx, openIdx) @() {
  watch = isJackpotFinalProgress
  key = isJackpotFinalProgress
  size = [progressbarWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), openCountIconSize]
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = {
        rendObj = ROBJ_TEXT
        text = loc("jackpot/received")
        transform = {}
        animations = [
          { prop = AnimProp.scale, to = [1.1, 1.1],
            duration = 2.0, easing = CosineFull, play = true, loop = true, globalTimer = true }
        ]
      }.__update(fontBig)
    }
    progressbar(isJackpotFinalProgress.value ? 1.0 : startIdx.tofloat() / openIdx)
  ]
}

let fixedRewardIcon = @(viewInfo) {
  children = [
    @() {
      watch = [needHighlight, isReceivedAnimFixed]
      size = flex()
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = needHighlight.value && isReceivedAnimFixed.value ? highlight : null
    }
    mkRewardPlate(viewInfo, REWARD_STYLE_MEDIUM)
    @() {
      watch = [recevedRewardAnimIdx, receiveRewardsAnimViewInfo, isReceivedAnimFixed]
      children = receiveRewardsAnimViewInfo.value == null || !isReceivedAnimFixed.value ? null
        : receiveRewardAnimBlock(receiveRewardsAnimViewInfo.value, recevedRewardAnimIdx.value,
            FIXED_REWARD_ANIM_KEY, aTimeFixedRewardScale)
    }
  ]
}

let nextFixedViewInfo = Computed(@() nextFixedReward.value?.viewInfo)
let fixedRewardInfo = @() {
  watch = [curJackpotInfo, nextFixedViewInfo]
  size = [SIZE_TO_CONTENT, rewardBoxSize]
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = slotsGap
  children = curJackpotInfo.value != null ? jackpotProgressInfo(curJackpotInfo.value.startIdx, curJackpotInfo.value.openIdx)
    : nextFixedViewInfo.value != null
      ? [
          fixedProgressInfo
          nextFixedViewInfo.value[0].rType == "lootbox" ? null //jackpot, no need icon
            : fixedRewardIcon(nextFixedViewInfo.value[0])
        ]
    : null
}

let lightBlock = {
  size = [sw(100), rewardBoxSize + 2 * slotPadding + slotsGap]
  pos = [0, slotsGap / 2]
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = 0xFFFFFFFF
  opacity = 0.0
  transform = {}
  animations = lightAnim
}

let rouletteWnd = @() {
  key = {}
  size = flex()

  function onAttach() {
    resetTimeout(openConfig.value.BACKUP_CLOSE_TIME * max(1, receivedRewardsAll.value.len()), closeRoulette) // in case of broken animation events
    requestOpenCurLootbox()
    delayUnseedPurchaseShow(100)
  }
  onDetach = @() delayUnseedPurchaseShow(0)

  behavior = Behaviors.Button
  onDoubleClick = closeRoulette

  flow = FLOW_VERTICAL
  padding = [rewardBoxSize, 0, 0, 0]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = markSize + markMaxOffset + 3 * slotsGap
  children = [
    receivedRewardsBlock
    {
      children = [
        rouletteRewardsBlock
        lightBlock
        {
          size = flex()
          pos = [0, -hdpx(20)]
          children = mkLensFlareLootbox()
        }
      ]
    }
    fixedRewardInfo
  ]
}

let lootboxWnd = @() {
  watch = scenesOrder
  key = WND_UID
  size = flex()
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FILL
  image = Picture("ui/images/event_bg.avif")
  color = 0xFFFFFFFF
  onClick = @() null
  children = {
    size = flex()
    children = rouletteWnd
    animations = scenesOrder.value?[0] == "eventWnd" ? wndSwitchAnim : null
  }
  animations = scenesOrder.value?[0] == "eventWnd" ? null : wndSwitchAnim
}

registerScene("lootboxOpenRoulette", lootboxWnd, closeRoulette, keepref(Computed(@() rouletteOpenId.value != null)), true)
