from "%globalsDarg/darg_library.nut" import *
from "dagor.math" import CatmullRomSplineBuilder2D
from "%sqstd/math.nut" import sqrt
from "%appGlobals/config/mapPointsPresentation.nut" import getMapPointsPresentation, getDefaultPointSize, getPointOffset,
  defaultPointView
from "%rGui/event/treeEvent/segmentMath.nut" import mkLineSplinePoints
from "%rGui/event/treeEvent/treeEventUtils.nut" import lineSectionLen, lineOutlineWidth, mapLineWidth,
  LINE_DASHED, LINE_SOLID
from "%rGui/event/treeEvent/treeEventState.nut" import curEventMapNodes, curEventMapStatus, selectedPointId,
  getEventNodeType, nodeStatusKind, nodeViews, curPagePointSizes, eventMapNodeInProgress, isRewardsReceived,
  NODE_QUESTS, NODE_REWARD, NODE_LOCKED, NODE_AVAILABLE, NODE_PURCHASED, NODE_RECEIVED, isPurchased
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_VERY_TINY
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlateBg, mkRewardPlateImage, getRewardPlateSize
from "%rGui/rewards/rewardViewInfo.nut" import getRewardsViewInfo, sortRewardsViewInfo


const lineDashSections = 3
const lineSpaceSections = 3
const lineBorderEmptySections = 6
const splineTension = -0.5
const linePeriod = lineDashSections + lineSpaceSections
const minBgElemSizeSqForComplexView = hdpx(200) * hdpx(200)
const completedIconSize = evenPx(40)

const editorSelLineColor = 0xC01860C0
const lineToCompletedColor = 0xFF7FAEFF
const lineToUnlockedColor = 0x80405780
const lineToLockedColor = 0x33192333

const defOutlineColor = 0x80000000
let lineOutLineColors = { 
  [editorSelLineColor] = 0xFF000000,
  [lineToUnlockedColor] = 0x40181810,
  [lineToLockedColor] = 0x40181810,
  [lineToCompletedColor] = 0xFF4C1804,
}
let lineOutlineWidthByColor = {
  [lineToCompletedColor] = 0
}

let variantFieldByKind = {
  [NODE_RECEIVED] = "finished",
  [NODE_PURCHASED] = "completed",
  [NODE_AVAILABLE] = "unlocked",
  [NODE_LOCKED] = "locked",
}

let completedMark = {
  size = completedIconSize
  pos = const [hdpx(4), -hdpx(4)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#daily_mark_claimed.avif:{completedIconSize}:P")
  keepAspect = true
}

let rewardPlateBase = getRewardPlateSize(1, REWARD_STYLE_VERY_TINY)

let sqr = @(v) v * v
let onNodeClick = @(id, node) node != null ? selectedPointId.set(id) : null
let resolveNodeView = @(id, view, nodesV) view != ""
  ? view
  : (nodesV?[id] ?? defaultPointView)

let pointStateCache = {}
function getPointState(id) {
  if (pointStateCache?[id] != null)
    return pointStateCache[id]

  let node = Computed(@() curEventMapNodes.get()?[id])
  let nodeStatus = Computed(@() curEventMapStatus.get()?[id])

  let res = {
    node
    nodeStatus
    kind = Computed(@() nodeStatusKind.get()?[id] ?? NODE_LOCKED)
    isSelected = Computed(@() id == selectedPointId.get())
    isNodeInProgress = Computed(@() eventMapNodeInProgress.get() == id)
    hasUnseenReward = Computed(@() isPurchased(nodeStatus.get()) && !isRewardsReceived(nodeStatus.get()))
  }
  pointStateCache[id] <- res.weakref()
  return res
}

let mkRewardPlate = @(r, rStyle) {
  transform = {}
  children = [
    mkRewardPlateBg(r, rStyle)
    mkRewardPlateImage(r, rStyle.__merge({ iconShiftY = 0 })) 
  ]
}

function mkNodeMarkerLayers(node, sizePx, marker, isCompleted, imgOffset) {
  let { image, color, opacity } = marker
  let nodeType = getEventNodeType(node)
  let rewards = nodeType == NODE_REWARD ? getRewardsViewInfo(node?.rewards).sort(sortRewardsViewInfo) : []
  let reward = rewards.findvalue(@(r) (r?.slots ?? 1) == 1)
  let plateScale = sizePx.tofloat() * 0.6 / rewardPlateBase[0]
  let questsIconSize = sizePx / 2

  return [
    {
      size = sizePx
      pos = [imgOffset[0] * sizePx, imgOffset[1] * sizePx]
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{sizePx}:P")
      color
      opacity
      keepAspect = true
    }
    reward == null
      ? null
      : {
          size = sizePx
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          opacity = isCompleted ? 0.5 : 1
          children = {
            size = rewardPlateBase
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            transform = { scale = [plateScale, plateScale], pivot = [0.5, 0.5] }
            children = mkRewardPlate(reward, REWARD_STYLE_VERY_TINY)
          }
        }
    nodeType != NODE_QUESTS
      ? null
      : {
          size = questsIconSize
          opacity = isCompleted ? 0.5 : 1
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#quests.svg:{questsIconSize}:P")
          keepAspect = true
        }
  ]
}

function mkNodeMarkerPreview(node, effView, box, isCompleted = false) {
  let presentation = getMapPointsPresentation(effView)
  let sizePx = (box.r - box.l + 0.5).tointeger()

  return {
    pos = [box.l, box.t]
    size = sizePx
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkNodeMarkerLayers(node, sizePx, presentation.selected, isCompleted, getPointOffset(effView))
      .append(!isCompleted ? null : completedMark)
  }
}

function mkPoint(state) {
  let { id, view = "", pos } = state 
  let { node, kind, isSelected, isNodeInProgress, hasUnseenReward } = getPointState(id)

  return function() {
    let effView = resolveNodeView(id, view, nodeViews.get())
    let presentation = getMapPointsPresentation(effView)
    let curKind = kind.get()
    let variant = presentation[variantFieldByKind?[curKind] ?? "locked"]
    let marker = isSelected.get() ? presentation.selected : variant
    let sizePx = evenPx(curPagePointSizes.get()?[effView] ?? getDefaultPointSize(effView))
    let isCompleted = curKind == NODE_RECEIVED

    return {
      watch = [kind, isSelected, node, nodeViews, curPagePointSizes, isNodeInProgress, hasUnseenReward]
      key = id
      pos = pos.map(@(v) hdpx(v) - sizePx / 2)
      size = sizePx
      touchMarginPriority = 1
      behavior = Behaviors.Button
      onClick = isNodeInProgress.get() ? @() null : @() onNodeClick(id, node.get())
      sound = { click = "click" }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkNodeMarkerLayers(node.get(), sizePx, marker, isCompleted, getPointOffset(effView)).append(
        !hasUnseenReward.get() ? null
          : {
              size = sizePx
              hplace = ALIGN_RIGHT
              vplace = ALIGN_TOP
              children = priorityUnseenMark
            },
        !isNodeInProgress.get() ? null
          : {
              size = sizePx
              hplace = ALIGN_CENTER
              vplace = ALIGN_CENTER
              children = mkSpinner(sizePx / 2)
            },
        !isCompleted ? null : completedMark)
    }
  }
}

function mkBgElementImg(img, size, ovr = {}) {
  if ((img ?? "") == "")
    return { size }.__update(ovr)
  let isComplexView = size[0] * size[1] <= minBgElemSizeSqForComplexView
  return {
    size
    rendObj = ROBJ_IMAGE
    image = Picture(isComplexView ? $"{img}:{size[0]}:{size[1]}:P" : $"{img}:0:P")
    keepAspect = true
  }.__update(ovr)
}

function mkBgElement(state) {
  let { img, size, pos, rotate, flipX = false, flipY = false } = state
  let sizePx = size.map(hdpx)
  return {
    pos = pos.map(hdpx)
    size = sizePx
    children = mkBgElementImg(img, sizePx, { flipX, flipY })
    transform = { rotate }
  }
}

let lineKindRank = [NODE_LOCKED, NODE_AVAILABLE, NODE_PURCHASED, NODE_RECEIVED]
  .reduce(@(res, v, i) res.$rawset(v, i), {})

function mkLinePresetColor(fromId, toId, statusKinds) {
  let kindFrom = statusKinds?[fromId] ?? NODE_LOCKED
  let kindTo = statusKinds?[toId] ?? NODE_LOCKED
  let kind = (lineKindRank?[kindFrom] ?? 0) <= (lineKindRank?[kindTo] ?? 0) ? kindFrom : kindTo
  return [VECTOR_COLOR,
    (kind == NODE_PURCHASED || kind == NODE_RECEIVED) ? lineToCompletedColor
      : kind == NODE_AVAILABLE ? lineToUnlockedColor
      : lineToLockedColor
  ]
}

function buildLineSpline(line, points) {
  let all = mkLineSplinePoints(line, points)
  if (all.len() < 2)
    return null
  local spline = CatmullRomSplineBuilder2D()
  spline.build(all.reduce(@(r, v) r.extend(v), []), false, splineTension)
  return spline
}

function splineCenter(spline) {
  if (spline == null)
    return null
  let p = spline.getMonotonicPoint(0.5)
  return [p.x, p.y]
}

function mkLineCmdsFromSpline(spline, size, sectionLen = lineSectionLen, rounded = true, width = mapLineWidth) {
  let res = []
  if (spline == null)
    return res

  let length = spline.getTotalSplineLength()
  let sectionsMin = (length / max(1, sectionLen ?? lineSectionLen) + 0.5).tointeger()
  let periods = max(2, (sectionsMin - 2 * lineBorderEmptySections + lineSpaceSections) / linePeriod)
  let periodF = 1.0 * linePeriod / (periods * linePeriod - lineSpaceSections + 2 * lineBorderEmptySections)
  let dashF = periodF * lineDashSections / linePeriod
  let start = periodF * lineBorderEmptySections / linePeriod
  let end = 1.0 - start

  let halfWidthMap = width / (2.0 * hdpxi(1))
  for (local f = start; f < end; f += periodF) {
    local p1 = spline.getMonotonicPoint(f)
    local p2 = spline.getMonotonicPoint(f + dashF)
    if (rounded) {
      res.append([ VECTOR_LINE,
        100.0 * p1.x / size[0],
        100.0 * p1.y / size[1],
        100.0 * p2.x / size[0],
        100.0 * p2.y / size[1]
      ])
      continue
    }
    let len = sqrt(sqr(p2.x - p1.x) + sqr(p2.y - p1.y))
    let nx = len > 0 ? -(p2.y - p1.y) / len * halfWidthMap : 0.0
    let ny = len > 0 ? (p2.x - p1.x) / len * halfWidthMap : 0.0
    res.append([ VECTOR_POLY,
      100.0 * (p1.x + nx) / size[0], 100.0 * (p1.y + ny) / size[1],
      100.0 * (p2.x + nx) / size[0], 100.0 * (p2.y + ny) / size[1],
      100.0 * (p2.x - nx) / size[0], 100.0 * (p2.y - ny) / size[1],
      100.0 * (p1.x - nx) / size[0], 100.0 * (p1.y - ny) / size[1]
    ])
  }
  return res
}

function mkSolidLineCmds(line, points, size) {
  let pts = mkLineSplinePoints(line, points)
  if (pts.len() < 2)
    return []
  let cmd = [VECTOR_LINE]
  foreach (p in pts)
    cmd.append(100.0 * p[0] / size[0], 100.0 * p[1] / size[1])
  return [cmd]
}

let mkLineCmds = @(line, points, size, sectionLen = lineSectionLen, rounded = true, width = mapLineWidth)
  mkLineCmdsFromSpline(buildLineSpline(line, points), size, sectionLen, rounded, width)

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

let lineTypeCtors = {
  [LINE_DASHED] = function(lineSplines, ctx) {
    let { size, width, sectionLen, rounded, colorOf } = ctx
    local commands = rounded ? [] : [[VECTOR_WIDTH, 0]]
    foreach (ls in lineSplines) {
      let colorCmd = colorOf(ls.line)
      if (colorCmd != null) {
        commands.append(colorCmd)
        if (!rounded)
          commands.append([VECTOR_FILL_COLOR, colorCmd[1]])
      }
      commands.extend(mkLineCmdsFromSpline(ls.spline, size, sectionLen, rounded, width))
    }
    return rounded ? mkLineCmdsOutline(commands, width) : commands
  },
  [LINE_SOLID] = function(lineSplines, ctx) {
    let { size, width, points, colorOf } = ctx
    local commands = [[VECTOR_WIDTH, width]]
    foreach (ls in lineSplines) {
      let colorCmd = colorOf(ls.line)
      if (colorCmd != null)
        commands.append(colorCmd)
      commands.extend(mkSolidLineCmds(ls.line, points, size))
    }
    return commands
  }
}

return {
  mkLineCmds
  mkLineCmdsFromSpline
  mkSolidLineCmds
  mkLineCmdsOutline
  lineTypeCtors
  mkLinePresetColor
  buildLineSpline
  splineCenter
  mkPoint
  mkNodeMarkerPreview
  mkBgElement
  resolveNodeView

  LINE_DASHED
  LINE_SOLID
  editorSelLineColor
}
