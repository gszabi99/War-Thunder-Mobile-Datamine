from "%darg/ui_imports.nut" import *
from "%darg/laconic.nut" import *

let {showEntitySelect, propPanelVisible, propPanelClosed, showHelp, de4editMode,
     de4workMode, de4workModes, showUIinEditor, editorTimeStop,
     gizmoBasisType, gizmoBasisTypeNames, gizmoBasisTypeEditingDisabled} = require("state.nut")

let pictureButton = require("components/pictureButton.nut")
let combobox = require("%daeditor/components/combobox.nut")
let cursors =  require("components/cursors.nut")
let {showLogsWindow, hasNewLogerr} = require("%daeditor/state/logsWindow.nut")

let daEditor = require("daEditorEmbedded")
let {DE4_MODE_CREATE_ENTITY, get_instance} = require("entity_editor")
let {DE4_MODE_MOVE, DE4_MODE_ROTATE, DE4_MODE_SCALE, DE4_MODE_MOVE_SURF, DE4_MODE_SELECT,
     DE4_MODE_POINT_ACTION, getEditMode, setEditMode} = daEditor

function toolbarButton(image, action, tooltip_text, checked=null, styles = {}) {
  function onHover(on) {
    cursors.setTooltip(on ? tooltip_text : null)
  }
  let defParams = {
    imageMargin = fsh(0.5)
    action
    checked
    onHover
    styles
  }
  let params = (type(image)=="table") ? defParams.__merge(image) : defParams.__merge({image})
  return pictureButton(params)
}

function modeButton(image, mode, tooltip_text, next_mode=null, next_action=null) {
  local params = (type(image)=="table") ? image : {image}
  params = params.__merge({
    checked = mode==getEditMode()
    imageMargin = fsh(0.5)
    function onHover(on) {
      cursors.setTooltip(on ? tooltip_text : null)
    }
    function action() {
      showEntitySelect.update(false)
      if (next_mode && mode==getEditMode())
        mode = next_mode
      daEditor.setEditMode(mode)
      if (next_action)
        next_action()
    }
  })
  return pictureButton(params)
}


let separator = {
  rendObj = ROBJ_SOLID
  color = Color(100, 100, 100, 100)
  size = [1, fsh(3)]
  margin = [0, fsh(0.5)]
}

let svg = @(name) {image = $"!%daeditor/images/{name}.svg"} 
function mainToolbar() {
  function toggleEntitySelect() {
    if (getEditMode() == DE4_MODE_CREATE_ENTITY || getEditMode() == DE4_MODE_POINT_ACTION)
      setEditMode(DE4_MODE_SELECT)
    showEntitySelect.update(!showEntitySelect.value);
  }
  function toggleLogsWindows() {
    showLogsWindow(!showLogsWindow.value)
  }
  function toggleCreateEntityMode() {
    showEntitySelect.update(false)
    local mode = DE4_MODE_CREATE_ENTITY
    if (DE4_MODE_CREATE_ENTITY==getEditMode())
      mode = DE4_MODE_SELECT
    daEditor.setEditMode(mode)
  }
  let togglePropPanel = function() {
    propPanelClosed(propPanelVisible.value && !showHelp.value)
    propPanelVisible(!propPanelVisible.value)
  }
  let toggleTime = @() editorTimeStop(!editorTimeStop.value)
  let toggleHelp = @() showHelp.update(!showHelp.value)
  let save = @() get_instance().saveObjects("")

  return {
    cursor = cursors.normal
    size = [sw(100), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_WORLD_BLUR
    fillColor = Color(20, 20, 20, 155)
    watch = [de4editMode, propPanelVisible, de4workMode, de4workModes, showUIinEditor, editorTimeStop, showLogsWindow, hasNewLogerr]
    valign = ALIGN_CENTER
    padding =hdpx(4)

    children = [
      
      toolbarButton(svg("select_by_name"), toggleEntitySelect, "Find entity (Tab)", showEntitySelect.value)
      separator
      modeButton(svg("select"), DE4_MODE_SELECT, "Select (Q)")
      modeButton(svg("move"),   DE4_MODE_MOVE,   "Move (W)")
      modeButton(svg("rotate"), DE4_MODE_ROTATE, "Rotate (E)") 
      modeButton(svg("scale"),  DE4_MODE_SCALE,  "Scale (R)")
      modeButton(svg("create"), DE4_MODE_CREATE_ENTITY, "Create entity (T)", DE4_MODE_SELECT)
      separator
      toolbarButton(svg("delete"),     @() get_instance().deleteSelectedObjects(true), "Delete selected (Del)")
      separator
      modeButton(svg("surf"), DE4_MODE_MOVE_SURF, "Surf over ground (Ctrl+Alt+W)")
      toolbarButton(svg("drop"),         @() get_instance().dropObjects(),                     "Drop (Ctrl+Alt+D)")
      toolbarButton(svg("dropnormal"),   @() get_instance().dropObjectsNorm(),                 "Drop on normal (Ctrl+Alt+E)")
      toolbarButton(svg("resetscale"),   @() get_instance().resetScale(),                      "Reset scale (Ctrl+Alt+R)")
      toolbarButton(svg("resetrotate"),  @() get_instance().resetRotate(),                     "Reset rotation (Ctrl+Alt+T)")
      toolbarButton(svg("zoomcenter"),   @() get_instance().zoomAndCenter(),                   "Zoom and center (Z)")
      toolbarButton(svg("parent_set"),   @() get_instance().setParentForSelection(),           "Set parent (Ctrl+P)")
      toolbarButton(svg("parent_clear"), @() get_instance().clearParentForSelection(),         "Clear parent (Alt+P)")
      toolbarButton(svg("parent_free"),  @() get_instance().toggleFreeTransformForSelection(), "Toggle between free and fixed transform")
      separator
      toolbarButton(svg("properties"), togglePropPanel, "Property panel (P)", propPanelVisible.value)
      toolbarButton(svg("hide"), @() get_instance().hideSelectedTemplate(), "Hide")
      toolbarButton(svg("show"), @() get_instance().unhideAll(), "Unhide all")
      separator
      toolbarButton(svg("gui_toggle"), @() showUIinEditor(!showUIinEditor.value), "Show UI", showUIinEditor.value)
      toolbarButton(svg("time_toggle"), toggleTime, "Toggle time (Ctrl+T)", !editorTimeStop.value)
      separator
      toolbarButton(svg("save"), save, "Save")
      toolbarButton(svg("logs"), toggleLogsWindows, "Show errors (Ctrl+L)", showLogsWindow.value, hasNewLogerr.value ? { defColor=Color(251,78,58,250) } : {})
      toolbarButton(svg("help"), toggleHelp, "Help (F1)", showHelp.value)

      de4workModes.value.len() <= 1 ? null : separator
      de4workModes.value.len() <= 1 ? null : {
        size = [hdpx(100),fontH(100)]
        children = combobox(de4workMode, de4workModes)
      }

      separator
      {
        size = [hdpx(150), fontH(100)]
        children = combobox({value = gizmoBasisType, disable = gizmoBasisTypeEditingDisabled}, gizmoBasisTypeNames, "Set gizmo basis mode (X)")
      }
    ]

    hotkeys = [
      ["L.Alt H", toggleEntitySelect],
      ["Tab", toggleEntitySelect],
      ["!L.Ctrl !L.Alt T", toggleCreateEntityMode],
      ["F1", toggleHelp],
      ["!L.Ctrl !L.Alt P", togglePropPanel],
      ["L.Ctrl !L.Alt P", @() get_instance().setParentForSelection()],
      ["!L.Ctrl L.Alt P", @() get_instance().clearParentForSelection()],
      ["L.Ctrl !L.Alt T", toggleTime],
      ["L.Ctrl !L.Alt S", { action = save, ignoreConsumerCallback = true }], 
      ["L.Ctrl !L.Alt L", toggleLogsWindows],
      ["Esc", @() daEditor.setEditMode(DE4_MODE_SELECT)]
    ]
  }
}


return mainToolbar
