from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { deferOnce, setTimeout } = require("dagor.workcycle")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")

let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { slots } = require("%rGui/slotBar/slotBarState.nut")

let TIME_TO_DELAY = 3.5
let delayedPurchaseList = persist("delayedPurchaseList", @() [])
let needSaveUnitDataForTutorial = mkWatched(persist, "needSaveUnitDataForTutorial", false)
let delayedPurchaseUnitData = mkWatched(persist, "delayedPurchaseUnitData", {})

needSaveUnitDataForTutorial.subscribe(@(v) !v ? delayedPurchaseUnitData.set({}) : null)

let needShow = keepref(Computed(@() !hasModalWindows.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && isMainMenuAttached.get()
  && isLoggedIn.get()))

function showPurchases() {
  if (!needShow.get() && delayedPurchaseList.len() == 0)
    return
  let listForRequest = delayedPurchaseList.filter(@(v) slots.get().findindex(@(slot) slot?.name == v) != null)

  if(listForRequest.len() == 0)
    return delayedPurchaseList.clear()

  if (curUnit.get()?.name != listForRequest.top())
    setCurrentUnit(listForRequest.top())

  foreach (idx, unitId in listForRequest) {
    let unit = campMyUnits.get()?[unitId]
    if (unit)
      setTimeout(idx * TIME_TO_DELAY, function() {
        setHangarUnit(unit.name)
        requestOpenUnitPurchEffect(unit)
        let index = delayedPurchaseList.findindex(@(p) p == unit.name)
        if(index != null)
          delayedPurchaseList.remove(index)
      }, {})
  }
}
needShow.subscribe(@(v) v ? deferOnce(showPurchases) : null)

function addNewPurchasedUnit(unitId) {
  if (unitId == null)
    return
  delayedPurchaseList.append(unitId)
}

function debug_unit_slots_purchase_effects() {
  delayedPurchaseList.replace(slots.get().map(@(v) v?.name).filter(@(v) v != ""))
  if (needShow.get())
    showPurchases()
  else
    console_print("Need to wait for the main menu to be attached!") 
}

register_command(debug_unit_slots_purchase_effects, "debug.unit_slots_purchase_effects")

return {
  addNewPurchasedUnit
  delayedPurchaseUnitData
  needSaveUnitDataForTutorial
}
