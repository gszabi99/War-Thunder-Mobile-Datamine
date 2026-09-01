from "%globalsDarg/darg_library.nut" import *
from "wt.behaviors" import HangarCameraControl
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/bqClient.nut" import sendNewbieBqEvent
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%appGlobals/permissions.nut" import can_debug_units
from "%rGui/attributes/attrState.nut" import hasSlotAttrPreset
from "%rGui/attributes/unitAttr/btnOpenUnitAttr.nut" import mkBtnOpenUnitAttr
from "%rGui/components/buttonStyles.nut" import defButtonMinWidth, defButtonHeight
import "%rGui/components/panelBg.nut" as panelBg
from "%rGui/components/textButton.nut" import textButtonCommon
import "%rGui/dmViewer/dmViewerBgComps.nut" as dmViewerBgComps
import "%rGui/dmViewer/dmViewerHintComps.nut" as dmViewerHintComps
from "%rGui/dmViewer/dmViewerState.nut" import clearDmViewerUnitDataCollection
import "%rGui/dmViewer/mkBtnOpenProtectionAnalysis.nut" as mkBtnOpenProtectionAnalysis
import "%rGui/dmViewer/mkDmViewerSwitchComp.nut" as mkDmViewerSwitchComp
from "%rGui/gameModes/startOfflineMode.nut" import startTestFlight
from "%rGui/mainMenu/gamercard.nut" import mkLeftBlockUnitCampaign
from "%rGui/navState.nut" import registerScene
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/components/unitInfoPanel.nut" import unitInfoPanelFull, statsWidth
from "%rGui/unit/hangarUnit.nut" import hasHangarUnitResources
import "%rGui/unit/mkUnitPkgDownloadInfo.nut" as mkUnitPkgDownloadInfo
import "%rGui/unitCustom/mkBtnOpenCustomization.nut" as mkBtnOpenCustomization
from "%rGui/unitDetails/unitDetailsState.nut" import closeUnitDetailsWnd, baseUnit, unitToShow, isWindowAttached,
  unitDetailsOpenCount
from "%rGui/unitMastery/btnOpenUnitMastery.nut" import mkBtnOpenUnitMastery
import "%rGui/unitMods/btnOpenUnitMods.nut" as btnOpenUnitMods


let infoPanelOffsetY = panelBg.padding
const frameButtonIconSize = hdpxi(50)
const frameButtonGap = hdpx(5)

let openCount = Computed(@() baseUnit.get() != null ? unitDetailsOpenCount.get() : 0)

let leftBtnSizeWithRewardBtn = [defButtonMinWidth + frameButtonIconSize * 2 + frameButtonGap * 2, defButtonHeight]

const defaultInfoPanelTopPad = hdpx(100)
let infoPanelTopPadByCampaign = {
  tanks = 0
}
let getInfoPanelTopPadByCampaign = @(campaign) (infoPanelTopPadByCampaign?[campaign] ?? defaultInfoPanelTopPad)
  - infoPanelOffsetY

let sceneHeader = @() {
  watch = baseUnit
  children = mkLeftBlockUnitCampaign(
    closeUnitDetailsWnd,
    getCampaignPresentation(baseUnit.get()?.campaign).levelUnitDetailsLocId,
    baseUnit)
}

let dmViewerSwitchComp = mkDmViewerSwitchComp(baseUnit)
let btnOpenUnitCustomization = mkBtnOpenCustomization(baseUnit,
  { hotkeys = ["^J:LB"], ovr = { size = leftBtnSizeWithRewardBtn } })
let protectionAnalysisButton = mkBtnOpenProtectionAnalysis(unitToShow, baseUnit,
  { hotkeys = ["^J:RB"], ovr = { size = [statsWidth, defButtonHeight] }, contentOvr = { width = statsWidth } })

let unitInfoPanelPlace = @() {
  watch = curCampaign
  size = FLEX_V
  pos = [0, infoPanelOffsetY]
  padding = [ getInfoPanelTopPadByCampaign(curCampaign.get()), 0, 0, 0 ]
  children = panelBg.__merge({
    size = FLEX_V
    gap = hdpx(30)
    children = [
      unitInfoPanelFull(unitToShow,
        {
          behavior = HangarCameraControl
          touchMarginPriority = TOUCH_BACKGROUND
        })
      dmViewerSwitchComp
      protectionAnalysisButton
    ]
  })
}

let testDriveButton = @() {
  watch = [can_debug_units, hasHangarUnitResources]
  children = !can_debug_units.get() || !hasHangarUnitResources.get() ? null
    : textButtonCommon("TEST DRIVE",
        @() startTestFlight(unitToShow.get()),
        { hotkeys = ["^J:X | Enter"], ovr = { size = leftBtnSizeWithRewardBtn } })
}

function buttonsBlock() {
  let { name = "", isUpgraded = false } = baseUnit.get()
  let myUnit = campMyUnits.get()?[name]
  let isOwnUnitPreview = myUnit != null && myUnit.isUpgraded == isUpgraded
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    watch = [curCampaign, hasSlotAttrPreset, baseUnit, campMyUnits]
    gap = hdpx(15)
    children = [
      { size = FLEX }
      mkUnitPkgDownloadInfo(baseUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
      isOwnUnitPreview ? mkBtnOpenUnitMastery(baseUnit, { ovr = { size = leftBtnSizeWithRewardBtn }})
        : null
      testDriveButton
      btnOpenUnitMods(baseUnit, {
        hotkeys = ["^J:Y"]
        ovr = { size = leftBtnSizeWithRewardBtn }
      })
      !hasSlotAttrPreset.get() && isOwnUnitPreview ? mkBtnOpenUnitAttr({ovr = { size = leftBtnSizeWithRewardBtn } })
        : null
      btnOpenUnitCustomization
    ]
  }
}

let sceneContent = {
  size = FLEX
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = FLEX
      children = [
        sceneHeader
        buttonsBlock
      ]
    }
    unitInfoPanelPlace
  ]
}

let sceneRoot = {
  key = openCount
  size = const [ sw(100), sh(100) ]
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim

  function onAttach() {
    isWindowAttached.set(true)
    sendNewbieBqEvent("openUnitDetails", { status = unitToShow.get()?.name ?? "" })
  }
  function onDetach() {
    clearDmViewerUnitDataCollection()
    isWindowAttached.set(false)
  }
  children = {
    size = FLEX
    children = [].extend(dmViewerBgComps, [ sceneContent ], dmViewerHintComps)
  }
}

registerScene("unitDetailWnd", sceneRoot, closeUnitDetailsWnd, openCount)
