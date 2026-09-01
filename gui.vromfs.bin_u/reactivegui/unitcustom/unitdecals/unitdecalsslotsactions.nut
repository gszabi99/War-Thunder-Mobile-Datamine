from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonInactive
import "%rGui/unitCustom/unitDecals/notEmptySlotWnd.nut" as notEmptySlotWnd
from "%rGui/unitCustom/unitDecals/unitDecalsState.nut" import removeDecalFromSelectedSlot, editSelectedSlot,
  selectedDecalId, selectedSlotId, selectedSlot, resetDecalsPreset, isEditingDecal, getEmptySlotIdx, enterDecalMode,
  isNotEqualPresets, isCurSkinAvailable, curSkinForEdit


const gap = hdpx(10)

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
  margin = const [hdpx(25), 0, 0, 0]
  flow = FLOW_HORIZONTAL
  gap
  children = isEditingDecal.get() ? null
    : (selectedSlotId.get() != null && !selectedSlot.get()?.isEmpty) ? slotsActions
    : (selectedDecalId.get() != null) ? [placeButton, resetButton]
    : resetButton
}
