from "%globalsDarg/darg_library.nut" import *

let { file_exists, read_text_from_file } = require("dagor.fs")
let { parse_json } = require("json")

let { activeUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { specialEventsWithTree } = require("%rGui/event/eventState.nut")


const SAVED_PRESETS_PATH = "%appGlobals/config/eventMapPresets"
const FILE_EXT = ".json"

let defaultMapSize = [600, 500]
let defaultGridSize = 100
let defaultPointSize = 50
let defaultMapBg = ""

function getPresetDataFromFile(path) {
  if (!path)
    return null
  local res = null
  try {
    let fileContent = read_text_from_file(path)
    res = parse_json(fileContent)
  }
  catch(e)
    logerr($"Failed to parse preset from file: {e}")

  return res
}

let loadPresetOnce = memoize(function(presetId) {
  let path = $"{SAVED_PRESETS_PATH}/{presetId}{FILE_EXT}"
  if (file_exists(path))
    return getPresetDataFromFile(path)
  logerr($"No file found for preset {presetId}!")
  return null
})

function mkUnlocksByPresets(events, unlocks) {
  let res = {}

  foreach (name, u in unlocks) {
    if (u?.meta.event_id not in events)
      continue
    let presetId = u?.meta.quest_cluster_id
    if (presetId == null)
      continue
    if (presetId not in res)
      res[presetId] <- {}
    res[presetId][name] <- u
  }

  return res
}

let mkEmptyPreset = @() {
  bg = defaultMapBg
  mapSize = defaultMapSize
  gridSize = defaultGridSize
  pointSize = defaultPointSize
  points = {}
  bgElements = []
  lines = []
}

let mkDefaultPoint = @(pos) { pos, view = "mapMark" }
let mkDefaultLine = @(from, to) { from, to }

let findLineIdx = @(point1, point2, lines)
  lines.findindex(@(l)
    (l.from == point1 && l.to == point2)
    || (l.from == point2 && l.to == point1))

function updatePresetByUnlocks(presetId, savedPreset = {}) {
  let events = specialEventsWithTree.get().reduce(@(res, v) res.$rawset(v.eventName, true), {})
  let unlocksByPresets = mkUnlocksByPresets(events, activeUnlocks.get())

  local preset = {}
  local indexes = 0
  let columns = 5

  function initPreset() {
    if (preset.len() == 0) {
      preset = mkEmptyPreset().__merge(preset, savedPreset)
      preset.points = clone preset.points
      preset.lines = clone preset.lines
    }
    return preset
  }

  let unlocks = unlocksByPresets?[presetId] ?? {}
  let orderedUnlock = unlocks.keys().sort()
  foreach (key in orderedUnlock) {
    
    if (key not in savedPreset?.points) {
      let curPreset = initPreset()
      let { mapSize, gridSize } = curPreset
      let x = clamp((mapSize[0] / 2) + (indexes % columns - 2) * gridSize, 0, mapSize[0])
      let y = clamp((mapSize[1] / 2) + (indexes / columns - 2) * gridSize, 0, mapSize[1])

      curPreset.points[key] <- mkDefaultPoint([x, y])
      indexes = indexes + 1
    }

    let unlock = unlocks?[key] ?? {}
    let { requirement = "" } = unlock
    
    if (requirement in unlocks
        && null == findLineIdx(key, requirement, savedPreset?.lines ?? [])) {
      let curPreset = initPreset()
      curPreset.lines.append(mkDefaultLine(requirement, key))
    }
  }

  return {}.__merge(savedPreset, preset)
}

return {
  loadPresetOnce
  updatePresetByUnlocks
}
