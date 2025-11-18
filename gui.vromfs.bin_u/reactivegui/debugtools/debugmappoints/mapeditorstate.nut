from "%globalsDarg/darg_library.nut" import *
let { file } = require("io")
let { scan_folder, read_text_from_file, remove_file } = require("dagor.fs")
let { register_command } = require("console")
let { object_to_json_string, parse_json } = require("json")
let { get_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual, deep_clone } = require("%sqstd/underscore.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { specialEventsWithTree } = require("%rGui/event/eventState.nut")
let { updatePresetByUnlocks, loadPresetOnce } = require("%rGui/event/treeEvent/treeEventUtils.nut")

const SAVE_PATH = "../../skyquake/prog/scripts/wtm/globals/config/eventMapPresets"
const SAVE_EXT = ".json"
const BG_ELEMS_COLLECTION = "../../skyquake/prog/scripts/wtm/globals/config/eventMapPresets/_bg_elems_collection.json"
const MAX_HISTORY_LEN = 50
const AUTO_SAVE_INTERVAL = 5

let ELEM_POINT = "Point"
let ELEM_BG = "Bg Elem"
let ELEM_LINE = "Line"
let ELEM_MIDPOINT = "Midpoint"

let scalableETypes = [ELEM_BG].reduce(@(res, v) res.$rawset(v, true), {})

let defaultMapSize = [2000, 1000]
let defaultGridSize = 200
let defaultPointSize = 50
let defaultMapBg = ""

let isEventMapEditorOpened = mkWatched(persist, "isEventMapEditorOpened", false)
let isHeaderOptionsOpen = mkWatched(persist, "isHeaderOptionsOpen", true)
let isSidebarOptionsOpen = mkWatched(persist, "isSidebarOptionsOpen", true)

let needUseAutoSave = mkWatched(persist, "needUseAutoSave", false)

let loadedPresetWithLastChange = mkWatched(persist, "loadedPresetWithLastChange", null)
let savedPresets = mkWatched(persist, "savedPresets", {})
let bgCollection = mkWatched(persist, "bgCollection", {})
let historyMapElements = mkWatched(persist, "historyMapElements", [])

let selectedElem = mkWatched(persist, "selectedElem", null)
let currentPresetId = mkWatched(persist, "currentPresetId", null)

let hasViewChanges = Watched(false) 
let transformInProgress = Watched(null)
let isShiftPressed = Watched(false)

let loadedPreset = Computed(@() loadedPresetWithLastChange.get()?.mes)
let tuningPoints = Computed(@() loadedPreset.get()?.points ?? {})
let tuningBgElems = Computed(@() loadedPreset.get()?.bgElements ?? [])
let presetLines = Computed(@() loadedPreset.get()?.lines ?? [])
let presetBackground = Computed(@() loadedPreset.get()?.bg ?? defaultMapBg)
let presetMapSize = Computed(@() loadedPreset.get()?.mapSize ?? defaultMapSize)
let presetGridSize = Computed(@() loadedPreset.get()?.gridSize ?? defaultGridSize)
let presetPointSize = Computed(@() loadedPreset.get()?.pointSize ?? defaultPointSize)
let curHistoryIdx = Computed(@() historyMapElements.get().findindex(@(h) h.mes == loadedPreset.get()))

let selectedPointId = Computed(@()
  selectedElem.get()?.id not in tuningPoints.get() || selectedElem.get()?.eType != ELEM_POINT ? null
    : selectedElem.get().id)
let selectedBgElemIdx = Computed(@()
  selectedElem.get()?.eType != ELEM_BG || selectedElem.get()?.id not in tuningBgElems.get() ? null
    : selectedElem.get().id)
let selectedBgElem = Computed(@() tuningBgElems.get()?[selectedBgElemIdx.get()])
let selectedLineIdx = Computed(@()
  (selectedElem.get()?.eType == ELEM_LINE && selectedElem.get()?.id in presetLines.get())
      ? selectedElem.get().id
    : (selectedElem.get()?.eType == ELEM_MIDPOINT && selectedElem.get()?.subId in presetLines.get())
      ? selectedElem.get().subId
    : null)
let selectedLineMidpoints = Computed(@() presetLines.get()?[selectedLineIdx.get()].midpoints ?? [])
let selectedMidpointIdx = Computed(@()
  selectedElem.get()?.eType != ELEM_MIDPOINT || selectedElem.get()?.id  not in selectedLineMidpoints.get() ? null
    : selectedElem.get()?.id)

let curSavedPreset = Computed(@() savedPresets.get()?[currentPresetId.get()])
let isCurPresetChanged = Computed(@() loadedPreset.get() != null
  && currentPresetId.get() != null
  && !isEqual(loadedPreset.get(), curSavedPreset.get()))

let hasEventUnlocks = Computed(@() !!specialEventsWithTree.get())

let isEditAllowed = get_settings_blk()?.debug.useAddonVromSrc ?? false

let keyByElemId = {
  [ELEM_BG] = @(id) $"bg_elem_{id}",
  [ELEM_MIDPOINT] = @(id) $"midpoint_{id}"
}
let getElemKey = @(id, eType) keyByElemId?[eType](id) ?? id

local lastHistoryIdx = curHistoryIdx.get()
loadedPresetWithLastChange.subscribe(function(t) {
  if (t == null || curHistoryIdx.get() != null) {
    lastHistoryIdx = curHistoryIdx.get()
    return
  }
  local h = clone historyMapElements.get()
  let lastHistory = h?[h.len() - 1]
  let isStackToLast = lastHistory != null
    && lastHistory.id == t.id
    && lastHistory.timeEnd >= get_time_msec()

  if (isStackToLast)
    h[h.len() - 1] = t
  else {
    if (lastHistoryIdx != null && lastHistoryIdx < h.len())
      h = h.slice(0, lastHistoryIdx + 1)
    h.append(t)
    if (h.len() > MAX_HISTORY_LEN)
      h.remove(0)
  }
  lastHistoryIdx = curHistoryIdx.get()
  historyMapElements.set(h)
})

let mkEmptyPreset = @() {
  bg = defaultMapBg
  mapSize = defaultMapSize
  gridSize = defaultGridSize
  pointSize = defaultPointSize
  points = {}
  bgElements = []
  lines = []
}

let setMapElementsState = @(mes, id = "")
  loadedPresetWithLastChange.set({ mes, id, timeEnd = get_time_msec() })

function changeCurPresetField(key, value) {
  if (loadedPreset.get() != null)
    setMapElementsState(loadedPreset.get().__merge({ [key] = value }))
}

let clearPointsState = @() setMapElementsState(mkEmptyPreset())

function loadPreset(id, useCurrentId = false) {
  if (!useCurrentId)
    currentPresetId.set(id)

  historyMapElements.set([])
  setMapElementsState(mkEmptyPreset().__merge(savedPresets.get()?[currentPresetId.get()] ?? {}))
}
currentPresetId.whiteListMutatorClosure(loadPreset)

function writePresetToFile(id, preset) {
  let presetfile = file($"{SAVE_PATH}/{id}{SAVE_EXT}", "wt+")
  presetfile.writestring(object_to_json_string(preset, true))
  presetfile.close()
  dlog($"Saved to: wtm/globals/config/eventMapPresets/{id}") 
}

function deleteFileByPresetId(id) {
  let path = $"{SAVE_PATH}/{id}{SAVE_EXT}"
  let status = remove_file(path)
  if (status)
    dlog($"The file {id} has been deleted") 
  else
    logerr($"Error while trying to delete file: {path}")
}

function savePreset(id, preset) {
  hasViewChanges.set(true)
  savedPresets.set(savedPresets.get().__merge({ [id] = preset }))
  writePresetToFile(id, preset)
}

function getPresetsDataFromFiles(files) {
  let res = {}

  foreach(fileName in files) {
    if (!fileName.endswith(SAVE_EXT))
      continue
    let id = fileName.split("/").top().slice(0, -SAVE_EXT.len())
    if (id.startswith("_"))
      continue
    try {
      let fileContent = read_text_from_file(fileName)
      let preset = parse_json(fileContent)
      if (type(preset) == "table")
        res[id] <- preset
    }
    catch(e)
      logerr($"Failed to parse preset {fileName} from file: {e}")
  }

  return res
}

function selectAndLoadFirstPreset() {
  let firstPreset = savedPresets.get().findindex(@(_) true)
  loadPreset(firstPreset, true)
}

let bgFieldErrors = {
  img = @(v) type(v) != "string" ? "should be a string" : null
  size = @(v) type(v) != "array" || v.len() != 2 || null != v.findindex(@(c) type(c) != "integer")
    ? "should be an array of 2 integers"
    : null
  rotate = @(v) v != null && type(v) != "integer" && type(v) != "float" ? "should be numeric" : null
}

function reloadBgElemsCollection() {
  try {
    let fileContent = read_text_from_file(BG_ELEMS_COLLECTION)
    let collection = parse_json(fileContent)
    if (type(collection) == "table")
      bgCollection.set(collection.filter(function(e, id) {
        foreach (key, getErr in bgFieldErrors) {
          let err = getErr(e?[key])
          if (err != null) {
            logerr($"Load collection bg elem {id} field error: {key}: {err}")
            return false
          }
        }
        foreach (key, _ in e)
          if (key not in bgFieldErrors)
            logerr($"Unknown collection bg elem {id} field: {key}")
        return true
      }))
  }
  catch(e)
    logerr($"Failed to parse collection {BG_ELEMS_COLLECTION} from file: {e}")
}

isEventMapEditorOpened.subscribe(function(v) {
  if (v) {
    let presetFiles = scan_folder({ root = SAVE_PATH, vromfs = true, realfs = true, recursive = false })

    savedPresets.set(getPresetsDataFromFiles(presetFiles))
    selectAndLoadFirstPreset()
    reloadBgElemsCollection()
  } else if (hasViewChanges.get())
    eventbus_send("reloadDargVM", { msg = "debug event map points apply" })
})

function addOrEditPreset(id, bg, mapSize) {
  loadPreset(id)
  setMapElementsState(loadedPreset.get().__merge({ bg, mapSize, gridSize = mapSize[0] / 10 }))
}

function deletePreset(id) {
  hasViewChanges.set(true)

  let presets = clone savedPresets.get()
  presets.$rawdelete(id)
  savedPresets.set(presets)
  deleteFileByPresetId(id)

  let newCurrenPreset = savedPresets.get().findvalue(@(_) true) ?? {}

  loadPreset(newCurrenPreset?.id)
}

let selectElem = @(id, eType = ELEM_POINT, subId = null) selectedElem.set(id == null ? null : { id, eType, subId })
let deselectElem = @() selectedElem.set(null)
selectedElem.whiteListMutatorClosure(selectElem)
selectedElem.whiteListMutatorClosure(deselectElem)

function getMiddleScreenMapPos(size) {
  let aabb = gui_scene.getCompAABBbyKey("mapEditorMap")
  if (aabb == null)
    return [0, 0]
  let mapSize = presetMapSize.get()
  let { t, l, r } = aabb
  let posPx = [sw(50) - l, sh(50) - t]
  let scale = mapSize[0].tofloat() / max(1, r - l)
  return posPx.map(@(v, i) (v * scale + 0.5).tointeger() - size[i] / 2)
}

function editBgElement(idx, id, img, size, rotate) {
  if (loadedPreset.get() == null)
    return

  let updatedElems = clone loadedPreset.get().bgElements
  if (idx not in updatedElems)
    return
  updatedElems[idx] = updatedElems[idx].__merge({ id, img, size, rotate })
  changeCurPresetField("bgElements", updatedElems)
}

function addBgElement(id, img, size, rotate) {
  if (loadedPreset.get() == null)
    return null

  let updatedElems = clone loadedPreset.get().bgElements
  updatedElems.append({ id, pos = getMiddleScreenMapPos(size), img, size, rotate })
  changeCurPresetField("bgElements", updatedElems)
  return updatedElems.len() - 1
}

function addOrEditPoint(id, view) {
  if (loadedPreset.get() == null)
    clearPointsState()

  let mes = loadedPreset.get()
  let updatedPoints = clone mes.points

  if (id in updatedPoints)
    updatedPoints[id] = updatedPoints[id].__merge({ view })
  else {
    let size = presetPointSize.get()
    updatedPoints[id] <- { pos = getMiddleScreenMapPos([size, size]), view }
  }

  setMapElementsState(mes.__merge({ points = updatedPoints }), id)
}

function deleteElement(id, eType, subId) {
  deselectElem()

  if (eType == ELEM_BG) {
    if (id not in tuningBgElems.get())
      return
    let bgElements = clone loadedPreset.get().bgElements
    bgElements.remove(id)
    changeCurPresetField("bgElements", bgElements)
    return
  }

  if (eType == ELEM_POINT) {
    if (id not in tuningPoints.get())
      return
    let points = clone loadedPreset.get().points
    points.$rawdelete(id)
    changeCurPresetField("points", points)
    return
  }

  if (eType == ELEM_LINE) {
    if (id not in presetLines.get())
      return
    let lines = clone loadedPreset.get().lines
    lines.remove(id)
    changeCurPresetField("lines", lines)
    return
  }

  if (eType == ELEM_MIDPOINT) {
    if (id not in presetLines.get()?[subId].midpoints)
      return
    let lines = clone loadedPreset.get().lines
    let midpoints = clone lines[subId].midpoints
    let { from, to } = lines[subId]
    let count = midpoints.len() + (from in tuningPoints.get() ? 1 : 0) + (to in tuningPoints.get() ? 1 : 0)
    if (count < 3) {
      openFMsgBox({ text = "Unable to remove point when only 2 points left in the line" })
      selectElem(id, eType, subId)
      return
    }

    midpoints.remove(id)
    lines[subId] = lines[subId].__merge({ midpoints })
    changeCurPresetField("lines", lines)
    selectElem(subId, ELEM_LINE) 
    return
  }
}

function copyElement(id, eType) {
  if (eType == ELEM_BG) {
    let elem = deep_clone(tuningBgElems.get()?[id])
    if (elem == null)
      return
    let bgElements = clone tuningBgElems.get()
    elem.pos = elem.pos.map(@(v) v + 20)
    bgElements.append(elem)
    changeCurPresetField("bgElements", bgElements)
    selectElem(bgElements.len() - 1, eType)
    return
  }
}

function setByHistory(historyIdx) {
  let h = historyMapElements.get()?[historyIdx]
  if (h != null)
    loadedPresetWithLastChange.set(h)
}

function saveCurrentPreset() {
  if (currentPresetId.get() != null && loadedPreset.get() != null)
    savePreset(currentPresetId.get(), loadedPreset.get())
}

let delayedAutoSave = @() isCurPresetChanged.get() ? saveCurrentPreset() : null
needUseAutoSave.subscribe(@(v) v ? setInterval(AUTO_SAVE_INTERVAL, delayedAutoSave) : clearTimer(delayedAutoSave))

function applyTransformProgress() {
  if (loadedPreset.get() == null || transformInProgress.get() == null)
    return

  let { id = null, eType = null, subId = null } = selectedElem.get()
  let { pos, mapSizePx, size = null, flip = null } = transformInProgress.get()
  transformInProgress.set(null)
  let { mapSize } = loadedPreset.get()
  let posExt = pos.map(@(v, i) (v.tofloat() * mapSize[i] / mapSizePx[i] + 0.5).tointeger())
  let sizeExt = size == null ? null
    : size.map(@(v, i) (v.tofloat() * mapSize[i] / mapSizePx[i] + 0.5).tointeger())

  if (eType == ELEM_BG) {
    let bgElements = clone loadedPreset.get().bgElements
    if (id in bgElements) {
      let { flipX = false, flipY = false } = bgElements[id]
      bgElements[id] = bgElements[id].__merge({
        pos = posExt
        size = sizeExt ?? bgElements[id].size
        flipX = flip?[0] ? !flipX : flipX
        flipY = flip?[1] ? !flipY : flipY
      })
      foreach (f in ["flipX", "flipY"])
        if (!bgElements[id][f])
          bgElements[id].$rawdelete(f)

      changeCurPresetField("bgElements", bgElements)
    }
    return
  }

  if (eType == ELEM_POINT) {
    let points = clone loadedPreset.get().points
    if (id in points) {
      points[id] = points[id].__merge({ pos = posExt.map(@(v) (v + presetPointSize.get() / 2).tointeger()) })
      changeCurPresetField("points", points)
    }
    return
  }

  if (eType == ELEM_MIDPOINT) {
    if (id not in presetLines.get()?[subId].midpoints)
      return
    let lines = clone loadedPreset.get().lines
    let midpoints = clone lines[subId].midpoints 
    midpoints[id] = posExt
    lines[subId] = lines[subId].__merge({ midpoints }) 
    changeCurPresetField("lines", lines)
    return
  }
}

function makePresetFilesByUnlocks(presets) {
  foreach (id, preset in presets) {
    let presetfile = file($"{SAVE_PATH}/{id}{SAVE_EXT}", "wt+")
    presetfile.writestring(object_to_json_string(preset, true))
    presetfile.close()
  }
}

let mkDefaultLine = @(from, to) { from, to }

let findLineIdx = @(point1, point2, lines)
  lines.findindex(@(l)
    (l.from == point1 && l.to == point2)
    || (l.from == point2 && l.to == point1))

function addLine(from, to) {
  let idx = findLineIdx(from, to, presetLines.get())
  if (idx != null)
    return "Line already exists"

  let line = mkDefaultLine(from, to)
  foreach(id in [from, to])
    if (id not in tuningPoints.get()) {
      let { pos = null, size = null } = tuningBgElems.get().findvalue(@(e) e.id == id)
      if (pos == null || size == null)
        return $"bg elem {id} not found"
      line.midpoints <- (line?.midpoints ?? []).append(pos.map(@(v, a) v + size[a] / 2))
    }

  let lines = clone presetLines.get()
  lines.append(line)
  changeCurPresetField("lines", lines)
  selectElem(lines.len() - 1, ELEM_LINE)
  return ""
}

function changeLine(idx, line) {
  if (idx not in presetLines.get())
    return

  let lines = clone presetLines.get()
  lines[idx] = line
  changeCurPresetField("lines", lines)
}

function createPresetsByUnlocks() {
  let treeEventPresets = activeUnlocks.get().filter(@(unlock) unlock?.meta.quest_cluster)

  let presets = {}
  foreach (presetId, _ in treeEventPresets)
    presets[presetId] <- updatePresetByUnlocks(presetId, loadPresetOnce(presetId) ?? {})

  savedPresets.set(savedPresets.get().__merge(presets))
  selectAndLoadFirstPreset()
  makePresetFilesByUnlocks(presets)
}

register_command(@() isEventMapEditorOpened.set(true), "ui.debug.event_map_editor")

return {
  isEventMapEditorOpened
  isHeaderOptionsOpen
  isSidebarOptionsOpen
  isCurPresetChanged
  isEditAllowed

  currentPresetId
  savedPresets
  addOrEditPreset
  loadPreset
  deletePreset

  transformInProgress
  isShiftPressed
  applyTransformProgress
  saveCurrentPreset

  loadedPreset
  changeCurPresetField

  selectedPointId
  addOrEditPoint
  tuningPoints
  presetLines
  addLine
  changeLine

  historyMapElements
  setByHistory
  curHistoryIdx

  presetMapSize
  presetGridSize
  presetBackground
  presetPointSize
  defaultPointSize

  selectedElem
  selectedLineIdx
  selectedLineMidpoints
  selectedMidpointIdx
  selectElem
  deselectElem
  deleteElement
  copyElement

  selectedBgElemIdx
  selectedBgElem
  addBgElement
  editBgElement
  tuningBgElems
  bgCollection

  needUseAutoSave
  createPresetsByUnlocks
  hasEventUnlocks
  closeEventMapEditor = @() isEventMapEditorOpened.set(false)

  ELEM_POINT
  ELEM_BG
  ELEM_LINE
  ELEM_MIDPOINT
  scalableETypes
  getElemKey
}
