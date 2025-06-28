from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { playSound, startSound, stopSound } = require("sound_wt")
let { lerpClamped } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getTextScaleToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { maxLevelStarChar } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelMedium } = require("%rGui/components/starLevel.nut")
let { doubleSideGradient } = require("%rGui/components/gradientDefComps.nut")

let levelBlockSize = hdpx(78)
let lightBorderWidth = hdpx(4)
let levelProgressBarHeight = hdpx(20)
let levelProgressBarWidth = hdpx(850)
let levelProgressBarFillWidth = levelProgressBarWidth
let iconPadlockW = hdpxi(38)
let iconPadlockH = hdpxi(62)
let rotateCompensate = 1.1

let levelUpTextColor = 0xFF000000
let levelBgColor = 0xFF000000
let levelProgressBgColor = 0xFF808080
let receivedExpProgressColor = 0xFFFFFFFF
let nextLevelBgColor = levelProgressBgColor
let nextLevelTextColor = levelBgColor

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
    borderWidth = lightBorderWidth
  }.__update(override?.childOvr ?? {})
}

let mkProgressLevelBg = @(override = {}) {
  size = [levelProgressBarWidth, levelProgressBarHeight]
  rendObj = ROBJ_SOLID
  hplace = ALIGN_LEFT
  color = levelProgressBgColor
}.__update(override)

let starLevelOvr = { pos = [0, ph(56)] }

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
    }.__update(fontMedium)
    starLevelMedium(starLevel, starLevelOvr)
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
    }.__update(fontMedium, textBlockOvr)
    starLevelMedium(nextStarLevel, starLevelOvr)
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
  size = FLEX_H
  maxWidth = hdpx(350)
  hplace = ALIGN_RIGHT
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

let mkLevelLineProgress = @(curLevelIdxWatch, isLevelupMomentWatch, levelUpsArray, lineColor, animStartTime) function() {
  let { curLevel, curStarLevel, isLevelUpCurStep, isLastLevelCurStep, curExpWidth, receivedExpWidth,
    isStarProgress, useLockIcon = false
  } = levelUpsArray[curLevelIdxWatch.get()]

  let stepsCount = levelUpsArray.len()
  let levelProgressAnimTime = (stepsCount - 1) == curLevelIdxWatch.get() ? levelProgressSingleAnimTime
    : min((maxLevelProgressAnimTime - levelProgressSingleAnimTime) / (stepsCount - 1), levelProgressSingleAnimTime)
  let levelProgressDelay = curLevelIdxWatch.get() == 0 ? animStartTime : 0
  let animationTrigger = $"progressFillFinished_{lineColor}"
  let nextStarLevel = isStarProgress ? curStarLevel + 1 : 0
  return {
    watch = curLevelIdxWatch
    key = $"line_{lineColor}"
    size = [levelProgressBarWidth + 2 * rotateCompensate * levelBlockSize, SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    onAttach = @() curLevelIdxWatch.set(0)
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
                onStart = function() {
                  levelLineSound(levelProgressAnimTime)
                  isLevelupMomentWatch.set(false)
                },
                onFinish = function() {
                  if (isLevelUpCurStep) {
                    anim_start(animationTrigger)
                    isLevelupMomentWatch.set(true)
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
      !useLockIcon
        ? mkCurLevelMark(lineColor, curLevel, curStarLevel)
        : null
      mkNextLevelMark(
        nextStarLevel,
        !useLockIcon
          ? {
              text = isLastLevelCurStep ? maxLevelStarChar : curLevel + 1 - nextStarLevel
              color = isLevelUpCurStep ? levelUpTextColor : nextLevelTextColor
              animations = mkNextLevelTextAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
            }
          : {
              children = @() {
                watch = isLevelupMomentWatch
                size = [iconPadlockW, iconPadlockH]
                rendObj = ROBJ_IMAGE
                image = isLevelupMomentWatch.get()
                  ? Picture($"ui/gameuiskin#padlock_open.svg:{iconPadlockW}:{iconPadlockH}")
                  : Picture($"ui/gameuiskin#padlock_closed.svg:{iconPadlockW}:{iconPadlockH}")
                color = isLevelUpCurStep ? levelUpTextColor : nextLevelTextColor
              }
              animations = mkNextLevelTextAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
            },
        {
          fillColor = isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
          borderWidth = 0
          transform = {}
          animations = mkNextLevelBgAnimations(levelProgressDelay, levelProgressAnimTime, animationTrigger)
        })
    ]
  }
}

let mkProgressTitle = @(text) {
  pos = [hdpx(85), hdpx(-15)]
  rendObj = ROBJ_TEXT
  text
}.__update(fontMedium)

let mkProgressDesc = @(text) doubleSideGradient.__merge({
  pos = [hdpx(39), hdpx(100)]
  padding = const [hdpx(5), hdpx(50)]
  children = {
    halign = ALIGN_LEFT
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(500)
    text
  }.__update(fontVeryTiny)
})

let levelUnlocksBarW = hdpx(400)
let levelUnlocksBarH = hdpx(64)

local levelUnlocksTexts = {}
function mkLevelUnlocksText(locId) {
  if (levelUnlocksTexts?[locId] == null) {
    let comp = {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(locId))
      color = nextLevelTextColor
    }.__update(fontSmall)
    let textWidthMax = levelUnlocksBarW - levelUnlocksBarH - hdpx(10)
    let textScale = getTextScaleToFitWidth(comp, textWidthMax)
    comp.__update({ transform = { pivot = [0.5, 0.5], scale = [textScale, textScale] } })
    levelUnlocksTexts[locId] <- comp
  }
  return levelUnlocksTexts[locId]
}

let mkLevelUnlocksBar = @(locId, lineColor, isLevelUp) {
  size = [levelUnlocksBarW, levelUnlocksBarH]
  rendObj = ROBJ_MASK
  image = Picture($"ui/gameuiskin#debr_level_unlocks_bar_mask.svg:{levelUnlocksBarW}:{levelUnlocksBarH}")
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = levelProgressBgColor
    }
    !isLevelUp ? null : {
      size = flex()
      rendObj = ROBJ_SOLID
      color = receivedExpProgressColor

      key = $"level_unlocks_bar_{lineColor}"
      transform = { pivot = [0, 0] }
      animations = [
        { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.5, play = true }
        { prop = AnimProp.scale, from = [0, 1], to = [1, 1], delay = 0.5, duration = 0.25, easing = Linear, play = true }
      ]
    }
    mkLevelUnlocksText(locId)
  ]
}

function mkLevelProgressLine(curLevelConfig, reward, title, desc, animStartTime, lineColor) {
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
    isLastLevelCurStep = "starLevel" not in curLevelConfig && isLastLevel 
    curExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp)
    receivedExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp + totalExp)
  }]
  if (isLevelUp && levelsExp.len() > 0) {
    local leftReceivedExp = totalExp - addExp
    foreach (idx, levelExp in levelsExp) {
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

      if (leftReceivedExp <= 0)
        break
    }
  }
  let levelProgressLineAnimTime = min(levelUpsArray.len() * levelProgressSingleAnimTime, maxLevelProgressAnimTime)
  let fullLevelDelayAnimTime = animStartTime + 0.5
  let curLevelIdxWatch = Watched(0)
  let isLevelupMomentWatch = Watched(false)
  let levelProgressLineComp = {
    size = const [SIZE_TO_CONTENT, hdpx(100)]
    children = [
      mkProgressTitle(title)
      {
        pos = [0, hdpx(30)]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          mkLevelLineProgress(curLevelIdxWatch, isLevelupMomentWatch, levelUpsArray, lineColor, animStartTime)
          mkLevelUnlocksBar("debriefing/levelUnlocks", lineColor, isLevelUp)
        ]
      }
      mkProgressDesc(desc)
      {
        size = [levelProgressBarWidth + hdpx(75), SIZE_TO_CONTENT]
        pos = [0, hdpx(100)]
        minHeight = expTextStarSize
        valign = ALIGN_CENTER
        key = $"level_status_{lineColor}"
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad,
            duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime }
        ]
        children = isLevelUp ? mkTextUnderLevelLine(utf8ToUpper(loc("debriefing/newLevel")), lineColor,
            {
              transform = { pivot = [1.0, 1.0] }
              animations = [
                { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                  delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up") }
              ]
            })
          : addExp > 0 ? mkExpText(addExp, lineColor)
          : totalExp > 0 ? mkTextUnderLevelLine(loc("debriefing/lostExp"), lineColor)
          : null
      }
    ]
  }

  return {
    levelProgressLineComp
    levelProgressLineAnimTime
  }
}

function mkResearchProgressLine(debrData, unitResearchInfo, title, desc, animStartTime, lineColor) {
  if (unitResearchInfo == null)
    return {
      researchProgressLineComp = null
      researchProgressLineAnimTime = 0
    }

  let { totalExp = 0 } = debrData?.reward.playerExp
  let { addExp, isUnlocked, exp, reqExp } = unitResearchInfo
  let levelUpData = {
    useLockIcon = true
    curLevel = 0
    curStarLevel = 0
    isStarProgress = false
    isLevelUpCurStep = isUnlocked
    isLastLevelCurStep = false
    curExpWidth = lerpClamped(0, reqExp, 0, levelProgressBarFillWidth, exp)
    receivedExpWidth = lerpClamped(0, reqExp, 0, levelProgressBarFillWidth, exp + addExp)
  }
  let researchProgressLineAnimTime = min(levelProgressSingleAnimTime, maxLevelProgressAnimTime)
  let fullLevelDelayAnimTime = animStartTime + 0.5
  let curLevelIdxWatch = Watched(0)
  let isLevelupMomentWatch = Watched(false)
  let researchProgressLineComp = {
    size = const [SIZE_TO_CONTENT, hdpx(100)]
    children = [
      mkProgressTitle(title)
      {
        pos = [0, hdpx(30)]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          mkLevelLineProgress(curLevelIdxWatch, isLevelupMomentWatch, [levelUpData], lineColor, animStartTime)
          mkLevelUnlocksBar("debriefing/researchUnlocks", lineColor, isUnlocked)
        ]
      }
      mkProgressDesc(desc)
      {
        size = [levelProgressBarWidth + hdpx(75), SIZE_TO_CONTENT]
        pos = [0, hdpx(100)]
        minHeight = expTextStarSize
        valign = ALIGN_CENTER
        key = $"research_status_{lineColor}"
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad,
            duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime }
        ]
        children = isUnlocked ? mkTextUnderLevelLine(utf8ToUpper(loc("debriefing/newUnitResearched")), lineColor,
            {
              transform = { pivot = [1.0, 1.0] }
              animations = [
                { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                  delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up") }
              ]
            })
          : addExp > 0 ? mkExpText(addExp, lineColor)
          : totalExp > 0 ? mkTextUnderLevelLine(loc("debriefing/lostExp"), lineColor)
          : null
      }
    ]
  }

  return {
    researchProgressLineComp
    researchProgressLineAnimTime
  }
}

return {
  mkLevelProgressLine
  mkResearchProgressLine
}
