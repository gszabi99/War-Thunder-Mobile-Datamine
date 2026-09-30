from "%globalsDarg/darg_library.nut" import *
from "dagor.fs" import file_exists, read_text_from_file
from "json" import parse_json


const defaultMapSize = [2000, 1000]
const defaultGridSize = 200
const defaultMapBg = ""


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

let mkLoadPreset = @(presetsPath) memoize(function(presetId) {
  let path = $"{presetsPath}/{presetId}.json"
  if (file_exists(path))
    return getPresetDataFromFile(path)
  logerr($"No file found for preset {presetId}!")
  return null
})

let mkEmptyPreset = @() {
  bg = defaultMapBg
  mapSize = defaultMapSize
  gridSize = defaultGridSize
  points = {}
  rewards = {}
  bgElements = []
  lines = []
}

return {
  defaultMapSize = [2000, 1000]
  defaultGridSize = 200
  defaultMapBg = ""

  mkEmptyPreset
  mkLoadPreset
}