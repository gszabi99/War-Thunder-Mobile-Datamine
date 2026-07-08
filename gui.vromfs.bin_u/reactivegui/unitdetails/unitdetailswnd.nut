from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { registerScene } = require("%rGui/navState.nut")
let { unitInfoPanelFull, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { can_debug_units } = require("%appGlobals/permissions.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { mkLeftBlockUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { hasHangarUnitResources } = require("%rGui/unit/hangarUnit.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { btnOpenUnitAttrBig } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let mkBtnOpenCustomization = require("%rGui/unitCustom/mkBtnOpenCustomization.nut")
let { closeUnitDetailsWnd, baseUnit, unitToShow, isWindowAttached,
  unitDetailsOpenCount
} = require("%rGui/unitDetails/unitDetailsState.nut")
let { hasSlotAttrPreset } = require("%rGui/attributes/attrState.nut")
let btnOpenUnitMods = require("%rGui/unitMods/btnOpenUnitMods.nut")
let { hasAlwaysModsBtnByCamp } = require("%rGui/unitMods/unitModsConst.nut")
let { defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { clearDmViewerUnitDataCollection } = require("%rGui/dmViewer/dmViewerState.nut")
let dmViewerBgComps = require("%rGui/dmViewer/dmViewerBgComps.nut")
let dmViewerHintComps = require("%rGui/dmViewer/dmViewerHintComps.nut")
let mkDmViewerSwitchComp = require("%rGui/dmViewer/mkDmViewerSwitchComp.nut")
let mkBtnOpenProtectionAnalysis = require("%rGui/dmViewer/mkBtnOpenProtectionAnalysis.nut")
let { mkBtnOpenUnitMastery } = require("%rGui/unitMastery/btnOpenUnitMastery.nut")


let buttonsGap = hdpx(40)
let infoPanelOffsetY = panelBg.padding
let frameButtonIconSize = hdpxi(50)
let frameButtonGap = hdpx(5)

let openCount = Computed(@() baseUnit.get() != null ? unitDetailsOpenCount.get() : 0)

let leftBtnSizeWithRewardBtn = [defButtonMinWidth + frameButtonIconSize * 2 + frameButtonGap * 2, defButtonHeight]

let defaultInfoPanelTopPad = hdpx(100)
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
      mkBtnOpenUnitMastery(baseUnit, { ovr = { size = leftBtnSizeWithRewardBtn }})
      testDriveButton
      !isOwnUnitPreview && !hasAlwaysModsBtnByCamp?[curCampaign.get()] ? null
        : {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = buttonsGap
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            children = hasSlotAttrPreset.get()
              ? btnOpenUnitMods(baseUnit, {
                  hotkeys = ["^J:Y"]
                  ovr = { size = leftBtnSizeWithRewardBtn }
                })
              : isOwnUnitPreview ? btnOpenUnitAttrBig
              : null
          }
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
