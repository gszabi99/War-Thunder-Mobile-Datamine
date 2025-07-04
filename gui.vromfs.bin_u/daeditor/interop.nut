let {editorIsActive, editorFreeCam, entitiesListUpdateTrigger, showTemplateSelect,
     showPointAction, callPointActionCallback, resetPointActionMode,
     handleEntityCreated, handleEntityRemoved, handleEntityMoved,
     de4editMode, de4workMode, gizmoBasisType, gizmoBasisTypeEditingDisabled, canChangeGizmoBasisType,
     gizmoCenterType} = require("state.nut")

let daEditor = require("daEditorEmbedded")
let entity_editor = require("entity_editor")

let { eventbus_subscribe } = require("eventbus")

let {DE4_MODE_POINT_ACTION, isFreeCamMode=null} = daEditor
let {DE4_MODE_CREATE_ENTITY, get_point_action_op} = entity_editor


eventbus_subscribe("daEditorEmbedded.onDeSetWorkMode", function onDeSetWorkMode(mode) {
  de4workMode(mode)
})

eventbus_subscribe("daEditorEmbedded.onDeSetEditMode", function onDeSetEditMode(mode) {
  de4editMode(mode)
  showTemplateSelect.set(mode == DE4_MODE_CREATE_ENTITY)

  showPointAction(mode == DE4_MODE_POINT_ACTION)
  if (!showPointAction.get())
    resetPointActionMode()

  gizmoBasisTypeEditingDisabled(!canChangeGizmoBasisType())
})

eventbus_subscribe("daEditorEmbedded.onDeSetGizmoBasis", function onDeSetGizmoBasis(basis) {
  gizmoBasisType(basis)
})

eventbus_subscribe("daEditorEmbedded.onDeSetGizmoCenterType", function onDeSetGizmoCenterType(center) {
  gizmoCenterType(center)
})

eventbus_subscribe("entity_editor.onEditorActivated", function onEditorActivated(on) {
  editorIsActive.update(on)
})

eventbus_subscribe("entity_editor.onEditorChanged", function onEditorChanged(_) {
  editorFreeCam.update(isFreeCamMode?() ?? false)

  local paOp = get_point_action_op()
  if (paOp != "") {
    let mod      = entity_editor.get_point_action_mod()
    let has_pos  = entity_editor.get_point_action_has_pos()
    let pos      = entity_editor.get_point_action_pos()
    let ext_id   = entity_editor.get_point_action_ext_id()
    let ext_name = entity_editor.get_point_action_ext_name()
    let ext_mtx  = entity_editor.get_point_action_ext_mtx()
    let ext_sph  = entity_editor.get_point_action_ext_sph()
    let ext_eid  = entity_editor.get_point_action_ext_eid()
    local ev = {
      op = paOp
      mod
      pos = has_pos ? pos : null
      ext_id
      ext_name
      ext_mtx
      ext_sph
      ext_eid
    }
    callPointActionCallback(ev)
  }
})

eventbus_subscribe("entity_editor.onEntityAdded", function onEntityAdded(_eid) {
  entitiesListUpdateTrigger.modify(@(v) v+1)
})

eventbus_subscribe("entity_editor.onEntityRemoved", function onEntityRemoved(eid) {
  entitiesListUpdateTrigger.modify(@(v) v+1)
  handleEntityRemoved(eid)
})

eventbus_subscribe("entity_editor.onEntityNewBySample", function onEntityNewBySample(eid) {
  handleEntityCreated(eid)
})

eventbus_subscribe("entity_editor.onEntityMoved", function onEntityMoved(eid) {
  handleEntityMoved(eid)
})
