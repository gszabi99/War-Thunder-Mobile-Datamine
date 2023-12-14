from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { setCustomHangarUnit, resetCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { unitInfoPanelFull, unitInfoPanelDefPos } = require("%rGui/unit/components/unitInfoPanel.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { can_debug_units } = require("%appGlobals/permissions.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { mkLeftBlockUnitCampaign } = require("%rGui/mainMenu/gamercard.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let buyUnitLevelWnd = require("%rGui/unitAttr/buyUnitLevelWnd.nut")
let { textButtonVehicleLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")
let { scaleAnimation } = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { justUnlockedPlatoonUnits } = require("%rGui/unit/justUnlockedPlatoonUnits.nut")
let { btnOpenUnitAttrBig } = require("%rGui/unitAttr/btnOpenUnitAttr.nut")

let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let curSelectedUnitId = Watched("")
let isWindowAttached = Watched(false)
let function close() {
  curSelectedUnitId("")
  openUnitOvr(null)
}
let buttonsGap = hdpx(40)

let baseUnit = Computed(function() {
  let { name = null, canShowOwnUnit = true} = openUnitOvr.value
  local res = canShowOwnUnit ? myUnits.value?[name] ?? serverConfigs.value?.allUnits[name]
    : serverConfigs.value?.allUnits[name]
  if (res == null)
    return res
  res = res.__merge(openUnitOvr.value)
  if (res?.isUpgraded ?? false)
    res.__update(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {})
  return res
})
let isOpened = Computed(@() baseUnit.value != null)

let isShowedUnitOwned = Computed(@() baseUnit.value?.name in myUnits.value)

let platoonUnitsList = Computed(function() {
  let { name = "", platoonUnits = [] } = baseUnit.value
  return platoonUnits.len() != 0
    ? [ { name, reqLevel = 0 } ].extend(platoonUnits)
    : []
})

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
    name = pu?[0].name ?? ""
  curSelectedUnitId(name)
})

let unitToShow = keepref(Computed(function() {
  if (!isWindowAttached.value || baseUnit.value == null)
    return null
  let unitName = curSelectedUnitId.value
  if (unitName == baseUnit.value.name || unitName == "")
    return baseUnit.value
  return baseUnit.value.__merge({ name = unitName })
}))
unitToShow.subscribe(function(unit) {
  if (unit != null)
    setCustomHangarUnit(unit, false)
  else
    resetCustomHangarUnit()
})

let UNIT_DELAY = 1.5
let UNIT_SCALE = 1.2
let function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let { isPremium = false, isUpgraded = false } = unit
  let isSelected = Computed(@() curSelectedUnitId.value == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && !isUpgraded && platoonUnit.reqLevel > (myUnits.value?[unit.name].level ?? 0))
  let imgOvr = { picSaturate = isLocked.value ? 0.0 : 1.0 }
  let justUnlockedDelay = Computed(@() justUnlockedPlatoonUnits.value.indexof(platoonUnit.name) != null ? UNIT_DELAY : null)

  return @() {
    watch = [isLocked, justUnlockedDelay]
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(isSelected)
      {
        key = {}
        size = [ unitPlateWidth, unitPlateHeight ]
        transform = {}
        animations = scaleAnimation(justUnlockedDelay.value, [UNIT_SCALE, UNIT_SCALE])
        children = [
          mkUnitBg(unit, imgOvr, justUnlockedDelay.value)
          mkUnitSelectedGlow(unit, isSelected, justUnlockedDelay.value)
          mkUnitImage(unit.__merge(platoonUnit)).__update(imgOvr)
          mkUnitTexts(unit, loc(p.locId))
          !isLocked.value
            ? mkGradRank(unit.mRank, {
              hplace = ALIGN_RIGHT
              vplace = ALIGN_BOTTOM
              padding = hdpx(10)
            }): null
          mkUnitSlotLockedLine(platoonUnit, isLocked.value, justUnlockedDelay.value)
        ]
      }
    ]
  }
}

let function platoonUnitsBlock() {
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
    onClick = close
  }, unitToShow)
}

let testDriveButton = @() {
  watch = can_debug_units
  children = !can_debug_units.value ? null
    : textButtonPrimary("Test Drive",
        @() startTestFlight(unitToShow.value?.name),
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
  flow = FLOW_VERTICAL
  watch = isShowedUnitOwned
  gap = hdpx(30)
  children = [
    mkUnitPkgDownloadInfo(baseUnit, true, { halign = ALIGN_LEFT })
    {
      flow = FLOW_HORIZONTAL
      gap = buttonsGap
      vplace = ALIGN_BOTTOM
      valign = ALIGN_BOTTOM
      children = [
        isShowedUnitOwned.value ? btnOpenUnitAttrBig : null
        lvlUpButton
        testDriveButton
      ]
    }
  ]
}

let sceneRoot = {
  key = isOpened
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
        children = mkLeftBlockUnitCampaign(close, $"gamercard/levelUnitDetails/desc/{curCampaign.value}",
          baseUnit.value)
      }
      unitInfoPanelPlace
      {
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

registerScene("unitDetailWnd", sceneRoot, close, isOpened)

return @(unitOvr = {}) openUnitOvr(unitOvr)
