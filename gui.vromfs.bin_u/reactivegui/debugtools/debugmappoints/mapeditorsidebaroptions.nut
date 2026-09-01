from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/components/modalWindows.nut" import removeModalWindow, addModalWindowWithHeader
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/debugTools/debugMapPoints/mapEditorComps.nut" import mkOptionBtn, mkTextOptionBtn, mkTextInputField,
  mkText, mkTextArea, modalBg
from "%rGui/debugTools/debugMapPoints/mapEditorConsts.nut" import optionsBtnGap, btnBgColorDefault, optionBtnSize,
  btnBgColorNegative, btnBgColorPositive
from "%rGui/debugTools/debugMapPoints/mapEditorState.nut" import isSidebarOptionsOpen, loadPage, createPageByTree,
  curEventId, availableEvents, curEventPages, selectEvent, pageMapSize, currentPageId, savedPages, addOrEditPage,
  deletePage, pageBackground, isCurPageChanged, saveCurrentPage, selectedPointId
from "%rGui/event/treeEvent/treeEventState.nut" import getEventNodeType
from "%rGui/event/treeEvent/treeEventUtils.nut" import getEventMapNodes


const ADD_PAGE_WND = "addPageWnd"
const EDIT_PAGE_WND = "editPageWnd"
const SELECT_EVENT_WND = "selectEventWnd"
const SELECT_PAGE_WND = "selectPageWnd"
const GENERATE_EVENT_WND = "generateEventWnd"

let pageIdField = Watched("")
let pageBackgroundField = Watched("")

let mapSizeXField = Watched("")
let mapSizeYField = Watched("")

function askSaveAndContinue(handler) {
  if (!isCurPageChanged.get()) {
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
          saveCurrentPage()
          handler()
        }
      }
    ]
  })
}

function clearOrFillFields(id = "", img = "") {
  pageIdField.set(id)
  pageBackgroundField.set(img)
}

function onAddPage(id, bg, mapSize) {
  if (id == "")
    return openMsgBox({ text = "Page ID is required!" })
  if (id in savedPages.get())
    return openMsgBox({ text = "Page ID must be unique" })

  addOrEditPage(id, bg, mapSize)
  removeModalWindow(ADD_PAGE_WND)
}

function onEditPage(id, bg, mapSize) {
  addOrEditPage(id, bg, mapSize)
  removeModalWindow(EDIT_PAGE_WND)
}

let mkEventPickContent = @(wndId, onPick) modalBg.__merge({
  size = const [hdpx(700), hdpx(900)]
  children = makeVertScroll(@() {
    watch = availableEvents
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = availableEvents.get()
      .map(@(id) mkTextOptionBtn(id, function() {
        onPick(id)
        removeModalWindow(wndId)
      }, { size = [FLEX, optionBtnSize] }))
  })
})

let selectEventContent = mkEventPickContent(SELECT_EVENT_WND, selectEvent)
let generateEventContent = mkEventPickContent(GENERATE_EVENT_WND, createPageByTree)

let selectPageContent = modalBg.__merge({
  size = const [hdpx(700), hdpx(900)]
  children = makeVertScroll(@() {
    watch = curEventPages
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = curEventPages.get().keys().sort()
      .map(@(id) mkTextOptionBtn(id, function() {
        loadPage(id)
        removeModalWindow(SELECT_PAGE_WND)
      }, { size = [FLEX, optionBtnSize] }))
  })
})

let addPageContent = modalBg.__merge({
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields()

    mapSizeXField.set(pageMapSize.get()[0].tostring())
    mapSizeYField.set(pageMapSize.get()[1].tostring())
  }
  children = [
    mkText("Page ID:")
    mkTextInputField(pageIdField, "Set page ID")
    mkText("Page background:")
    mkTextInputField(pageBackgroundField, "Set page background")
    mkText("Set size in pixels on the X axis:")
    mkTextInputField(mapSizeXField, "Set size in pixels on the X axis", { inputType = "num" })
    mkText("Set size in pixels on the Y axis:")
    mkTextInputField(mapSizeYField, "Set size in pixels on the Y axis", { inputType = "num" })
    mkTextOptionBtn("ADD",
      @() onAddPage(pageIdField.get(), pageBackgroundField.get(),
        [mapSizeXField.get().tointeger(), mapSizeYField.get().tointeger()]))
  ]
})

let editPageContent = modalBg.__merge({
  size = const [hdpx(600), SIZE_TO_CONTENT]
  function onAttach() {
    clearOrFillFields(currentPageId.get(), pageBackground.get())

    mapSizeXField.set(pageMapSize.get()[0].tostring())
    mapSizeYField.set(pageMapSize.get()[1].tostring())
  }
  children = [
    mkText("Page background:")
    mkTextInputField(pageBackgroundField, "Set page background")
    mkText("Set size in pixels on the X axis:")
    mkTextInputField(mapSizeXField, "Set size in pixels on the X axis", { inputType = "num" })
    mkText("Set size in pixels on the Y axis:")
    mkTextInputField(mapSizeYField, "Set size in pixels on the Y axis", { inputType = "num" })
    mkTextOptionBtn("SAVE",
      @() onEditPage(pageIdField.get(), pageBackgroundField.get(),
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

let deletePageBtn = @() {
  watch = currentPageId
  children = !currentPageId.get() ? null
    : mkTextOptionBtn("Delete page", @() deletePage(currentPageId.get()), { color = btnBgColorNegative })
}
let editPageBtn = @(id) mkTextOptionBtn("Edit page", @()
  addModalWindowWithHeader(EDIT_PAGE_WND, $"Edit page {id}", editPageContent), { size = [FLEX, optionBtnSize] })
let addPageBtn = mkTextOptionBtn("Add page", @() askSaveAndContinue(@()
  addModalWindowWithHeader(ADD_PAGE_WND, "Create new blank page", addPageContent)), { size = [FLEX, optionBtnSize] })
let selectEventBtn = mkTextOptionBtn("Select event", @() askSaveAndContinue(@()
  addModalWindowWithHeader(SELECT_EVENT_WND, "Select event", selectEventContent)), { size = [FLEX, optionBtnSize] })
let selectPageBtn = mkTextOptionBtn("Select page", @() askSaveAndContinue(@()
  addModalWindowWithHeader(SELECT_PAGE_WND, "Select page", selectPageContent)), { size = [FLEX, optionBtnSize] })
let generatePagesBtn = mkTextOptionBtn("Generate pages",
  @() askSaveAndContinue(@()
    addModalWindowWithHeader(GENERATE_EVENT_WND, "Select event to generate pages", generateEventContent)),
  { size = [FLEX, optionBtnSize], color = btnBgColorPositive })

let mkNodeInfoRows = @(nodeId, node) mkTextArea("\n".join([
  $"CURRENT ID: {nodeId}"
  $"TYPE: {getEventNodeType(node)}"
  $"PAGE: {node?.page ?? ""}"
  $"CURRENCY: {node?.currencyId ?? ""}"
  $"PRICE: {node?.price ?? 0}"
  $"QUESTS: {node?.meta.quests ?? ""}"
]))

function content() {
  let node = getEventMapNodes(serverConfigs.get(), curEventId.get())?[selectedPointId.get()]
  return {
    watch = [currentPageId, curEventId, availableEvents, curEventPages, selectedPointId, serverConfigs]
    size = const [hdpx(300), FLEX]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = optionsBtnGap
    children = node != null
      ? mkNodeInfoRows(selectedPointId.get(), node)
      : [
          addPageBtn
          currentPageId.get() ? editPageBtn(currentPageId.get()) : null
          availableEvents.get().len() > 1 ? selectEventBtn : null
          curEventPages.get().len() > 1 ? selectPageBtn : null
          generatePagesBtn
          { size = FLEX_V }
          deletePageBtn
        ]
  }
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
