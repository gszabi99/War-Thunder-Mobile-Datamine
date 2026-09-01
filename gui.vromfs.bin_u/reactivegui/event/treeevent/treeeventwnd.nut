from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/config/eventSeasonPresentation.nut" import getEventPresentation
import "%rGui/event/treeEvent/mapNet.nut" as mapNet
from "%rGui/event/treeEvent/treeEventComps.nut" import lineTypeCtors, LINE_DASHED, mkLinePresetColor,
  mkPoint, mkBgElement, mkNodeMarkerPreview, buildLineSpline, splineCenter, resolveNodeView
from "%appGlobals/config/mapPointsPresentation.nut" import getPointLineStartOffset
from "%rGui/event/treeEvent/treeEventNodeInfo.nut" import mkNodeInfoWnd
from "%rGui/event/treeEvent/treeEventState.nut" import openedTreeEventId, curEventMapNodes,
  curPageBgElems, curPageBackground, curPageMapSize, selectedPointId, curPagePoints, nodeViews,
  curPageGridSize, curPageLines, curPageLineSectionLen, curPageRoundedDashes, curPageLineType, curPageLineWidth,
  nodeStatusKind, pagesList, curPage, curPageResolved, NODE_LOCKED, NODE_RECEIVED,
  curEventUnlocks
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/components/tabs.nut" import tabExtraWidth
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/animGrowLines.nut" import mkAnimGrowLines, mkAGLinesCfgOrdered
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/gradientDefComps.nut" import headerHeightInSafeArea, headerMargin
import "%rGui/options/mkOptionsTabs.nut" as mkOptionsTabs
from "%rGui/options/optionsStyle.nut" import tabW
from "%rGui/event/eventState.nut" import eventSeason


const backButtonHeight = hdpx(60)
const gapBackButton = hdpx(50)
const pageBlocksGap = hdpx(30)
const lineLockSize = hdpxi(32)
const topAreaSize = saBorders[1] + backButtonHeight + gapBackButton
const seasonHeaderHeight = headerHeightInSafeArea + headerMargin
const gradientHeightBottom = saBorders[1]

const NODE_FOCUS_WND_UID = "tree_event_node_focus"

let defBgMapImage = "ui/gameuiskin#icon_primary_attention.svg"
let defBgMapOffs = [0, 0, 0, 0]
let tabsAreaWidth = tabW + hdpx(25)
let connectorWndGap = hdpx(60)

let modalOverlayShadeColor = 0xC0020B19
let contentOverlayShadeColor = 0x73020B19

let nodeInfoWndKey = {}
let nodeInfoWndPadding = [saBordersRv[0] + seasonHeaderHeight, saBordersRv[1], saBordersRv[0], saBordersRv[1]]
let selBoxes = Watched(null)

let focusedNodeId = Computed(function() {
  let id = selectedPointId.get()
  return (id != null && id in curEventMapNodes.get()) ? id : null
})

function refreshFocusBoxes(id) {
  let boxes = {
    nodeBox = gui_scene.getCompAABBbyKey(id)
    wndBox = gui_scene.getCompAABBbyKey(nodeInfoWndKey)
  }
  if (!isEqual(boxes, selBoxes.get()))
    selBoxes.set(boxes)
}

let doRefreshFocusBoxes = @() refreshFocusBoxes(focusedNodeId.get())
let scheduleFocusRefresh = @() focusedNodeId.get() != null ? deferOnce(doRefreshFocusBoxes) : null

let boxEdges = @(b) [
  [b.l, b.t, b.r, b.t],
  [b.r, b.t, b.r, b.b],
  [b.r, b.b, b.l, b.b],
  [b.l, b.b, b.l, b.t],
]

function mkOrthoConnector(nodeBox, wndBox, startOffset) {
  let ncy = 0.5 * (nodeBox.t + nodeBox.b)
  let startX = nodeBox.l + startOffset * (nodeBox.r - nodeBox.l)
  let endX = wndBox.r

  if (ncy >= wndBox.t && ncy <= wndBox.b)
    return [[startX, ncy, endX, ncy]]

  let wcy = 0.5 * (wndBox.t + wndBox.b)
  let turnX = clamp(endX + connectorWndGap, min(startX, endX), max(startX, endX))
  return [
    [startX, ncy, turnX, ncy],
    [turnX, ncy, turnX, wcy],
    [turnX, wcy, endX, wcy],
  ]
}

function mkFocusLines(nodeBox, wndBox, startOffset) {
  let lines = []
  foreach (seg in mkOrthoConnector(nodeBox, wndBox, startOffset))
    lines.append([seg])
  lines.append(boxEdges(wndBox))
  return mkAnimGrowLines(mkAGLinesCfgOrdered(lines, hdpx(3000)))
}

let focusGeom = Computed(function() {
  let boxes = selBoxes.get()
  let nodeBox = boxes?.nodeBox
  let wndBox = boxes?.wndBox
  return { nodeBox, wndBox, showNode = nodeBox != null && wndBox != null }
})

let focusedNodeEffView = Computed(function() {
  let id = focusedNodeId.get()
  return resolveNodeView(id, curPagePoints.get()?[id].view ?? "", nodeViews.get())
})

let focusedNodeLineStartOffset = Computed(@() getPointLineStartOffset(focusedNodeEffView.get()))

function focusLines() {
  let { nodeBox, wndBox, showNode } = focusGeom.get()
  return {
    watch = [focusGeom, focusedNodeLineStartOffset]
    size = FLEX
    children = showNode ? mkFocusLines(nodeBox, wndBox, focusedNodeLineStartOffset.get()) : null
  }
}

function nodeInfoBlock() {
  let id = focusedNodeId.get()
  let node = id != null ? curEventMapNodes.get()?[id] : null
  return {
    watch = [focusedNodeId, curEventMapNodes]
    size = FLEX
    padding = nodeInfoWndPadding
    vplace = ALIGN_BOTTOM
    halign = ALIGN_LEFT
    children = node == null
      ? null
      : {
          key = nodeInfoWndKey
          size = SIZE_TO_CONTENT
          onAttach = scheduleFocusRefresh
          children = mkNodeInfoWnd(id, node)
        }
  }
}

function nodeFocusContent() {
  let watch = [focusedNodeId, curEventMapNodes, focusGeom, nodeStatusKind, focusedNodeEffView]
  let id = focusedNodeId.get()
  let node = id != null ? curEventMapNodes.get()?[id] : null
  if (node == null)
    return { watch, size = FLEX }

  let effView = focusedNodeEffView.get()
  let curKind = nodeStatusKind.get()?[id]
  let isCompleted = curKind == NODE_RECEIVED
  let { nodeBox, showNode } = focusGeom.get()
  return {
    watch
    size = FLEX
    children = [
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = modalOverlayShadeColor
        animations = wndSwitchAnim
      }
      !showNode ? null : mkNodeMarkerPreview(node, effView, nodeBox, isCompleted)
      focusLines
      nodeInfoBlock
    ]
  }
}

let openNodeFocus = @() addModalWindow({
  key = NODE_FOCUS_WND_UID
  size = FLEX
  children = nodeFocusContent
  onClick = @() selectedPointId.set(null)
})

focusedNodeId.subscribe(function(v) {
  selBoxes.set(null)
  if (v == null) {
    removeModalWindow(NODE_FOCUS_WND_UID)
    return
  }
  openNodeFocus()
})

foreach (w in [nodeStatusKind, curEventUnlocks])
  w.subscribe(@(_) scheduleFocusRefresh())

if (focusedNodeId.get() != null)
  openNodeFocus()

let mapPoints = @() {
  watch = curPagePoints
  size = FLEX
  children = curPagePoints.get().reduce(@(acc, value, id) acc.append(mkPoint(value.__merge({ id }))), [])
}

let bgElementsOnTop = @() {
  watch = curPageBgElems
  size = FLEX
  children = curPageBgElems.get()
    .filter(@(v) !!v?.isOnTop)
    .map(mkBgElement)
}

let bgElements = @() {
  watch = curPageBgElems
  size = FLEX
  children = curPageBgElems.get()
    .filter(@(v) !v?.isOnTop)
    .map(mkBgElement)
}

let mapBackground = @() {
  watch = curPageBackground
  size = FLEX
  children = curPageBackground.get() == "" ? null
    : {
        size = FLEX
        behavior = Behaviors.Button
        onClick = @() selectedPointId.set(null)
        rendObj = ROBJ_IMAGE
        image = Picture($"{curPageBackground.get()}:0:P")
        keepAspect = true
      }
}

let curPageLineSplines = Computed(function() {
  let points = curPagePoints.get()
  return curPageLines.get().map(@(line) { line, spline = buildLineSpline(line, points) })
})

function mapLines() {
  let mkCommands = lineTypeCtors?[curPageLineType.get()] ?? lineTypeCtors[LINE_DASHED]

  return {
    watch = [curPageLineSplines, curPageMapSize, nodeStatusKind, curPageLineSectionLen,
      curPageRoundedDashes, curPageLineType, curPageLineWidth]
    size = FLEX
    rendObj = ROBJ_VECTOR_CANVAS
    commands = mkCommands(curPageLineSplines.get(), {
      size = curPageMapSize.get()
      width = curPageLineWidth.get()
      sectionLen = curPageLineSectionLen.get()
      rounded = curPageRoundedDashes.get()
      points = curPagePoints.get()
      colorOf = @(line) mkLinePresetColor(line.from, line.to, nodeStatusKind.get())
    })
  }
}

function mapLineLocks() {
  let kinds = nodeStatusKind.get()

  let poses = []
  foreach (ls in curPageLineSplines.get()) {
    let { line } = ls
    if ((kinds?[line.from] ?? NODE_LOCKED) != NODE_LOCKED || (kinds?[line.to] ?? NODE_LOCKED) != NODE_LOCKED)
      continue
    let center = splineCenter(ls.spline)
    if (center == null)
      continue
    poses.append([hdpx(center[0]) - lineLockSize / 2, hdpx(center[1]) - lineLockSize / 2])
  }

  return {
    watch = [nodeStatusKind, curPageLineSplines]
    size = FLEX
    children = poses.map(@(pos) {
      pos
      size = lineLockSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#lock_icon.svg:{lineLockSize}:P")
      keepAspect = true
      color = 0xFFA0A0A0
    })
  }
}

let mapScrollHandler = ScrollHandler()
let tabsScrollHandler = ScrollHandler()

function mapContainer(viewportSize) {
  let mapSize = curPageMapSize.get().map(hdpx)
  return {
    key = curPageMapSize
    size = viewportSize
    clipChildren = true
    children = {
      size = FLEX
      behavior = [Behaviors.Pannable, Behaviors.ScrollEvent],
      touchMarginPriority = TOUCH_BACKGROUND
      scrollHandler = mapScrollHandler
      skipDirPadNav = true
      xmbNode = XmbContainer()
      children = {
        size = mapSize
        children = {
          size = FLEX
          children = [
            mapBackground
            bgElements
            mapNet(curPageMapSize, curPageGridSize, curPageBgElems)
            bgElementsOnTop
            mapLines
            mapLineLocks
            mapPoints
          ]
        }
      }
    }
  }
}

let mkTabLabel = @(page) {
  size = FLEX
  halign = ALIGN_RIGHT
  valign = ALIGN_TOP
  children = {
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = [Behaviors.TextArea, Behaviors.Marquee]
    halign = ALIGN_RIGHT
    color = 0xFFFFFFFF
    text = loc("mainmenu/page", { page })
  }.__update(fontTinyAccented)
}

let mkTabsVerticalPannableArea = verticalPannableAreaCtor(
  sh(100) - topAreaSize + pageBlocksGap,
  [pageBlocksGap, gradientHeightBottom])

function mkTabIndexBridge(pages, pageId, resolvedPageId) {
  let toIdx = @(page) max(0, pages.get().findindex(@(p) p == page) ?? 0)
  let tabIdx = Watched(toIdx(resolvedPageId.get()))
  tabIdx.subscribe(function(i) {
    let page = pages.get()?[i]
    if (page != null)
      pageId.set(page)
  })
  resolvedPageId.subscribe(@(page) tabIdx.set(toIdx(page)))
  return tabIdx
}
let curTabIdx = mkTabIndexBridge(pagesList, curPage, curPageResolved)

let tabsList = @(tabs) mkTabsVerticalPannableArea(
    mkOptionsTabs(tabs, curTabIdx),
    { size = [tabsAreaWidth, sh(100) - topAreaSize] },
    { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler = tabsScrollHandler }
  )

let bgMap = Computed(@() getEventPresentation(openedTreeEventId.get())?.bgMap)

function treeEventMapWnd() {
  if (openedTreeEventId.get() == null)
    return { watch = openedTreeEventId }
  let hasTabs = pagesList.get().len() > 1
  let mapBlock = curPageMapSize.get().map(hdpx)
  let cfg = bgMap.get()
  let eventPres = getEventPresentation(eventSeason.get())
  let texOffs = cfg?.offs ?? defBgMapOffs
  let screenOffs = texOffs.map(hdpx)
  let bgScreenSize = [mapBlock[0] + screenOffs[1] + screenOffs[3], mapBlock[1] + screenOffs[0] + screenOffs[2]]
  let tabsColRight = saBorders[0] - tabExtraWidth + tabsAreaWidth
  let mapPos = [hasTabs ? tabsColRight / 2 : 0, 0]

  return {
    watch = [openedTreeEventId, bgMap, pagesList, curPageMapSize, eventSeason]
    size = FLEX
    behavior = Behaviors.Button
    onClick = @() selectedPointId.set(null)
    onDetach = @() selectedPointId.set(null)
    children = [
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = contentOverlayShadeColor
      }
      {
        size = bgScreenSize
        rendObj = ROBJ_9RECT
        texOffs
        screenOffs
        image = Picture($"{cfg?.image ?? defBgMapImage}:0:P")
        hplace = ALIGN_CENTER
        pos = mapPos
        vplace = ALIGN_CENTER
        padding = screenOffs
      }
      {
        size = bgScreenSize
        hplace = ALIGN_CENTER
        pos = mapPos
        vplace = ALIGN_CENTER
        padding = screenOffs
        children = mapContainer(mapBlock)
      }
      !hasTabs ? null
        : {
            size = [saSize[0] + tabExtraWidth, FLEX]
            pos = [saBorders[0] - tabExtraWidth, 0]
            flow = FLOW_HORIZONTAL
            children = tabsList(pagesList.get().map(@(p) {
              image = eventPres.image
              tabContent = mkTabLabel(p)
            }))
          }
    ]
    animations = wndSwitchAnim
  }
}

return { treeEventMapWnd, contentOverlayShadeColor }
