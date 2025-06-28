from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { registerScene } = require("%rGui/navState.nut")
let { unitInfoPanelFull, statsWidth } = require("%rGui/unit/components/unitInfoPanel.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitInfo
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine
} = require("%rGui/unit/components/unitPlateComp.nut")
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
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { scaleAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { justUnlockedPlatoonUnits } = require("%rGui/unit/justUnlockedPlatoonUnits.nut")
let { btnOpenUnitAttrBig } = require("%rGui/attributes/unitAttr/btnOpenUnitAttr.nut")
let mkBtnOpenCustomization = require("%rGui/unitCustom/mkBtnOpenCustomization.nut")
let { curSelectedUnitId, openUnitOvr, closeUnitDetailsWnd, baseUnit,
  platoonUnitsList, unitToShow, isWindowAttached, openUnitDetailsWnd, unitDetailsOpenCount
} = require("unitDetailsState.nut")
let { selectedLineHorUnitsCustomSize, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
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
  if (null != pu.findvalue(@(p) p.name == curSelectedUnitId.value))
    return
  local name = openUnitOvr.value?.selUnitName
  if (name == null || null == pu.findvalue(@(p) p.name == name))
    name = pu?[0].name
  curSelectedUnitId(name)
})

let UNIT_DELAY = 1.5
let UNIT_SCALE = 1.2
function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isSelected = Computed(@() unitToShow.get()?.name == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (campMyUnits.get()?[unit.name].level ?? 0))
  let justUnlockedDelay = Computed(@() justUnlockedPlatoonUnits.value.indexof(platoonUnit.name) != null ? UNIT_DELAY : null)
  let isCollectible = unit?.isCollectible
  return @() {
    watch = [isLocked, justUnlockedDelay]
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      {
        key = {}
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [UNIT_SCALE, UNIT_SCALE])
        children = [
          {
            size = flex()
            valign = ALIGN_TOP
            pos = [0, -2 * selLineSize]
            children = selectedLineHorUnitsCustomSize([flex(), 2*selLineSize], isSelected, isPremium, isCollectible)
          }
          mkUnitBg(unit, isLocked.get(), justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked.get())
          !isLocked.value ? mkUnitInfo(unit, { pos = [-hdpx(30), 0] }) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.value, justUnlockedDelay.value)
        ]
      }
    ]
  }
}

function platoonUnitsBlock() {
  let res = { watch = [ baseUnit, platoonUnitsList ] }
  return platoonUnitsList.value.len() == 0
    ? res
    : res.__update({
        size = SIZE_TO_CONTENT
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = platoonUnitsList.value
          .map(@(pu) mkUnitPlate(baseUnit.value, pu, @() curSelectedUnitId(pu.name)))
      })
}

let dmViewerSwitchComp = mkDmViewerSwitchComp(baseUnit)
let btnopenUnitCustomization = mkBtnOpenCustomization(baseUnit, statsWidth)

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
      btnopenUnitCustomization
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
  watch = [can_debug_units, hasUnseenRewards]
  children = !can_debug_units.value ? null
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
            platoonUnitsBlock
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
    sendNewbieBqEvent("openUnitDetails", { status = unitToShow.value?.name ?? "" })
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
