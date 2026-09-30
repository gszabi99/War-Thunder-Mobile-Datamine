from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import toIntegerSafe
from "%appGlobals/config/mapPointsPresentation.nut" import mapPointsPresentations, getDefaultPointSize, defaultPointView
from "%rGui/collections/rewardProgressConsts.nut" import defRewardProgress, rewardSizes
from "%rGui/components/modalWindows.nut" import removeModalWindow, addModalWindowWithHeader
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/debugTools/debugMapPoints/bgCollectionChoice.nut" import mkBgCollectionChoice
from "%rGui/debugTools/debugMapPoints/mapEditorComps.nut" import mkOptionBtnImg, mkOptionBtn, mkTextOptionBtn,
  btnWithActivity, mkTextInputField, mkText, mkFramedText, modalBg, mkTextOptionBtnNoUpper
from "%rGui/debugTools/debugMapPoints/mapEditorConsts.nut" import optionsBtnGap, btnBgColorDefault,
  btnBgColorPositive, btnBgColorNegative, btnBgColorDisabled, btnImgColor, btnImgColorDisabled, defaultBgElemSize,
  optionBtnSize, SNAP_NONE, SNAP_GRID, SNAP_ELEMS
from "%rGui/debugTools/debugMapPoints/mapEditorState.nut" import isCurPageChanged, closeEventMapEditor,
  saveCurrentPage, addOrEditPoint, selectedBgElemIdx, isHeaderOptionsOpen, selectedPointId, setByHistory, curHistoryIdx,
  deleteElement, isEditAllowed, needUseAutoSave, tuningPoints, tuningBgElems, historyMapElements, snapType,
  selectElem, changeCurPageField, pageGridSize, pageLineSectionLen, pageRoundedDashes, pageLineType, pageLineWidth,
  ELEM_POINT, ELEM_BG, addBgElement, editBgElement, selectedElem, copyElement, curEventNodeViews, pagePointSizes,
  pageObjDist, isCollectionMode, tuningRewards, selectedRewardId, addOrEditReward, ELEM_REWARD
from "%rGui/event/treeEvent/treeEventUtils.nut" import lineTypes, LINE_SOLID


const TYPE_SIZES_SETTING_WND = "typeSizesSettingsWnd"
const GRID_SIZE_SETTING_WND = "gridSizeSettingsWnd"
const LINE_SETTING_WND = "lineSettingsWnd"
const LINE_DASH_SETTING_WND = "lineDashSettingsWnd"
const LINE_TYPE_SETTING_WND = "lineTypeSettingsWnd"
const LINE_WIDTH_SETTING_WND = "lineWidthSettingsWnd"
const ADD_POINT_WND = "addPointWnd"
const POINT_EDIT_WND = "pointEditWnd"
const SELECT_POINT_VIEW_WND = "selectPointViewWnd"

const SETTING_WND = "settingsWnd"
const ADD_BG_ELEMENT_WND = "addBgElementWnd"
const EDIT_BG_ELEMENT_WND = "editBgElementWnd"

let effectiveView = @(id, view, nodeViews) view != "" ? view : (nodeViews?[id] ?? defaultPointView)

const viewIconSize = hdpxi(50)
function mkViewBtn(viewKey, onClick, ovr = {}) {
  let icon = mapPointsPresentations?[viewKey].unlocked

  return mkTextOptionBtnNoUpper(viewKey, onClick, {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_LEFT
    valign = ALIGN_CENTER
    gap = hdpx(15)
    padding = hdpx(15)
    children = [
      icon == null ? null : {
        size = viewIconSize
        rendObj = ROBJ_IMAGE
        image = Picture($"{icon.image}:{viewIconSize}:P")
        color = icon.color
        keepAspect = true
      }
      {
        rendObj = ROBJ_TEXT
        text = viewKey
      }.__update(fontTinyAccented)
    ]
  }.__update(ovr))
}

let bgElemIdField = Watched("")
let bgElemImgField = Watched("")
let bgElemSizeXField = Watched("")
let bgElemSizeYField = Watched("")
let bgRotateElemField = Watched("")

let pointIdField = Watched("")
let pointViewField = Watched(defaultPointView)

let gridSizeField = Watched("")
let lineWidthField = Watched("")
let lineSectionLenField = Watched("")

function askSaveAndClose() {
  if (!isCurPageChanged.get()) {
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
          saveCurrentPage()
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
  size = const [hdpx(600), hdpx(900)]
  children = makeVertScroll({
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = mapPointsPresentations.keys().sort()
      .map(@(v) mkViewBtn(v,
        function() {
          pointViewField.set(v)
          removeModalWindow(SELECT_POINT_VIEW_WND)
        },
        { size = [FLEX, optionBtnSize] }))
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

function onEditPoint(id, view, nodeViews) {
  let auto = nodeViews?[id] ?? defaultPointView
  addOrEditPoint(id, view == auto ? "" : view)
  removeModalWindow(POINT_EDIT_WND)
}

let addPointContent = @() modalBg.__merge({
  watch = pointViewField
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields()
    set_kb_focus(pointIdField)
  }
  children = [
    mkText("Point ID:")
    mkTextInputField(pointIdField, "Set point ID",
      { onReturn = @() onAddPoint(pointIdField.get(), pointViewField.get()) })
    mkText("Point View:")
    mkViewBtn(pointViewField.get(), openPointViewChoice)
    mkTextOptionBtn("ADD",
      @() onAddPoint(pointIdField.get(), pointViewField.get()))
  ]
})

let typeSizeFields = mapPointsPresentations.keys().sort().reduce(@(res, k) res.$rawset(k, Watched("")), {})
let typeSizesSettingContent = modalBg.__merge({
  size = const [hdpx(500), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  function onAttach() {
    let sizes = pagePointSizes.get()
    foreach (k, f in typeSizeFields)
      f.set((sizes?[k] ?? getDefaultPointSize(k)).tostring())
  }
  children = mapPointsPresentations.keys().sort().map(@(k) {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    valign = ALIGN_CENTER
    children = [
      mkText(k)
      mkTextInputField(typeSizeFields[k], "size px", { inputType = "num" })
    ]
  }).append(
    mkTextOptionBtn("SAVE",
      function() {
        let sizes = {}
        foreach (k, f in typeSizeFields)
          if (f.get() != "")
            sizes[k] <- f.get().tointeger()
        changeCurPageField("pointSizes", sizes)
        removeModalWindow(TYPE_SIZES_SETTING_WND)
      }))
})

let pointEditContent = @() modalBg.__merge({
  watch = pointViewField
  key = POINT_EDIT_WND
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    let curPoint = tuningPoints.get()?[selectedPointId.get()] ?? {}
    let { view = "" } = curPoint
    clearOrFillFields(selectedPointId.get(), effectiveView(selectedPointId.get(), view, curEventNodeViews.get()))
  }
  children = [
    mkText("Point View:")
    mkViewBtn(pointViewField.get(), openPointViewChoice)
    mkTextOptionBtn("SAVE", @() onEditPoint(pointIdField.get(), pointViewField.get(), curEventNodeViews.get()))
  ]
})

function onAddBgElem(elem, imgSize) {
  let { img, rotate = 0 } = elem
  local size = elem?.size ?? imgSize
  if (size[0] <= 0 || size[1] <= 0)
    size = [100, 100]
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
  if (id in tuningRewards.get())
    return openMsgBox({ text = $"Already used id '{id}' for reward" })

  let elemSize = [
    sizeX <= 0 ? defaultBgElemSize : sizeX,
    sizeY <= 0 ? defaultBgElemSize : sizeY
  ]
  editBgElement(idx, id, img, elemSize, rotate)
  selectElem(idx, ELEM_BG)
  removeModalWindow(EDIT_BG_ELEMENT_WND)
}

function onChooseBgImageForEdit(elem, imgSize) {
  let { img, rotate = null } = elem
  bgElemImgField.set(img)
  if (rotate != null)
    bgRotateElemField.set(rotate.tostring())
  local size = elem?.size ?? imgSize
  if (size[0] > 0 && size[1] > 0) {
    bgElemSizeXField.set(size[0].tostring())
    bgElemSizeYField.set(size[1].tostring())
  }
  removeModalWindow("choose_bg_image")
}

let editBgElemContent = modalBg.__merge({
  size = const [hdpx(600), SIZE_TO_CONTENT]
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
    mkTextInputField(bgRotateElemField, "Set rotate", { charMask = "-0123456789" })
    {
      size = FLEX_H
      children = [
        mkTextOptionBtn("APPLY", onEditBgElem)
        mkTextOptionBtn("CHOOSE IMAGE",
          @() addModalWindowWithHeader("choose_bg_image", "Choose image",
            mkBgCollectionChoice(onChooseBgImageForEdit, modalBg))
          { hplace = ALIGN_RIGHT })
      ]
    }
  ]
})

let toggleBtn = @() {
  watch = isHeaderOptionsOpen
  hplace = ALIGN_LEFT
  pos = const [sw(50), 0]
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
  watch = isCurPageChanged
  children = mkOptionBtn("ui/gameuiskin#icon_exit.svg", askSaveAndClose, "hudTuning/exit/desc",
    { color = isCurPageChanged.get() ? btnBgColorNegative : btnBgColorPositive })
}

let saveBtn = btnWithActivity(isCurPageChanged, "ui/gameuiskin#icon_save.svg",
  saveCurrentPage, "hudTuning/save/desc")

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

let autoSaveBtn = @() {
  watch = needUseAutoSave
  children = mkTextOptionBtn($"Auto save: {needUseAutoSave.get()}",
    @() needUseAutoSave.set(!needUseAutoSave.get()),
    { color = needUseAutoSave.get() ? btnBgColorPositive : btnBgColorNegative })
}

let snapBtn = @() {
  watch = snapType
  children = mkTextOptionBtn($"Snap: {snapType.get() ?? "none"}",
    @() snapType.set(snapType.get() == SNAP_NONE ? SNAP_GRID
      : snapType.get() == SNAP_GRID ? SNAP_ELEMS
      : SNAP_NONE),
    { color = snapType.get() != SNAP_NONE ? btnBgColorPositive : btnBgColorNegative })
}

let addPointBtn = mkOptionBtn("ui/gameuiskin#icon_hud_flag.svg",
  @() addModalWindowWithHeader(ADD_POINT_WND, "Create point", addPointContent),
  "Add point")

let openRewardViewChoice = @(apply)
  addModalWindowWithHeader("reward_view_choice", "Select reward view",
    modalBg.__merge({ 
      size = const [hdpx(600), hdpx(900)]
      children = makeVertScroll({
        size = FLEX_H
        valign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = hdpx(20)
        children = rewardSizes.keys().sort()
          .map(@(v) mkTextOptionBtnNoUpper(v,
            function() {
              apply(v)
              removeModalWindow("reward_view_choice")
            }
            { size = [FLEX, optionBtnSize] }))
      })
    }))

function onAddReward(id, view) {
  if (id == "")
    return openMsgBox({ text = "Reward ID is required!" })
  if (id in tuningRewards.get())
    return openMsgBox({ text = "Reward ID must be unique" })
  if (null != tuningBgElems.get().findvalue(@(elem) elem.id == id))
    return openMsgBox({ text = $"Already used id '{id}' for bg elem" })

  addOrEditReward(id, view)
  selectElem(id, ELEM_REWARD)
  removeModalWindow("add_reward")
}

function openAddRewardWnd() {
  let id = Watched("")
  let view = Watched(defRewardProgress)

  addModalWindowWithHeader("add_reward", "Create reward",
    @() modalBg.__merge({
      watch = view
      size = const [hdpx(600), SIZE_TO_CONTENT]
      onAttach = @() set_kb_focus(id)
      children = [
        mkText("Reward ID:")
        mkTextInputField(id, "Set reward ID",
          { onReturn = @() onAddReward(id.get(), view.get()) })
        mkText("Reward View:")
        mkTextOptionBtnNoUpper(view.get(), @() openRewardViewChoice(@(v) view.set(v)),
          { size = [FLEX, optionBtnSize] })
        mkTextOptionBtn("ADD",
          @() onAddReward(id.get(), view.get()))
      ]
    }))
}

let addRewardBtn = mkOptionBtn("ui/gameuiskin#quest_events_icon.svg", openAddRewardWnd, "Add reward")

function onEditReward(id, view) {
  if (view != (tuningRewards.get()?[id].view ?? defRewardProgress))
    addOrEditReward(id, view)
  removeModalWindow("edit_reward")
}

function openEditRewardWnd() {
  let id = selectedRewardId.get()
  let view = Watched(tuningRewards.get()?[id].view ?? defRewardProgress)
  addModalWindowWithHeader("edit_reward", $"Edit reward {id}",
    @() modalBg.__merge({
      watch = view
      size = const [hdpx(600), SIZE_TO_CONTENT]
      children = [
        mkText("Reward View:")
        mkTextOptionBtnNoUpper(view.get(), @() openRewardViewChoice(@(v) view.set(v)),
          { size = [FLEX, optionBtnSize] })
        mkTextOptionBtn("APPLY", @() onEditReward(id, view.get()))
      ]
    }))
}

let editElemBtn = @() {
  watch = [selectedPointId, selectedBgElemIdx, selectedRewardId]
  children = !selectedPointId.get() && selectedBgElemIdx.get() == null && !selectedRewardId.get() ? null
    : mkOptionBtn("ui/gameuiskin#menu_edit.svg",
        @() selectedPointId.get() != null
            ? addModalWindowWithHeader(POINT_EDIT_WND, $"Edit point {selectedPointId.get()}", pointEditContent)
          : selectedBgElemIdx.get() != null
            ? addModalWindowWithHeader(EDIT_BG_ELEMENT_WND, "Edit background element", editBgElemContent)
          : selectedRewardId.get() != null ? openEditRewardWnd()
          : null,
        selectedRewardId.get() ? "Edit reward"
          : selectedPointId.get() ? "Edit point"
          : "Edit bg elem")
}

let gridSizeSettingContent = @() modalBg.__merge({
  onAttach = @() gridSizeField.set(pageGridSize.get().tostring())
  children = [
    mkText("Grid size:")
    mkTextInputField(gridSizeField, "Set grid size", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      function() {
        if (gridSizeField.get() != "")
          changeCurPageField("gridSize", gridSizeField.get().tointeger())
        removeModalWindow(GRID_SIZE_SETTING_WND)
      })
  ]
})

let lineDashSettingContent = @() modalBg.__merge({
  onAttach = @() lineSectionLenField.set(pageLineSectionLen.get().tostring())
  children = [
    mkText("Dash section length (smaller = more dashes):")
    mkTextInputField(lineSectionLenField, "Set dash section length", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      function() {
        if (lineSectionLenField.get() != "")
          changeCurPageField("lineSectionLen", lineSectionLenField.get().tointeger())
        removeModalWindow(LINE_DASH_SETTING_WND)
      })
  ]
})

let lineTypeSettingContent = @() modalBg.__merge({
  size = const [hdpx(500), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = lineTypes.map(@(t) mkTextOptionBtn(t,
    function() {
      changeCurPageField("lineType", t)
      removeModalWindow(LINE_TYPE_SETTING_WND)
    },
    { size = [FLEX, optionBtnSize] }))
})

let lineWidthSettingContent = @() modalBg.__merge({
  onAttach = @() lineWidthField.set(pageLineWidth.get().tostring())
  children = [
    mkText("Line width (px):")
    mkTextInputField(lineWidthField, "Set line width", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      function() {
        if (lineWidthField.get() != "")
          changeCurPageField("lineWidth", lineWidthField.get().tointeger())
        removeModalWindow(LINE_WIDTH_SETTING_WND)
      })
  ]
})

let lineSettingContent = @() modalBg.__merge({
  watch = pageLineType
  size = const [hdpx(500), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    mkTextOptionBtn("Line type",
      @() addModalWindowWithHeader(LINE_TYPE_SETTING_WND, "Select line type", lineTypeSettingContent),
      { size = [FLEX, optionBtnSize] })
    pageLineType.get() == LINE_SOLID ? null
      : mkTextOptionBtn("Line dashes",
          @() addModalWindowWithHeader(LINE_DASH_SETTING_WND, "Change line dash frequency", lineDashSettingContent),
          { size = [FLEX, optionBtnSize] })
    pageLineType.get() == LINE_SOLID ? null
      : mkTextOptionBtn("Line ends: round / square",
          @() changeCurPageField("roundedDashes", !pageRoundedDashes.get()),
          { size = [FLEX, optionBtnSize] })
    mkTextOptionBtn("Line width",
      @() addModalWindowWithHeader(LINE_WIDTH_SETTING_WND, "Change line width", lineWidthSettingContent),
      { size = [FLEX, optionBtnSize] })
  ]
})

function openObjectDistanceWnd() {
  let valueStr = Watched(pageObjDist.get().tostring())
  addModalWindowWithHeader("obj_dist", "Change snap object distance",
    modalBg.__merge({
      children = [
        mkText("Object snap distance:")
        mkTextInputField(valueStr, "Set snap distance", { inputType = "num" })
        mkTextOptionBtn("SAVE",
          function() {
            if (valueStr.get() != "")
              changeCurPageField("objDist", valueStr.get().tointeger())
            removeModalWindow("obj_dist")
          })
      ]
    }))
}

let settingContent = @() modalBg.__merge({
  size = const [hdpx(500), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  children = [
    mkTextOptionBtn("type sizes",
      @() addModalWindowWithHeader(TYPE_SIZES_SETTING_WND, "Marker size per type", typeSizesSettingContent),
      { size = [FLEX, optionBtnSize] })
    mkTextOptionBtn("grid size",
      @() addModalWindowWithHeader(GRID_SIZE_SETTING_WND, "Change grid size", gridSizeSettingContent),
      { size = [FLEX, optionBtnSize] })
    mkTextOptionBtn("object distance", openObjectDistanceWnd, { size = [FLEX, optionBtnSize] })
    mkTextOptionBtn("line settings",
      @() addModalWindowWithHeader(LINE_SETTING_WND, "Line settings", lineSettingContent),
      { size = [FLEX, optionBtnSize] })
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

let content = @() {
  watch = isCollectionMode
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = optionsBtnGap
  children = [
    exitBtn
    saveBtn
    historyBackBtn
    historyFwdBtn
    autoSaveBtn
    snapBtn
    { size = FLEX }
    deleteElemBtn
    copyElemBtn
    editElemBtn
    isCollectionMode.get() ? addRewardBtn : addPointBtn
    addBgElemBtn
    settingsBtn
  ]
}

let mapEditorHeaderOptions = {
  size = FLEX_H
  children = !isEditAllowed
    ? mkFramedText($"To edit points you must set\ndebug/<color={0xFFFFFFFF}>useAddonVromSrc</color>:b=yes\nin the config.blk")
    : [
      @() {
        watch = isHeaderOptionsOpen
        size = FLEX_H
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
