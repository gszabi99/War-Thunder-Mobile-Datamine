from "%globalsDarg/darg_library.nut" import *
let DataBlock = require("DataBlock")
let { DM_VIEWER_XRAY } = require("hangar")
let { get_unittags_blk } = require("blkGetters")
let { getUnitFileName } = require("vehicleModel")
let { copyParamsToTable } = require("%sqstd/datablock.nut")
let { getPartType, getPartNameLocText } = require("%globalScripts/modeXrayLib.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { loadedHangarUnitName, hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { dmViewerMode, dmViewerUnitReady, getDmViewerUnitData, dmViewerUnitDataVer,
  isDebugMode, isDebugBatchExportProcess
} = require("dmViewerState.nut")
let { getSimpleUnitType, xrayCommonGetters, getDescriptionInXrayMode, collectArmorClassToSteelMuls
} = require("modeXrayUtils.nut")
let { toggleSubscription, mkDmViewerHint, mkHintTitle, mkHintDescText
} = require("dmViewerPkg.nut")

let isModeActive = Computed(@() dmViewerMode.get() == DM_VIEWER_XRAY)

let scrPosX = Watched(0)
let scrPosY = Watched(0)
let partParamsW = Watched({})

let armorClassToSteel = {}

local isInited = false
function init() {
  if (isInited)
    return
  isInited = true
  armorClassToSteel.__update(collectArmorClassToSteelMuls())
}
isModeActive.subscribe(@(v) v ? init() : null)
if (isModeActive.get())
  init()

dmViewerMode.subscribe(function(_) {
  partParamsW.set({})
  scrPosX.set(0)
  scrPosY.set(0)
})

function onUpdateHintXray(p) {
  let { posX, posY, name = "", weapon_trigger = null } = p
  scrPosX.set(posX)
  scrPosY.set(posY)
  if (name != (partParamsW.get()?.name ?? ""))
    partParamsW.set({ name, weapon_trigger })
}

let toggleSub = @(isEnable) toggleSubscription("on_hangar_damage_part_pick", onUpdateHintXray, isEnable)
let isNeedSub = keepref(Computed(@() isModeActive.get() && !isDebugBatchExportProcess.get()))
isNeedSub.subscribe(toggleSub)
toggleSub(isNeedSub.get())

function mkUnitDataForXray(unitName, unit, unitBlk) {
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
  let unitTags = get_unittags_blk()?[unitName]
  let simUnitType = getSimpleUnitType(unit)
  return {
    unitBlk
    unitTags
    unitName
    unit
    crewId = -1
    simUnitType
    unitDataCache = {}
    xrayRemap
    xrayOverride
    xrayTipInfo = {}
    xrayIsInited = true
  }
}

let curUnitW = Computed(function() {
  if (!isModeActive.get())
    return null
  if (dmViewerUnitDataVer.get() < 0)
    return null 
  let unitName = loadedHangarUnitName.get()
  let unit = hangarUnit.get()
  if (unit == null || unitName != getTagsUnitName(unit.name))
    return null
  return clone unit
})

function mkPartTooltipInfo(partParams, unitData) {
  let res = {
    partType = ""
    title = ""
    desc = ""
  }
  let partName = partParams?.name ?? ""
  if (partName == "" || unitData == null)
    return res

  let { xrayRemap, xrayOverride, unit, unitName, simUnitType, unitBlk, unitDataCache
  } = unitData
  let partType = getPartType(partName, xrayRemap)

  let descData = getDescriptionInXrayMode(partType, partParams, {
    unit
    unitName
    simUnitType
    unitBlk
    unitDataCache
    crewId = -1
    armorClassToSteel
    isSecondaryModsValid = true
    isDebugBatchExportProcess = isDebugBatchExportProcess.get()
  }.__update(xrayCommonGetters))
  let { overrideTitle = "", hideDescription = false } = xrayOverride?[partName]
  let titleLocId = overrideTitle != "" ? overrideTitle : descData.partLocId
  res.__update({
    partType
    title = getPartNameLocText(titleLocId, simUnitType)
    desc = hideDescription ? "" : "\n".join(descData.desc.map(@(v) v?.value ?? v), true)
  })
  return res
}

function getPartTooltipInfoCached(partParams, unit) {
  if (unit == null)
    return null
  let partName = partParams?.name ?? ""
  let unitName = getTagsUnitName(unit.name)
  let unitData = getDmViewerUnitData(unitName)
  if (!unitData?.xrayIsInited)
    unitData.__update(mkUnitDataForXray(unitName, unit, unitData?.unitBlk))
  if (unitData.xrayTipInfo?[partName] == null || isDebugMode.get())
    unitData.xrayTipInfo[partName] <- mkPartTooltipInfo(partParams, unitData)
  return unitData.xrayTipInfo[partName]
}

let mkDebugInfo = @(isDebug, partType, partName) !isDebug ? ""
  : "".concat("\n", colorize(0xFFFF4B38, partName), colorize(0xFF808080, $" // {partType}"))

function hintComp() {
  if (!isModeActive.get())
    return { watch = isModeActive }

  let hintTitleW = Computed(@() getPartTooltipInfoCached(partParamsW.get(), curUnitW.get())?.title ?? "")
  let hintDescW = Computed(@() getPartTooltipInfoCached(partParamsW.get(), curUnitW.get())?.desc ?? "")
  let hintDebugW = Computed(@() mkDebugInfo(isDebugMode.get(),
    getPartTooltipInfoCached(partParamsW.get(), curUnitW.get())?.partType ?? "", partParamsW.get()?.name ?? ""))

  let isHintVisible = Computed(@() isModeActive.get() && dmViewerUnitReady.get()
    && (scrPosX.get() != 0 || scrPosY.get() != 0 || hintTitleW.get() != ""))

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
    children = mkDmViewerHint(isHintVisible, scrPosX, scrPosY, hintContent)
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
