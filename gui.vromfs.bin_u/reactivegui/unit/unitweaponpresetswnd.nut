from "%globalsDarg/darg_library.nut" import *

let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShadedLight } = require("%rGui/style/backgrounds.nut")
let { unitWeaponPresetWeaponry, curUnit, onDelete, onApply, openEditNameWnd, isCurrentPreset,
  isNotSavedPreset, isMaxSavedPresetAmountReached } = require("unitWeaponPresetsWeaponry.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { sendPlayerActivityToServer } = require("%rGui/respawn/playerActivity.nut")

let isOpenedPresetWnd = Watched(false)
let WND_UID = "PRESET_WND"
let BTN_WIDTH = hdpx(250)
let BTN_HEIGHT = hdpx(70)
let BTN_ICON_SIZE = BTN_HEIGHT
let ICON_SIZE = hdpx(40)
let BTN_GAP = hdpx(20)

function openUnitWeaponPresetWnd(unit) {
  sendPlayerActivityToServer()
  isOpenedPresetWnd.set(true)
  curUnit.set(unit)
}

function closeUnitWeaponPresetWnd() {
  sendPlayerActivityToServer()
  isOpenedPresetWnd.set(false)
  curUnit.set(null)
}

function mkCustomIconButton(iconPath, onClick, isDisabled) {
  let btn = (isDisabled ? textButtonCommon : textButtonPrimary)(
    null,
    onClick,
    {ovr = { size = [BTN_ICON_SIZE, BTN_ICON_SIZE], minWidth = BTN_ICON_SIZE}}
  )
  let icon = {
    size = [ICON_SIZE, ICON_SIZE]
    rendObj = ROBJ_IMAGE
    image = Picture($"{iconPath}:{ICON_SIZE}:{ICON_SIZE}")
    keepAspect = KEEP_ASPECT_FIT
  }
  return {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [btn, icon]
  }
}

let mkButtons = @() {
  watch = [isCurrentPreset, isNotSavedPreset, isMaxSavedPresetAmountReached]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = BTN_GAP
  children = [
    mkCustomIconButton(
      "ui/gameuiskin#btn_trash.svg",
      onDelete,
      isNotSavedPreset.get()
    ),
    mkCustomIconButton(
      "ui/gameuiskin#menu_edit.svg",
      @() openEditNameWnd(false),
      isNotSavedPreset.get()
    ),
    mkCustomIconButton(
      "ui/gameuiskin#icon_save.svg",
      @() openEditNameWnd(true),
      !isNotSavedPreset.get() || isMaxSavedPresetAmountReached.get()
    ),
    (isCurrentPreset.get() ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(loc("mainmenu/btnApply")),
      onApply,
      {ovr = {size = [SIZE_TO_CONTENT, BTN_HEIGHT], minWidth = BTN_WIDTH}, childOvr = fontTinyAccentedShaded}
    )
  ]
}

let contentHeader = {
  flow = FLOW_HORIZONTAL
  size = SIZE_TO_CONTENT
  valign = ALIGN_CENTER
  gap = saBordersRv[0]
  margin = [0, 0, saBordersRv[0], 0]
  children = [
    backButton(closeUnitWeaponPresetWnd)
    {
      rendObj = ROBJ_TEXT
      text = loc("presets/title")
    }.__update(fontMedium)
  ]
}

let mainContent = bgShadedLight.__merge({
  stopMouse = true
  size =  flex()
  padding = saBordersRv
  children = {
    size =  flex()
    flow = FLOW_VERTICAL
    children = [
      contentHeader
      unitWeaponPresetWeaponry
      mkButtons
    ]
  }
})

function unitWeaponPresetWnd(){
  let res = { watch = isOpenedPresetWnd }
  if (!isOpenedPresetWnd.get())
    return res
  return res.__update({
    key = {}
    size = flex()
    onDetach = closeUnitWeaponPresetWnd
    children = [
      mkCutBg([]),
      mainContent
    ]
  })
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  children = unitWeaponPresetWnd
  onClick = closeUnitWeaponPresetWnd
  stopMouse = true
})

if (isOpenedPresetWnd.get())
  openImpl()
isOpenedPresetWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return {
  openUnitWeaponPresetWnd
}
