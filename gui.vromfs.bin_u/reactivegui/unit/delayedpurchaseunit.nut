from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { campMyUnits, curUnit } = require("%appGlobals/pServer/profile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")

let { requestOpenUnitPurchEffect, isPurchEffectVisible } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { isTutorialActive } = require("%rGui/tutorial/tutorialWnd/tutorialWndState.nut")
let { isMainMenuAttached } = require("%rGui/mainMenu/mainMenuState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")

let delayedPurchaseList = persist("delayedPurchaseList", @() [])
let needSaveUnitDataForTutorial = mkWatched(persist, "needSaveUnitDataForTutorial", false)
let delayedPurchaseUnitData = mkWatched(persist, "delayedPurchaseUnitData", {})
let needShowLastPurchasedUnit = mkWatched(persist, "needShowLastPurchasedUnit", false)
let lastPurchasedUnit = mkWatched(persist, "lastPurchasedUnit", null)

needSaveUnitDataForTutorial.subscribe(@(v) !v ? delayedPurchaseUnitData.set({}) : null)
needShowLastPurchasedUnit.subscribe(@(v) !v ? lastPurchasedUnit.set(null) : null)

let needShow = keepref(Computed(@() !hasModalWindows.get()
  && !isPurchEffectVisible.get()
  && !isInLoadingScreen.get()
  && !isTutorialActive.get()
  && isMainMenuAttached.get()
  && isLoggedIn.get()))

let needShowLastUnit = keepref(Computed(@() needShow.get()
  && needShowLastPurchasedUnit.get()
  && lastPurchasedUnit.get() != null))

function showPurchasedUnit(unit) {
  if (!unit)
    return
  setHangarUnit(unit.name)
  requestOpenUnitPurchEffect(unit)
}

function showPurchases() {
  if (!needShow.get() || delayedPurchaseList.len() == 0 || isPurchEffectVisible.get())
    return

  let listForRequest = delayedPurchaseList.filter(@(v) curSlots.get().findindex(@(slot) slot?.name == v) != null)
  if(listForRequest.len() == 0)
    return delayedPurchaseList.clear()

  let unit = campMyUnits.get()?[listForRequest.top()]
  if (!unit)
    return

  if (curUnit.get()?.name != unit.name)
    setCurrentUnit(unit.name)
  showPurchasedUnit(unit)

  let index = delayedPurchaseList.findindex(@(p) p == unit.name)
  if (index != null)
    delayedPurchaseList.remove(index)
}
needShow.subscribe(@(v) v ? deferOnce(showPurchases) : null)

function addNewPurchasedUnit(unitId) {
  if (unitId == null)
    return
  delayedPurchaseList.append(unitId)
}

function showLastPurchasedUnit() {
  if (!needShowLastUnit.get())
    return
  showPurchasedUnit(lastPurchasedUnit.get())
  needShowLastPurchasedUnit.set(false)
}

needShowLastUnit.subscribe(@(v) v ? deferOnce(showLastPurchasedUnit) : null)

function addLastPurchasedUnit(unitId) {
  let unit = campMyUnits.get()?[unitId]
  if (unit == null)
    return
  lastPurchasedUnit.set(unit)
  needShowLastPurchasedUnit.set(true)
}

function debug_unit_slots_purchase_effects() {
  delayedPurchaseList.replace(curSlots.get().map(@(v) v?.name).filter(@(v) v != ""))
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
  lastPurchasedUnit
  addLastPurchasedUnit
  needShowLastPurchasedUnit
}
