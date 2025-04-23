from "%globalsDarg/darg_library.nut" import *
let DataBlock = require("DataBlock")
let { DM_VIEWER_XRAY } = require("hangar")
let { getUnitFileName } = require("vehicleModel")
let { deferOnce } = require("dagor.workcycle")
let { copyParamsToTable } = require("%sqstd/datablock.nut")
let { getPartType, getPartNameLocText } = require("%globalScripts/modeXrayLib.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { loadedHangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { dmViewerMode, dmViewerUnitReady, getDmViewerUnitData, isDebugMode, isDebugBatchExportProcess,
  needDmViewerPointerControl, pointerScreenX, pointerScreenY
} = require("dmViewerState.nut")
let { getSimpleUnitType } = require("modeXrayUtils.nut")
let { toggleSubscription, mkDmViewerHint, mkHintTitle, mkHintDescText
} = require("dmViewerPkg.nut")

let isModeActive = Computed(@() dmViewerMode.get() == DM_VIEWER_XRAY)

let scrPosX = Watched(0)
let scrPosY = Watched(0)
let nameW = Watched("")

let hintScrPosX = Watched(0)
let hintScrPosY = Watched(0)
scrPosX.subscribe(@(v) !needDmViewerPointerControl.get() ? hintScrPosX.set(v) : null)
scrPosY.subscribe(@(v) !needDmViewerPointerControl.get() ? hintScrPosY.set(v) : null)
pointerScreenX.subscribe(@(v) needDmViewerPointerControl.get() ? deferOnce(@() hintScrPosX.set(v)) : null)
pointerScreenY.subscribe(@(v) needDmViewerPointerControl.get() ? deferOnce(@() hintScrPosY.set(v)) : null)

function onUpdateHintXray(p) {
  let { posX, posY, name = "" } = p
  scrPosX.set(posX)
  scrPosY.set(posY)
  nameW.set(name)
}

let toggleSub = @(isEnable) toggleSubscription("on_hangar_damage_part_pick", onUpdateHintXray, isEnable)
isModeActive.subscribe(toggleSub)
toggleSub(isModeActive.get())

function mkUnitDataForXray(unitName, unitBlk) {
  if (unitBlk == null) {
    unitBlk = DataBlock()
    let path = getUnitFileName(unitName)
    if (!unitBlk.tryLoad(path, !isDebugBatchExportProcess.get()))
      logerr($"Not found unit blk by path {path}")
  }
  let xrayRemap = {}
  copyParamsToTable(unitBlk?.xray, xrayRemap)
  let xrayOverride = {}
  copyParamsToTable(unitBlk?.xrayOverride, xrayOverride)
  let unit = serverConfigs.get()?.allUnits[unitName]
  return {
    unitBlk
    unitName
    unit
    simUnitType = getSimpleUnitType(unit)
    xrayRemap
    xrayOverride
    xrayTipInfo = {}
    xrayIsInited = true
  }
}

function initUnit() {
  if (!isModeActive.get())
    return
  let unitName = loadedHangarUnitName.get()
  let unitData = getDmViewerUnitData(unitName)
  if (unitData?.xrayIsInited)
    return
  unitData.__update(mkUnitDataForXray(unitName, unitData?.unitBlk))
}
isModeActive.subscribe(@(v) v ? initUnit() : null)
loadedHangarUnitName.subscribe(@(_) isModeActive.get() ? initUnit() : null)
if (isModeActive.get())
  initUnit()

function mkPartTooltipInfo(name, unitData) {
  let res = {
    partType = ""
    title = ""
    desc = ""
  }
  if (name == "")
    return res

  let { xrayRemap, xrayOverride, simUnitType } = unitData
  let partType = getPartType(name, xrayRemap)
  let description = "" 
  let partLocId = null 
  let { overrideTitle = "", hideDescription = false } = xrayOverride?[name]
  let titleLocId = overrideTitle != "" ? overrideTitle : (partLocId ?? partType)
  res.__update({
    partType
    title = getPartNameLocText(titleLocId, simUnitType)
    desc = hideDescription ? "" : description
  })
  return res
}

function getPartTooltipInfoCached(name) {
  initUnit()
  let unitData = getDmViewerUnitData(loadedHangarUnitName.get())
  if (unitData.xrayTipInfo?[name] == null || isDebugMode.get())
    unitData.xrayTipInfo[name] <- mkPartTooltipInfo(name, unitData)
  return unitData.xrayTipInfo[name]
}

let mkDebugInfo = @(isDebug, partType, name) !isDebug ? ""
  : "".concat("\n", colorize(0xFFFF4B38, name), colorize(0xFF808080, $" // {partType}"))

function hintComp() {
  if (!isModeActive.get())
    return { watch = isModeActive }

  let hintTitleW = Computed(@() getPartTooltipInfoCached(nameW.get()).title)
  let hintDescW = Computed(@() getPartTooltipInfoCached(nameW.get()).desc)
  let hintDebugW = Computed(@() mkDebugInfo(isDebugMode.get(),
    getPartTooltipInfoCached(nameW.get()).partType, nameW.get()))

  let isHintVisible = Computed(@() isModeActive.get() && dmViewerUnitReady.get()
    && hintTitleW.get() != "")

  let hintContent = {
    flow = FLOW_VERTICAL
    children = [
      mkHintTitle(hintTitleW)
      mkHintDescText(hintDescW)
      mkHintDescText(hintDebugW)
    ]
  }

  return {
    watch = isModeActive
    size= flex()
    children = mkDmViewerHint(isHintVisible, hintScrPosX, hintScrPosY, hintContent)
  }
}

let modeXrayComps = [
  hintComp
]

return {
  modeXrayComps

  mkUnitDataForXray
  mkPartTooltipInfo
}
