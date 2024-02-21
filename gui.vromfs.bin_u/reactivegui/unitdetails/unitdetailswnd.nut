from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { unitInfoPanelFull, unitInfoPanelDefPos } = require("%rGui/unit/components/unitInfoPanel.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitRank
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { can_debug_units } = require("%appGlobals/permissions.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { mkLeftBlockUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let buyUnitLevelWnd = require("%rGui/unitAttr/buyUnitLevelWnd.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { scaleAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { justUnlockedPlatoonUnits } = require("%rGui/unit/justUnlockedPlatoonUnits.nut")
let { btnOpenUnitAttrBig } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")
let btnOpenUnitSkins = require("%rGui/unitSkins/btnOpenUnitSkins.nut")
let { curSelectedUnitId, openUnitOvr, closeUnitDetailsWnd, baseUnit,
  platoonUnitsList, unitToShow, isWindowAttached } = require("unitDetailsState.nut")

let buttonsGap = hdpx(40)

let isUnitDetailsOpen = Computed(@() baseUnit.value != null)
let isShowedUnitOwned = Computed(@() baseUnit.value?.name in myUnits.value)

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
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (myUnits.value?[unit.name].level ?? 0))
  let justUnlockedDelay = Computed(@() justUnlockedPlatoonUnits.value.indexof(platoonUnit.name) != null ? UNIT_DELAY : null)

  return @() {
    watch = [isLocked, justUnlockedDelay]
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(unit, isSelected)
      {
        key = {}
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [UNIT_SCALE, UNIT_SCALE])
        children = [
          mkUnitBg(unit, isLocked.get(), justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked)
          !isLocked.value ? mkUnitRank(unit, { pos = [-hdpx(30), 0] }) : null
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

let unitInfoPanelPlace = @() {
  watch = curCampaign
  size = [ saSize[0], SIZE_TO_CONTENT ]
  children = unitInfoPanelFull({
    pos = curCampaign.value == "tanks" ? [ saBorders[0], hdpx(20) ] : unitInfoPanelDefPos
    hplace = ALIGN_RIGHT
    behavior = [ Behaviors.Button, Behaviors.HangarCameraControl ]
    eventPassThrough = true
    onClick = closeUnitDetailsWnd
  }, unitToShow)
}

let testDriveButton = @() {
  watch = can_debug_units
  children = !can_debug_units.value ? null
    : textButtonPrimary("Test Drive",
        @() startTestFlight(unitToShow.get()),
        { hotkeys = ["^J:X | Enter"] })
}

let lvlUpButton = @() {
  watch = [nextLevelToUnlockUnit, baseUnit]
  children = nextLevelToUnlockUnit.value == null ? null
    : textButtonVehicleLevelUp(utf8ToUpper(loc("mainmenu/btnLevelBoost")),
        nextLevelToUnlockUnit.value,
        @() buyUnitLevelWnd(baseUnit.value?.name), { hotkeys = ["^J:Y"] })
}

let buttonsBlock = @() {
  size = flex()
  flow = FLOW_VERTICAL
  watch = isShowedUnitOwned
  gap = hdpx(30)
  children = [
    { size = flex() }
    mkUnitPkgDownloadInfo(baseUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
    testDriveButton
    !isShowedUnitOwned.get() ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = buttonsGap
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = [
            btnOpenUnitAttrBig
            lvlUpButton
            { size = flex() }
            btnOpenUnitSkins
          ]
        }
  ]
}

let sceneRoot = {
  key = isUnitDetailsOpen
  size = [ sw(100), sh(100) ]
  behavior = Behaviors.HangarCameraControl
  animations = wndSwitchAnim

  function onAttach() {
    isWindowAttached(true)
    sendNewbieBqEvent("openUnitDetails", { status = unitToShow.value?.name ?? "" })
  }
  onDetach = @() isWindowAttached(false)
  children = {
    size = saSize
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    children = [
      @(){
        watch = [baseUnit, curCampaign]
        children = mkLeftBlockUnitCampaign(
          function() {
            curSelectedUnitId.set(null)
            closeUnitDetailsWnd()
          },
          $"gamercard/levelUnitDetails/desc/{curCampaign.get()}",
          baseUnit.value)
      }
      unitInfoPanelPlace
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
}

registerScene("unitDetailWnd", sceneRoot, closeUnitDetailsWnd, isUnitDetailsOpen)

return @(unitOvr = {}) openUnitOvr(unitOvr)
