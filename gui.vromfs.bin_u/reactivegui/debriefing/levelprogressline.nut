from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { playSound, startSound, stopSound } = require("sound_wt")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkLevelBg, mkProgressLevelBg, maxLevelStarChar, playerExpColor,
  levelProgressBarWidth, levelProgressBarFillWidth, rotateCompensate
} = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { unitPlateWidth } = require("%rGui/unit/components/unitPlateComp.nut")

let levelBlockSize = hdpx(60)

let nextLevelBorderColor = 0xFFDADADA
let nextLevelBgColor = 0xFF464646
let nextLevelTextColor = 0xFFFFFFFF
let receivedExpProgressColor = 0xFFFFFFFF
let levelUpTextColor = 0xFF000000

let rewardAnimTime = 0.5
let levelProgressSingleAnimTime = 0.5
let maxLevelProgressAnimTime = 1.5

let starLevelOvr = { pos = [0, ph(40)] }

let mkCurLevelMark = @(lineColor, level, starLevel) {
  size = array(2, levelBlockSize)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLevelBg({ childOvr = { borderColor = lineColor } })
    {
      rendObj = ROBJ_TEXT
      pos = [0, -hdpx(2)]
      text = level - starLevel
    }.__update(fontSmall)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

let mkNextLevelMark = @(nextStarLevel, textBlockOvr, bgBlockOvr) {
  size = array(2, levelBlockSize)
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLevelBg({ childOvr = bgBlockOvr })
    {
      rendObj = ROBJ_TEXT
      pos = [0, -hdpx(2)]
    }.__update(fontSmall, textBlockOvr)
    starLevelTiny(nextStarLevel, starLevelOvr)
  ]
}

let mkNextLevelTextAnimations = @(levelProgressDelay, levelProgressAnimTime, trigger) [
  {
    prop = AnimProp.color, from = nextLevelTextColor,
    to = nextLevelTextColor, duration = levelProgressDelay + levelProgressAnimTime,
    play = true
  }
  {
    prop = AnimProp.color, from = nextLevelTextColor,
    to = levelUpTextColor, duration = levelProgressAnimTime * 0.5,
    easing = InQuad, trigger
  }
]

let mkNextLevelBgAnimations = @(levelProgressDelay, levelProgressAnimTime, trigger) [
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

let function levelLineSound(soundEndTime) {
  startSound("exp_bar")
  resetTimeout(soundEndTime, stopLevelLineSound)
}

let mkLevelLineProgress = @(curLevelIdxWatch, levelUpsArray, lineColor, animStartTime) function() {
  let { curLevel, curStarLevel, isLevelUpCurStep, isLastLevelCurStep, curExpWidth, receivedExpWidth,
    isStarProgress
  } = levelUpsArray[curLevelIdxWatch.get()]

  let stepsCount = levelUpsArray.len()
  let levelProgressAnimTime = (stepsCount - 1) == curLevelIdxWatch.get() ? levelProgressSingleAnimTime
    : min((maxLevelProgressAnimTime - levelProgressSingleAnimTime) / (stepsCount - 1), levelProgressSingleAnimTime)
  let levelProgressDelay = curLevelIdxWatch.get() == 0 ? animStartTime : 0
  let animationTrigger = $"progressFillFinished_{lineColor}"
  let nextStarLevel = isStarProgress ? curStarLevel + 1 : 0
  return {
    watch = curLevelIdxWatch
    size = [levelProgressBarWidth + 2 * rotateCompensate * levelBlockSize, SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    onDetach = stopLevelLineSound
    children = [
      mkProgressLevelBg({
        pos = [levelBlockSize * rotateCompensate, 0]
        children = [
          {
            key = $"line_{levelUpsArray[curLevelIdxWatch.get()]}"
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
                onStart = @() levelLineSound(levelProgressAnimTime),
                onFinish = function() {
                  if (isLevelUpCurStep)
                    anim_start(animationTrigger)
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
      mkCurLevelMark(lineColor, curLevel, curStarLevel)
      mkNextLevelMark(
        nextStarLevel,
        {
          text = isLastLevelCurStep ? maxLevelStarChar : curLevel + 1 - nextStarLevel
          color = isLevelUpCurStep ? levelUpTextColor : nextLevelTextColor
          animations = mkNextLevelTextAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
        },
        {
          fillColor = isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
          borderColor = nextLevelBorderColor
          transform = {}
          animations = mkNextLevelBgAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
        })
    ]
  }
}

let function mkLevelProgressLine(curLevelConfig, reward, text, animStartTime , lineColor = playerExpColor, override = {}) {
  let { exp = 0, level = 1, starLevel = 0, isStarProgress = false,
    nextLevelExp = 0, isLastLevel = false, levelsExp = []
  } = curLevelConfig
  if (nextLevelExp == 0)
    return {
      levelProgressLineComp = null
      levelProgressLineAnimTime = 0
    }

  let { totalExp = 0 } = reward
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)
  let levelUpsArray = [{
    curLevel = level
    curStarLevel = starLevel
    isStarProgress
    isLevelUpCurStep = isLevelUp
    isLastLevelCurStep = "starLevel" not in curLevelConfig && isLastLevel //no need to show star for player level. But still has star for unit level
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
        isStarProgress
        isLevelUpCurStep = levelExp <= leftReceivedExp
        isLastLevelCurStep = (idx + 1) not in levelsExp
        curExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, 0)
        receivedExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, leftReceivedExp)
      })
      leftReceivedExp = leftReceivedExp - levelExp
    }
  }
  let levelProgressLineAnimTime = min(levelUpsArray.len() * levelProgressSingleAnimTime, maxLevelProgressAnimTime)
  let fullLevelDelayAnimTime = animStartTime + levelProgressLineAnimTime
  let curLevelIdxWatch = Watched(0)
  let levelProgressLineComp = {
    size = [unitPlateWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj = ROBJ_TEXT
        text = text
      }.__update(fontTiny)
      mkLevelLineProgress(curLevelIdxWatch, levelUpsArray, lineColor, animStartTime)
      {
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = expTextStarSize
        valign = ALIGN_CENTER
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
          {
            prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad
            duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime
          }
        ]
        children = isLevelUp ? mkTextUnderLevelLine(utf8ToUpper(loc("debriefing/newLevel")), lineColor,
            { animations = [
                {
                  prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                  delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up")
                }
              ]
              transform = { pivot = [1.0, 1.0] } })
          : addExp > 0 ? mkExpText(addExp, lineColor)
          : totalExp > 0 ? mkTextUnderLevelLine(loc("debriefing/lostExp"), lineColor)
          : null
      }
    ]
  }.__update(override)

  return {
    levelProgressLineComp
    levelProgressLineAnimTime
  }
}

return mkLevelProgressLine
