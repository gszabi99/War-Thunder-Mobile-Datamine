from "%globalsDarg/darg_library.nut" import *
let { CatmullRomSplineBuilder2D } = require("dagor.math")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { mkLineSplinePoints } = require("segmentMath.nut")
let { getMapPointsPresentation } = require("%appGlobals/config/mapPointsPresentation.nut")
let { mkCompletedPrevElem, selectedElemId, curEventUnlocks, selectedPointId, pointsStatusesByPresets,
  presetsStatuses, treeEventPresets
} = require("treeEventState.nut")
let { saveSeenQuests } = require("%rGui/quests/questsState.nut")
let { priorityUnseenMarkLight } = require("%rGui/components/unseenMark.nut")
let { mkRewardsPreview, questItemsGap, getRewardsPreviewInfo, getEventCurrencyReward } = require("%rGui/quests/rewardsComps.nut")
let { exploreRewardMsgBox, mkQuestBtn } = require("%rGui/quests/questsWndPage.nut")
let { btnSize } = require("%rGui/quests/questsPkg.nut")
let { mkQuestBar } = require("%rGui/quests/questBar.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let currencyStyles = require("%rGui/components/currencyStyles.nut")
let { CS_COMMON } = currencyStyles


let lineSectionLen = 6
let lineDashSections = 3
let lineSpaceSections = 3
let lineBorderEmptySections = 6
let splineTension = -0.5
let linePeriod = lineDashSections + lineSpaceSections
let selectMarkerSize = hdpxi(90)
let imgLockSize = hdpxi(60)
let infoPanelWidth = hdpx(550)
let textSubPresetColor = 0xFF512E0B
let lineOutlineWidth = hdpxi(1)
let mapLineWidth = hdpx(7) + 2 * lineOutlineWidth
let blockedIconSize = [hdpx(140), hdpx(40)]
let completedIconSize = hdpxi(40)
let minBgElemSizeSqForComplexView = hdpx(200) * hdpx(200)

let editorSelLineColor = 0xC01860C0
let lineToCompletedColor = 0xFFEEE7D9
let lineToUnlockedColor = 0xFF9E0606
let lineToLockedColor = 0xFF411D04

let defOutlineColor = 0x80000000
let lineOutLineColors = { 
  [editorSelLineColor] = 0xFF000000,
  [lineToUnlockedColor] = 0x40181810,
  [lineToLockedColor] = 0x40181810,
  [lineToCompletedColor] = 0xFF4C1804,
}
let lineOutlineWidthByColor = {
  [lineToCompletedColor] = hdpxi(2)
}

let selectMarker = {
  size = [selectMarkerSize, selectMarkerSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#scroll_selection.avif:{selectMarkerSize}:{selectMarkerSize}:P")
}

let scalePointAnim = [{
  prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2],
  duration = 1.2, easing = CosineFull, play = true, loop = true
}]

function mkPoint(state, pointSize) {
  let { id, view = "", pos } = state
  let size = evenPx(pointSize)

  let unlock = Computed(@() curEventUnlocks.get()?[id])
  let pointStatus = Computed(@() pointsStatusesByPresets.get()?[unlock.get()?.meta.quest_cluster_id][id])
  let isCompletedPrevQuest = Computed(@() pointStatus.get()?.isCompletedPrevQuest ?? false)
  let isCompleted = Computed(@() pointStatus.get()?.isCompleted ?? false)
  let isFinished = Computed(@() !!unlock.get()?.isFinished)
  let isSelected = Computed(@() id == selectedPointId.get())

  let hasUnseenMarker = Computed(@() pointStatus.get()?.isUnseen ?? false)

  return function() {
    let presentation = getMapPointsPresentation(view)
    let { image, color, scale } = isFinished.get() ? presentation.finished
      : isCompleted.get() ? presentation.completed
      : isCompletedPrevQuest.get() ? presentation.unlocked
      : presentation.locked
    let sizeExt = scaleEven(size, scale)
    return {
      watch = [isCompletedPrevQuest, isCompleted, isFinished, isSelected, hasUnseenMarker]
      pos = pos.map(@(v) hdpx(v) - sizeExt / 2)
      size = [sizeExt, sizeExt]
      behavior = Behaviors.Button
      touchMarginPriority = 1
      function onClick() {
        saveSeenQuests([id])
        selectedPointId.set(id)
      }
      sound = { click  = "click" }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        !hasUnseenMarker.get() ? null : priorityUnseenMarkLight
        {
          key = {}
          children = [
            {
              key = id
              size = flex()
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = {
                size = [sizeExt, sizeExt]
                rendObj = ROBJ_IMAGE
                image = Picture($"{image}:{sizeExt}:{sizeExt}:P")
                color =!hasUnseenMarker.get() ? color : 0xFFffb71d
                keepAspect = true
              }
            }
            isSelected.get() ? selectMarker : null
          ]
          transform = !hasUnseenMarker.get() ? null : {}
          animations = !hasUnseenMarker.get() ? null : scalePointAnim
        }
      ]
    }
  }
}

function mkBgElementImg(img, size, ovr = {}) {
  let isComplexView = size[0] * size[1] <= minBgElemSizeSqForComplexView
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture(isComplexView ? $"{img}:{size[0]}:{size[1]}:P" : $"{img}:0:P")
    keepAspect = true
  }.__update(ovr)
}

let mkStatusPlateText = @(text) {
  rendObj = ROBJ_TEXT
  maxWidth = hdpx(100)
  color = textSubPresetColor
  text
}.__update(CS_COMMON.fontStyle)

let mkRangeStatus = @(range, hasUnseenMarker) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(6)
  children = [
    {
      children = [
        !hasUnseenMarker ? null : priorityUnseenMarkLight
        {
          key = {}
          size = [completedIconSize, completedIconSize]
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#scroll_quest_completed.avif:{completedIconSize}:{completedIconSize}:P")
          color = hasUnseenMarker ? 0xFFffb71d : lineToCompletedColor
          keepAspect = true
          transform = !hasUnseenMarker ? null : {}
          animations = !hasUnseenMarker ? null : scalePointAnim
        }
      ]
    }
    mkStatusPlateText($"{range.count}/{range.total}")
  ]
}

let mkCurrencyComp = @(value, currencyId, style) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = style.iconGap
  children = [
    mkCurrencyImage(currencyId, style.iconSize, { key = style?.iconKey })
    mkStatusPlateText(value)
  ]
}

function mkStatusPlate(isAvailable, isBlocked, price, range, hasUnseenMarker, ovr = {}) {
  let currency = mkCurrencyComp(price.price, price.currency, CS_COMMON.__merge({ textColor = textSubPresetColor }))
  let children = isBlocked ? mkBgElementImg("ui/images/pirates/island_status_locked.avif", blockedIconSize)
    : isAvailable ? mkRangeStatus(range, hasUnseenMarker)
    : currency

  return {
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    padding = [hdpx(5), 0]
    children
  }.__update(ovr)
}

function mkBgElementStatus(state) {
  let { img, size, pos, rotate, flipX = false, flipY = false, required = "" } = state
  let sizePx = size.map(hdpx)

  let presetStatuses = Computed(@() presetsStatuses.get()?[required])
  let price = Computed(@() presetStatuses.get()?.price)
  let isAvailable = Computed(@() presetStatuses.get()?.isAvailable)
  let isBlocked = Computed(@() presetStatuses.get()?.isBlocked)

  let hasUnseenMarker = Computed(@() pointsStatusesByPresets.get()?[required]
    .findindex(@(point) point.isUnseen) != null)

  let completedPointsRange = Computed(function() {
    let presets = pointsStatusesByPresets.get()?[required] ?? {}
    return presets.reduce(function(res, point) {
      if (point.isCompleted)
        res.count = res.count + 1
      return res
    }, { total = presets.len(), count = 0 })
  })

  return @() {
    watch = [isAvailable, isBlocked, price, completedPointsRange, hasUnseenMarker]
    pos = pos.map(hdpx)
    size = sizePx
    children = [
      mkBgElementImg(img, sizePx, { flipX, flipY })
      mkStatusPlate(isAvailable.get(), isBlocked.get(), price.get(), completedPointsRange.get(), hasUnseenMarker.get())
    ]
    transform = { rotate }
  }
}

function mkDefaultBgElement(state) {
  let { img, size, pos, rotate, flipX = false, flipY = false } = state
  let sizePx = size.map(hdpx)

  return {
    pos = pos.map(hdpx)
    size = sizePx
    children = mkBgElementImg(img, sizePx, { flipX, flipY })
    transform = { rotate }
  }
}

function mkBgElementIsland(state) {
  let { id, img, size, pos, rotate, flipX = false, flipY = false } = state
  let unlock = Computed(@() curEventUnlocks.get()?[id])
  let sizeBase = size.map(hdpx)

  let presetStatuses = Computed(@() presetsStatuses.get()?[id] ?? {})

  let price = Computed(@() presetStatuses.get()?.price)
  let isAvailable = Computed(@() presetStatuses.get()?.isAvailable)
  let isBlocked = Computed(@() presetStatuses.get()?.isBlocked)

  let rewardsPreview = Computed(@() getRewardsPreviewInfo(unlock.get(), serverConfigs.get()))
  let eventCurrencyReward = Computed(@() getEventCurrencyReward(rewardsPreview.get()))

  return @() {
    key = id
    watch = [unlock, price, isAvailable, rewardsPreview, eventCurrencyReward, isBlocked, treeEventPresets]
    pos = pos.map(hdpx)
    size = sizeBase
    onClick = @() !treeEventPresets.get().contains(id) || isBlocked.get() ? null
      : isAvailable.get() ? selectedElemId.set(id)
      : exploreRewardMsgBox(unlock.get(), rewardsPreview.get(), price.get().price, price.get().currency, eventCurrencyReward.get())
    behavior = Behaviors.Button
    sound = id != null ? { click  = "click" } : null
    children = mkBgElementImg(img, sizeBase, { key = id, flipX, flipY })
    transform = { rotate }
  }
}

let bgElementCtor = {
  island = mkBgElementIsland
  status = mkBgElementStatus
}

let mkBgElement = @(bgElem) (bgElementCtor?[bgElem?.bgType] ?? mkDefaultBgElement)(bgElem)

function mkLinePresetColor(id, unlocksCompletion) {
  let { isCompleted = false, isCompletedPrevQuest = false } = unlocksCompletion?[id]
  return [VECTOR_COLOR,
    isCompleted && isCompletedPrevQuest ? lineToCompletedColor
      : lineToLockedColor
  ]
}

function mkLineColor(id, unlocksCompletion) {
  let { isCompleted = false, isCompletedPrevQuest = false } = unlocksCompletion?[id]
  return [VECTOR_COLOR,
    isCompleted && isCompletedPrevQuest ? lineToCompletedColor
      : isCompletedPrevQuest ? lineToUnlockedColor
      : lineToLockedColor
  ]
}

function mkLineCmds(line, points, size) {
  let all = mkLineSplinePoints(line, points)
  let res = []
  if (all.len() < 2)
    return res

  local spline = CatmullRomSplineBuilder2D()
  spline.build(all.reduce(@(r, v) r.extend(v), []), false, splineTension)

  let length = spline.getTotalSplineLength()
  let sectionsMin = (length / lineSectionLen + 0.5).tointeger()
  let periods = max(2, (sectionsMin - 2 * lineBorderEmptySections + lineSpaceSections) / linePeriod)
  let periodF = 1.0 * linePeriod / (periods * linePeriod - lineSpaceSections + 2 * lineBorderEmptySections)
  let dashF = periodF * lineDashSections / linePeriod
  let start = periodF * lineBorderEmptySections / linePeriod
  let end = 1.0 - start
  for (local f = start; f < end; f += periodF) {
    local p1 = spline.getMonotonicPoint(f)
    local p2 = spline.getMonotonicPoint(f + dashF)
    res.append([ VECTOR_LINE,
      100.0 * p1.x / size[0],
      100.0 * p1.y / size[1],
      100.0 * p2.x / size[0],
      100.0 * p2.y / size[1]
    ])
  }
  return res
}

function mkLineCmdsOutline(commands, baseWidth = mapLineWidth, defColor = lineToCompletedColor) {
  let res = [
    [VECTOR_WIDTH, baseWidth],
    [VECTOR_COLOR, lineOutLineColors?[defColor] ?? defOutlineColor]
  ]
    .extend(commands.map(@(c) c[0] != VECTOR_COLOR ? c
      : [c[0], lineOutLineColors?[c[1]] ?? defOutlineColor]))
    .append(
      [VECTOR_WIDTH, baseWidth - 2 * (lineOutlineWidthByColor?[defColor] ?? lineOutlineWidth)],
      [VECTOR_COLOR, defColor])

  foreach(cmd in commands) {
    res.append(cmd)
    if (cmd[0] != VECTOR_COLOR)
      continue
    res.append([VECTOR_WIDTH, baseWidth - 2 * (lineOutlineWidthByColor?[cmd[1]] ?? lineOutlineWidth)])
  }
  return res
}

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = pw(100)
  halign = ALIGN_CENTER
  text
}.__update(ovr)

function mkQuestTexts(item) {
  let locId = item.meta?.lang_id ?? item.name
  let header = loc(locId)
  let text = loc($"{locId}/desc")
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(8)
    children = [
      mkText(header, fontSmall)
      mkText(text, fontTiny)
    ]
  }
}

function mkEventInfoPanelContent(id) {
  let unlock = Computed(@() curEventUnlocks.get()?[id])
  let isCompletedPrevQuest = mkCompletedPrevElem(id)
  let isAvailable = Computed(@() isCompletedPrevQuest.get())

  let rewardsPreview = Computed(@() getRewardsPreviewInfo(unlock.get(), serverConfigs.get()))
  let eventCurrencyReward = Computed(@() getEventCurrencyReward(rewardsPreview.get()))

  return {
    stopMouse = true
    rendObj = ROBJ_SOLID
    color = 0x80000000
    children = {
      size = [infoPanelWidth, SIZE_TO_CONTENT]
      padding = [hdpx(20), hdpx(10)]
      flow = FLOW_VERTICAL
      gap = questItemsGap
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          padding = [hdpx(10), hdpx(30), hdpx(15), hdpx(30)]
          flow = FLOW_HORIZONTAL
          gap = questItemsGap
          vplace = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            @() {
              watch = [unlock, isAvailable]
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = hdpx(8)
              halign = ALIGN_CENTER
              children = isAvailable.get()
                ? [
                    mkQuestTexts(unlock.get())
                    mkQuestBar(unlock.get())
                  ]
                : mkText(loc("quests/requiredCompletePreviousQuest"), fontSmall)
            }
          ]
        }
        @() {
          watch = [rewardsPreview, unlock]
          flow = FLOW_HORIZONTAL
          gap = questItemsGap
          hplace = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = rewardsPreview.get().len() > 0
            ? mkRewardsPreview(rewardsPreview.get(), unlock.get()?.isFinished)
            : null
        }
        @() {
          watch = [unlock, eventCurrencyReward, rewardsPreview, servProfile, isAvailable]
          hplace = ALIGN_CENTER
          children = isAvailable.get()
            ? mkQuestBtn(unlock.get(), eventCurrencyReward.get(), rewardsPreview.get(), servProfile.get())
            : {
              size = btnSize
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = {
                rendObj = ROBJ_IMAGE
                size = [imgLockSize, imgLockSize]
                image = Picture($"ui/gameuiskin#lock_icon.svg:{imgLockSize}:{imgLockSize}:P")
                keepAspect = true
              }
            }
        }
      ]
    }
  }
}

let mkQuestInfoWnd = @(id) {
  margin = [0, saBorders[0], saBorders[1] + defButtonHeight + questItemsGap, 0]
  onClick = @() selectedPointId.set(null)
  children = mkEventInfoPanelContent(id)
  transform = {}
  animations = wndSwitchAnim
}

return {
  mkLineCmds
  mkLineCmdsOutline
  mkLinePresetColor
  mkLineColor
  mkPoint
  mkBgElement
  mkQuestInfoWnd

  editorSelLineColor
  mapLineWidth
}
