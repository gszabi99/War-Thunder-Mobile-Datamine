from "%globalsDarg/darg_library.nut" import *
let { getMapPointsPresentation } = require("%appGlobals/config/mapPointsPresentation.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isEventMapEditorOpened, closeEventMapEditor, selectedPointId, presetMapSize, tuningPoints, selectedBgElemIdx,
  transformInProgress, presetPointSize, presetBackground, currentPresetId, tuningBgElems, selectedElem,
  selectedBgElem, presetGridSize, getElemKey, presetLines, selectedLineIdx, isShiftPressed,
  ELEM_BG, ELEM_POINT, ELEM_LINE, ELEM_MIDPOINT, selectedLineMidpoints, selectedMidpointIdx,
  scalableETypes
} = require("mapEditorState.nut")
let { shiftActions } = require("comboActions.nut")
let { gamercardHeight } = require("%rGui/mainMenu/gamercard.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkText } = require("mapEditorComps.nut")
let mapNet = require("%rGui/event/treeEvent/mapNet.nut")

let manipulator = require("mapPointsManipulator.nut")
let mapEditorHeaderOptions = require("mapEditorHeaderOptions.nut")
let mapEditorSidebarOptions = require("mapEditorSidebarOptions.nut")
let { mkLineCmds, mkLineCmdsOutline, editorSelLineColor, mapLineWidth
} = require("%rGui/event/treeEvent/treeEventComps.nut")


let mapDefaultBackground = mkColoredGradientY(0xFF8A7C63, 0xFFB39B70)
let midpointSize = evenPx(20)
let selBorderWidth = evenPx(4)
let mapBlockSize = [
  sw(100) - 2 * saBorders[0],
  sh(100) - 2 * saBorders[1] - gamercardHeight - defButtonHeight
]

let lineColor = 0xFFFFF0D0
let selPointColor = 0xFF2080FF

let presetInfo = @() {
  watch = [presetMapSize, currentPresetId]
  flow = FLOW_VERTICAL
  children = [
    mkText($"Current preset: {currentPresetId.get()}")
    mkText($"Map size: {presetMapSize.get()[0]} x {presetMapSize.get()[1]}")
  ]
}

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
    let { from = "", to = "" } = presetLines.get()?[id]
    children.append(mkText(from))
    children.append(mkText(to))
  }
  else if (eType == ELEM_MIDPOINT) {
    let { from = "", to = "" } = presetLines.get()?[subId]
    children = [
      mkText($"Current {eType} ({id}) on line:")
      mkText(from)
      mkText(to)
    ]
  }
  return {
    watch = [selectedBgElem, selectedElem, presetLines]
    hplace = ALIGN_RIGHT
    halign = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    children
  }
}

let bottomBar = {
  size = [flex(), SIZE_TO_CONTENT]
  margin = saBordersRv
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  children = [
    presetInfo
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
  size = flex()
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

let pointSizePx = Computed(@() evenPx(presetPointSize.get()))
function mkPoint(id, state) {
  let { view = "", pos } = state
  let { image, color, scale } = getMapPointsPresentation(view).unlocked
  let isSelected = Computed(@() selectedPointId.get() == id)
  let sizeExt = Computed(@() scaleEven(pointSizePx.get(), scale))
  let posExt = Computed(@() (isSelected.get() ? transformInProgress.get()?.pos : null)
    ?? pos.map(@(v) hdpx(v) - sizeExt.get() / 2))

  return function() {
    let size = sizeExt.get()
    return {
      watch = [posExt, sizeExt]
      pos = posExt.get()
      size = [size, size]
      children = @() {
        key = id
        watch = isSelected
        size = flex()
        children = [
          {
            size = [size, size]
            rendObj = ROBJ_IMAGE
            image = Picture($"{image}:{size}:{size}:P")
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
  watch = tuningPoints
  size = flex()
  children = tuningPoints.get().reduce(@(acc, value, id) acc.append(mkPoint(id, value)), [])
}


let bgElements = @() {
  watch = tuningBgElems
  size = flex()
  children = tuningBgElems.get()
    .map(@(b, i) !b?.isOnTop ? mkBgElement(b, i) : null)
}

let bgElementsOnTop = @() {
  watch = tuningBgElems
  size = flex()
  children = tuningBgElems.get()
    .map(@(b, i) !b?.isOnTop ? null : mkBgElement(b, i))
}

let mapBackground = @() {
  watch = presetBackground
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"{presetBackground.get()}:0:P")
  keepAspect = true
}

function mkMidpoint(pRel, idx, mapSize) {
  let isSelected = Computed(@() selectedMidpointIdx.get() == idx)
  let posExt = Computed(@()
    (!isSelected.get() ? null
      : transformInProgress.get()?.pos.map(@(v, a) v - hdpx(presetMapSize.get()[a]) / 2))
    ?? [pw(100.0 * (pRel[0].tofloat() / mapSize[0] - 0.5)), ph(100.0 * (pRel[1].tofloat() / mapSize[1] - 0.5))])
  return @() {
    watch = [isSelected, posExt]
    key = getElemKey(idx, ELEM_MIDPOINT)
    size = [midpointSize, midpointSize]
    pos = posExt.get()
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_VECTOR_CANVAS
    color = isSelected.get() ? editorSelLineColor : lineColor
    fillColor = 0x00202020
    lineWidth = hdpx(6)
    commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  }
}

let mapMidpoints = @() {
  watch = [selectedLineMidpoints, presetMapSize]
  size = flex()
  children = selectedLineMidpoints.get().map(@(p, i) mkMidpoint(p, i, presetMapSize.get()))
}

function selectedLine(lines, points, size) {
  let selMidpointPos = Computed(@() selectedMidpointIdx.get() == null ? null
    : transformInProgress.get()?.pos.map(@(v, a) v.tofloat() * size[a] / hdpx(size[a])))
  return function() {
    local line = lines?[selectedLineIdx.get()]
    if (selMidpointPos.get() != null && selectedMidpointIdx.get() in line?.midpoints) {
      line = line.__merge({ midpoints = clone line.midpoints })
      line.midpoints[selectedMidpointIdx.get()] = selMidpointPos.get()
    }
    let commands = line == null ? null : mkLineCmds(line, points, size)
    if (commands == null || commands.len() == 0)
      return { watch = selectedLineIdx }

    return {
      watch = [selectedLineIdx, selectedMidpointIdx, selMidpointPos]
      size = flex()
      rendObj = ROBJ_VECTOR_CANVAS
      commands = mkLineCmdsOutline(commands, mapLineWidth + 2 * hdpxi(1), editorSelLineColor)
    }
  }
}

function mapLines() {
  let commands = []
  let points = tuningPoints.get()
  let size = presetMapSize.get()
  foreach (line in presetLines.get())
    commands.extend(mkLineCmds(line, points, size))
  return {
    watch = [presetLines, tuningPoints, presetMapSize]
    size = flex()
    rendObj = ROBJ_VECTOR_CANVAS
    color = lineColor
    commands = mkLineCmdsOutline(commands, mapLineWidth)
    children = selectedLine(presetLines.get(), tuningPoints.get(), presetMapSize.get())
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

let mapSize = Computed(@() presetMapSize.get().map(hdpx))
let mapContainer = {
  size = [mapBlockSize[0], mapBlockSize[1]]
  clipChildren = true
  children = {
    size = flex()
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
        mapNet(presetMapSize, presetGridSize, tuningBgElems)
        bgElementsOnTop
        mapLines
        mapPoints
        mapMidpoints
        manipulator
      ]
    }
  }
}

let scPressedMonitor = @(sc, watch) {
  behavior = Behaviors.Button
  onElemState = @(sf) watch((sf & S_ACTIVE) != 0)
  hotkeys = [[sc]]
  onDetach = @() watch(false)
}
let shiftPressedMonitor = scPressedMonitor("^L.Shift | R.Shift", isShiftPressed)

let eventMapEditorWnd = {
  key = {}
  size = flex()
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
