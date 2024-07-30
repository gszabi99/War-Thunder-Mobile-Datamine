from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { playSound, startSound, stopSound } = require("sound_wt")
let { lerpClamped } = require("%sqstd/math.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")

let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, unitPlateRatio
} = require("%rGui/unit/components/unitPlateComp.nut")

let plateW = hdpx(350)
let plateH = plateW * unitPlateRatio

let levelBlockSize = evenPx(46)
let levelBlockBorderWidth = hdpx(3)
let levelProgressBarHeight = hdpx(12)
let levelProgressBarWidth = plateW
let levelProgressBarFillWidth = levelProgressBarWidth

let fadedTextColor = 0xFFACACAC
let levelTextColor = 0xFFFFFFFF
let levelUpTextColor = 0xFF000000
let levelBgColor = 0xFF000000
let levelProgressBgColor = 0xFF808080
let receivedExpProgressColor = 0xFFFFFFFF
let nextLevelBgColor = 0xFF33363A

let rewardAnimTime = 0.5
let levelProgressSingleAnimTime = 0.5
let maxLevelProgressAnimTime = 1.5

let mkLevelBg = @(override = {}) {
  size = flex()
  rendObj = ROBJ_SOLID
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFF000000
  transform = { rotate = 45 }
  children = {
    size = flex()
    rendObj = ROBJ_BOX
    fillColor = levelBgColor
    borderWidth = levelBlockBorderWidth
  }.__update(override?.childOvr ?? {})
}

let mkProgressLevelBg = @(override = {}) {
  size = [levelProgressBarWidth, levelProgressBarHeight]
  rendObj = ROBJ_SOLID
  hplace = ALIGN_LEFT
  color = levelProgressBgColor
}.__update(override)

let starLevelOvr = { pos = [0, ph(56)] }

let mkCurLevelMark = @(starLevel, textBlockOvr, bgBlockOvr) {
  size = array(2, levelBlockSize)
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [hdpx(20), hdpx(15)]
  children = [
    mkLevelBg({ childOvr = bgBlockOvr })
    {
      rendObj = ROBJ_TEXT
      pos = [0, -hdpx(2)]
    }.__update(fontTinyAccented, textBlockOvr)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

let mkCurLevelTextAnimations = @(levelProgressDelay, levelProgressAnimTime, trigger) [
  {
    prop = AnimProp.color, from = levelTextColor,
    to = levelTextColor, duration = levelProgressDelay + levelProgressAnimTime,
    play = true
  }
  {
    prop = AnimProp.color, from = levelTextColor,
    to = levelUpTextColor, duration = levelProgressAnimTime * 0.5,
    easing = InQuad, trigger
  }
]

let mkCurLevelBgAnimations = @(levelProgressDelay, levelProgressAnimTime, trigger) [
  {
    prop = AnimProp.fillColor, from = nextLevelBgColor,
    to = nextLevelBgColor, duration = levelProgressDelay + levelProgressAnimTime,
    play = true
  }
  {
    prop = AnimProp.fillColor, from = nextLevelBgColor,
    to = receivedExpProgressColor, duration = levelProgressAnimTime * 0.5,
    easing = InQuad, trigger
  }
  {
    prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], easing = Blink,
    duration = levelProgressAnimTime * 0.5, trigger
  }
]

let mkTextUnderLevelLine = @(text, color, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = text
  color
}.__update(fontVeryTiny, override)

let expTextStarSize = hdpx(35)

let mkExpText = @(exp, color) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  gap = hdpx(5)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"+ {exp}"
      color
    }.__update(fontTiny)
    {
      size = [expTextStarSize, expTextStarSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/gameuiskin#experience_icon.svg:{expTextStarSize}:{expTextStarSize}")
      color
    }
  ]
}

let stopLevelLineSound = @() stopSound("exp_bar")

function levelLineSound(soundEndTime) {
  startSound("exp_bar")
  resetTimeout(soundEndTime, stopLevelLineSound)
}

let mkLevelLineProgress = @(animId, unit, curLevelIdxWatch, levelUpsArray, lineColor, animStartTime) function() {
  let { curLevel, curStarLevel, isLevelUpPrevSteps, isLevelUpCurStep, curExpWidth, receivedExpWidth
  } = levelUpsArray[curLevelIdxWatch.get()]

  let stepsCount = levelUpsArray.len()
  let levelProgressAnimTime = (stepsCount - 1) == curLevelIdxWatch.get() ? levelProgressSingleAnimTime
    : min((maxLevelProgressAnimTime - levelProgressSingleAnimTime) / (stepsCount - 1), levelProgressSingleAnimTime)
  let levelProgressDelay = curLevelIdxWatch.get() == 0 ? animStartTime : 0
  let animationTrigger = $"progressFillFinished_{animId}"
  return {
    watch = curLevelIdxWatch
    key = $"line_{animId}"
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = @() curLevelIdxWatch.set(0)
    onDetach = stopLevelLineSound
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ plateW, plateH ]
        vplace = ALIGN_BOTTOM
        children = [
          mkUnitBg(unit)
          mkUnitImage(unit)
          mkUnitTexts(unit, loc(getUnitPresentation(unit).locId))
          mkCurLevelMark(curStarLevel,
            {
              text = curLevel - curStarLevel
              color = isLevelUpPrevSteps || isLevelUpCurStep ? levelUpTextColor : levelTextColor
              animations = mkCurLevelTextAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
            }
            {
              fillColor = isLevelUpPrevSteps || isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
              borderColor = lineColor
              transform = {}
              animations = mkCurLevelBgAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
            })
        ]
      }
      mkProgressLevelBg({
        children = [
          {
            key = $"line_{animId}_{levelUpsArray[curLevelIdxWatch.get()]}"
            size = [receivedExpWidth, flex()]
            rendObj = ROBJ_SOLID
            color = receivedExpProgressColor
            transform = { pivot = [0, 0] }
            animations = [
              {
                prop = AnimProp.scale, from = [0.0, 0.0],
                to = [0.0, 0.0], duration = levelProgressDelay,
                play = true
              }
              {
                prop = AnimProp.scale, from = [curExpWidth.tofloat() / (receivedExpWidth || 1), 1.0],
                to = [1.0, 1.0], duration = levelProgressAnimTime, delay = levelProgressDelay,
                easing = InOutQuart, play = true,
                onStart = function() {
                  levelLineSound(levelProgressAnimTime)
                },
                onFinish = function() {
                  if (isLevelUpCurStep) {
                    anim_start(animationTrigger)
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
    ]
  }
}

function mkUnitPlateWithLevelProgress(curLevelConfig, reward, animStartTime, lineColor) {
  let { name = "", exp = 0, level = 1, starLevel = 0, isStarProgress = false,
    nextLevelExp = 0, levelsExp = []
  } = curLevelConfig

  if (nextLevelExp == 0)
    return {
      unitPlateWithLevelProgressComp = null
      levelProgressAnimTime = 0
    }

  let { totalExp = 0 } = reward
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)
  let levelUpsArray = [{
    curLevel = level
    curStarLevel = starLevel
    isLevelUpPrevSteps = false
    isLevelUpCurStep = isLevelUp
    curExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp)
    receivedExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp + totalExp)
  }]
  if (isLevelUp && levelsExp.len() > 0) {
    local leftReceivedExp = totalExp - addExp
    foreach (idx, levelExp in levelsExp) {
      if (leftReceivedExp <= 0)
        break

      if (level >= idx)
        continue

      levelUpsArray.append({
        curLevel = idx
        curStarLevel = isStarProgress ? starLevel + idx - level : 0
        isLevelUpPrevSteps = isLevelUp
        isLevelUpCurStep = levelExp <= leftReceivedExp
        curExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, 0)
        receivedExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, leftReceivedExp)
      })
      leftReceivedExp = leftReceivedExp - levelExp
    }
  }
  let animId = $"exp_unit_{name}"
  let levelProgressAnimTime = min(levelUpsArray.len() * levelProgressSingleAnimTime, maxLevelProgressAnimTime)
  let fullLevelDelayAnimTime = animStartTime + 0.5
  let curLevelIdxWatch = Watched(0)

  let unitPlateWithLevelProgressComp = {
    size = [plateW, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      mkLevelLineProgress(animId, curLevelConfig, curLevelIdxWatch, levelUpsArray, lineColor, animStartTime)
      {
        size = [plateW, SIZE_TO_CONTENT]
        pos = [0, hdpx(100)]
        minHeight = expTextStarSize
        valign = ALIGN_CENTER
        key = $"level_status_{animId}"
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad,
            duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime }
        ]
        children = isLevelUp ? mkTextUnderLevelLine(loc("debriefing/newLevel"), lineColor,
            {
              transform = { pivot = [1.0, 1.0] }
              animations = [
                { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                  delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up") }
              ]
            })
          : addExp > 0 ? mkExpText(addExp, lineColor)
          : totalExp > 0 ? mkTextUnderLevelLine(loc("debriefing/lostExp"), lineColor)
          : mkTextUnderLevelLine(loc("debriefing/nextLevelUlocks"), fadedTextColor)
      }
    ]
  }

  return {
    unitPlateWithLevelProgressComp
    levelProgressAnimTime
  }
}

return {
  mkUnitPlateWithLevelProgress
}
