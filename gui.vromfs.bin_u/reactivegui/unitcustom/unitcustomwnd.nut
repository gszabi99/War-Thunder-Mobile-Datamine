from "%globalsDarg/darg_library.nut" import *

let { HangarCameraControl } = require("wt.behaviors")
let { getUnitPresentation, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { skinActionBtn, skinsBlockNoTags, skinsBlockWithTags } = require("%rGui/unitCustom/unitSkins/unitSkinsComps.nut")
let { hasTagsChoice } = require("%rGui/unitCustom/unitSkins/unitSkinsState.nut")
let { unitPlateWidth, unitPlateHeight, unitPlatesGap, mkUnitInfo, mkUnitBg, mkUnitSelectedGlow,
  mkUnitImage, mkUnitTexts, mkUnitSlotLockedLine, mkUnitSelectedUnderlineVert
} = require("%rGui/unit/components/unitPlateComp.nut")
let { curSelectedUnitId, baseUnit, platoonUnitsList, unitToShow, isCustomizationWndAttached
} = require("%rGui/unitDetails/unitDetailsState.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY
} = require("%rGui/components/gradientDefComps.nut")
let { gamercardHeight, mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { closeUnitCustom, unitCustomOpenCount } = require("%rGui/unitCustom/unitCustomState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { registerScene } = require("%rGui/navState.nut")


function mkUnitPlate(unit, platoonUnit, onClick) {
  let p = getUnitPresentation(platoonUnit)
  let platoonUnitFull = unit.__merge(platoonUnit)
  let isPremium = !!(unit?.isPremium || unit?.isUpgraded)
  let isSelected = Computed(@() unitToShow.get()?.name == platoonUnit.name)
  let isLocked = Computed(@() !isPremium && platoonUnit.reqLevel > (campMyUnits.get()?[unit.name].level ?? 0))

  return @() {
    watch = isLocked
    behavior = Behaviors.Button
    onClick
    sound = { click  = "choose" }
    flow = FLOW_HORIZONTAL
    children = [
      mkUnitSelectedUnderlineVert(unit, isSelected)
      {
        size = [unitPlateWidth, unitPlateHeight]
        children = [
          mkUnitBg(unit, isLocked.get())
          mkUnitSelectedGlow(unit, isSelected)
          mkUnitImage(platoonUnitFull, isLocked.get())
          mkUnitTexts(platoonUnitFull, loc(p.locId), isLocked.get())
          !isLocked.get() ? mkUnitInfo(unit, { pos = [-hdpx(30), 0] }) : null
          mkUnitSlotLockedLine(platoonUnit, isLocked.get())
        ]
      }
    ]
  }
}

function platoonUnitsBlock() {
  let res = { watch = [ baseUnit, platoonUnitsList ] }
  return platoonUnitsList.get().len() == 0
      ? res
    : res.__update({
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = platoonUnitsList.get()
          .map(@(pu) mkUnitPlate(baseUnit.get(), pu, @() curSelectedUnitId.set(pu.name)))
      })
}



let unitCustomizationGamercard = {
  size = [flex(), gamercardHeight]
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  children = [
    doubleSideGradient.__merge({
      size = [SIZE_TO_CONTENT, gamercardHeight]
      padding = [doubleSideGradientPaddingY, doubleSideGradientPaddingX, doubleSideGradientPaddingY, 0]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = hdpx(50)
      children = [
        backButton(closeUnitCustom)
        {
          flow = FLOW_VERTICAL
          gap = hdpx(10)
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("skins/header")
            }.__update(fontSmall)
            @() {
              watch = baseUnit
              rendObj = ROBJ_TEXT
              text = getPlatoonOrUnitName(baseUnit.get(), loc)
            }.__update(fontSmall)
          ]
        }
      ]
    })
    { size = flex() }
    mkCurrenciesBtns([GOLD])
  ]
}

let unitCustomWnd = {
  key = {}
  size = flex()
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  onAttach = @() isCustomizationWndAttached.set(true)
  onDetach = @() isCustomizationWndAttached.set(false)
  children = [
    unitCustomizationGamercard
    {
      size = flex()
      valign = ALIGN_BOTTOM
      padding = saBordersRv
      children = [
        platoonUnitsBlock
        @() {
          watch = [hasTagsChoice, unitToShow]
          hplace = ALIGN_RIGHT
          pos = [doubleSideGradientPaddingX, 0] 
          flow = FLOW_VERTICAL
          gap = hdpx(50)
          children = !unitToShow.get() ? null
            : [
                hasTagsChoice.get() ? skinsBlockWithTags : skinsBlockNoTags
                skinActionBtn
              ]
        }
      ]
    }
  ]
  animations = wndSwitchAnim
}

registerScene("unitCustomWnd", unitCustomWnd, closeUnitCustom, unitCustomOpenCount)
