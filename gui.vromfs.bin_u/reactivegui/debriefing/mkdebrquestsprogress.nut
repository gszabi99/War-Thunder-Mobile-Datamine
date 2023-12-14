from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")

let progressFillTime = 1.0
let completedTxtBlinkTime = 0.25
let completedTxtDelayTime = progressFillTime - completedTxtBlinkTime
let completedTxtScale = 1.2

let progressBarW = hdpxi(660)
let progressBarH = hdpxi(28)
let progressBarBorderWidth = hdpx(3)
let progressBarBgColor = 0x80000000
let progressBarFillOldColor = 0xFF2EC181
let progressBarFillNewColor = 0xFFBAEBD5
let progressBarBorderColor = 0xFF606060

let function mkQuestTitle(quest) {
  let isAchievement = quest.meta?.achievement ?? false
  let locId = quest.meta?.lang_id ?? quest.name
  let text = loc(isAchievement ? $"{locId}/desc" : locId)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXT
    text
    behavior = Behaviors.Marquee
    speed = hdpx(30)
    delay = defMarqueeDelay
  }.__update(fontTinyAccented)
}

let function mkQuestProgressBar(quest, delay) {
  let { name = "", required = 1, current = 0, _previous = 0 } = quest
  let percentOld = _previous.tofloat() / required
  let percentNew = current.tofloat() / required
  let progressWidthOld = round(progressBarW * percentOld)
  let progressWidthNew = max(progressWidthOld + 1, round(progressBarW * percentNew))
  let initialScale = progressWidthOld / progressWidthNew
  return {
    rendObj = ROBJ_BOX
    size = [progressBarW, progressBarH]
    fillColor = progressBarBgColor
    borderWidth = progressBarBorderWidth
    borderColor = progressBarBorderColor
    children = [
      {
        rendObj = ROBJ_BOX
        size = [progressWidthNew, progressBarH]
        fillColor = progressBarFillNewColor
        key = $"progress_{name}"
        transform = { pivot = [0, 0] }
        animations = [
          { prop = AnimProp.scale, from = [initialScale, 1], to = [initialScale, 1],
            duration = delay, play = true }
          { prop = AnimProp.scale, from = [initialScale, 1], to = [1, 1], delay,
            duration = progressFillTime, easing = Linear, play = true }
        ]
      }
      {
        rendObj = ROBJ_BOX
        size = [progressWidthOld, progressBarH]
        fillColor = progressBarFillOldColor
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        text = $"{current}/{required}"
        padding = [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let mkCompletedTxt = @(quest, delay) !(quest?.isCompleted ?? false) ? null : {
  pos = [pw(100), 0]
  vplace = ALIGN_CENTER
  padding = [0, 0, 0, hdpx(30)]
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(loc("quests/completed"))

  key = $"completed_{quest?.name}"
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0,
      duration = delay + completedTxtDelayTime, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay = delay + completedTxtDelayTime,
      duration = completedTxtBlinkTime, easing = Linear, play = true }
    { prop = AnimProp.scale, from = [completedTxtScale, completedTxtScale],
      to = [completedTxtScale, completedTxtScale],
      duration = delay + completedTxtBlinkTime, play = true }
    { prop = AnimProp.scale, from = [completedTxtScale, completedTxtScale],
      to = [1, 1], delay = delay + completedTxtDelayTime,
      duration = completedTxtBlinkTime, easing = InQuad, play = true }
  ]
}.__update(fontSmall)

let function mkQuestComp(quest, delay) {
  let { current = 0, _previous = 0 } = quest
  let diff = current - _previous
  return {
    size = [progressBarW, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(2)
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          mkQuestTitle(quest)
          {
            rendObj = ROBJ_TEXT
            text = $"+{diff}"
          }.__update(fontTiny)
        ]
      }
      {
        size = [progressBarW, progressBarH]
        children = [
          mkQuestProgressBar(quest, delay)
          mkCompletedTxt(quest, delay)
        ]
      }
    ]
  }
}

let function mkQuestSortingInfo(quest) {
  let { isCompleted = false, current = 0, _previous = 0, required = 1, name = "" } = quest
  let completion = current.tofloat() / required
  let growthPerMission = (current.tofloat() - _previous) / required
  let predictedMissionsLeft = (required - current).tofloat() / max(1, current - _previous)
  return {
    quest
    isCompleted
    predictedMissionsLeft
    completion
    growthPerMission
    required
    name
  }
}

let sortQuests = @(a, b)
  b.isCompleted <=> a.isCompleted
  || a.predictedMissionsLeft <=> b.predictedMissionsLeft
  || b.completion <=> a.completion
  || b.growthPerMission <=> a.growthPerMission
  || b.required <=> a.required
  || a.name <=> b.name

let function mkDebrQuestsProgress(debrData, delay) {
  let { quests = {} } = debrData
  let hasContent = quests.len() != 0
  return {
    questsProgressComps = hasContent
      ? quests.values().map(@(v) mkQuestSortingInfo(v)).sort(sortQuests).map(@(v) mkQuestComp(v.quest, delay))
      : null
    questsProgressShowTime = hasContent
      ? progressFillTime
      : 0
  }
}

return mkDebrQuestsProgress
