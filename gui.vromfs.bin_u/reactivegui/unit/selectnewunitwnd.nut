from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isPurchEffectVisible, requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { openMsgBox, msgBoxText, closeMsgBox } = require("%rGui/components/msgBox.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")


let WND_UID = "selectNewUnitToCurrent"

let boughtUnit = mkWatched(persist, "boughtUnit", null)

let needOpen = keepref(Computed(@() boughtUnit.get() != null
  && !isPurchEffectVisible.get()
  && !isInBattle.get()))

let shouldOpen = keepref(Computed(@() needOpen.get() && !hasModalWindows.get()))

function close() {
  boughtUnit.set(null)
  closeMsgBox(WND_UID)
}

function onSubmit() {
  setCurrentUnit(boughtUnit.get())
  let unitForPurchEffect = campMyUnits.get()?[boughtUnit.get()]
  if (unitForPurchEffect != null)
    requestOpenUnitPurchEffect(unitForPurchEffect)
  close()
}

let openImpl = @() openMsgBox({
  uid = WND_UID
  text = msgBoxText(loc("shop/chooseUnit",
  { unit = colorize(userlogTextColor, loc(getUnitPresentation(boughtUnit.get()).locId)) })),
  buttons = [
    { id = "cancel", cb = close, isCancel = true }
    { text = loc("msgbox/btn_choose"), cb = onSubmit , styleId = "PRIMARY", isDefault = true }
  ],
})

function open() {
  resetTimeout(0.1, function() {
    if (!shouldOpen.get())
      return
    openImpl()
  })
}

if (shouldOpen.get())
  open()
shouldOpen.subscribe(@(v) v ? open() : null)
needOpen.subscribe(@(v) v ? null : close())

return { boughtUnit }