from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/activeControls.nut" import isGamepad
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon, iconButtonPrimary, iconButtonCommon
from "%rGui/respawn/playerActivity.nut" import sendPlayerActivityToServer
from "%rGui/style/backgrounds.nut" import bgShadedLight
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import mkCutBg
from "%rGui/unit/unitWeaponPresetsWeaponry.nut" import unitWeaponPresetWeaponry, curUnit, onDelete, onApply,
  openEditNameWnd, isCurrentPreset, isNotSavedPreset, isMaxSavedPresetAmountReached


let isOpenedPresetWnd = Watched(false)
const WND_UID = "PRESET_WND"
const BTN_WIDTH = hdpx(250)
const BTN_HEIGHT = hdpx(70)
const BTN_ICON_SIZE = BTN_HEIGHT
const ICON_SIZE = hdpx(40)
const BTN_GAP = hdpx(20)

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

function mkCustomIconButton(iconPath, onClick, isDisabled, hotkeys = null) {
  let mkButton = isDisabled ? iconButtonCommon : iconButtonPrimary
  return @() {
    watch = isGamepad
    children = mkButton(
      iconPath,
      onClick
      {
        iconOvr = { size = ICON_SIZE },
        ovr = {
          size = isGamepad.get() ? [BTN_ICON_SIZE*2, BTN_ICON_SIZE] : [BTN_ICON_SIZE, BTN_ICON_SIZE],
          minWidth = BTN_ICON_SIZE
        }
        hotkeys
      }
    )
  }
}

let mkButtons = @() {
  watch = [isCurrentPreset, isNotSavedPreset, isMaxSavedPresetAmountReached]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  gap = BTN_GAP
  children = [
    mkCustomIconButton(
      "ui/gameuiskin#btn_trash.svg",
      onDelete,
      isNotSavedPreset.get(),
      ["^J:LT"]
    ),
    mkCustomIconButton(
      "ui/gameuiskin#menu_edit.svg",
      @() openEditNameWnd(false),
      isNotSavedPreset.get(),
      ["^J:LB"]
    ),
    mkCustomIconButton(
      "ui/gameuiskin#icon_save.svg",
      @() openEditNameWnd(true),
      !isNotSavedPreset.get() || isMaxSavedPresetAmountReached.get(),
      ["^J:Y"]
    ),
    (isCurrentPreset.get() ? textButtonCommon : textButtonPrimary)(
      utf8ToUpper(loc("mainmenu/btnApply")),
      onApply,
      {
          ovr = {size = const [SIZE_TO_CONTENT, BTN_HEIGHT], minWidth = BTN_WIDTH},
          childOvr = fontTinyAccentedShaded,
          hotkeys = ["^J:X"]
      },
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
  size =  FLEX
  padding = saBordersRv
  children = {
    size =  FLEX
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
    size = FLEX
    onDetach = closeUnitWeaponPresetWnd
    children = [
      mkCutBg([]),
      mainContent
    ]
  })
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = FLEX
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
