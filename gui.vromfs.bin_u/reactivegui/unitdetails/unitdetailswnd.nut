from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { myUnits, allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { setCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonName
} = require("%appGlobals/unitPresentation.nut")
let { unitInfoPanelFull, unitInfoPanelDefPos } = require("%rGui/unit/components/unitInfoPanel.nut")
let { unitPlateWidth, unitPlateHeight, unitSelUnderlineFullHeight, unitPlatesGap,
  mkUnitBg, mkUnitSelectedGlow, mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let backButton = require("%rGui/components/backButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { textColor, premiumTextColor } = require("%rGui/style/stdColors.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { can_debug_units } = require("%appGlobals/permissions.nut")
let { startTestFlight } = require("%rGui/gameModes/startOfflineMode.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")

let openUnitOvr = mkWatched(persist, "openUnitOvr", null)
let curSelectedUnitId = Watched("")
let isWindowAttached = Watched(false)
let function close() {
  curSelectedUnitId("")
  openUnitOvr(null)
}
let backBtn = backButton(close)

let baseUnit = Computed(function() {
  let { name = null, canShowOwnUnit = true} = openUnitOvr.value
  local res = canShowOwnUnit ? myUnits.value?[name] ?? allUnitsCfg.value?[name] : allUnitsCfg.value?[name]
  if (res == null)
    return res
  res = res.__merge(openUnitOvr.value)
  if (res?.isUpgraded ?? false)
    res.__update(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {})
  return res
})
let isOpened = Computed(@() baseUnit.value != null)

let platoonUnitsList = Computed(function() {
  let { name = "", platoonUnits = [] } = baseUnit.value
  return platoonUnits.len() != 0
    ? [ { name, reqLevel = 0 } ].extend(platoonUnits)
    : []
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
})

let function platoonTitle(unit) {
  let { name, isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let text = "  ".concat(getPlatoonName(name, loc), getUnitClassFontIcon(unit))
  return {
    margin = [ 0, unitSelUnderlineFullHeight ]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    children = [
      !isElite ? null : {
        size = [hdpxi(50), hdpxi(50)]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/gameuiskin#icon_premium.avif")
      }
      {
        rendObj = ROBJ_TEXT
        color = isElite ? premiumTextColor : textColor
        fontFx = FFT_GLOW
        fontFxColor = 0xFF000000
        fontFxFactor = hdpx(64)
        text
      }.__update(fontMedium)
    ]
  }
}

let function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let { isPremium = false, isUpgraded = false } = unit
  let isSelected = Computed(@() curSelectedUnitId.value == platoonUnit.name)
  let isLocked = !isPremium && !isUpgraded && platoonUnit.reqLevel > (myUnits.value?[unit.name].level ?? 0)
  let imgOvr = { picSaturate = isLocked ? 0.0 : 1.0 }

  return {
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(isSelected)
      {
        size = [ unitPlateWidth, unitPlateHeight ]
        children = [
          mkUnitBg(unit, imgOvr)
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(unit.__merge(platoonUnit)).__update(imgOvr)
          mkUnitTexts(unit, loc(p.locId))
          isLocked ? mkUnitSlotLockedLine(platoonUnit) : null
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
        vplace = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = [ platoonTitle(baseUnit.value) ]
          .extend(platoonUnitsList.value
            .map(@(pu) mkUnitPlate(baseUnit.value, pu, @() curSelectedUnitId(pu.name))))
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
  vplace = ALIGN_BOTTOM
  children = !can_debug_units.value ? null
    : textButtonPrimary("Test Drive",
        @() startTestFlight(unitToShow.value?.name),
        { hotkeys = ["^J:X | Enter"] })
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
      backBtn
      unitInfoPanelPlace
      {
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_BOTTOM
        children = [
          platoonUnitsBlock
          testDriveButton
        ]
      }
    ]
  }
}

registerScene("unitDetailWnd", sceneRoot, close, isOpened)

return @(unitOvr = {}) openUnitOvr(unitOvr)
