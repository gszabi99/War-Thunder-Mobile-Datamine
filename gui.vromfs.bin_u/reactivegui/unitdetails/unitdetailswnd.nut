from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { registerScene } = require("%rGui/navState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { unitInfoPanelFull } = require("%rGui/unit/components/unitInfoPanel.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitInfo
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine
} = require("%rGui/unit/components/unitPlateComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
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
let btnOpenUnitSkins = require("%rGui/unitSkins/btnOpenUnitSkins.nut")
let { curSelectedUnitId, openUnitOvr, closeUnitDetailsWnd, baseUnit,
  platoonUnitsList, unitToShow, isWindowAttached, openUnitDetailsWnd, unitDetailsOpenCount
} = require("unitDetailsState.nut")
let { selectedLineHorUnitsCustomSize, selLineSize } = require("%rGui/components/selectedLineUnits.nut")
let { hasSlotAttrPreset } = require("%rGui/attributes/attrState.nut")
let btnOpenUnitMods = require("%rGui/unitMods/btnOpenUnitMods.nut")


let buttonsGap = hdpx(40)

let openCount = Computed(@() baseUnit.value != null ? unitDetailsOpenCount.get() : 0)
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

let unitInfoPanelPlace = @() {
  watch = curCampaign
  size = [ saSize[0], SIZE_TO_CONTENT ]
  children = unitInfoPanelFull({
    pos = curCampaign.value == "tanks" ? [ 0, hdpx(20) ] : [ 0, hdpx(100) ]

    hplace = ALIGN_RIGHT
    behavior = [ Behaviors.Button, HangarCameraControl ]
    eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
    touchMarginPriority = TOUCH_BACKGROUND
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
  watch = [curCampaign, isShowedUnitOwned]
  gap = hdpx(30)
  children = [
    { size = flex() }
    mkUnitPkgDownloadInfo(baseUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
    testDriveButton
    !(curCampaign.get() == "air" || isShowedUnitOwned.get()) ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = buttonsGap
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          children = [
            @() {
              watch = [hasSlotAttrPreset, baseUnit]
              children = hasSlotAttrPreset.get()
                  ? btnOpenUnitMods({ hotkeys = ["^J:Y"] })
                : !isShowedUnitOwned.get()
                  ? null
                : (myUnits.get()[baseUnit.get().name]?.isUpgraded == baseUnit.get()?.isUpgraded
                    || baseUnit.get()?.isPremium)
                  ? btnOpenUnitAttrBig
                : null
            }
            lvlUpButton
            { size = flex() }
            btnOpenUnitSkins
          ]
        }
  ]
}

let sceneRoot = {
  key = openCount
  size = [ sw(100), sh(100) ]
  behavior = HangarCameraControl
  eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
  touchMarginPriority = TOUCH_BACKGROUND
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
        watch = baseUnit
        children = baseUnit.get() == null ? null : mkLeftBlockUnitCampaign(
          function() {
            curSelectedUnitId.set(null)
            closeUnitDetailsWnd()
          },
          $"gamercard/levelUnitDetails/desc/{baseUnit.get()?.campaign ?? curCampaign.get()}",
          baseUnit)
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

registerScene("unitDetailWnd", sceneRoot, closeUnitDetailsWnd, openCount)

return openUnitDetailsWnd
