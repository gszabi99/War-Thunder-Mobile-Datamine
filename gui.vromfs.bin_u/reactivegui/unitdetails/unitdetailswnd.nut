from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { registerScene } = require("%rGui/navState.nut")
let { unitInfoPanelFull, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary, mkButtonTextMultiline, mergeStyles, mkCustomButton, mkFrameImg, textButtonUnseenMargin
} = require("%rGui/components/textButton.nut")
let { can_debug_units } = require("%appGlobals/permissions.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { mkLeftBlockUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let buyUnitLevelWnd = require("%rGui/attributes/unitAttr/buyUnitLevelWnd.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hasNotDownloadedPkgForHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { btnOpenUnitAttrBig } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let mkBtnOpenCustomization = require("%rGui/unitCustom/mkBtnOpenCustomization.nut")
let { curSelectedUnitId, openUnitOvr, closeUnitDetailsWnd, baseUnit,
  platoonUnitsList, unitToShow, isWindowAttached, openUnitDetailsWnd, unitDetailsOpenCount
} = require("unitDetailsState.nut")
let { mkPlatoonUnitsBlock } = require("unitDetailsComps.nut")
let { hasSlotAttrPreset } = require("%rGui/attributes/attrState.nut")
let btnOpenUnitMods = require("%rGui/unitMods/btnOpenUnitMods.nut")
let { openUnitRewardsModal, unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")
let { PRIMARY, defButtonMinWidth, defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { clearDmViewerUnitDataCollection } = require("%rGui/dmViewer/dmViewerState.nut")
let dmViewerBgComps = require("%rGui/dmViewer/dmViewerBgComps.nut")
let dmViewerHintComps = require("%rGui/dmViewer/dmViewerHintComps.nut")
let mkDmViewerSwitchComp = require("%rGui/dmViewer/mkDmViewerSwitchComp.nut")


let buttonsGap = hdpx(40)
let infoPanelOffsetY = panelBg.padding
let frameButtonIconSize = hdpxi(50)
let frameButtonGap = hdpx(5)

let openCount = Computed(@() baseUnit.value != null ? unitDetailsOpenCount.get() : 0)
let hasUnseenRewards = Computed(@() baseUnit.get()?.name in unseenUnitLvlRewardsList.get())

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
    function() {
      curSelectedUnitId.set(null)
      closeUnitDetailsWnd()
    },
    getCampaignPresentation(baseUnit.get()?.campaign).levelUnitDetailsLocId,
    baseUnit)
}

let nextLevelToUnlockUnit = Computed(function() {
  if ("level" not in baseUnit.value)
    return null
  local nextLevel
  foreach (unlockLevel in platoonUnitsList.value.map(@(v) v.reqLevel))
    if ((unlockLevel < nextLevel || !nextLevel) && unlockLevel > baseUnit.value.level)
      nextLevel = unlockLevel
  return nextLevel
})

platoonUnitsList.subscribe(function(pu) {
  if (null != pu.findvalue(@(p) p.name == curSelectedUnitId.get()))
    return
  local name = openUnitOvr.get()?.selUnitName
  if (name == null || null == pu.findvalue(@(p) p.name == name))
    name = pu?[0].name
  curSelectedUnitId(name)
})

let dmViewerSwitchComp = mkDmViewerSwitchComp(baseUnit)
let btnopenUnitCustomization = mkBtnOpenCustomization(baseUnit, statsWidth)

let unitInfoPanelPlace = @() {
  watch = [curCampaign, hasNotDownloadedPkgForHangarUnit]
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
      hasNotDownloadedPkgForHangarUnit.get() ? null : btnopenUnitCustomization
    ]
  })
}

let rewardsButton = @() {
  watch = [hasUnseenRewards, baseUnit]
  children = !hasUnseenRewards.get() ? null
    : [
        mkCustomButton(
          mkFrameImg(mkButtonTextMultiline(loc("unitLevelUp/rewardBtn")), "laurels", frameButtonIconSize),
          @() openUnitRewardsModal(baseUnit.get()),
          mergeStyles(PRIMARY, { hotkeys = ["^J:LB"] }))
        {
          margin = textButtonUnseenMargin
          children = priorityUnseenMark
        }
      ]
}

let testDriveButton = @() {
  watch = [can_debug_units, hasNotDownloadedPkgForHangarUnit, hasUnseenRewards]
  children = !can_debug_units.get() || hasNotDownloadedPkgForHangarUnit.get() ? null
    : textButtonPrimary("TEST DRIVE",
        @() startTestFlight(unitToShow.get()),
        { hotkeys = ["^J:X | Enter"], ovr = hasUnseenRewards.get() ? { size = leftBtnSizeWithRewardBtn } : {} })
}

let lvlUpButton = @() {
  watch = [nextLevelToUnlockUnit, baseUnit]
  children = nextLevelToUnlockUnit.value == null ? null
    : textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")),
        nextLevelToUnlockUnit.value,
        @() buyUnitLevelWnd(baseUnit.value?.name), { hotkeys = ["^J:Y"] })
}

function buttonsBlock() {
  let { name = "", isUpgraded = false } = baseUnit.get()
  let myUnit = campMyUnits.get()?[name]
  let isOwnUnitPreview = myUnit != null && myUnit.isUpgraded == isUpgraded
  return {
    size = flex()
    flow = FLOW_VERTICAL
    watch = [curCampaign, hasSlotAttrPreset, baseUnit, hasUnseenRewards, campMyUnits]
    gap = hdpx(30)
    children = [
      { size = flex() }
      mkUnitPkgDownloadInfo(baseUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
      rewardsButton
      testDriveButton
      !(curCampaign.get() == "air" || isOwnUnitPreview) ? null
        : {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = buttonsGap
            vplace = ALIGN_BOTTOM
            valign = ALIGN_BOTTOM
            children = [
              hasSlotAttrPreset.get()
                ? btnOpenUnitMods(baseUnit, {
                    hotkeys = ["^J:Y"]
                    ovr = hasUnseenRewards.get() ? { size = leftBtnSizeWithRewardBtn } : {}
                  })
                : isOwnUnitPreview ? btnOpenUnitAttrBig
                : null
              isOwnUnitPreview ? lvlUpButton : null
            ]
          }
    ]
  }
}

let sceneContent = {
  size = flex()
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = flex()
      children = [
        sceneHeader
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = buttonsGap
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = [
            mkPlatoonUnitsBlock(baseUnit, platoonUnitsList, unitToShow, @(n) curSelectedUnitId.set(n))
            buttonsBlock
          ]
        }
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
    isWindowAttached(true)
    sendNewbieBqEvent("openUnitDetails", { status = unitToShow.get()?.name ?? "" })
  }
  function onDetach() {
    clearDmViewerUnitDataCollection()
    isWindowAttached(false)
  }
  children = {
    size = flex()
    children = [].extend(dmViewerBgComps, [ sceneContent ], dmViewerHintComps)
  }
}

registerScene("unitDetailWnd", sceneRoot, closeUnitDetailsWnd, openCount)

return openUnitDetailsWnd
