from "%globalsDarg/darg_library.nut" import *
let { register_command, command } = require("console")
let { object_to_json_string } = require("json")
let { get_unittags_blk } = require("blkGetters")
let { file } = require("io")
let { DM_VIEWER_NONE, DM_VIEWER_XRAY } = require("hangar")
let { mkpath } = require("dagor.fs")
let { get_time_msec } = require("dagor.time")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { eachBlock } = require("%sqstd/datablock.nut")
let { dmViewerMode, isDebugBatchExportProcess } = require("dmViewerState.nut")
let { mkUnitDataForXray, mkPartTooltipInfo } = require("modeXray.nut")

function collectItemInfo(unitName) {
  let unitData = mkUnitDataForXray(unitName, null)
  if (unitData.unit == null)
    return null
  let partNames = []
  let damagePartsBlk = unitData.unitBlk?.DamageParts
  if (damagePartsBlk)
    for (local b = 0; b < damagePartsBlk.blockCount(); b++) {
      let partsBlk = damagePartsBlk.getBlock(b)
      for (local p = 0; p < partsBlk.blockCount(); p++) {
        let partName = partsBlk.getBlock(p).getBlockName()
        if (!partNames.contains(partName))
          partNames.append(partName)
      }
    }
  partNames.sort()

  let res = {}
  foreach (partName in partNames) {
    let info = mkPartTooltipInfo(partName, unitData)
    if (info.title.len())
      res[partName] <- "\n".join([ info.title, info.desc ], true)
  }
  return res.len() ? res : null
}

let progressId = "unitsXray"
local loadAllItemsProgress = null
let onFinishActions = []

function onFinishLoad() {
  let actions = clone onFinishActions
  onFinishActions.clear()
  if (loadAllItemsProgress == null)
    return
  let { res } = loadAllItemsProgress
  loadAllItemsProgress = null
  foreach(action in actions)
    action(res)
}

function loadNextItem() {
  if (loadAllItemsProgress == null) {
    clearTimer(loadNextItem)
    onFinishLoad()
    return
  }
  let time = get_time_msec()
  let { res, todo } = loadAllItemsProgress
  while(todo.len() > 0) {
    let name = todo.pop()
    command($"console.progress_indicator {progressId} {res.len()}/{res.len() + todo.len()}")
    let info = collectItemInfo(name)
    if (info != null)
      res[name] <- info
    if (get_time_msec() - time >= 10)
      return
  }
  command($"console.progress_indicator {progressId}")
  clearTimer(loadNextItem)
  onFinishLoad()
}

function loadAllItemsAndDo(action) {
  onFinishActions.append(action)
  if (loadAllItemsProgress != null)
    return
  loadAllItemsProgress = { res = {}, todo = [] }
  eachBlock(get_unittags_blk(), @(blk) loadAllItemsProgress.todo.append(blk.getBlockName()))
  setInterval(0.001, loadNextItem)
}

function exportXrayPartsDescs() {
  isDebugBatchExportProcess.set(true)
  dmViewerMode.set(DM_VIEWER_XRAY)

  loadAllItemsAndDo(function(res) {
    isDebugBatchExportProcess.set(false)
    dmViewerMode.set(DM_VIEWER_NONE)

    let filePath = "export/unitsXray.json"
    mkpath(filePath)
    let fp = file(filePath, "wt+")
    fp.writestring(object_to_json_string(res, true))
    fp.close()
  })
}

register_command(exportXrayPartsDescs, "ui.debug.export_xray_parts_descs")
