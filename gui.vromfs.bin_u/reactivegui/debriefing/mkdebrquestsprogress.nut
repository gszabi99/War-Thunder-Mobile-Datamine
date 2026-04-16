from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getEventPresentation } = require("%appGlobals/config/eventSeasonPresentation.nut")
let { withTooltip, tooltipDetach } = require("%rGui/tooltip.nut")
let { MAIN_EVENT_ID } = require("%rGui/unlocks/unlocksConst.nut")
let { getSpecialEventLocName } = require("%rGui/event/specialEventLocName.nut")

let progressFillTime = 0.5
let completedTxtBlinkTime = 0.25
let completedTxtDelayTime = progressFillTime - completedTxtBlinkTime
let completedTxtScale = 1.2

let completedLocText = utf8ToUpper(loc("quests/completed"))
let progressTextBase = {
  halign = ALIGN_RIGHT
  rendObj = ROBJ_TEXT
  text = completedLocText
}.__update(fontTinyAccented)
let progressTextWidth = max(hdpx(100), calc_comp_size(progressTextBase)[0])
progressTextBase.__update({ size = [progressTextWidth, SIZE_TO_CONTENT] })

let columnsGap = hdpx(30)
let columnWidth = ((saSize[0] - columnsGap) / 2).tointeger()
let questSectionBgHorPad = hdpx(30)
let questSectionBgColor = 0x80000000
let progressTextGap = hdpx(30)
let progressBarW = (columnWidth - (2 * questSectionBgHorPad) - progressTextGap - progressTextWidth).tointeger()
let progressBarH = hdpxi(28)
let progressBarBorderWidth = hdpx(3)
let progressBarBgColor = 0x80000000
let progressBarFillOldColor = 0xFF2EC181
let progressBarFillNewColor = 0xFFBAEBD5
let progressBarBorderColor = 0xFF606060

let mkTextArea = @(text, ovr) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(ovr)

function getQuestSectionLocName(quest) {
  let { event_id = "", daily_quest = false, weekly_quest = false, promo_quest = false, achievement = false,
    personal = "" } = quest?.meta
  if (event_id != "") {
    if (event_id == MAIN_EVENT_ID)
      return loc(getEventPresentation($"season_{quest?.activity.start_index ?? 0}").locId)
    let { _specialEventRewardUnitName = "" } = quest
    return getSpecialEventLocName(event_id, _specialEventRewardUnitName)
  }
  if (daily_quest || weekly_quest)
    return loc("quests/common")
  if (promo_quest)
    return loc("quests/promo")
  if (achievement)
    return loc("quests/achievements")
  if (personal != "")
    return loc("quests/personal")
  return loc("shop/category/other")
}

function getQuestSubSectionLocName(quest) {
  let { daily_quest = false, weekly_quest = false, event_day = 0 } = quest?.meta
  return daily_quest ? loc("userlog/battletask/type/daily")
    : weekly_quest ? loc("quests/weekly")
    : event_day != 0 ? loc("enumerated_day", { number = event_day })
    : ""
}

function getQuestLocName(quest) {
  let { achievement = false, tree_quest = false, lang_id = quest.name } = quest?.meta
  let isHeaderDesc = achievement || tree_quest
  return loc(isHeaderDesc ? $"{lang_id}/desc" : lang_id)
}

function getQuestLocDesc(quest) {
  let { achievement = false, tree_quest = false, lang_id = quest.name } = quest?.meta
  let isHeaderDesc = achievement || tree_quest
  return isHeaderDesc ? "" : loc($"{lang_id}/desc")
}

let mkQuestTitle = @(quest) mkTextArea(loc("ui/slash")
  .join([ getQuestSubSectionLocName(quest), getQuestLocName(quest) ], true), fontTinyAccented)

function mkQuestTooltipContent(quest) {
  local desc = getQuestLocDesc(quest)
  if (desc == "")
    desc = getQuestLocName(quest)
  return {
    sound = { attach = "click" }
    children = mkTextArea(desc, { size = SIZE_TO_CONTENT, maxWidth = hdpxi(750) }.__update(fontTiny))
  }
}

function mkQuestProgressBar(quest, delay) {
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
        padding = const [0, hdpx(15), 0, 0]
      }.__update(fontVeryTinyShaded)
    ]
  }
}

function mkProgressTxt(quest, delay) {
  let { isCompleted = false, current = 0, _previous = 0, name = "" } = quest
  let diff = current - _previous
  let res = progressTextBase.__merge({ text = isCompleted ? completedLocText : $"+{diff}" })
  return !isCompleted ? res : res.__update({
      key = $"completed_{name}"
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
    })
}

function mkQuestComp(quest, delay) {
  let stateFlags = Watched(0)
  let key = {}
  return @() {
    watch = stateFlags
    key
    behavior = Behaviors.Button
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = hdpx(8)
    children = [
      mkQuestTitle(quest)
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = progressTextGap
        children = [
          mkQuestProgressBar(quest, delay)
          mkProgressTxt(quest, delay)
        ]
      }
    ]
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.97, 0.97] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]
    onDetach = tooltipDetach(stateFlags)
    onElemState = withTooltip(stateFlags, key, @() {
      content = mkQuestTooltipContent(quest)
      flow = FLOW_HORIZONTAL
    })
  }
}

let mkQuestSectionComp = @(locName, questSection, delay) {
  size = FLEX_H
  margin = [0, 0, hdpx(12), 0]
  flow = FLOW_VERTICAL
  gap = hdpx(16)
  children = [
    mkTextArea(locName, fontMedium)
    {
      padding = [hdpx(24), questSectionBgHorPad, hdpx(30), questSectionBgHorPad]
      rendObj = ROBJ_SOLID
      color = questSectionBgColor
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(30)
      children = questSection.map(@(v) mkQuestComp(v.quest, delay))
    }
  ]
}

function mkColumns(questSectionComps) {
  let columnsTotal = 2
  let columns = [ [], [] ]
  let colH = array(columnsTotal, 0)
  let qs = questSectionComps.map(@(comp) { comp, h = calc_comp_size(comp)[1] })
  foreach (v in qs) {
    local shortestColIdx = -1
    local shortestColH = 0
    for (local i = 0; i < columnsTotal; i++)
      if (shortestColIdx == -1 || shortestColH > colH[i]) {
        shortestColIdx = i
        shortestColH = colH[i]
      }
    columns[shortestColIdx].append(v.comp)
    colH[shortestColIdx] += v.h
  }
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = columnsGap
    children = columns.map(@(children) {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children
    })
  }
}

function splitBySections(questsBySection, questSortingInfo) {
  let { questSectionLocName } = questSortingInfo
  if (questSectionLocName not in questsBySection)
    questsBySection[questSectionLocName] <- []
  questsBySection[questSectionLocName].append(questSortingInfo)
  return questsBySection
}

function mkQuestSectionSortingInfo(questSection, locName) {
  let completedTotal = questSection.reduce(@(res, v) res + (v.isCompleted ? 1 : 0), 0)
  let minPredictedMissionsLeft = questSection.reduce(@(res, v)
    min(res, v.isCompleted ? res : v.predictedMissionsLeft), questSection[0].predictedMissionsLeft)
  let maxCompletion = questSection.reduce(@(res, v) max(res, v.isCompleted ? 0 : v.completion), 0)
  let maxGrowthPerMission = questSection.reduce(@(res, v) max(res, v.isCompleted ? 0 : v.growthPerMission), 0)
  let maxRequired = questSection.reduce(@(res, v) max(res, v.isCompleted ? 0 : v.required), 0)
  return {
    questSection
    locName
    completedTotal
    minPredictedMissionsLeft
    maxCompletion
    maxGrowthPerMission
    maxRequired
  }
}

function mkQuestSortingInfo(quest) {
  let { isCompleted = false, current = 0, _previous = 0, required = 1, name = "" } = quest
  let completion = current.tofloat() / required
  let growthPerMission = (current.tofloat() - _previous) / required
  let predictedMissionsLeft = (required - current).tofloat() / max(1, current - _previous)
  let questSectionLocName = getQuestSectionLocName(quest)
  return {
    quest
    questSectionLocName
    isCompleted
    predictedMissionsLeft
    completion
    growthPerMission
    required
    name
  }
}

let sortQuestSections = @(a, b)
  b.completedTotal <=> a.completedTotal
  || a.minPredictedMissionsLeft <=> b.minPredictedMissionsLeft
  || b.maxCompletion <=> a.maxCompletion
  || b.maxGrowthPerMission <=> a.maxGrowthPerMission
  || b.maxRequired <=> a.maxRequired
  || a.locName <=> b.locName

let sortQuests = @(a, b)
  b.isCompleted <=> a.isCompleted
  || a.predictedMissionsLeft <=> b.predictedMissionsLeft
  || b.completion <=> a.completion
  || b.growthPerMission <=> a.growthPerMission
  || b.required <=> a.required
  || a.name <=> b.name

function mkDebrQuestsProgress(debrData, delay) {
  let { quests = {} } = debrData
  let hasContent = quests.len() != 0
  return {
    questsProgressComps = hasContent
      ? mkColumns(quests.values().map(mkQuestSortingInfo).sort(sortQuests)
          .reduce(splitBySections {}).map(mkQuestSectionSortingInfo).values().sort(sortQuestSections)
          .map(@(v) mkQuestSectionComp(v.locName, v.questSection, delay)))
      : null
    questsProgressShowTime = hasContent
      ? progressFillTime
      : 0
  }
}

return mkDebrQuestsProgress
