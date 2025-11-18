from "%globalsDarg/darg_library.nut" import *
let { register_command, command } = require("console")
let { getUnitFileName } = require("vehicleModel")
let { get_unittags_blk } = require("blkGetters")
let { object_to_json_string } = require("json")
let io = require("io")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { Point2 } = require("dagor.math")
let { eachBlock, blkOptFromPath } = require("%sqstd/datablock.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { MAX_DECAL_SLOTS_COUNT } = require("%rGui/unit/hangarUnit.nut")

let prepareInstance = {
  [Point2] = @(v) { x = v.x, y = v.y },
}

local loadAllSkinDecalsProgress = null
let onloadAllSkinDecals = []

let remapSkinNames = {
  "default": ""
}

let getRemapSkinName = @(skin) skin in remapSkinNames ? remapSkinNames[skin] : skin

function prepareDataForJson(data) {
  let dataType = type(data)
  if (dataType == "instance")
    return prepareInstance?[data.getclass()](data) ?? data
  if (dataType == "array" || dataType == "table") {
    local isChanged = false
    let prepare = prepareDataForJson
    local res = data.map(function(v) {
      let newV = prepare(v)
      isChanged = isChanged || newV != v
      return newV
    })
    return isChanged ? res : data
  }
  return data
}

function getUnitDecals(decalBlk) {
  let res = []
  if (!decalBlk)
    return res

  for (local i = 0; i < MAX_DECAL_SLOTS_COUNT; i++) {
    let decal = decalBlk?[$"decal{i}Tex"]
    if (decal != null && decal != "")
      res.append(decal)
  }

  return res
}

function loadUnitSkinsDecals(realUnitName) {
  let unitBlk = blkOptFromPath(getUnitFileName(getTagsUnitName(realUnitName)))
  let { defaultDecals = {}, upgradedDecals = {} } = unitBlk

  let res = {}

  foreach(skinName, decalBlk in defaultDecals) {
    let decals = getUnitDecals(decalBlk)
    let skin = getRemapSkinName(skinName)
    if (decals.len() != 0)
      res[skin] <- decals
  }

  foreach(skinName, decalBlk in upgradedDecals) {
    let decals = getUnitDecals(decalBlk)
    let skin = getRemapSkinName(skinName)
    if (decals.len() != 0)
      res[skin] <- decals
  }

  return res
}

function onFinishLoad() {
  let actions = clone onloadAllSkinDecals
  onloadAllSkinDecals.clear()
  if (loadAllSkinDecalsProgress == null)
    return
  let { res } = loadAllSkinDecalsProgress
  loadAllSkinDecalsProgress = null
  foreach(action in actions)
    action(res)
}

function loadNextSkinDecals() {
  if (loadAllSkinDecalsProgress == null) {
    clearTimer(loadNextSkinDecals)
    onFinishLoad()
    return
  }
  let time = get_time_msec()
  let { res, todo } = loadAllSkinDecalsProgress
  while(todo.len() > 0) {
    let name = todo.pop()
    command($"console.progress_indicator loadAllSkinDecals {res.len()}/{res.len() + todo.len()}")
    let decalsList = loadUnitSkinsDecals(name)
    if (decalsList.len() != 0)
      res[name] <- decalsList
    if (get_time_msec() - time >= 10)
      return
  }
  command($"console.progress_indicator loadAllSkinDecals")
  clearTimer(loadNextSkinDecals)
  onFinishLoad()
}

function loadAllSkinDecalsAndDo(action) {
  onloadAllSkinDecals.append(action)
  if (loadAllSkinDecalsProgress != null)
    return
  loadAllSkinDecalsProgress = { res = {}, todo = [] }
  eachBlock(get_unittags_blk(), @(blk) loadAllSkinDecalsProgress.todo.append(blk.getBlockName()))
  setInterval(0.001, loadNextSkinDecals)
}

register_command(
  @(filePrefix) loadAllSkinDecalsAndDo(function(data) {
    let filePath = $"{filePrefix}SkinDecals.json"
    let file = io.file(filePath, "wt+")
    file.writestring(object_to_json_string(prepareDataForJson(data), true))
    file.close()
    log($"Saved file {filePath}")
  }),
  "debug.save_all_unit_skin_decals_to_files_by_type")