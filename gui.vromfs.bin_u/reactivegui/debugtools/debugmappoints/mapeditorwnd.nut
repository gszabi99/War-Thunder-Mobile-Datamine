from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/mapPointsPresentation.nut" import getMapPointsPresentation, getPointOffset, defaultPointView
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/debugTools/debugMapPoints/comboActions.nut" import shiftActions
from "%rGui/debugTools/debugMapPoints/mapEditorComps.nut" import mkText, mkTextArea
import "%rGui/debugTools/debugMapPoints/mapEditorHeaderOptions.nut" as mapEditorHeaderOptions
import "%rGui/debugTools/debugMapPoints/mapEditorSidebarOptions.nut" as mapEditorSidebarOptions
from "%rGui/debugTools/debugMapPoints/mapEditorState.nut" import isEventMapEditorOpened, closeEventMapEditor,
  selectedPointId, pageMapSize, tuningPoints, selectedBgElemIdx, curEventId, transformInProgress,
  pageBackground, currentPageId, tuningBgElems, selectedElem, selectedBgElem, pageGridSize, getElemKey, pageLines,
  selectedLineIdx, isShiftPressed, ELEM_BG, ELEM_POINT, ELEM_LINE, ELEM_MIDPOINT, ELEM_LINE_END, selectedLineMidpoints,
  selectedMidpointIdx, selectedLineEnds, selectedLineEndId, scalableETypes, curEventNodeViews, pagePointSizes,
  pointViewSize, pageLineSectionLen, pageRoundedDashes, pageLineType, pageLineWidth
import "%rGui/debugTools/debugMapPoints/mapPointsManipulator.nut" as manipulator
import "%rGui/event/treeEvent/mapNet.nut" as mapNet
from "%rGui/event/treeEvent/treeEventComps.nut" import mkLineCmds, mkSolidLineCmds, mkLineCmdsOutline,
  lineTypeCtors, buildLineSpline, LINE_DASHED, LINE_SOLID, editorSelLineColor
from "%rGui/navState.nut" import registerScene
from "%rGui/style/gamercardStyle.nut" import gamercardHeight
from "%rGui/style/gradients.nut" import mkColoredGradientY
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let mapDefaultBackground = mkColoredGradientY(0xFF8A7C63, 0xFFB39B70)
let midpointSize = evenPx(20)
let selBorderWidth = evenPx(4)
let mapBlockSize = [
  sw(100) - 2 * saBorders[0],
  sh(100) - 2 * saBorders[1] - gamercardHeight - defButtonHeight
]

const lineColor = 0xFFFFF0D0
const selPointColor = 0xFF2080FF
const selMarkerColor = 0xFFFF2020

let pageInfo = @() mkTextArea(
  "\n".join([
    $"Event: {curEventId.get()}"
    $"Current page: {currentPageId.get()}"
    $"Map size: {pageMapSize.get()[0]} x {pageMapSize.get()[1]}"
  ]),
  { watch = [pageMapSize, currentPageId, curEventId] })

function selectedInfo() {
  let { id = null, eType = null, subId = null } = selectedElem.get()
  local children = []
  if (id != null)
    children.append(mkText($"Current {eType}:"))
  if (eType == ELEM_POINT)
    children.append(mkText(id))
  else if (eType == ELEM_BG) {
    children.append(mkText(selectedBgElem.get()?.id ?? id))
    children.append(mkText(selectedBgElem.get()?.img ?? ""))
  }
  else if (eType == ELEM_LINE) {
    let { from = "", to = "" } = pageLines.get()?[id]
    children.append(mkText(from))
    children.append(mkText(to))
  }
  else if (eType == ELEM_MIDPOINT || eType == ELEM_LINE_END) {
    let { from = "", to = "" } = pageLines.get()?[subId]
    children = [
      mkText($"Current {eType} ({id}) on line:")
      mkText(from)
      mkText(to)
    ]
  }
  return {
    watch = [selectedBgElem, selectedElem, pageLines]
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    children
  }
}

let bottomBar = {
  size = FLEX_H
  margin = saBordersRv
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  children = [
    pageInfo
    selectedInfo
  ]
}

let point = {
  size = [selBorderWidth, selBorderWidth]
  children = {
    size = [3 * selBorderWidth, 3 * selBorderWidth]
    rendObj = ROBJ_SOLID
    color = selPointColor
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
  }
}

let selectBorder = {
  size = FLEX
  rendObj = ROBJ_BOX
  fillColor = 0
  borderColor = editorSelLineColor
  borderWidth = selBorderWidth
  children = [
    { hplace = ALIGN_CENTER, vplace = ALIGN_TOP }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_LEFT, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_LEFT, vplace = ALIGN_CENTER }
    { hplace = ALIGN_LEFT, vplace = ALIGN_TOP }
  ].map(@(ovr) point.__merge(ovr))
}

function mkPoint(id, state, nodeViews) {
  let { view = "", pos } = state
  let effView = view != "" ? view : (nodeViews?[id] ?? defaultPointView)
  let { image, color } = getMapPointsPresentation(effView).unlocked
  let offset = getPointOffset(effView)
  let isSelected = Computed(@() selectedPointId.get() == id)
  let sizeExt = Computed(@() evenPx(pointViewSize(id, view, nodeViews, pagePointSizes.get())))
  let posExt = Computed(@() (isSelected.get() ? transformInProgress.get()?.pos : null)
    ?? pos.map(@(v) hdpx(v) - sizeExt.get() / 2))

  return function() {
    let size = sizeExt.get()
    return {
      watch = [posExt, sizeExt]
      pos = posExt.get()
      size
      children = @() {
        key = id
        watch = isSelected
        size = FLEX
        children = [
          {
            size
            pos = [offset[0] * size, offset[1] * size]
            rendObj = ROBJ_IMAGE
            image = Picture($"{image}:{size}:P")
            color
            keepAspect = true
          }
          isSelected.get() ? selectBorder : null
        ]
      }
    }
  }
}

function mkBgElement(state, idx) {
  let { img, size, pos, rotate, flipX = false, flipY = false } = state
  let isSelected = Computed(@() selectedBgElemIdx.get() == idx)
  let posExt = Computed(@() (isSelected.get() ? transformInProgress.get()?.pos : null)
    ?? pos.map(hdpx))
  let sizeBase = size.map(hdpx)
  let sizeExt = Computed(@() (isSelected.get() ? transformInProgress.get()?.size : null)
    ?? sizeBase)
  let flipExt = Computed(@() isSelected.get() ? transformInProgress.get()?.flip : null)
  return @() {
    watch = [posExt, sizeExt, flipExt, isSelected]
    pos = posExt.get()
    size = sizeExt.get()
    children = {
      key = getElemKey(idx, ELEM_BG)
      children = [
        {
          size = sizeExt.get()
          rendObj = ROBJ_IMAGE
          image = Picture($"{img}:{sizeBase[0]}:{sizeBase[1]}:P")
          keepAspect = true
          flipX = flipExt.get()?[0] ? !flipX : flipX
          flipY = flipExt.get()?[1] ? !flipY : flipY
        }
        isSelected.get() ? selectBorder : null
      ]
      transform = { rotate }
    }
  }
}

let mapPoints = @() {
  watch = [tuningPoints, curEventNodeViews]
  size = FLEX
  children = tuningPoints.get().reduce(@(acc, value, id) acc.append(mkPoint(id, value, curEventNodeViews.get())), [])
}

let bgElements = @() {
  watch = tuningBgElems
  size = FLEX
  children = tuningBgElems.get()
    .map(@(b, i) !b?.isOnTop ? mkBgElement(b, i) : null)
}

let bgElementsOnTop = @() {
  watch = tuningBgElems
  size = FLEX
  children = tuningBgElems.get()
    .map(@(b, i) !b?.isOnTop ? null : mkBgElement(b, i))
}

let mapBackground = @() {
  watch = pageBackground
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"{pageBackground.get()}:0:P")
  keepAspect = true
}

function mkMarker(isSelected, key, pRel, mapSize, unselColor) {
  let posExt = Computed(@()
    (!isSelected.get() ? null
      : transformInProgress.get()?.pos.map(@(v, a) v - hdpx(pageMapSize.get()[a]) / 2))
    ?? [pw(100.0 * (pRel[0].tofloat() / mapSize[0] - 0.5)), ph(100.0 * (pRel[1].tofloat() / mapSize[1] - 0.5))])
  return @() {
    watch = [isSelected, posExt]
    key
    size = [midpointSize, midpointSize]
    pos = posExt.get()
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    color = isSelected.get() ? selMarkerColor : unselColor
    fillColor = 0x00202020
    lineWidth = hdpx(6)
    commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  }
}

let mapMidpoints = @() {
  watch = [selectedLineMidpoints, pageMapSize]
  size = FLEX
  children = selectedLineMidpoints.get().map(@(p, i) mkMarker(Computed(@() selectedMidpointIdx.get() == i),
    getElemKey(i, ELEM_MIDPOINT), p, pageMapSize.get(), lineColor))
}

let mapLineEnds = @() {
  watch = [selectedLineEnds, pageMapSize]
  size = FLEX
  children = selectedLineEnds.get().map(@(e) mkMarker(Computed(@() selectedLineEndId.get() == e.id),
    getElemKey(e.id, ELEM_LINE_END), e.pos, pageMapSize.get(), selPointColor))
}

function selectedLine(lines, points, size) {
  let dragMapPos = Computed(@() transformInProgress.get()?.pos.map(@(v, a) v.tofloat() * size[a] / hdpx(size[a])))
  return function() {
    local line = lines?[selectedLineIdx.get()]
    let dragPos = dragMapPos.get()
    let midIdx = selectedMidpointIdx.get()
    let endId = selectedLineEndId.get()
    if (dragPos != null && midIdx != null && midIdx in line?.midpoints) {
      line = line.__merge({ midpoints = clone line.midpoints })
      line.midpoints[midIdx] = dragPos
    }
    if (dragPos != null && endId != null && line != null)
      line = line.__merge({ [endId == "from" ? "fromPos" : "toPos"] = dragPos })
    let commands = line == null ? null
      : pageLineType.get() == LINE_SOLID ? mkSolidLineCmds(line, points, size)
      : mkLineCmds(line, points, size, pageLineSectionLen.get())
    if (commands == null || commands.len() == 0)
      return { watch = selectedLineIdx }

    return {
      watch = [selectedLineIdx, selectedMidpointIdx, selectedLineEndId, dragMapPos,
        pageLineSectionLen, pageLineWidth, pageLineType]
      size = FLEX
      rendObj = ROBJ_VECTOR_CANVAS
      commands = mkLineCmdsOutline(commands, hdpx(pageLineWidth.get()) + 2 * hdpxi(1), editorSelLineColor)
    }
  }
}

function mapLines() {
  let points = tuningPoints.get()
  let lineType = pageLineType.get()
  let mkCommands = lineTypeCtors?[lineType] ?? lineTypeCtors[LINE_DASHED]
  let needSpline = lineType != LINE_SOLID
  let lineSplines = pageLines.get().map(@(line) { line, spline = needSpline ? buildLineSpline(line, points) : null })

  return {
    watch = [pageLines, tuningPoints, pageMapSize, pageLineSectionLen, pageRoundedDashes, pageLineType, pageLineWidth]
    size = FLEX
    rendObj = ROBJ_VECTOR_CANVAS
    color = lineColor
    fillColor = lineColor
    commands = mkCommands(lineSplines, {
      size = pageMapSize.get()
      width = hdpx(pageLineWidth.get())
      sectionLen = pageLineSectionLen.get()
      rounded = pageRoundedDashes.get()
      points
      colorOf = @(_) null
    })
    children = selectedLine(pageLines.get(), tuningPoints.get(), pageMapSize.get())
  }
}

function comboHint() {
  let { shiftInfo = null, info = "", isFit = null } = shiftActions?[selectedElem.get()?.eType]
  return {
    watch = [selectedElem, isShiftPressed]
    margin = hdpx(10)
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = selectedElem.get() == null ? null
      : [
          !scalableETypes?[selectedElem.get().eType] ? null
            : mkText("Hold Ctrl and drag mouse to scale", fontTinyAccentedShaded)
          !(isFit?(selectedElem.get().id) ?? true) ? null
            : mkText((isShiftPressed.get() ? shiftInfo : null) ?? info, fontTinyAccentedShaded)
        ]
  }
}

let mapSize = Computed(@() pageMapSize.get().map(hdpx))
let mapContainer = {
  size = [mapBlockSize[0], mapBlockSize[1]]
  clipChildren = true
  children = {
    size = FLEX
    behavior = Behaviors.Pannable,
    touchMarginPriority = TOUCH_BACKGROUND
    halign = ALIGN_CENTER
    children = @() {
      watch = mapSize
      key = "mapEditorMap"
      size = mapSize.get()
      hplace = mapBlockSize[0] > mapSize.get()[0] ? ALIGN_CENTER : null
      vplace = mapBlockSize[1] > mapSize.get()[1] ? ALIGN_CENTER : null
      rendObj = ROBJ_IMAGE
      image = mapDefaultBackground
      children = [
        mapBackground
        bgElements
        mapNet(pageMapSize, pageGridSize, tuningBgElems)
        bgElementsOnTop
        mapLines
        mapPoints
        mapMidpoints
        mapLineEnds
        manipulator
      ]
    }
  }
}

let scPressedMonitor = @(sc, watch) {
  behavior = Behaviors.Button
  onElemState = @(sf) watch.set((sf & S_ACTIVE) != 0)
  hotkeys = [[sc]]
  onDetach = @() watch.set(false)
}
let shiftPressedMonitor = scPressedMonitor("^L.Shift | R.Shift", isShiftPressed)

let eventMapEditorWnd = {
  key = {}
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/event_bg.avif")
  children = [
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        mapContainer
        comboHint
      ]
    }
    mapEditorHeaderOptions
    mapEditorSidebarOptions
    bottomBar
    shiftPressedMonitor
  ]
  animations = wndSwitchAnim
}

registerScene("eventMapEditorWnd", eventMapEditorWnd, closeEventMapEditor, isEventMapEditorOpened)
