from "%globalsDarg/darg_library.nut" import *
let { toIntegerSafe } = require("%sqstd/string.nut")
let { mapPointsPresentations } = require("%appGlobals/config/mapPointsPresentation.nut")
let { isCurPresetChanged, closeEventMapEditor, saveCurrentPreset, addOrEditPoint, selectedBgElemIdx,
  isHeaderOptionsOpen, selectedPointId, setByHistory, curHistoryIdx, deleteElement,
  isEditAllowed, presetPointSize, needUseAutoSave, tuningPoints, tuningBgElems,
  historyMapElements, selectElem, defaultPointSize, changeCurPresetField, presetGridSize,
  ELEM_POINT, ELEM_BG, addBgElement, editBgElement, selectedElem, copyElement
} = require("mapEditorState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { removeModalWindow, addModalWindowWithHeader } = require("%rGui/components/modalWindows.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { optionsBtnGap, btnBgColorDefault, btnBgColorPositive, btnBgColorNegative, btnBgColorDisabled,
  btnImgColor, btnImgColorDisabled, defaultBgElemSize, optionBtnSize
} = require("mapEditorConsts.nut")
let { mkOptionBtnImg, mkOptionBtn, mkTextOptionBtn, btnWithActivity, mkTextInputField, mkText,
  mkFramedText, modalBg, mkTextOptionBtnNoUpper
} = require("mapEditorComps.nut")
let { mkBgCollectionChoice } = require("bgCollectionChoice.nut")


let POINTS_SIZE_SETTING_WND = "pointsSizeSettingsWnd"
let GRID_SIZE_SETTING_WND = "gridSizeSettingsWnd"
let ADD_POINT_WND = "addPointWnd"
let POINT_EDIT_WND = "pointEditWnd"
let SELECT_POINT_VIEW_WND = "selectPointViewWnd"

let SETTING_WND = "settingsWnd"
let ADD_BG_ELEMENT_WND = "addBgElementWnd"
let EDIT_BG_ELEMENT_WND = "editBgElementWnd"

let defaultPointView = "mapMark"

let bgElemIdField = Watched("")
let bgElemImgField = Watched("")
let bgElemSizeXField = Watched("")
let bgElemSizeYField = Watched("")
let bgRotateElemField = Watched("")

let pointIdField = Watched("")
let pointViewField = Watched(defaultPointView)

let pointSizeField = Watched("")
let gridSizeField = Watched("")

function askSaveAndClose() {
  if (!isCurPresetChanged.get()) {
    closeEventMapEditor()
    return
  }
  openMsgBox({
    text = loc("hudTuning/apply"),
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "reset", cb = closeEventMapEditor }
      {
        text = loc("filesystem/btnSave")
        styleId = "PRIMARY"
        isDefault = true
        function cb() {
          saveCurrentPreset()
          closeEventMapEditor()
        }
      }
    ]
  })
}

function clearOrFillFields(id = "", view = defaultPointView) {
  pointIdField.set(id)
  pointViewField.set(view)
}

let selectPointViewContent = @() modalBg.__merge({ 
  size = [hdpx(600), hdpx(900)]
  children = makeVertScroll({
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = mapPointsPresentations.keys().sort()
      .map(@(v) mkTextOptionBtnNoUpper(v,
        function() {
          pointViewField.set(v)
          removeModalWindow(SELECT_POINT_VIEW_WND)
        },
        { size = [flex(), optionBtnSize] }))
  })
})

let openPointViewChoice = @()
  addModalWindowWithHeader(SELECT_POINT_VIEW_WND, "Select point view", selectPointViewContent)

function onAddPoint(id, view) {
  if (id == "")
    return openMsgBox({ text = "Point ID is required!" })
  if (id in tuningPoints.get())
    return openMsgBox({ text = "Point ID must be unique" })
  if (null != tuningBgElems.get().findvalue(@(elem) elem.id == id))
    return openMsgBox({ text = $"Already used id '{id}' for bg elem" })

  addOrEditPoint(id, view)
  selectElem(id, ELEM_POINT)
  removeModalWindow(ADD_POINT_WND)
}

function onEditPoint(id, view) {
  addOrEditPoint(id, view)
  removeModalWindow(POINT_EDIT_WND)
}

let addPointContent = @() modalBg.__merge({
  watch = pointViewField
  size = [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields()
    set_kb_focus(pointIdField)
  }
  children = [
    mkText("Point ID:")
    mkTextInputField(pointIdField, "Set point ID",
      { onReturn = @() onAddPoint(pointIdField.get(), pointViewField.get()) })
    mkText("Point View:")
    mkTextOptionBtnNoUpper(pointViewField.get(), openPointViewChoice)
    mkTextOptionBtn("ADD",
      @() onAddPoint(pointIdField.get(), pointViewField.get()))
  ]
})

let pointsSizeSettingContent = modalBg.__merge({
  onAttach = @() pointSizeField.set(presetPointSize.get().tostring())
  children = [
    mkText("Points size:")
    mkTextInputField(pointSizeField, "Set points size", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      function() {
        changeCurPresetField("pointSize", pointSizeField.get() == "" ? defaultPointSize : pointSizeField.get().tointeger())
        removeModalWindow(POINTS_SIZE_SETTING_WND)
      })
  ]
})

let pointEditContent = @() modalBg.__merge({
  watch = pointViewField
  key = POINT_EDIT_WND
  size = [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    let curPoint = tuningPoints.get()?[selectedPointId.get()] ?? {}
    let { view = defaultPointView } = curPoint
    clearOrFillFields(selectedPointId.get(), view)
  }
  children = [
    mkText("Point View:")
    mkTextOptionBtnNoUpper(pointViewField.get(), openPointViewChoice)
    mkTextOptionBtn("SAVE", @() onEditPoint(pointIdField.get(), pointViewField.get()))
  ]
})

function onAddBgElem(elem) {
  let { img, size, rotate = 0 } = elem
  let idx = addBgElement("", img, size, rotate)
  selectElem(idx, ELEM_BG)
  removeModalWindow(ADD_BG_ELEMENT_WND)
}

let addBgElemBtn = mkOptionBtn("ui/gameuiskin#icon_hud_base_new_year.svg",
  @() addModalWindowWithHeader(ADD_BG_ELEMENT_WND, "Create new background element",
    mkBgCollectionChoice(onAddBgElem, modalBg)),
  "Add bg elem")

function onEditBgElem() {
  let idx = selectedBgElemIdx.get()
  if (idx == null)
    return
  let id = bgElemIdField.get()
  let img = bgElemImgField.get()
  let sizeX = toIntegerSafe(bgElemSizeXField.get(), -1, false)
  let sizeY = toIntegerSafe(bgElemSizeYField.get(), -1, false)
  let rotate = toIntegerSafe(bgRotateElemField.get(), 0, false)
  if (img == "")
    return openMsgBox({ text = "Element img is required!" })
  if (id != "" && tuningBgElems.get().findindex(@(elem, i) elem.id == id && i != idx) != null)
    return openMsgBox({ text = "Element ID must be unique" })
  if (id in tuningPoints.get())
    return openMsgBox({ text = $"Already used id '{id}' for point" })

  let elemSize = [
    sizeX <= 0 ? defaultBgElemSize : sizeX,
    sizeY <= 0 ? defaultBgElemSize : sizeY
  ]
  editBgElement(idx, id, img, elemSize, rotate)
  selectElem(idx, ELEM_BG)
  removeModalWindow(EDIT_BG_ELEMENT_WND)
}

let editBgElemContent = modalBg.__merge({
  size = [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    let { id = "", img = "", size = [], rotate = 0 } = tuningBgElems.get()?[selectedBgElemIdx.get()]
    bgElemIdField.set(id)
    bgElemImgField.set(img)
    bgElemSizeXField.set(size?[0].tostring() ?? "")
    bgElemSizeYField.set(size?[1].tostring() ?? "")
    bgRotateElemField.set(rotate.tostring())
  }
  children = [
    mkText("Bg element ID:")
    mkTextInputField(bgElemIdField, "Set bg element ID")
    mkText("Bg element image:")
    mkTextInputField(bgElemImgField, "Set bg element image")
    mkText("Set size in pixels on the X axis:")
    mkTextInputField(bgElemSizeXField, "Set size in pixels on the X axis", { inputType = "num" })
    mkText("Set size in pixels on the Y axis:")
    mkTextInputField(bgElemSizeYField, "Set size in pixels on the Y axis", { inputType = "num" })
    mkText("Set rotate bg element:")
    mkTextInputField(bgRotateElemField, "Set rotate", { inputType = "num" })
    mkTextOptionBtn("EDIT", onEditBgElem)
  ]
})

let toggleBtn = @() {
  watch = isHeaderOptionsOpen
  hplace = ALIGN_LEFT
  pos = [sw(50), 0]
  children = mkOptionBtn("ui/gameuiskin#hud_tank_arrow_segment.svg",
    @() isHeaderOptionsOpen.set(!isHeaderOptionsOpen.get()),
    isHeaderOptionsOpen.get() ? "hudTuning/toggle/desc/hide" : "hudTuning/toggle/desc/show",
    {
      color = btnBgColorDefault
      transform = isHeaderOptionsOpen.get() ? {} : { rotate = 180 }
      transitions = [{ prop = AnimProp.rotate, duration = 0.2, easing = InOutQuad }]
    })
}

let exitBtn = @() {
  watch = isCurPresetChanged
  children = mkOptionBtn("ui/gameuiskin#icon_exit.svg", askSaveAndClose, "hudTuning/exit/desc",
    { color = isCurPresetChanged.get() ? btnBgColorNegative : btnBgColorPositive })
}

let saveBtn = btnWithActivity(isCurPresetChanged, "ui/gameuiskin#icon_save.svg",
  saveCurrentPreset, "hudTuning/save/desc")

let copyElemBtn = @() {
  watch = selectedElem
  children = selectedElem.get()?.eType != ELEM_BG ? null
    : mkOptionBtn("ui/gameuiskin#icon_copy.svg",
        @() selectedElem.get() == null ? null
          : copyElement(selectedElem.get().id, selectedElem.get().eType),
        $"Copy selected {selectedElem.get().eType}")
}

let deleteElemBtn = @() {
  watch = selectedElem
  children = selectedElem.get() == null ? null
    : mkOptionBtn("ui/gameuiskin#btn_trash.svg",
        @() selectedElem.get() == null ? null
          : deleteElement(selectedElem.get().id, selectedElem.get().eType, selectedElem.get()?.subId),
        $"Delete selected {selectedElem.get().eType}",
        { color = btnBgColorNegative })
}

let editElemBtn = @() {
  watch = [selectedPointId, selectedBgElemIdx]
  children = !selectedPointId.get() && selectedBgElemIdx.get() == null ? null
    : mkOptionBtn("ui/gameuiskin#menu_edit.svg",
        @() selectedPointId.get() != null
            ? addModalWindowWithHeader(POINT_EDIT_WND, $"Edit point {selectedPointId.get()}", pointEditContent)
          : selectedBgElemIdx.get() != null
            ? addModalWindowWithHeader(EDIT_BG_ELEMENT_WND, "Edit background element", editBgElemContent)
          : null,
        $"Edit {selectedPointId.get() == null ? "bg elem" : "point"}")
}

let autoSaveBtn = @() {
  watch = needUseAutoSave
  children = mkTextOptionBtn($"Auto save: {needUseAutoSave.get()}",
    @() needUseAutoSave.set(!needUseAutoSave.get()),
    { color = needUseAutoSave.get() ? btnBgColorPositive : btnBgColorNegative })
}

let addPointBtn = mkOptionBtn("ui/gameuiskin#icon_hud_flag.svg",
  @() addModalWindowWithHeader(ADD_POINT_WND, "Create point", addPointContent),
  "Add point")

let gridSizeSettingContent = @() modalBg.__merge({
  onAttach = @() gridSizeField.set(presetGridSize.get().tostring())
  children = [
    mkText("Grid size:")
    mkTextInputField(gridSizeField, "Set grid size", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      function() {
        if (gridSizeField.get() != "")
          changeCurPresetField("gridSize", gridSizeField.get().tointeger())
        removeModalWindow(GRID_SIZE_SETTING_WND)
      })
  ]
})

let settingContent = @() modalBg.__merge({
  size = [hdpx(500), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    mkTextOptionBtn("points size",
      @() addModalWindowWithHeader(POINTS_SIZE_SETTING_WND, "Change points size", pointsSizeSettingContent),
      { size = [flex(), optionBtnSize] })
    mkTextOptionBtn("grid size",
      @() addModalWindowWithHeader(GRID_SIZE_SETTING_WND, "Change grid size", gridSizeSettingContent),
      { size = [flex(), optionBtnSize] })
  ]
})

let settingsBtn = mkOptionBtn("ui/gameuiskin#upgrade_points.avif", @()
  addModalWindowWithHeader(SETTING_WND, "Settings", settingContent),
  "Settings")

let historyBack = @() ((curHistoryIdx.get() ?? 0) != 0 && historyMapElements.get().len() != 0)
  ? setByHistory(min(curHistoryIdx.get() - 1, historyMapElements.get().len() - 1))
  : null

let historyFwd = @() (curHistoryIdx.get() != null && curHistoryIdx.get() < historyMapElements.get().len() - 1)
  ? setByHistory(curHistoryIdx.get() + 1)
  : null

let historyBackBtn = btnWithActivity(Computed(@() (curHistoryIdx.get() ?? 0) > 0),
  "ui/gameuiskin#icon_cancel.svg", historyBack, "hudTuning/back/desc")

function historyFwdBtn() {
  let isAvailable = curHistoryIdx.get() != null && curHistoryIdx.get() < historyMapElements.get().len() - 1
  return {
    watch = [curHistoryIdx, historyMapElements]
    children = mkOptionBtn(
      mkOptionBtnImg("ui/gameuiskin#icon_cancel.svg", { flipX = true, color = isAvailable ? btnImgColor : btnImgColorDisabled }),
        historyFwd, "hudTuning/fwd/desc", { color = isAvailable ? btnBgColorDefault : btnBgColorDisabled })
  }
}

let content = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = optionsBtnGap
  children = [
    exitBtn
    saveBtn
    historyBackBtn
    historyFwdBtn
    autoSaveBtn
    { size = flex() }
    deleteElemBtn
    copyElemBtn
    editElemBtn
    addPointBtn
    addBgElemBtn
    settingsBtn
  ]
}

let mapEditorHeaderOptions = {
  size = [flex(), SIZE_TO_CONTENT]
  children = !isEditAllowed
    ? mkFramedText($"To edit points you must set\ndebug/<color={0xFFFFFFFF}>useAddonVromSrc</color>:b=yes\nin the config.blk")
    : [
      @() {
        watch = isHeaderOptionsOpen
        size = [flex(), SIZE_TO_CONTENT]
        padding = [saBordersRv[0], saBordersRv[1], optionsBtnGap, saBordersRv[1]]
        rendObj = ROBJ_SOLID
        color = 0xC0000000
        children = content
        transform = { translate = [0, isHeaderOptionsOpen.get() ? 0 : hdpx(-500)] }
        transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
      }
      toggleBtn
    ]
}

return mapEditorHeaderOptions
