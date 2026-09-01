from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_unittags_blk
from "console" import register_command, command
from "dagor.fs" import mkpath, file_exists
from "dagor.time" import get_time_msec
from "dagor.workcycle" import setInterval, clearTimer
from "hangar" import DM_VIEWER_NONE, DM_VIEWER_XRAY
from "io" import file
from "json" import object_to_json_string
from "string" import format
from "vehicleModel" import getUnitFileName
from "%sqstd/datablock.nut" import eachBlock
from "%globalScripts/modeXrayLib.nut" import getPartType
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/unitCfgByTagName.nut" import getUnitCfgByTagName
from "%rGui/dmViewer/dmViewerState.nut" import dmViewerMode, isDebugBatchExportProcess
from "%rGui/dmViewer/modeXray.nut" import mkUnitDataForXray, mkPartTooltipInfo


const progressId = "unitsXray"
local loadAllItemsProgress = null
let onFinishActions = []

let msToTimeStr = @(ms) format("%02dm%02ds", ms / 60000, (ms % 60000) / 1000)

function collectItemInfo(unitName, partsWhitelist) {
  let unit = getUnitCfgByTagName(unitName, serverConfigs.get(), curCampaign.get())
  if (unit == null)
    return null
  let unitData = mkUnitDataForXray(unitName, unit, null)
  let damagePartsBlk = unitData.unitBlk?.DamageParts
  let partNames = []
  eachBlock(damagePartsBlk, function(partsBlk) {
    eachBlock(partsBlk, function(pBlk) {
      let partName = pBlk.getBlockName()
      if (partsWhitelist != null && partsWhitelist.findindex(@(v) partName.startswith(v)) == null)
        return
      if (!partNames.contains(partName))
        partNames.append(partName)
    })
  })
  partNames.sort()

  let res = {}
  foreach (name in partNames) {
    let partType = getPartType(name, unitData.xrayRemap)
    let { title, desc } = mkPartTooltipInfo({ name }, unitData)
    if (title != partType || desc != "")
      res[name] <- "\n".join([ title, desc ], true)
  }
  return res.len() ? res : null
}

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

function loadNextItems() {
  if (loadAllItemsProgress == null) {
    clearTimer(loadNextItems)
    onFinishLoad()
    return
  }
  let frameStartTimeMs = get_time_msec()
  let { res, todo, params } = loadAllItemsProgress
  let { partsWhitelist, exportStartTimeMs } = params
  let total = res.len() + todo.len()
  while(todo.len() > 0) {
    let i = res.len()
    let prc = (100.0 * i / total).tointeger()
    let passedMs = get_time_msec() - exportStartTimeMs
    let eta = msToTimeStr(max(0, (1.0 * passedMs / max(i, 1) * total).tointeger() - passedMs))
    command($"console.progress_indicator {progressId} {i}/{total}{nbsp}({prc}%),{nbsp}ETA:{nbsp}{eta}")

    let unitName = todo.pop()
    let info = collectItemInfo(unitName, partsWhitelist)
    if (info != null)
      res[unitName] <- info
    if (get_time_msec() - frameStartTimeMs >= 10)
      return
  }
  let totalTimeMs = get_time_msec() - exportStartTimeMs
  command($"console.progress_indicator {progressId} Finished{nbsp}{total}{nbsp}items{nbsp}in{nbsp}{msToTimeStr(totalTimeMs)}")
  command($"console.progress_indicator {progressId}")
  clearTimer(loadNextItems)
  onFinishLoad()
}

function loadAllItemsAndDo(params, onFinishCb) {
  onFinishActions.append(onFinishCb)
  if (loadAllItemsProgress != null)
    return
  loadAllItemsProgress = { res = {}, todo = [], params }
  let { unitsWhitelist, unitsBlacklist } = params
  eachBlock(get_unittags_blk(), function(blk) {
    let unitName = blk.getBlockName()
    if (unitsWhitelist != null && !unitsWhitelist.contains(unitName))
      return
    if (unitsBlacklist?.contains(unitName) ?? false)
      return
    if (!file_exists(getUnitFileName(unitName)))
      return
    loadAllItemsProgress.todo.append(unitName)
  })
  setInterval(0.001, loadNextItems)
}

function exportXrayPartsDescs(nullOrPartIdWhitelist = null, nullOrUnitIdWhitelist = null, nullOrUnitIdBlacklist = null) {
  isDebugBatchExportProcess.set(true)
  dmViewerMode.set(DM_VIEWER_XRAY)
  let params = {
    partsWhitelist = nullOrPartIdWhitelist
    unitsWhitelist = nullOrUnitIdWhitelist
    unitsBlacklist = nullOrUnitIdBlacklist
    exportStartTimeMs = get_time_msec()
  }

  loadAllItemsAndDo(params, function(res) {
    isDebugBatchExportProcess.set(false)
    dmViewerMode.set(DM_VIEWER_NONE)

    const filePath = "export/unitsXray.json"
    mkpath(filePath)
    let fp = file(filePath, "wt+")
    fp.writestring(object_to_json_string(res, true))
    fp.close()
  })
}

register_command(exportXrayPartsDescs, "ui.debug.export_xray_parts_descs")
