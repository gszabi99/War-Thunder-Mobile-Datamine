from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { deep_clone, isEqual } = require("%sqstd/underscore.nut")
let { apply_slot_preset } = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { iconButtonPrimary, iconButtonCommon, textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShadedLight } = require("%rGui/style/backgrounds.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { unitInfoPanel, mkUnitTitle } = require("%rGui/unit/components/unitInfoPanel.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { unitPlateSize } = require("slotBarConsts.nut")
let { mkUnitBg, bgUnit, mkUnitImage, mkUnitTexts, mkUnitPlateBorder, mkUnitLock, mkUnitSelectedGlow
} = require("%rGui/unit/components/unitPlateComp.nut")
let { openEditTextWnd, closeEditTextWnd } = require("%rGui/components/editTextWnd.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let panelBg = require("%rGui/components/panelBg.nut")
let { mkSlotHeader, emptySlotText } = require("%rGui/slotBar/slotBar.nut")
let { getSlotAnimTrigger } = require("%rGui/slotBar/slotBarState.nut")
let { playerSelectedPresetIdx, playerSelectedSlotIdx, currentPresetName, savedSlotPresets,
  isOpenedPresetWnd, closeSlotPresetWnd,
  currentPresetUnits, setSavedSlotPresets, loadSlotPresets
} = require("%rGui/slotBar/slotPresetsState.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { mkBlocksContainer } = require("%rGui/components/verticalBlocks.nut")


let WND_UID = "SLOT_PRESET_WND"

let MAX_TEXT_LENGTH_DEFAULT = 16
let MAX_SAVED_PRESET = 5
let btnWidth = hdpx(250)
let btnIconSize = hdpx(70)
let iconSize = hdpx(40)
let btnGap = hdpx(20)
let infoPanelWidth = hdpx(640)
let infoPanelHeight = saSize[1] - backButtonHeight - btnIconSize - saBordersRv[0] * 2
let infoPanelPadding = hdpx(50)
let presetBlockWidth = saSize[0] - infoPanelWidth + saBordersRv[1] - hdpx(10)
let presetBlockHeight = Computed(@() isGamepad.get() ? infoPanelHeight : saSize[1] - backButtonHeight - saBordersRv[0])


let mkUnitPlate = @(unit) {
  size = unitPlateSize
  behavior = Behaviors.Button
  children = [
    mkUnitBg(unit)
    mkUnitSelectedGlow(unit, Watched(false))
    mkUnitImage(unit)
    mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
    mkUnitLock(unit, false)
    mkUnitPlateBorder(Watched(false))
  ]
}

function closeEditNameWnd() {
  closeEditTextWnd()
  currentPresetName.set("")
}

function onSave(name) {
  let newPreset = {
    name
    presetUnits = currentPresetUnits.get()
  }
  setSavedSlotPresets(deep_clone(savedSlotPresets.get()).append(newPreset), curCampaign.get())
}

function onSetPresetName(presets, presetIdx) {
  let name = currentPresetName.get().strip()
  if (name.len() == 0)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/empty_name")})
  let savedPresets = savedSlotPresets.get()
  if (savedPresets.findindex(@(p) p.name == name) != null)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply/duplicated")})
  let allPresets = presets
  let presetIdxToEdit = allPresets.len() == savedPresets.len() ? presetIdx : presetIdx - 1
  if (presetIdxToEdit == -1)
    onSave(name)
  else
    setSavedSlotPresets(savedPresets.map(@(p, idx) idx != presetIdxToEdit ? p : p.__merge({name})), curCampaign.get())
  closeEditNameWnd()
}

function openEditNameWnd(presets, presetIdx, isNotSaved, isMaxAmountReached, isNew = false) {
  if (isNew) {
    if (!isNotSaved)
      return openMsgBox({text = loc("msgbox/presets/cannot_save/already_saved")})
    if (isMaxAmountReached)
      return openMsgBox({text = loc("msgbox/presets/cannot_save/max_reached")})
  } else {
    if (isNotSaved)
      return openMsgBox({text = loc("msgbox/presets/cannot_edit")})
  }

  openEditTextWnd(currentPresetName, @() onSetPresetName(presets, presetIdx), MAX_TEXT_LENGTH_DEFAULT)
  currentPresetName.set(presets?[presetIdx].name ?? "")
}

function onDelete(presets, presetIdx, isNotSaved, campaign) {
  if (presetIdx not in presets)
    return
  if (isNotSaved)
    return openMsgBox({text = loc("msgbox/presets/cannot_delete")})
  setSavedSlotPresets(deep_clone(savedSlotPresets.get()).filter(@(p) p.name != presets[presetIdx].name), campaign)
}

function onApply(presets, presetIdx, campaign, isCurrent) {
  if (presetIdx not in presets)
    return
  if (isCurrent)
    return openMsgBox({text = loc("msgbox/presets/cannot_apply")})
  let curPreset = presets[presetIdx]
  apply_slot_preset(curPreset.presetUnits, campaign)
  foreach(idx, name in curPreset.presetUnits)
    anim_start(getSlotAnimTrigger(idx, name, presetIdx))
}

function mkCustomIconButton(iconPath, onClick, isDisabled, hotkeys = null) {
  let mkButton = isDisabled ? iconButtonCommon : iconButtonPrimary
  return @() {
    watch = isGamepad
    children = mkButton(
      iconPath,
      onClick
      {
        iconSize = iconSize,
        ovr = {
          size = isGamepad.get() ? [btnIconSize*2, btnIconSize] : [btnIconSize, btnIconSize],
          minWidth = btnIconSize
        }
        hotkeys
      }
    )
  }
}

function mkPresetButtons(presets, presetIdx) {
  let isCurrentPreset = Computed(@() isEqual(presets.get()?[presetIdx.get()].presetUnits, currentPresetUnits.get()))
  let isNotSavedPreset = Computed(@() presets.get().len() != savedSlotPresets.get().len() && presetIdx.get() == 0)
  let isMaxSavedPresetAmountReached = Computed(@() presets.get().len() > MAX_SAVED_PRESET)

  return @() {
    watch = [presets, isCurrentPreset, isNotSavedPreset, isMaxSavedPresetAmountReached, curCampaign]
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    vplace =  ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = btnGap
    children = [
      mkCustomIconButton(
        "ui/gameuiskin#btn_trash.svg",
        @() onDelete(presets.get(), presetIdx.get(), isNotSavedPreset.get(), curCampaign.get()),
        isNotSavedPreset.get(),
        ["^J:LT"]
      ),
      mkCustomIconButton(
        "ui/gameuiskin#menu_edit.svg",
        @() openEditNameWnd(presets.get(), presetIdx.get(), isNotSavedPreset.get(), isMaxSavedPresetAmountReached.get(), false),
        isNotSavedPreset.get(),
        ["^J:LB"]
      ),
      mkCustomIconButton(
        "ui/gameuiskin#icon_save.svg",
        @() openEditNameWnd(presets.get(), presetIdx.get(), isNotSavedPreset.get(), isMaxSavedPresetAmountReached.get(), true),
        !isNotSavedPreset.get() || isMaxSavedPresetAmountReached.get(),
        ["^J:Y"]
      ),
      (isCurrentPreset.get() ? textButtonCommon : textButtonPrimary)(
        utf8ToUpper(loc("mainmenu/btnApply")),
        @() onApply(presets.get(), presetIdx.get(), curCampaign.get(), isCurrentPreset.get()),
        {
            ovr = {size = [SIZE_TO_CONTENT, btnIconSize], minWidth = btnWidth},
            childOvr = fontTinyAccentedShaded,
            hotkeys = ["^J:X"]
        },
      )
    ]
  }
}

let contentHeader = {
  flow = FLOW_HORIZONTAL
  size = SIZE_TO_CONTENT
  valign = ALIGN_CENTER
  gap = saBordersRv[0]
  margin = [0, 0, saBordersRv[0], 0]
  children = [
    backButton(closeSlotPresetWnd)
    {
      rendObj = ROBJ_TEXT
      text = loc("presets/title")
    }.__update(fontMedium)
  ]
}

let function mkPresetUnitSlot(unit, slotIdx, presetIdx, onClick, isSelected) {
  let stateFlags = Watched(0)
  if (unit == null)
    return @() {
      watch = [isSelected, stateFlags]
      size = unitPlateSize
      behavior = Behaviors.Button
      onClick
      rendObj = ROBJ_IMAGE
      image = bgUnit
      sound = { click = "choose" }
      children = [
        emptySlotText
        mkUnitPlateBorder(isSelected)
      ]
    }
  let trigger = getSlotAnimTrigger(slotIdx, unit.name, presetIdx)

  return @() {
    watch = [isSelected, stateFlags]
    key = trigger
    size = unitPlateSize
    behavior = Behaviors.Button
    onClick
    onElemState = @(s) stateFlags(s)
    clickableInfo = isSelected.get() ? { skipDescription = true } : loc("mainmenu/btnSelect")
    sound = { click = "choose" }
    children = [
      mkUnitBg(unit)
      mkUnitSelectedGlow(unit, Computed(@() isSelected.get() || (stateFlags.get() & S_HOVER)))
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitLock(unit, false)
      mkUnitPlateBorder(isSelected)
    ]
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.scale, from = [0.8, 0.8], duration = 0.2, easing = InQuad, trigger }
      { prop = AnimProp.scale, to = [1.1, 1.1], duration = 0.3, delay = 0.2, easing = Blink, trigger}
      { prop = AnimProp.opacity, from = 0.0, duration = 0.2, easing = OutQuad, trigger }
    ]
  }
}

function mkPresetSlot(slot, slotIdx, presetIdx, isSelected, onClick) {
  let { name = "" } = slot
  let unit = Computed(@() campMyUnits.get()?[name])
  return @() {
    watch = unit
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = [
      mkSlotHeader(slot, slotIdx, unit, isSelected)
      mkPresetUnitSlot(unit.get(), slotIdx, presetIdx, onClick, isSelected)
    ]
  }
}

let mkPresetSlots = @(preset, presetIdx, aPresetIdx, aSlotIdx) @() {
  watch = [curSlots, aPresetIdx, aSlotIdx]
  flow = FLOW_HORIZONTAL
  gap = hdpx(4)
  children = curSlots.get()
    .map(function(slot, i) {
      let pSlot = slot.__merge({name = preset.presetUnits[i]})
      return mkPresetSlot(
        pSlot,
        i,
        presetIdx,
        Computed(@() aPresetIdx.get() == presetIdx && aSlotIdx.get() == i),
        function() {
          if (pSlot.name != "")
            playerSelectedSlotIdx.set(i)
          else
            playerSelectedSlotIdx.set(preset.presetUnits.findindex(@(n) n != ""))
          playerSelectedPresetIdx.set(presetIdx)
        },
      )}
    )
}

let mkBlockContent = @(preset, pIdx, activePresetIdx, activeSlotIdx) @() {
  watch = currentPresetUnits
  rendObj = ROBJ_BOX
  size = [presetBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(4)
  padding = [hdpx(10), hdpx(2), hdpx(2)]
  children = [
    {
      rendObj = ROBJ_TEXT
      margin = [0, 0, 0, hdpx(4)]
      text = $"{preset.name}{!(isEqual(preset.presetUnits, currentPresetUnits.get())) ? "" : $" ({loc("presets/current")})"}"
    }.__update(fontTinyShaded)
    mkPresetSlots(preset, pIdx, activePresetIdx, activeSlotIdx)
  ]
}

function mkMainContent(presets, presetIdx, slotIdx) {
  return bgShadedLight.__merge({
    stopMouse = true
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    children = [
      contentHeader
      @() {
        watch = [presetIdx, presetBlockHeight]
        size = flex()
        children = [
          mkBlocksContainer(
            presets,
            presetIdx,
            @(p, pIdx) mkBlockContent(p, pIdx, presetIdx, slotIdx),
            function(idx) {
              playerSelectedPresetIdx.set(idx)
              playerSelectedSlotIdx.set(null)
            },
            presetBlockWidth,
            hdpx(190),
            presetBlockHeight.get()
          )
          mkPresetButtons(presets, presetIdx)
        ]
      }
    ]
  })
}

function slotPresetWnd() {
  let slotPresets = Computed(function() {
    let savedSPresets = savedSlotPresets.get()
    let currentPresetIdx = savedSPresets.findindex(@(p) isEqual(p.presetUnits, currentPresetUnits.get())) ?? -1

    if (currentPresetIdx == -1)
      return [{
        name = "",
        presetUnits = currentPresetUnits.get()
      }].extend(savedSPresets)

    return savedSPresets
  })
  let activePresetIdx = Computed(@() playerSelectedPresetIdx.get() ?? slotPresets.get().findindex(@(p) isEqual(p?.presetUnits, currentPresetUnits.get())))
  let activeSlotIdx = Computed(@() playerSelectedSlotIdx.get() ?? slotPresets.get()?[activePresetIdx.get()].presetUnits.findindex(@(n) n !=""))
  let presetSlotUnit = Computed(@() campMyUnits.get()?[slotPresets.get()?[activePresetIdx.get()].presetUnits[activeSlotIdx.get()]])

  return {
    watch = [isOpenedPresetWnd, presetSlotUnit]
    key = {}
    size = flex()
    onDetach = closeSlotPresetWnd
    onAttach = loadSlotPresets
    children = [
      mkCutBg([])
      mkMainContent(slotPresets, activePresetIdx, activeSlotIdx)
      !presetSlotUnit.get() ? null : panelBg.__merge({
        size = [infoPanelWidth, infoPanelHeight]
        margin = [backButtonHeight + saBordersRv[0] * 2, 0, 0, 0]
        hplace = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        padding = [infoPanelPadding, 0]
        gap = infoPanelPadding
        children = [
          mkUnitPlate(presetSlotUnit.get()).__merge({hplace = ALIGN_CENTER})
          unitInfoPanel(
            {
              rendObj = ROBJ_BOX
              size = [flex(), SIZE_TO_CONTENT]
              hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
              padding = [0, infoPanelPadding]
              animations = wndSwitchAnim
            }, mkUnitTitle, presetSlotUnit)
          {size = flex()}
        ]
      })
    ]
  }
}

let openImpl = @() addModalWindow({
  key = WND_UID
  size = flex()
  children = slotPresetWnd
  onClick = closeSlotPresetWnd
  stopMouse = true
})

if (isOpenedPresetWnd.get())
  openImpl()
isOpenedPresetWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))
