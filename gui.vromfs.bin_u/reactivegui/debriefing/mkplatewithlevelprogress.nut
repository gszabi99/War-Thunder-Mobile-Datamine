from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { playSound, startSound, stopSound } = require("sound_wt")
let { lerpClamped } = require("%sqstd/math.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { maxLevelStarChar } = require("%rGui/components/levelBlockPkg.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitRank, unitPlateRatio, plateTextsSmallPad,
  unitBgImageBase, bgUnit, mkPlateText, unitPlateNameOvr
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getSlotLevelIcon } = require("%rGui/attributes/slotAttr/slotLevelComp.nut")
let { getLevelProgress, getNextUnitLevelWithRewards } = require("%rGui/debriefing/debrUtils.nut")
let { mkTotalRewardCountsUnit } = require("totalRewardCounts.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")

let plateW = hdpx(350)
let plateH = plateW * unitPlateRatio

let slotLevelBoxSize = [evenPx(120), evenPx(40)]
let slotLevelIconSize = evenPx(45)

let unitLevelBlockSize = evenPx(46)
let levelBlockBorderWidth = hdpx(3)
let levelProgressBarHeight = hdpx(12)
let levelProgressBarWidth = plateW
let levelProgressBarFillWidth = levelProgressBarWidth

let levelTextColor = 0xFFFFFFFF
let levelUpTextColor = 0xFF000000
let levelProgressBgColor = 0xFF808080
let receivedExpProgressColor = 0xFFFFFFFF
let nextLevelBgColor = 0xFF2B2B2B
let slotLevelBoxOutlineColor = 0xFFA5A5A5
let expRewardBoxColor = 0xFF434343

let rewardAnimTime = 0.5
let singleStepAnimTime = 0.5
let maxTotalAnimTime = 1.5

let mkSlotLevelBg = @(ovr = {}) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(3)
  color = slotLevelBoxOutlineColor
  fillColor = nextLevelBgColor
  commands = [[VECTOR_POLY, 0, 100, 20, 0, 100, 0, 100, 100, 0, 100]]
}.__update(ovr)

let mkUnitLevelBg = @(childOvr = {}) {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = { rotate = 45 }
  children = {
    size = flex()
    rendObj = ROBJ_BOX
    fillColor = nextLevelBgColor
    borderWidth = levelBlockBorderWidth
  }.__update(childOvr)
}

let mkProgressLevelBg = @(override = {}) {
  size = [levelProgressBarWidth, levelProgressBarHeight]
  rendObj = ROBJ_SOLID
  hplace = ALIGN_LEFT
  color = levelProgressBgColor
}.__update(override)

let starLevelOvr = { pos = [0, ph(56)] }
let rankOvr = { padding = [plateTextsSmallPad * 0.5, plateTextsSmallPad + unitLevelBlockSize * 1.6] }

let mkUnitPlateBase = @(unit, _campaign) {
  size = [ plateW, plateH ]
  children = [
    mkUnitBg(unit)
    mkUnitImage(unit)
    mkUnitRank(unit, rankOvr)
    mkUnitTexts(unit, loc(getUnitPresentation(unit).locId))
  ]
}

let slotBg = unitBgImageBase.__merge({ image = bgUnit })
let slotImgByCampaign = {
  air = "ui/gameuiskin#upgrades_plane_crew.avif"
  tank = "ui/gameuiskin#upgrades_tank_crew_icon.avif"
}
let mkSlotImg = @(campaign) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(slotImgByCampaign?[campaign] ?? slotImgByCampaign.tank)
  keepAspect = true
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

let mkSlotPlateBase = @(slot, campaign) {
  size = [ plateW, plateH ]
  children = [
    slotBg
    mkSlotImg(campaign)
    mkPlateText(loc("gamercard/slot/title", { idx = (slot?.slotIdx ?? 0) + 1 }), unitPlateNameOvr)
  ]
}

let mkCurLevelTextAnimations = @(stepAnimDelay, stepAnimTime, trigger) [
  {
    prop = AnimProp.color, from = levelTextColor,
    to = levelTextColor, duration = stepAnimDelay + stepAnimTime,
    play = true
  }
  {
    prop = AnimProp.color, from = levelTextColor,
    to = levelUpTextColor, duration = stepAnimTime * 0.5,
    easing = InQuad, trigger
  }
]

let mkCurLevelBgAnimations = @(stepAnimDelay, stepAnimTime, trigger, blinkSize) [
  {
    prop = AnimProp.fillColor, from = nextLevelBgColor,
    to = nextLevelBgColor, duration = stepAnimDelay + stepAnimTime,
    play = true
  }
  {
    prop = AnimProp.fillColor, from = nextLevelBgColor,
    to = receivedExpProgressColor, duration = stepAnimTime * 0.5,
    easing = InQuad, trigger
  }
  {
    prop = AnimProp.scale, from = [1.0, 1.0], to = [blinkSize, blinkSize], easing = Blink,
    duration = stepAnimTime * 0.5, trigger
  }
]

let mkLevelStatusText = @(text, isOpaque, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = text
  color = 0xFFFFFFF
  opacity = isOpaque ? 1 : 0.35
}.__update(fontVeryTinyShaded, override)

let expTextStarSize = hdpx(25)

let mkExpText = @(exp, color) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [0, hdpx(5), 0, 0]
  flow = FLOW_HORIZONTAL
  gap = hdpx(3)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = "+"
    }.__update(fontTiny)
    {
      size = [expTextStarSize, expTextStarSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#experience_icon.svg:{expTextStarSize}:{expTextStarSize}:P")
      color
    }
    {
      rendObj = ROBJ_TEXT
      text = exp
    }.__update(fontTiny)
  ]
}

let stopLevelLineSound = @() stopSound("exp_bar")

function levelLineSound(soundEndTime) {
  startSound("exp_bar")
  resetTimeout(soundEndTime, stopLevelLineSound)
}

let mkProgressBar = @(animId, curLevelIdxWatch, levelUpsArray, lineColor) function() {
  let { isLevelUpCurStep, isMaxLevel, curExpWidth, receivedExpWidth
    stepAnimTime, stepAnimDelay, levelSplashAnimTrigger
  } = levelUpsArray[curLevelIdxWatch.get()]

  return mkProgressLevelBg({
    watch = curLevelIdxWatch
    children = [
      {
        key = $"line_{animId}_{levelUpsArray[curLevelIdxWatch.get()]}"
        size = [receivedExpWidth, flex()]
        rendObj = ROBJ_SOLID
        color = receivedExpProgressColor
        transform = { pivot = [0, 0] }
        animations = isMaxLevel ? null : [
          {
            prop = AnimProp.scale, from = [0.0, 0.0],
            to = [0.0, 0.0], duration = stepAnimDelay,
            play = true
          }
          {
            prop = AnimProp.scale, from = [curExpWidth.tofloat() / (receivedExpWidth || 1), 1.0],
            to = [1.0, 1.0], duration = stepAnimTime, delay = stepAnimDelay,
            easing = InOutQuart, play = true,
            onStart = @() levelLineSound(stepAnimTime),
            function onFinish() {
              if (isLevelUpCurStep) {
                anim_start(levelSplashAnimTrigger)
              }
              if (levelUpsArray.len() > (curLevelIdxWatch.get() + 1))
                curLevelIdxWatch.set(curLevelIdxWatch.get() + 1)
            }
          }
        ]
      }
      {
        size = [curExpWidth, flex()]
        rendObj = ROBJ_SOLID
        color = lineColor
      }
    ]
  })
}

let mkSlotPlateLevelComp = @(animId, curLevelIdxWatch, levelUpsArray, lineColor) function() {
  let { curLevel, isLevelUpPrevSteps, isLevelUpCurStep,
    stepAnimTime, stepAnimDelay, levelSplashAnimTrigger
  } = levelUpsArray[curLevelIdxWatch.get()]

  return {
    watch = curLevelIdxWatch
    key = $"line_{animId}"
    onAttach = @() curLevelIdxWatch.set(0)
    onDetach = stopLevelLineSound
    size = slotLevelBoxSize
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    margin = [hdpx(2), hdpx(2)]
    children = [
      mkSlotLevelBg({
        fillColor = isLevelUpPrevSteps || isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
        transform = {}
        animations = mkCurLevelBgAnimations(stepAnimDelay, stepAnimTime, levelSplashAnimTrigger, 1.2)
      })
      {
        size = [slotLevelIconSize, slotLevelIconSize]
        pos = [hdpx(22), 0]
        rendObj = ROBJ_IMAGE
        hplace = ALIGN_LEFT
        color = lineColor
        image = Picture($"{getSlotLevelIcon(curLevel)}:{slotLevelIconSize}:{slotLevelIconSize}:P")
        keepAspect = true
      }
      {
        pos = [hdpx(29), -hdpx(2)]
        rendObj = ROBJ_TEXT
        text = curLevel
        color = isLevelUpPrevSteps || isLevelUpCurStep ? levelUpTextColor : levelTextColor
        animations = mkCurLevelTextAnimations(stepAnimDelay, stepAnimTime, levelSplashAnimTrigger)
      }.__update(fontTinyAccented)
    ]
  }
}

let mkUnitPlateLevelComp = @(animId, curLevelIdxWatch, levelUpsArray, lineColor) function() {
  let { curLevel, curStarLevel, isLevelUpPrevSteps, isLevelUpCurStep, isMaxLevel
    stepAnimTime, stepAnimDelay, levelSplashAnimTrigger
  } = levelUpsArray[curLevelIdxWatch.get()]

  return {
    watch = curLevelIdxWatch
    key = $"line_{animId}"
    onAttach = @() curLevelIdxWatch.set(0)
    onDetach = stopLevelLineSound
    size = [unitLevelBlockSize, unitLevelBlockSize]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    margin = [hdpx(20), hdpx(15)]
    children = [
      mkUnitLevelBg({
        fillColor = isLevelUpPrevSteps || isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
        borderColor = lineColor
        transform = {}
        animations = mkCurLevelBgAnimations(stepAnimDelay, stepAnimTime, levelSplashAnimTrigger, 1.5)
      })
      {
        pos = [0, -hdpx(2)]
        rendObj = ROBJ_TEXT
        text = isMaxLevel ? maxLevelStarChar : (curLevel - curStarLevel)
        color = isLevelUpPrevSteps || isLevelUpCurStep ? levelUpTextColor : levelTextColor
        animations = mkCurLevelTextAnimations(stepAnimDelay, stepAnimTime, levelSplashAnimTrigger)
      }.__update(fontTinyAccented)
      starLevelTiny(curStarLevel, starLevelOvr)
    ]
  }
}

let mkPlateWithProgress = @(animId, curLevelIdxWatch, levelUpsArray, lineColor, plateBaseComp, plateLevelCompCtor) {
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    {
      size = [ plateW, plateH ]
      vplace = ALIGN_BOTTOM
      children = [
        plateBaseComp
        plateLevelCompCtor(animId, curLevelIdxWatch, levelUpsArray, lineColor)
      ]
    }
    mkProgressBar(animId, curLevelIdxWatch, levelUpsArray, lineColor)
  ]
}

function mkPlateWithLevelProgress(debrData, levelCfg, reward, animStartTime, lineColor) {
  let { campaign = "", unitWeaponry = {} } = debrData
  let { name = "", exp = 0, level = 0, starLevel = 0, isStarProgress = false,
    nextLevelExp = 0, levelsExp = [], modPresetCfg = {}, isSlot = false, slotIdx = 0
  } = levelCfg

  let animId = isSlot ? $"exp_slot{slotIdx}" : $"exp_{name}"

  let isMaxLevel = nextLevelExp == 0
  let { totalExp = 0 } = reward
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)

  let unlockedLevel = isLevelUp
    ? getLevelProgress(levelCfg, reward).unlockedLevel
    : level
  let nextLevelWithRewards = isMaxLevel ? 0
    : isSlot ? (level + 1)
    : getNextUnitLevelWithRewards(level + 1, levelsExp.len(), modPresetCfg, unitWeaponry?[name])
  let hasLevelUnlockRewards = isLevelUp && nextLevelWithRewards <= unlockedLevel

  let levelUpsArray = [{
    curLevel = level
    curStarLevel = starLevel
    isLevelUpPrevSteps = false
    isLevelUpCurStep = isLevelUp
    isMaxLevel
    curExpWidth = isMaxLevel
      ? levelProgressBarFillWidth
      : lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp)
    receivedExpWidth = isMaxLevel
      ? levelProgressBarFillWidth
      : lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp + totalExp)
  }]
  if (isLevelUp && levelsExp.len() > 0) {
    local leftReceivedExp = totalExp - addExp
    for (local idx = 0; idx < levelsExp.len() + 1; idx++) {
      if (level >= idx)
        continue

      let isMaxLevelStep = idx == levelsExp.len()
      let levelExp = isMaxLevelStep ? levelsExp[idx - 1] : levelsExp[idx]

      levelUpsArray.append({
        curLevel = idx
        curStarLevel = isStarProgress ? starLevel + idx - level : 0
        isLevelUpPrevSteps = isLevelUp
        isLevelUpCurStep = !isMaxLevelStep && levelExp <= leftReceivedExp
        isMaxLevel = isMaxLevelStep
        curExpWidth = isMaxLevelStep
          ? lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, exp)
          : 0
        receivedExpWidth = isMaxLevelStep
          ? levelProgressBarFillWidth
          : lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, leftReceivedExp)
      })
      leftReceivedExp -= levelExp
      if (leftReceivedExp <= 0)
        break
    }
  }
  let stepsCount = levelUpsArray.len()
  levelUpsArray.each(@(v, idx) v.__update({
    stepAnimTime = (stepsCount - 1) == idx ? singleStepAnimTime
      : min((maxTotalAnimTime - singleStepAnimTime) / (stepsCount - 1), singleStepAnimTime)
    stepAnimDelay = idx == 0 ? animStartTime : 0
    levelSplashAnimTrigger = $"levelSplash_{animId}"
  }))

  let levelProgressAnimTime = min(stepsCount * singleStepAnimTime, maxTotalAnimTime)
  let fullLevelDelayAnimTime = animStartTime + 0.5
  let curLevelIdxWatch = Watched(0)

  let key = {}
  let stateFlags = Watched(0)

  let plateBaseComp = @() {
      key
      watch = stateFlags
      behavior = Behaviors.Button
      onElemState = withTooltip(stateFlags, key, function mkTooltip() {
        let tooltipData = mkTotalRewardCountsUnit(debrData, 0.5, levelCfg)?.totalRewardCountsComp
        return tooltipData == null
          ? null
          : { content = tooltipData, flow = FLOW_HORIZONTAL }
      })
      onDetach = tooltipDetach(stateFlags)
      children = (isSlot ? mkSlotPlateBase : mkUnitPlateBase)(levelCfg, campaign)
    }

  let plateLevelCompCtor = isSlot ? mkSlotPlateLevelComp : mkUnitPlateLevelComp

  let statusAppearAnimations = [
    { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad,
      duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime }
  ]

  let plateWithLevelProgressComp = {
    size = [plateW, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      mkPlateWithProgress(animId, curLevelIdxWatch, levelUpsArray, lineColor, plateBaseComp, plateLevelCompCtor)
      {
        rendObj = ROBJ_SOLID
        color = expRewardBoxColor
        size = [plateW, hdpx(38)]
        children = addExp <= 0 ? null : {
          size = [plateW, SIZE_TO_CONTENT]
          key = $"level_exp_{animId}"
          transform = {}
          animations = statusAppearAnimations
          children = mkExpText(totalExp, lineColor)
        }
      }
      {
        size = [plateW, SIZE_TO_CONTENT]
        margin = [hdpx(10), 0]
        minHeight = expTextStarSize
        valign = ALIGN_CENTER
        key = $"level_status_{animId}"
        transform = {}
        animations = statusAppearAnimations
        flow = FLOW_VERTICAL
        children = isLevelUp && hasLevelUnlockRewards
            ? mkLevelStatusText(loc("debriefing/reachedLevelN", { level = unlockedLevel }), true,
                {
                  transform = { pivot = [0.0, 1.0] }
                  animations = [
                    { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                      delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up") }
                  ]
                })
          : isMaxLevel
            ? mkLevelStatusText(loc("battlepass/maxLevel"), false)
          : mkLevelStatusText(loc("debriefing/requiresLevelN", { level = nextLevelWithRewards }), false)
      }
    ]
  }

  return {
    plateWithLevelProgressComp
    levelProgressAnimTime
  }
}

return mkPlateWithLevelProgress
