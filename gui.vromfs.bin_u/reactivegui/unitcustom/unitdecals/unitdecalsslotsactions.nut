from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { removeDecalFromSelectedSlot, editSelectedSlot, selectedDecalId, selectedSlotId, selectedSlot, resetDecalsPreset
  isEditingDecal, getEmptySlotIdx, enterDecalMode, isNotEqualPresets, isCurSkinAvailable, curSkinForEdit
} = require("%rGui/unitCustom/unitDecals/unitDecalsState.nut")
let notEmptySlotWnd = require("%rGui/unitCustom/unitDecals/notEmptySlotWnd.nut")
let { textButtonPrimary, textButtonInactive } = require("%rGui/components/textButton.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let gap = hdpx(10)

let skinIsNotAvailableForEditMsg = @(skin) openMsgBox({
  text = skin == "upgraded"
    ? loc("mainmenu/customization/decals/upgradedSkinIsNotAvailable")
    : loc("mainmenu/customization/decals/skinIsNotAvailable")
})
let deleteButton = @() {
  watch = [isCurSkinAvailable, curSkinForEdit]
  children = !isCurSkinAvailable.get()
    ? textButtonInactive(utf8ToUpper(loc("msgbox/btn_remove")), @() skinIsNotAvailableForEditMsg(curSkinForEdit.get()))
    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_remove")), removeDecalFromSelectedSlot)
}
let editButton = @() {
  watch = [isCurSkinAvailable, curSkinForEdit]
  children = !isCurSkinAvailable.get()
    ? textButtonInactive(utf8ToUpper(loc("msgbox/btn_edit")), @() skinIsNotAvailableForEditMsg(curSkinForEdit.get()))
    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_edit")), editSelectedSlot)
}
let placeButton = @() {
  watch = [isCurSkinAvailable, curSkinForEdit]
  children = !isCurSkinAvailable.get()
    ? textButtonInactive(utf8ToUpper(loc("msgbox/btn_place")), @() skinIsNotAvailableForEditMsg(curSkinForEdit.get()))
    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_place")),
        @() getEmptySlotIdx() != null
          ? enterDecalMode(getEmptySlotIdx())
          : notEmptySlotWnd(),
        { hotkeys = ["Space | Enter"]})
}

let resetButton = @() {
  watch = [isNotEqualPresets, isCurSkinAvailable, curSkinForEdit]
  children = !isNotEqualPresets.get()
      ? null
    : !isCurSkinAvailable.get()
      ? textButtonInactive(utf8ToUpper(loc("msgbox/btn_reset")), @() skinIsNotAvailableForEditMsg(curSkinForEdit.get()))
    : textButtonPrimary(utf8ToUpper(loc("msgbox/btn_reset")), @() openMsgBox({
        text = loc("mainmenu/customization/decals/resetDecalsPreset"),
        buttons = [
          { id = "cancel", isCancel = true }
          { id = "ok", styleId = "PRIMARY", cb = resetDecalsPreset }
        ]
      }))
}

let slotsActions = {
  flow = FLOW_VERTICAL
  gap
  children = [
    resetButton
    {
      flow = FLOW_HORIZONTAL
      gap
      children = [editButton, deleteButton]
    }
  ]
}

return @() {
  watch = [selectedSlot, isEditingDecal, selectedSlotId, selectedDecalId]
  margin = [hdpx(25), 0, 0, 0]
  flow = FLOW_HORIZONTAL
  gap
  children = isEditingDecal.get() ? null
    : (selectedSlotId.get() != null && !selectedSlot.get()?.isEmpty) ? slotsActions
    : (selectedDecalId.get() != null) ? [placeButton, resetButton]
    : resetButton
}
