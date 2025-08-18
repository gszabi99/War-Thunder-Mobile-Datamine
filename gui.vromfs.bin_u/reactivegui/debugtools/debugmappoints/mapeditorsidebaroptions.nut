from "%globalsDarg/darg_library.nut" import *
let { isSidebarOptionsOpen, loadPreset, createPresetsByUnlocks, hasEventUnlocks
  presetMapSize, currentPresetId, savedPresets, addOrEditPreset, deletePreset
  presetBackground, isCurPresetChanged, saveCurrentPreset
} = require("%rGui/debugTools/debugMapPoints/mapEditorState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { removeModalWindow, addModalWindowWithHeader } = require("%rGui/components/modalWindows.nut")
let { optionsBtnGap, btnBgColorDefault, optionBtnSize, btnBgColorNegative, btnBgColorPositive } = require("%rGui/debugTools/debugMapPoints/mapEditorConsts.nut")
let { mkOptionBtn, mkTextOptionBtn, mkTextInputField, mkText, modalBg } = require("%rGui/debugTools/debugMapPoints/mapEditorComps.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let ADD_PRESET_WND = "addPresetWnd"
let SELECT_PRESET_WND = "selectPresetWnd"
let EDIT_PRESET_WND = "editPresetWnd"

let presetIdField = Watched("")
let presetBackgroundField = Watched("")

let mapSizeXField = Watched("")
let mapSizeYField = Watched("")

function askSaveAndContinue(handler) {
  if (!isCurPresetChanged.get()) {
    handler()
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = handler }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        function cb() {
          saveCurrentPreset()
          handler()
        }
      }
    ]
  })
}

function clearOrFillFields(id = "", img = "") {
  presetIdField.set(id)
  presetBackgroundField.set(img)
}

function onAddPreset(id, bg, mapSize) {
  if (id == "")
    return openMsgBox({ text = "Preset ID is required!" })
  if (id in savedPresets.get())
    return openMsgBox({ text = "Preset ID must be unique" })

  addOrEditPreset(id, bg, mapSize)
  removeModalWindow(ADD_PRESET_WND)
}

function onEditPreset(id, bg, mapSize) {
  addOrEditPreset(id, bg, mapSize)
  removeModalWindow(EDIT_PRESET_WND)
}

let selectPresetContent = modalBg.__merge({
  size = const [hdpx(700), hdpx(900)]
  children = makeVertScroll(@() {
    watch = savedPresets
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = savedPresets.get().keys().sort()
      .map(@(id) mkTextOptionBtn(id, @() loadPreset(id), { size = [flex(), optionBtnSize] }))
  })
})

let addPresetContent = modalBg.__merge({
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields()

    mapSizeXField.set(presetMapSize.get()[0].tostring())
    mapSizeYField.set(presetMapSize.get()[1].tostring())
  }
  children = [
    mkText("Preset ID:")
    mkTextInputField(presetIdField, "Set preset ID")
    mkText("Preset background:")
    mkTextInputField(presetBackgroundField, "Set preset background")
    mkText("Set size in pixels on the X axis:")
    mkTextInputField(mapSizeXField, "Set size in pixels on the X axis", { inputType = "num" })
    mkText("Set size in pixels on the Y axis:")
    mkTextInputField(mapSizeYField, "Set size in pixels on the Y axis", { inputType = "num" })
    mkTextOptionBtn("ADD",
      @() onAddPreset(presetIdField.get(), presetBackgroundField.get(),
        [mapSizeXField.get().tointeger(), mapSizeYField.get().tointeger()]))
  ]
})

let editPresetContent = modalBg.__merge({
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields(currentPresetId.get(), presetBackground.get())

    mapSizeXField.set(presetMapSize.get()[0].tostring())
    mapSizeYField.set(presetMapSize.get()[1].tostring())
  }
  children = [
    mkText("Preset background:")
    mkTextInputField(presetBackgroundField, "Set preset background")
    mkText("Set size in pixels on the X axis:")
    mkTextInputField(mapSizeXField, "Set size in pixels on the X axis", { inputType = "num" })
    mkText("Set size in pixels on the Y axis:")
    mkTextInputField(mapSizeYField, "Set size in pixels on the Y axis", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      @() onEditPreset(presetIdField.get(), presetBackgroundField.get(),
        [mapSizeXField.get().tointeger(), mapSizeYField.get().tointeger()]))
  ]
})

let toggleBtn = @() {
  watch = isSidebarOptionsOpen
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER

  children = mkOptionBtn("ui/gameuiskin#hud_tank_arrow_segment.svg",
    @() isSidebarOptionsOpen.set(!isSidebarOptionsOpen.get()),
    isSidebarOptionsOpen.get() ? "hudTuning/toggle/desc/hide" : "hudTuning/toggle/desc/show",
    {
      color = btnBgColorDefault
      transform = isSidebarOptionsOpen.get() ? { rotate = 270 } : { rotate = 90 }
      transitions = [{ prop = AnimProp.rotate, duration = 0.2, easing = InOutQuad }]
    })
}

let deletePresetBtn = @() {
  watch = currentPresetId
  children = !currentPresetId.get() ? null
    : mkTextOptionBtn("Delete preset", @() deletePreset(currentPresetId.get()), { color = btnBgColorNegative })
}
let editPresetBtn = @(id) mkTextOptionBtn("Edit preset", @()
  addModalWindowWithHeader(EDIT_PRESET_WND, $"Edit preset {id}", editPresetContent), { size = [flex(), optionBtnSize] })
let addPresetBtn = mkTextOptionBtn("Add preset", @() askSaveAndContinue(@()
  addModalWindowWithHeader(ADD_PRESET_WND, "Create new blank preset", addPresetContent)), { size = [flex(), optionBtnSize] })
let selectPresetBtn = mkTextOptionBtn("Select preset", @() askSaveAndContinue(@()
  addModalWindowWithHeader(SELECT_PRESET_WND, "Select preset", selectPresetContent)), { size = [flex(), optionBtnSize] })
let generatePresetsBtn = mkTextOptionBtn("Generate presets",
  @() askSaveAndContinue(createPresetsByUnlocks),
  { size = [flex(), optionBtnSize], color = btnBgColorPositive })

let content = @() {
  watch = [currentPresetId, savedPresets, hasEventUnlocks]
  size = const [hdpx(300), flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = optionsBtnGap
  children = [
    addPresetBtn
    currentPresetId.get() ? editPresetBtn(currentPresetId.get()) : null
    savedPresets.get().len() > 1 ? selectPresetBtn : null
    hasEventUnlocks.get() ? generatePresetsBtn : null
    { size = FLEX_V }
    deletePresetBtn
  ]
}

let mapEditorSidebarOptions = {
  size = FLEX_V
  padding = [optionBtnSize + optionsBtnGap + saBordersRv[0], 0]
  vplace = ALIGN_BOTTOM
  children = [
    @() {
      watch = isSidebarOptionsOpen
      size = FLEX_V
      padding = [optionsBtnGap, saBorders[0]]
      rendObj = ROBJ_SOLID
      color = 0xC0000000
      children = content
      transform = { translate = [isSidebarOptionsOpen.get() ? 0 : hdpx(-800), 0] }
      transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    }
    toggleBtn
  ]
}

return mapEditorSidebarOptions
